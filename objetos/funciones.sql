-- ============================================================
-- FUNCIONES — Proyecto FinCore S.A.
-- Requiere: 01_crear_tablas.sql y 02_insertar_datos.sql ya ejecutados
-- ============================================================
USE fincore_sa;

-- ------------------------------------------------------------
-- fn_clasificar_mora
-- ------------------------------------------------------------
-- Recibe los días de mora de un préstamo y devuelve su categoría
-- de aging según la política interna de FinCore S.A.:
--
--   0 días        -> Al día
--   1  - 30 días  -> Mora Temprana (1-30d)
--   31 - 60 días  -> Mora Media (31-60d)
--   61 - 90 días  -> Mora Grave (61-90d)
--   +90 días      -> Mora Crítica (+90d)
--
-- Se declara DETERMINISTIC porque para la misma entrada siempre
-- devuelve la misma salida (no depende de fecha/hora ni de datos
-- externos). Se centraliza acá la regla de negocio para que
-- vistas, procedimientos y consultas la reutilicen sin duplicar
-- lógica ni arriesgar divergencias entre distintos objetos.
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_clasificar_mora;

DELIMITER $$

CREATE FUNCTION fn_clasificar_mora(p_dias_mora INT)
RETURNS VARCHAR(30)
DETERMINISTIC
BEGIN
    DECLARE v_categoria VARCHAR(30);

    IF p_dias_mora = 0 THEN
        SET v_categoria = 'Al día';
    ELSEIF p_dias_mora BETWEEN 1 AND 30 THEN
        SET v_categoria = 'Mora Temprana (1-30d)';
    ELSEIF p_dias_mora BETWEEN 31 AND 60 THEN
        SET v_categoria = 'Mora Media (31-60d)';
    ELSEIF p_dias_mora BETWEEN 61 AND 90 THEN
        SET v_categoria = 'Mora Grave (61-90d)';
    ELSE
        SET v_categoria = 'Mora Crítica (+90d)';
    END IF;

    RETURN v_categoria;
END$$

DELIMITER ;

-- ------------------------------------------------------------
-- Prueba de la función sobre los préstamos Vencidos
-- ------------------------------------------------------------
-- Indicador de validación: fn_clasificar_mora(180) debe devolver
-- 'Mora Crítica (+90d)'.
SELECT fn_clasificar_mora(180) AS prueba_indicador;

SELECT
    p.id_prestamo,
    c.nombre AS cliente,
    p.monto_otorgado,
    p.dias_mora,
    fn_clasificar_mora(p.dias_mora) AS categoria_mora
FROM prestamos p
JOIN clientes c ON c.id_cliente = p.id_cliente
WHERE p.estado = 'Vencido'
ORDER BY p.dias_mora DESC;
