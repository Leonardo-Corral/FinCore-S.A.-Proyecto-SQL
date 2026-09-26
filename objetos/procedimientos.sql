-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS — Proyecto FinCore S.A.
-- Requiere: objetos/funciones.sql ya ejecutado
-- ============================================================
USE fincore_sa;

-- ------------------------------------------------------------
-- sp_registrar_pago
-- ------------------------------------------------------------
-- Recibe el préstamo, monto, tipo de pago y canal. Valida que
-- el préstamo exista y esté Activo/Vencido, registra el pago,
-- actualiza el saldo pendiente y, si llega a cero, cambia el
-- estado a Cancelado. Todo dentro de una transacción con
-- manejo de errores (EXIT HANDLER + ROLLBACK + RESIGNAL).
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_registrar_pago;

DELIMITER $$

CREATE PROCEDURE sp_registrar_pago(
    IN p_id_prestamo INT,
    IN p_monto       DECIMAL(10,2),
    IN p_tipo_pago   ENUM('Cuota','Prepago','Mora'),
    IN p_canal       ENUM('App','Sucursal','Transferencia','Débito Automático')
)
BEGIN
    DECLARE v_estado_actual   VARCHAR(20);
    DECLARE v_saldo_actual    DECIMAL(12,2);
    DECLARE v_nuevo_saldo     DECIMAL(12,2);

    -- Si ocurre cualquier error SQL dentro del bloque, deshacemos todo
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL; -- re-lanza el error original para que el que llamó lo vea
    END;

    START TRANSACTION;

    -- 1. Validar que el préstamo exista y traer su estado/saldo
    SELECT estado, saldo_pendiente
      INTO v_estado_actual, v_saldo_actual
      FROM prestamos
     WHERE id_prestamo = p_id_prestamo
     FOR UPDATE; -- bloquea la fila para evitar pagos simultáneos sobre el mismo préstamo

    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El préstamo indicado no existe.';
    END IF;

    -- 2. Validar que esté en un estado que admite pagos
    IF v_estado_actual NOT IN ('Activo','Vencido') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden registrar pagos sobre préstamos Activos o Vencidos.';
    END IF;

    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El monto del pago debe ser mayor a cero.';
    END IF;

    -- 3. Registrar el pago (siempre se registra, incluso si es de tipo Mora)
    INSERT INTO pagos (id_prestamo, fecha_pago, monto_pagado, tipo_pago, canal)
    VALUES (p_id_prestamo, CURDATE(), p_monto, p_tipo_pago, p_canal);

    -- 4. Solo Cuota y Prepago reducen el saldo pendiente (Mora es un cargo, no capital)
    IF p_tipo_pago IN ('Cuota','Prepago') THEN
        SET v_nuevo_saldo = GREATEST(v_saldo_actual - p_monto, 0); -- nunca queda negativo

        UPDATE prestamos
           SET saldo_pendiente = v_nuevo_saldo,
               estado = IF(v_nuevo_saldo = 0, 'Cancelado', estado)
         WHERE id_prestamo = p_id_prestamo;
    END IF;

    COMMIT;
END$$

DELIMITER ;

-- ------------------------------------------------------------
-- sp_generar_resumen_mensual
-- ------------------------------------------------------------
-- Recibe año y mes, calcula los indicadores del período
-- (préstamos otorgados, monto total, pagos recibidos y tasa de
-- morosidad) y hace upsert en resumen_mensual con
-- INSERT ... ON DUPLICATE KEY UPDATE (aprovechando la UNIQUE KEY
-- uk_anio_mes).
--
-- Nota de diseño: el esquema no guarda historial mes a mes de
-- 'estado'/'dias_mora' (solo el valor actual), por lo que
-- prestamos_vencidos y tasa_morosidad reflejan la foto actual
-- de la cartera completa, no algo exclusivo del período.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_generar_resumen_mensual;

DELIMITER $$

CREATE PROCEDURE sp_generar_resumen_mensual(
    IN p_anio INT,
    IN p_mes  INT
)
BEGIN
    DECLARE v_total_prestamos       INT;
    DECLARE v_monto_total_otorgado  DECIMAL(14,2);
    DECLARE v_total_pagos           DECIMAL(14,2);
    DECLARE v_prestamos_vencidos    INT;
    DECLARE v_total_cartera         INT;
    DECLARE v_tasa_morosidad        DECIMAL(5,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_mes < 1 OR p_mes > 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El mes debe estar entre 1 y 12.';
    END IF;

    START TRANSACTION;

    -- Préstamos otorgados en el período
    SELECT COUNT(*), COALESCE(SUM(monto_otorgado), 0)
      INTO v_total_prestamos, v_monto_total_otorgado
      FROM prestamos
     WHERE YEAR(fecha_otorgamiento) = p_anio
       AND MONTH(fecha_otorgamiento) = p_mes;

    -- Pagos recibidos en el período (sin importar de qué préstamo)
    SELECT COALESCE(SUM(monto_pagado), 0)
      INTO v_total_pagos
      FROM pagos
     WHERE YEAR(fecha_pago) = p_anio
       AND MONTH(fecha_pago) = p_mes;

    -- Foto actual de la cartera (no es histórico por período, es el estado a hoy)
    SELECT COUNT(*)
      INTO v_prestamos_vencidos
      FROM prestamos
     WHERE estado = 'Vencido';

    SELECT COUNT(*)
      INTO v_total_cartera
      FROM prestamos
     WHERE estado IN ('Activo','Vencido');

    SET v_tasa_morosidad = IF(v_total_cartera = 0, 0,
                              ROUND((v_prestamos_vencidos / v_total_cartera) * 100, 2));

    -- Insertar o actualizar (gracias a la UNIQUE KEY uk_anio_mes)
    INSERT INTO resumen_mensual (
        anio, mes, total_prestamos, monto_total_otorgado,
        total_pagos_recibidos, prestamos_vencidos, tasa_morosidad
    )
    VALUES (
        p_anio, p_mes, v_total_prestamos, v_monto_total_otorgado,
        v_total_pagos, v_prestamos_vencidos, v_tasa_morosidad
    )
    ON DUPLICATE KEY UPDATE
        total_prestamos        = VALUES(total_prestamos),
        monto_total_otorgado   = VALUES(monto_total_otorgado),
        total_pagos_recibidos  = VALUES(total_pagos_recibidos),
        prestamos_vencidos     = VALUES(prestamos_vencidos),
        tasa_morosidad         = VALUES(tasa_morosidad),
        fecha_generacion       = CURRENT_TIMESTAMP;

    COMMIT;
END$$

DELIMITER ;

-- ------------------------------------------------------------
-- sp_refinanciar_prestamo
-- ------------------------------------------------------------
-- Recibe el préstamo a refinanciar, el nuevo plazo en meses y
-- la nueva tasa. Marca el préstamo original como Refinanciado y
-- crea uno nuevo con el saldo pendiente como monto, calculando
-- la cuota con la fórmula de amortización francesa. Todo dentro
-- de una transacción que garantiza que ambas operaciones se
-- realicen juntas o ninguna.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_refinanciar_prestamo;

DELIMITER $$

CREATE PROCEDURE sp_refinanciar_prestamo(
    IN p_id_prestamo      INT,
    IN p_nuevo_plazo_meses INT,
    IN p_nueva_tasa        DECIMAL(5,2)
)
BEGIN
    DECLARE v_estado_actual   VARCHAR(20);
    DECLARE v_id_cliente      INT;
    DECLARE v_id_producto     INT;
    DECLARE v_saldo_pendiente DECIMAL(12,2);
    DECLARE v_tasa_mensual    DECIMAL(10,6);
    DECLARE v_cuota_mensual   DECIMAL(10,2);
    DECLARE v_nuevo_id        INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT estado, id_cliente, id_producto, saldo_pendiente
      INTO v_estado_actual, v_id_cliente, v_id_producto, v_saldo_pendiente
      FROM prestamos
     WHERE id_prestamo = p_id_prestamo
     FOR UPDATE;

    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El préstamo indicado no existe.';
    END IF;

    IF v_estado_actual NOT IN ('Activo','Vencido') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden refinanciar préstamos Activos o Vencidos.';
    END IF;

    IF p_nuevo_plazo_meses <= 0 OR p_nueva_tasa <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Plazo y tasa deben ser mayores a cero.';
    END IF;

    -- Cuota mensual con fórmula de amortización francesa (cuota fija)
    SET v_tasa_mensual = (p_nueva_tasa / 100) / 12;
    SET v_cuota_mensual = ROUND(
        v_saldo_pendiente * v_tasa_mensual * POWER(1 + v_tasa_mensual, p_nuevo_plazo_meses)
        / (POWER(1 + v_tasa_mensual, p_nuevo_plazo_meses) - 1),
        2
    );

    -- 1. Marcar el préstamo original como Refinanciado
    UPDATE prestamos
       SET estado = 'Refinanciado'
     WHERE id_prestamo = p_id_prestamo;

    -- 2. Crear el préstamo nuevo, con el saldo pendiente como monto otorgado
    INSERT INTO prestamos (
        id_cliente, id_producto, monto_otorgado, tasa_aplicada, plazo_meses,
        fecha_otorgamiento, fecha_vencimiento, cuota_mensual, saldo_pendiente,
        estado, dias_mora
    )
    VALUES (
        v_id_cliente, v_id_producto, v_saldo_pendiente, p_nueva_tasa, p_nuevo_plazo_meses,
        CURDATE(), DATE_ADD(CURDATE(), INTERVAL p_nuevo_plazo_meses MONTH),
        v_cuota_mensual, v_saldo_pendiente, 'Activo', 0
    );

    SET v_nuevo_id = LAST_INSERT_ID();

    COMMIT;

    -- Fuera de la transacción, informamos el resultado (SELECT informativo)
    SELECT p_id_prestamo AS prestamo_original,
           v_nuevo_id     AS prestamo_nuevo,
           v_saldo_pendiente AS monto_refinanciado,
           v_cuota_mensual   AS nueva_cuota_mensual;
END$$

DELIMITER ;

-- ------------------------------------------------------------
-- Pruebas de los 3 procedimientos
-- ------------------------------------------------------------

-- sp_registrar_pago
CALL sp_registrar_pago(1, 1672.00, 'Cuota', 'App');
SELECT id_prestamo, saldo_pendiente, estado FROM prestamos WHERE id_prestamo = 1;
SELECT * FROM pagos WHERE id_prestamo = 1 ORDER BY id_pago DESC LIMIT 1;

-- Indicador de validación: debe rechazar pagos en préstamos Cancelado/Refinanciado
-- (probar contra el id_prestamo 17, que está Cancelado en los datos originales)
-- CALL sp_registrar_pago(17, 100, 'Cuota', 'App'); -- debe lanzar el error de estado

-- sp_generar_resumen_mensual (llamado 3 veces con períodos distintos
-- para cumplir el indicador de "al menos 3 filas en resumen_mensual")
CALL sp_generar_resumen_mensual(2022, 9);
CALL sp_generar_resumen_mensual(2023, 1);
CALL sp_generar_resumen_mensual(2023, 6);
SELECT * FROM resumen_mensual ORDER BY anio, mes;

-- sp_refinanciar_prestamo
CALL sp_refinanciar_prestamo(16, 24, 16.00);
SELECT id_prestamo, estado, saldo_pendiente FROM prestamos WHERE id_prestamo = 16;
SELECT * FROM prestamos ORDER BY id_prestamo DESC LIMIT 1;
