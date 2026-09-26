-- ============================================================
-- VISTAS DE ANÁLISIS — Proyecto FinCore S.A.
-- Requiere: objetos/funciones.sql ya ejecutado (usa fn_clasificar_mora)
-- ============================================================
USE fincore_sa;

-- ------------------------------------------------------------
-- vw_estado_cartera
-- ------------------------------------------------------------
-- Detalle por préstamo: datos del cliente, del producto, el
-- porcentaje de saldo restante sobre el monto original y la
-- clasificación de mora (reutilizando fn_clasificar_mora).
--
-- Se usa JOIN (no LEFT JOIN) porque todo préstamo siempre tiene
-- un cliente y un producto válidos (FK + NOT NULL).
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_estado_cartera;

CREATE VIEW vw_estado_cartera AS
SELECT
    p.id_prestamo,
    c.id_cliente,
    c.nombre                              AS nombre_cliente,
    c.segmento,
    c.categoria_riesgo,
    pc.nombre                             AS nombre_producto,
    pc.tipo                               AS tipo_producto,
    p.monto_otorgado,
    p.saldo_pendiente,
    p.tasa_aplicada,
    p.plazo_meses,
    p.fecha_otorgamiento,
    p.fecha_vencimiento,
    p.estado,
    p.dias_mora,
    ROUND((p.saldo_pendiente / p.monto_otorgado) * 100, 2) AS porcentaje_saldo_restante,
    fn_clasificar_mora(p.dias_mora)       AS clasificacion_mora
FROM prestamos p
JOIN clientes c          ON c.id_cliente  = p.id_cliente
JOIN productos_credito pc ON pc.id_producto = p.id_producto;

-- ------------------------------------------------------------
-- vw_resumen_clientes
-- ------------------------------------------------------------
-- Agregado por cliente: total de préstamos, monto total otorgado,
-- saldo pendiente consolidado, días de mora máximos y si tiene
-- mora activa.
--
-- Se usa LEFT JOIN para que un cliente sin préstamos también
-- aparezca en el resumen (con 0 en vez de desaparecer), y
-- COALESCE para convertir los NULL que produce el LEFT JOIN
-- en 0 en las columnas agregadas.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_resumen_clientes;

CREATE VIEW vw_resumen_clientes AS
SELECT
    c.id_cliente,
    c.nombre,
    c.segmento,
    c.categoria_riesgo,
    COUNT(p.id_prestamo)                       AS total_prestamos,
    COALESCE(SUM(p.monto_otorgado), 0)         AS monto_total_otorgado,
    COALESCE(SUM(p.saldo_pendiente), 0)        AS saldo_pendiente_consolidado,
    COALESCE(MAX(p.dias_mora), 0)              AS dias_mora_maximo,
    CASE
        WHEN MAX(p.dias_mora) > 0 THEN 'Sí'
        ELSE 'No'
    END                                         AS tiene_mora_activa
FROM clientes c
LEFT JOIN prestamos p ON p.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nombre, c.segmento, c.categoria_riesgo;

-- ------------------------------------------------------------
-- Verificación de ambas vistas
-- ------------------------------------------------------------
-- Indicador de validación: vw_estado_cartera debe mostrar al
-- menos 21 filas (todos los préstamos).
SELECT COUNT(*) AS total_filas_vw_estado_cartera FROM vw_estado_cartera;

SELECT * FROM vw_estado_cartera ORDER BY dias_mora DESC;

SELECT * FROM vw_resumen_clientes ORDER BY dias_mora_maximo DESC;
