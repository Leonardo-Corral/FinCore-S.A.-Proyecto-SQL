-- ============================================================
-- CREACIÓN DE ESTRUCTURA — Proyecto FinCore S.A.
-- DDL: base de datos, tablas, PKs, FKs, ENUMs
-- Motor: MySQL 8.0+
-- ============================================================
-- IMPORTANTE: este script NO se modifica (dato original de cátedra).
-- Recrea la base de datos desde cero (DROP DATABASE IF EXISTS).
-- ============================================================

DROP DATABASE IF EXISTS fincore_sa;
CREATE DATABASE fincore_sa CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE fincore_sa;

-- ------------------------------------------------------------
-- TABLA: clientes
-- ------------------------------------------------------------
CREATE TABLE clientes (
    id_cliente      INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    documento       VARCHAR(20)  NOT NULL UNIQUE,
    email           VARCHAR(100),
    telefono        VARCHAR(20),
    ciudad          VARCHAR(50),
    segmento        ENUM('Personal','Empresarial') NOT NULL,
    categoria_riesgo CHAR(1)     NOT NULL COMMENT 'A=Excelente, B=Bueno, C=Regular, D=Alto riesgo',
    fecha_alta      DATE         NOT NULL,
    activo          TINYINT(1)   NOT NULL DEFAULT 1
);

-- ------------------------------------------------------------
-- TABLA: productos_credito
-- ------------------------------------------------------------
CREATE TABLE productos_credito (
    id_producto     INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(80)  NOT NULL,
    tipo            ENUM('Personal','Empresarial','Hipotecario','Automotriz') NOT NULL,
    tasa_anual      DECIMAL(5,2) NOT NULL COMMENT 'Tasa nominal anual en %',
    plazo_min_meses INT          NOT NULL,
    plazo_max_meses INT          NOT NULL,
    monto_min       DECIMAL(12,2) NOT NULL,
    monto_max       DECIMAL(12,2) NOT NULL
);

-- ------------------------------------------------------------
-- TABLA: prestamos
-- ------------------------------------------------------------
CREATE TABLE prestamos (
    id_prestamo     INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente      INT           NOT NULL,
    id_producto     INT           NOT NULL,
    monto_otorgado  DECIMAL(12,2) NOT NULL,
    tasa_aplicada   DECIMAL(5,2)  NOT NULL,
    plazo_meses     INT           NOT NULL,
    fecha_otorgamiento DATE       NOT NULL,
    fecha_vencimiento  DATE       NOT NULL,
    cuota_mensual   DECIMAL(10,2) NOT NULL,
    saldo_pendiente DECIMAL(12,2) NOT NULL,
    estado          ENUM('Activo','Cancelado','Vencido','Refinanciado') NOT NULL DEFAULT 'Activo',
    dias_mora       INT           NOT NULL DEFAULT 0,
    FOREIGN KEY (id_cliente)  REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_producto) REFERENCES productos_credito(id_producto)
);

-- ------------------------------------------------------------
-- TABLA: pagos
-- ------------------------------------------------------------
CREATE TABLE pagos (
    id_pago         INT AUTO_INCREMENT PRIMARY KEY,
    id_prestamo     INT           NOT NULL,
    fecha_pago      DATE          NOT NULL,
    monto_pagado    DECIMAL(10,2) NOT NULL,
    tipo_pago       ENUM('Cuota','Prepago','Mora') NOT NULL,
    canal           ENUM('App','Sucursal','Transferencia','Débito Automático') NOT NULL,
    registrado_por  VARCHAR(50)   NOT NULL DEFAULT 'sistema',
    FOREIGN KEY (id_prestamo) REFERENCES prestamos(id_prestamo)
);

-- ------------------------------------------------------------
-- TABLA: auditoria_prestamos (el alumno la llena con trigger)
-- ------------------------------------------------------------
CREATE TABLE auditoria_prestamos (
    id_auditoria    INT AUTO_INCREMENT PRIMARY KEY,
    id_prestamo     INT           NOT NULL,
    campo_modificado VARCHAR(50)  NOT NULL,
    valor_anterior  VARCHAR(100),
    valor_nuevo     VARCHAR(100),
    fecha_cambio    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario         VARCHAR(50)   NOT NULL DEFAULT (USER())
);

-- ------------------------------------------------------------
-- TABLA: resumen_mensual (el alumno la llena con procedimiento)
-- ------------------------------------------------------------
CREATE TABLE resumen_mensual (
    id_resumen      INT AUTO_INCREMENT PRIMARY KEY,
    anio            INT           NOT NULL,
    mes             INT           NOT NULL,
    total_prestamos INT           NOT NULL DEFAULT 0,
    monto_total_otorgado DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_pagos_recibidos DECIMAL(14,2) NOT NULL DEFAULT 0,
    prestamos_vencidos   INT       NOT NULL DEFAULT 0,
    tasa_morosidad  DECIMAL(5,2)  NOT NULL DEFAULT 0,
    fecha_generacion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_anio_mes (anio, mes)
);
