-- ============================================================
-- TRIGGER DE AUDITORÍA — Proyecto FinCore S.A.
-- Requiere: 01_crear_tablas.sql y 02_insertar_datos.sql ya ejecutados
-- ============================================================
USE fincore_sa;

-- ------------------------------------------------------------
-- trg_auditoria_estado
-- ------------------------------------------------------------
-- Se dispara AFTER UPDATE sobre prestamos, una vez por cada fila
-- afectada. Compara OLD vs NEW y registra en auditoria_prestamos
-- cualquier cambio en los campos 'estado' y 'dias_mora',
-- guardando el valor anterior y el nuevo (un INSERT por campo
-- modificado, porque la tabla de auditoría es "un campo por fila").
--
-- Se usa el operador null-safe <=> en vez de <> para comparar
-- OLD/NEW sin riesgo de perder cambios si alguno fuera NULL.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_auditoria_estado;

DELIMITER $$

CREATE TRIGGER trg_auditoria_estado
AFTER UPDATE ON prestamos
FOR EACH ROW
BEGIN
    IF NOT (NEW.estado <=> OLD.estado) THEN
        INSERT INTO auditoria_prestamos (id_prestamo, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (OLD.id_prestamo, 'estado', OLD.estado, NEW.estado);
    END IF;

    IF NOT (NEW.dias_mora <=> OLD.dias_mora) THEN
        INSERT INTO auditoria_prestamos (id_prestamo, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (OLD.id_prestamo, 'dias_mora', OLD.dias_mora, NEW.dias_mora);
    END IF;
END$$

DELIMITER ;

-- ------------------------------------------------------------
-- Prueba manual del trigger
-- ------------------------------------------------------------
-- Indicador de validación: auditoria_prestamos debe tener al
-- menos 2 registros después de esta prueba.

-- Se usa el préstamo 14 (Vencido) para esta prueba manual, dejando
-- libre el préstamo 16 para la prueba de sp_refinanciar_prestamo
-- en objetos/procedimientos.sql.

-- Estado antes del cambio
SELECT id_prestamo, estado, dias_mora FROM prestamos WHERE id_prestamo = 14;

-- Disparamos el trigger cambiando dias_mora
UPDATE prestamos
SET dias_mora = 110
WHERE id_prestamo = 14;

-- Disparamos el trigger cambiando estado y dias_mora a la vez
UPDATE prestamos
SET estado = 'Cancelado', dias_mora = 0
WHERE id_prestamo = 14;

-- Revertimos el estado de prueba para no alterar el resto del análisis
-- (esto también queda registrado en la auditoría, como cualquier UPDATE real)
UPDATE prestamos
SET estado = 'Vencido', dias_mora = 95
WHERE id_prestamo = 14;

-- Verificamos que el trigger generó los registros correspondientes
SELECT * FROM auditoria_prestamos WHERE id_prestamo = 14 ORDER BY fecha_cambio;

SELECT COUNT(*) AS total_registros_auditoria FROM auditoria_prestamos;
