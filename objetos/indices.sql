-- ============================================================
-- ÍNDICES DE OPTIMIZACIÓN — Proyecto FinCore S.A.
-- ============================================================
USE fincore_sa;

-- ------------------------------------------------------------
-- EXPLAIN "antes" (sin índices adicionales) sobre la consulta
-- de historial de pagos completo (4 JOIN + ORDER BY + LIMIT)
-- ------------------------------------------------------------
EXPLAIN
SELECT
    pa.id_pago, pa.fecha_pago, pa.monto_pagado, pa.tipo_pago, pa.canal,
    p.id_prestamo, c.nombre AS cliente, c.segmento,
    pc.nombre AS producto, pc.tipo AS tipo_producto
FROM pagos pa
JOIN prestamos p          ON p.id_prestamo  = pa.id_prestamo
JOIN clientes c            ON c.id_cliente   = p.id_cliente
JOIN productos_credito pc  ON pc.id_producto = p.id_producto
ORDER BY pa.fecha_pago DESC, pa.id_pago DESC
LIMIT 20;

-- ------------------------------------------------------------
-- Creación de índices
-- ------------------------------------------------------------
-- idx_pagos_fecha_id: compuesto, en el mismo orden que el
-- ORDER BY de la consulta de historial de pagos, para que MySQL
-- pueda leer el índice ya ordenado sin necesidad de un sort aparte.
--
-- Nota: MySQL no soporta "DROP INDEX ... IF EXISTS", por eso este
-- script no re-ejecuta el CREATE INDEX; si lo corrés dos veces
-- sobre la misma base sin recrearla desde cero, primero hacé
-- DROP INDEX idx_pagos_fecha_id ON pagos; y
-- DROP INDEX idx_prestamos_estado ON prestamos;
CREATE INDEX idx_pagos_fecha_id ON pagos (fecha_pago DESC, id_pago DESC);

-- idx_prestamos_estado: usado en filtros por estado en la Parte 5
-- (aging, reporte ejecutivo) y en sp_generar_resumen_mensual.
CREATE INDEX idx_prestamos_estado ON prestamos (estado);

SHOW INDEX FROM pagos;

-- ------------------------------------------------------------
-- EXPLAIN "después" con FORCE INDEX
-- ------------------------------------------------------------
-- Nota analítica: con solo ~47 filas en 'pagos', el optimizador
-- de MySQL puede preferir espontáneamente un Table scan por costo
-- estimado (comportamiento esperado, no un error de diseño). Se
-- usa FORCE INDEX para demostrar que el índice es correcto y que
-- sería la elección automática del optimizador con un volumen de
-- datos real (miles/millones de filas), donde el filesort sería
-- mucho más costoso que la lectura ya ordenada por índice.
EXPLAIN
SELECT
    pa.id_pago, pa.fecha_pago, pa.monto_pagado, pa.tipo_pago, pa.canal,
    p.id_prestamo, c.nombre AS cliente, c.segmento,
    pc.nombre AS producto, pc.tipo AS tipo_producto
FROM pagos pa FORCE INDEX (idx_pagos_fecha_id)
JOIN prestamos p          ON p.id_prestamo  = pa.id_prestamo
JOIN clientes c            ON c.id_cliente   = p.id_cliente
JOIN productos_credito pc  ON pc.id_producto = p.id_producto
ORDER BY pa.fecha_pago DESC, pa.id_pago DESC
LIMIT 20;

-- ============================================================
-- ANÁLISIS DE OPTIMIZACIÓN
-- ============================================================
-- ANTES: tabla conductora = pagos (pa), acceso por Table scan
--        (key=NULL), estimaba 47 filas, requería Sort manual
--        (Using filesort) para cumplir el ORDER BY
--        fecha_pago DESC, id_pago DESC. Costo=54.3.
--
-- ÍNDICE CREADO: idx_pagos_fecha_id (fecha_pago DESC, id_pago DESC)
--        Compuesto y en el mismo orden que el ORDER BY, para que
--        MySQL pueda leer el índice ya ordenado sin sort aparte.
--
-- DESPUÉS (con FORCE INDEX): el nodo Sort desaparece, pa pasa a
--        usar Index scan on idx_pagos_fecha_id, y las filas
--        estimadas bajan de 47 a 20 (no necesita leer toda la
--        tabla, corta apenas junta las 20 que pide el LIMIT).
--        Costo baja a 47.2.
--
-- Las tablas prestamos, productos_credito y clientes ya
-- resolvían sus JOIN por PRIMARY KEY (Single-row index lookup
-- / eq_ref, rows=1) desde antes de crear estos índices, porque
-- las FK son PK del lado "uno" de cada relación.
-- ============================================================
