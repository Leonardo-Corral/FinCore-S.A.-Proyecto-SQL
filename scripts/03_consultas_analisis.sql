-- ============================================================
-- CONSULTAS DE ANÁLISIS AVANZADO DE CARTERA — Proyecto FinCore S.A.
-- Requiere: objetos/funciones.sql y objetos/vistas.sql ya ejecutados
-- ============================================================
USE fincore_sa;

-- ------------------------------------------------------------
-- 0. Exploración inicial de la base de datos
-- ------------------------------------------------------------
-- Cantidad de registros por tabla.
SELECT 'clientes' AS tabla, COUNT(*) AS registros FROM clientes
UNION ALL
SELECT 'productos_credito', COUNT(*) FROM productos_credito
UNION ALL
SELECT 'prestamos', COUNT(*) FROM prestamos
UNION ALL
SELECT 'pagos', COUNT(*) FROM pagos
UNION ALL
SELECT 'auditoria_prestamos', COUNT(*) FROM auditoria_prestamos
UNION ALL
SELECT 'resumen_mensual', COUNT(*) FROM resumen_mensual;

-- Distribución de préstamos por estado.
SELECT
    estado,
    COUNT(*) AS cantidad_prestamos,
    SUM(monto_otorgado) AS monto_total,
    ROUND(AVG(monto_otorgado), 2) AS monto_promedio
FROM prestamos
GROUP BY estado
ORDER BY cantidad_prestamos DESC;

-- ------------------------------------------------------------
-- 1. Aging de cartera
-- ------------------------------------------------------------
-- Agrupa todos los préstamos Activos y Vencidos por su tramo de
-- mora (vía fn_clasificar_mora), mostrando cantidad, saldo en
-- riesgo y porcentaje del total.
--
-- SUM(SUM(saldo_pendiente)) OVER () es una función de ventana
-- sobre un resultado ya agrupado: sin PARTITION BY, suma los
-- totales de todos los grupos para obtener el gran total de la
-- cartera (repetido en cada fila), y así calcular el % de cada
-- tramo sin una subconsulta aparte.
-- ------------------------------------------------------------
SELECT
    fn_clasificar_mora(dias_mora)                              AS tramo_mora,
    COUNT(*)                                                   AS cantidad_prestamos,
    SUM(saldo_pendiente)                                       AS saldo_en_riesgo,
    ROUND(
        SUM(saldo_pendiente) * 100.0 / SUM(SUM(saldo_pendiente)) OVER (),
        2
    )                                                           AS porcentaje_del_total
FROM prestamos
WHERE estado IN ('Activo','Vencido')
GROUP BY fn_clasificar_mora(dias_mora)
ORDER BY saldo_en_riesgo DESC;

-- ------------------------------------------------------------
-- 2. Top 5 de exposición crediticia
-- ------------------------------------------------------------
-- Identifica los 5 clientes con mayor saldo pendiente total y
-- compara cada uno contra el promedio de la cartera.
--
-- El promedio (AVG(...) OVER ()) se calcula en la subconsulta
-- 't', ANTES del LIMIT 5, sobre todos los clientes con préstamos
-- activos/vencidos -- si el LIMIT se aplicara antes, el promedio
-- quedaría mal calculado (solo sobre esas 5 filas).
-- ------------------------------------------------------------
SELECT *
FROM (
    SELECT
        c.id_cliente,
        c.nombre,
        c.segmento,
        c.categoria_riesgo,
        SUM(p.saldo_pendiente)                              AS saldo_total,
        ROUND(AVG(SUM(p.saldo_pendiente)) OVER (), 2)        AS promedio_cartera,
        ROUND(
            SUM(p.saldo_pendiente) - AVG(SUM(p.saldo_pendiente)) OVER (),
            2
        )                                                    AS diferencia_vs_promedio,
        RANK() OVER (ORDER BY SUM(p.saldo_pendiente) DESC)   AS ranking
    FROM clientes c
    JOIN prestamos p ON p.id_cliente = c.id_cliente
    WHERE p.estado IN ('Activo','Vencido')
    GROUP BY c.id_cliente, c.nombre, c.segmento, c.categoria_riesgo
) t
ORDER BY saldo_total DESC
LIMIT 5;

-- ------------------------------------------------------------
-- 3. Historial de pagos completo
-- ------------------------------------------------------------
-- Cruza pagos, prestamos, clientes y productos_credito para
-- mostrar el detalle de los últimos 20 pagos registrados.
-- ------------------------------------------------------------
SELECT
    pa.id_pago,
    pa.fecha_pago,
    pa.monto_pagado,
    pa.tipo_pago,
    pa.canal,
    p.id_prestamo,
    c.nombre        AS cliente,
    c.segmento,
    pc.nombre        AS producto,
    pc.tipo          AS tipo_producto
FROM pagos pa
JOIN prestamos p          ON p.id_prestamo  = pa.id_prestamo
JOIN clientes c            ON c.id_cliente   = p.id_cliente
JOIN productos_credito pc  ON pc.id_producto = p.id_producto
ORDER BY pa.fecha_pago DESC, pa.id_pago DESC
LIMIT 20;

-- ------------------------------------------------------------
-- 4. Reporte ejecutivo
-- ------------------------------------------------------------
-- Usando la vista vw_estado_cartera, agrupa la cartera por
-- segmento y categoría de riesgo, mostrando tasa promedio,
-- créditos vencidos y porcentaje de cartera en riesgo.
--
-- NULLIF(SUM(saldo_pendiente), 0) evita división por cero si
-- algún grupo tuviera saldo total 0.
-- ------------------------------------------------------------
SELECT
    segmento,
    categoria_riesgo,
    COUNT(*)                                                        AS total_prestamos,
    ROUND(AVG(tasa_aplicada), 2)                                    AS tasa_promedio,
    SUM(CASE WHEN estado = 'Vencido' THEN 1 ELSE 0 END)             AS creditos_vencidos,
    ROUND(
        SUM(CASE WHEN estado = 'Vencido' THEN saldo_pendiente ELSE 0 END)
        * 100.0 / NULLIF(SUM(saldo_pendiente), 0),
        2
    )                                                                AS porcentaje_cartera_en_riesgo
FROM vw_estado_cartera
GROUP BY segmento, categoria_riesgo
ORDER BY segmento, categoria_riesgo;
