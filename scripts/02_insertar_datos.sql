-- ============================================================
-- INSERCIÓN DE DATOS DE PRÁCTICA — FinCore S.A.
-- Requiere haber ejecutado antes 01_crear_tablas.sql
-- ============================================================
USE fincore_sa;

-- ============================================================
-- INSERTS
-- ============================================================

INSERT INTO productos_credito (nombre, tipo, tasa_anual, plazo_min_meses, plazo_max_meses, monto_min, monto_max) VALUES
('Crédito Personal Flex',    'Personal',     28.00,  6,  48,   1000.00,  50000.00),
('Crédito Personal Plus',    'Personal',     22.00, 12,  60,   5000.00,  80000.00),
('Crédito Empresarial Básico','Empresarial', 18.00, 12,  36,  10000.00, 200000.00),
('Crédito Empresarial Pro',  'Empresarial',  15.50, 24,  72,  50000.00, 500000.00),
('Crédito Hipotecario',      'Hipotecario',  12.00, 60, 240, 100000.00,1000000.00),
('Crédito Automotriz',       'Automotriz',   19.50, 24,  72,   8000.00, 120000.00);

INSERT INTO clientes (nombre, documento, email, telefono, ciudad, segmento, categoria_riesgo, fecha_alta) VALUES
-- Categoría A (excelente) — 6 clientes
('Carlos Méndez Torres',     'DNI-10234567', 'cmendez@email.com',    '555-1001', 'Ciudad de México', 'Personal',    'A', '2021-03-15'),
('Laura Ramírez Vega',       'DNI-10234568', 'lramirez@email.com',   '555-1002', 'Guadalajara',      'Personal',    'A', '2021-05-20'),
('Inversiones GHL S.A.',     'RUC-20512345', 'contacto@ghl.com',     '555-2001', 'Monterrey',        'Empresarial', 'A', '2020-11-10'),
('Distribuidora Pacífico',   'RUC-20512346', 'dpacif@empresa.com',   '555-2002', 'Ciudad de México', 'Empresarial', 'A', '2021-01-08'),
('Miguel Ángel Fuentes',     'DNI-10234571', 'mfuentes@email.com',   '555-1005', 'Puebla',           'Personal',    'A', '2022-02-14'),
('Sofía Castillo Herrera',   'DNI-10234572', 'scastillo@email.com',  '555-1006', 'Guadalajara',      'Personal',    'A', '2022-07-30'),
-- Categoría B (bueno) — 6 clientes
('Roberto Silva Pardo',      'DNI-10234569', 'rsilva@email.com',     '555-1003', 'Monterrey',        'Personal',    'B', '2021-08-12'),
('Ana Patricia Ochoa',       'DNI-10234570', 'apochoa@email.com',    '555-1004', 'Puebla',           'Personal',    'B', '2022-01-25'),
('Tech Solutions MX S.A.',   'RUC-20512347', 'info@techsol.com',     '555-2003', 'Ciudad de México', 'Empresarial', 'B', '2021-06-18'),
('Constructora Norteña',     'RUC-20512348', 'cnortena@empresa.com', '555-2004', 'Monterrey',        'Empresarial', 'B', '2021-09-05'),
('Diego Hernández Cruz',     'DNI-10234575', 'dhernandez@email.com', '555-1009', 'Ciudad de México', 'Personal',    'B', '2022-04-10'),
('Valentina Torres Ruiz',    'DNI-10234576', 'vtorres@email.com',    '555-1010', 'Guadalajara',      'Personal',    'B', '2022-09-22'),
-- Categoría C (regular) — 5 clientes
('Jorge Luis Paredes',       'DNI-10234573', 'jparedes@email.com',   '555-1007', 'Ciudad de México', 'Personal',    'C', '2022-03-18'),
('Importadora del Centro',   'RUC-20512349', 'imp.centro@emp.com',   '555-2005', 'Puebla',           'Empresarial', 'C', '2022-05-30'),
('Patricia Morales Díaz',    'DNI-10234577', 'pmorales@email.com',   '555-1011', 'Monterrey',        'Personal',    'C', '2022-11-05'),
('Comercial Rápida S.R.L.',  'RUC-20512351', 'crapida@empresa.com',  '555-2007', 'Ciudad de México', 'Empresarial', 'C', '2023-01-20'),
('Fernando López Salinas',   'DNI-10234579', 'flopez@email.com',     '555-1013', 'Puebla',           'Personal',    'C', '2023-03-08'),
-- Categoría D (alto riesgo) — 3 clientes
('Elena Gutiérrez Blanco',   'DNI-10234574', 'egutierrez@email.com', '555-1008', 'Guadalajara',      'Personal',    'D', '2022-06-05'),
('Servicios Omega Ltda.',     'RUC-20512350', 'omega@empresa.com',    '555-2006', 'Ciudad de México', 'Empresarial', 'D', '2022-08-15'),
('Andrés Ramírez Soto',      'DNI-10234578', 'aramirez@email.com',   '555-1012', 'Monterrey',        'Personal',    'D', '2022-12-12');

INSERT INTO prestamos (id_cliente, id_producto, monto_otorgado, tasa_aplicada, plazo_meses, fecha_otorgamiento, fecha_vencimiento, cuota_mensual, saldo_pendiente, estado, dias_mora) VALUES
-- Préstamos ACTIVOS
(1,  2, 45000.00, 22.00, 36, '2023-01-10', '2026-01-10', 1672.00, 28000.00, 'Activo', 0),
(2,  1, 15000.00, 28.00, 24, '2023-03-15', '2025-03-15',  820.00,  6500.00, 'Activo', 0),
(3,  4,180000.00, 15.50, 60, '2022-06-01', '2027-06-01', 4320.00,130000.00, 'Activo', 0),
(4,  3, 90000.00, 18.00, 36, '2023-02-20', '2026-02-20', 3250.00, 62000.00, 'Activo', 0),
(5,  6, 35000.00, 19.50, 48, '2023-05-10', '2027-05-10', 1050.00, 28000.00, 'Activo', 0),
(6,  2, 25000.00, 22.00, 24, '2023-07-01', '2025-07-01', 1285.00, 15000.00, 'Activo', 0),
(7,  1, 20000.00, 28.00, 36, '2022-11-15', '2025-11-15',  855.00, 12000.00, 'Activo', 0),
(8,  2, 30000.00, 22.00, 36, '2023-04-20', '2026-04-20', 1115.00, 22500.00, 'Activo', 0),
(9,  3, 75000.00, 18.00, 24, '2023-06-01', '2025-06-01', 3740.00, 45000.00, 'Activo', 0),
(10, 4,250000.00, 15.50, 72, '2022-09-10', '2028-09-10', 5100.00,200000.00, 'Activo', 0),
(11, 1, 12000.00, 28.00, 18, '2023-08-05', '2025-02-05',  820.00,  7000.00, 'Activo', 0),
(12, 2, 18000.00, 22.00, 24, '2023-09-12', '2025-09-12',  925.00, 12000.00, 'Activo', 0),
(5,  5,200000.00, 12.00,120, '2022-04-01', '2032-04-01', 2860.00,175000.00, 'Activo', 0),
-- Préstamos VENCIDOS (para ejercicios de mora y aging)
(13, 1, 10000.00, 28.00, 12, '2022-08-01', '2023-08-01',  960.00,  8500.00, 'Vencido', 95),
(18, 1,  8000.00, 28.00, 12, '2022-10-15', '2023-10-15',  768.00,  7200.00, 'Vencido',180),
(19, 3, 55000.00, 18.00, 24, '2021-12-01', '2023-12-01', 2740.00, 40000.00, 'Vencido', 62),
-- Préstamos CANCELADOS
(1,  1, 10000.00, 28.00, 12, '2022-01-01', '2023-01-01',  955.00,     0.00, 'Cancelado', 0),
(2,  6, 20000.00, 19.50, 24, '2021-06-01', '2023-06-01', 1015.00,     0.00, 'Cancelado', 0),
(3,  3, 50000.00, 18.00, 18, '2021-03-01', '2022-09-01', 3180.00,     0.00, 'Cancelado', 0),
-- Préstamos REFINANCIADOS
(14, 3, 40000.00, 18.00, 24, '2022-07-01', '2024-07-01', 1990.00, 18000.00, 'Refinanciado', 0),
(20, 2, 22000.00, 22.00, 24, '2022-09-01', '2024-09-01', 1130.00, 10000.00, 'Refinanciado', 0);

INSERT INTO pagos (id_prestamo, fecha_pago, monto_pagado, tipo_pago, canal) VALUES
-- Pagos del préstamo 1 (Carlos Méndez)
(1, '2023-02-10', 1672.00, 'Cuota', 'Débito Automático'),
(1, '2023-03-10', 1672.00, 'Cuota', 'Débito Automático'),
(1, '2023-04-10', 1672.00, 'Cuota', 'Débito Automático'),
(1, '2023-05-10', 1672.00, 'Cuota', 'Débito Automático'),
(1, '2023-06-10', 1672.00, 'Cuota', 'Débito Automático'),
(1, '2023-07-10', 1672.00, 'Cuota', 'Débito Automático'),
-- Pagos del préstamo 2 (Laura Ramírez)
(2, '2023-04-15',  820.00, 'Cuota', 'App'),
(2, '2023-05-15',  820.00, 'Cuota', 'App'),
(2, '2023-06-15',  820.00, 'Cuota', 'App'),
(2, '2023-07-15',  820.00, 'Cuota', 'App'),
(2, '2023-08-15',  820.00, 'Cuota', 'App'),
-- Pagos del préstamo 3 (Inversiones GHL)
(3, '2022-07-01', 4320.00, 'Cuota', 'Transferencia'),
(3, '2022-08-01', 4320.00, 'Cuota', 'Transferencia'),
(3, '2022-09-01', 4320.00, 'Cuota', 'Transferencia'),
(3, '2022-10-01', 4320.00, 'Cuota', 'Transferencia'),
(3, '2022-11-01', 4320.00, 'Cuota', 'Transferencia'),
(3, '2022-12-01', 4320.00, 'Cuota', 'Transferencia'),
(3, '2023-01-01', 4320.00, 'Cuota', 'Transferencia'),
(3, '2023-02-01', 4320.00, 'Cuota', 'Transferencia'),
(3, '2023-03-01', 4320.00, 'Cuota', 'Transferencia'),
-- Pagos del préstamo 7 (Roberto Silva)
(7, '2022-12-15',  855.00, 'Cuota', 'Sucursal'),
(7, '2023-01-15',  855.00, 'Cuota', 'Sucursal'),
(7, '2023-02-15',  855.00, 'Cuota', 'Sucursal'),
(7, '2023-03-15',  855.00, 'Cuota', 'Sucursal'),
-- Prepago del préstamo 5
(5, '2023-10-15', 5000.00, 'Prepago', 'Transferencia'),
-- Pagos con mora (préstamos vencidos)
(14, '2023-09-20',  960.00, 'Cuota', 'Sucursal'),
(14, '2023-09-20',  150.00, 'Mora',  'Sucursal'),
(15, '2024-04-10',  768.00, 'Cuota', 'App'),
(15, '2024-04-10',  220.00, 'Mora',  'App'),
-- Pagos del préstamo 17 (Cancelado — Laura)
(17, '2021-07-01', 1015.00, 'Cuota', 'Débito Automático'),
(17, '2021-08-01', 1015.00, 'Cuota', 'Débito Automático'),
(17, '2021-09-01', 1015.00, 'Cuota', 'Débito Automático'),
(17, '2021-10-01', 1015.00, 'Cuota', 'Débito Automático'),
(17, '2021-11-01', 1015.00, 'Cuota', 'Débito Automático'),
(17, '2021-12-01', 1015.00, 'Cuota', 'Débito Automático'),
(17, '2022-01-01', 1015.00, 'Cuota', 'Débito Automático'),
(17, '2022-02-01', 1015.00, 'Cuota', 'Débito Automático'),
(17, '2022-03-01', 1015.00, 'Cuota', 'Débito Automático'),
(17, '2022-04-01', 1015.00, 'Cuota', 'Débito Automático'),
(17, '2022-05-01', 1015.00, 'Cuota', 'Débito Automático'),
(17, '2022-06-01', 1015.00, 'Cuota', 'Débito Automático'),
-- Pagos del préstamo 9 (Tech Solutions)
(9, '2023-07-01', 3740.00, 'Cuota', 'Transferencia'),
(9, '2023-08-01', 3740.00, 'Cuota', 'Transferencia'),
(9, '2023-09-01', 3740.00, 'Cuota', 'Transferencia'),
(9, '2023-10-01', 3740.00, 'Cuota', 'Transferencia'),
(9, '2023-11-01', 3740.00, 'Cuota', 'Transferencia'),
(9, '2023-12-01', 3740.00, 'Cuota', 'Transferencia');
