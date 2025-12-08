
--CASO UNO:

-- Limpiar la tabla antes de volver a insertar
TRUNCATE TABLE detalle_bonificaciones_trabajador;

-- Crear la secuencia (si no existe, recrearla)
BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_det_bonif';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Agregué lo anterior para poder hacer pruebas  

CREATE SEQUENCE seq_det_bonif
START WITH 100
INCREMENT BY 10
NOCACHE;

-- Insertar datos calculados en DETALLE_BONIFICACIONES_TRABAJADOR
INSERT INTO detalle_bonificaciones_trabajador
(NUM, RUT, NOMBRE_TRABAJADOR, SUELDO_BASE, NUM_TICKET, DIRECCION, SISTEMA_SALUD,
 MONTO, BONIF_X_TICKET, SIMULACION_X_TICKET, SIMULACION_ANTIGUEDAD)
SELECT 
    seq_det_bonif.NEXTVAL AS NUM,
    t.numrut || '-' || t.dvrut AS RUT,
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS NOMBRE_TRABAJADOR,
    TO_CHAR(t.sueldo_base, '$999G999G999') AS SUELDO_BASE,
    NVL(TO_CHAR(tc.nro_ticket), 'No hay info') AS NUM_TICKET,
    t.direccion AS DIRECCION,
    i.nombre_isapre AS SISTEMA_SALUD,
    TO_CHAR(NVL(tc.monto_ticket,0), '$999G999G999') AS MONTO,
    TO_CHAR(
        CASE 
            WHEN tc.monto_ticket IS NULL THEN 0
            WHEN tc.monto_ticket <= 50000 THEN 0
            WHEN tc.monto_ticket > 50000 AND tc.monto_ticket <= 100000 THEN ROUND(tc.monto_ticket*0.05)
            WHEN tc.monto_ticket > 100000 THEN ROUND(tc.monto_ticket*0.07)
            ELSE 0
        END, '$999G999G999'
    ) AS BONIF_X_TICKET,
    TO_CHAR(
        t.sueldo_base + 
        CASE 
            WHEN tc.monto_ticket IS NULL THEN 0
            WHEN tc.monto_ticket <= 50000 THEN 0
            WHEN tc.monto_ticket > 50000 AND tc.monto_ticket <= 100000 THEN ROUND(tc.monto_ticket*0.05)
            WHEN tc.monto_ticket > 100000 THEN ROUND(tc.monto_ticket*0.07)
            ELSE 0
        END, '$999G999G999'
    ) AS SIMULACION_X_TICKET,
    TO_CHAR(ROUND(t.sueldo_base * (1 + ba.porcentaje)), '$999G999G999') AS SIMULACION_ANTIGUEDAD
FROM trabajador t
LEFT JOIN tickets_concierto tc ON t.numrut = tc.numrut_t
JOIN bono_antiguedad ba 
     ON FLOOR(MONTHS_BETWEEN(SYSDATE, t.fecing)/12) BETWEEN ba.limite_inferior AND ba.limite_superior
JOIN isapre i ON t.cod_isapre = i.cod_isapre
WHERE i.porc_descto_isapre > 4
AND FLOOR(MONTHS_BETWEEN(SYSDATE, t.fecnac)/12) < 50;

-- Confirmar los cambios
COMMIT;

-- Revisar resultados ordenados
SELECT *
FROM detalle_bonificaciones_trabajador
ORDER BY monto DESC, nombre_trabajador;


--CASO DOS: 

CREATE SYNONYM syn_trabajador FOR trabajador;
CREATE SYNONYM syn_asignacion FOR asignacion_familiar;

CREATE OR REPLACE VIEW v_aumentos_estudios AS
SELECT 
    t.numrut || '-' || t.dvrut AS RUT_TRABAJADOR,
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS TRABAJADOR,
    be.descrip AS DESCRIP,
    LPAD(be.porc_bono,7,'0') AS PCT_ESTUDIOS,
    t.sueldo_base AS SUELDO_ACTUAL,
    ROUND(t.sueldo_base * (be.porc_bono/100)) AS AUMENTO,
    TO_CHAR(t.sueldo_base + ROUND(t.sueldo_base * (be.porc_bono/100)), '$999G999G999') AS SUELDO_AUMENTADO
FROM syn_trabajador t
JOIN bono_escolar be ON t.id_escolaridad_t = be.id_escolar
WHERE 
    -- Restricción: solo cajeros
    t.id_categoria_t = (SELECT id_categoria FROM tipo_trabajador WHERE UPPER(desc_categoria) = 'CAJERO')
    -- O trabajadores con 1 o 2 cargas familiares
    OR (SELECT COUNT(*) FROM syn_asignacion af WHERE af.numrut_t = t.numrut) BETWEEN 1 AND 2
ORDER BY PCT_ESTUDIOS ASC, TRABAJADOR ASC;


SELECT *
FROM v_aumentos_estudios
ORDER BY 4, 1;


-- OPTIMIZACION DE CONSULTAS:

-- Índice B-Tree para búsquedas directas por apellido materno
CREATE INDEX idx_trabajador_apm
ON trabajador(apmaterno);

-- Índice Function-Based para búsquedas con UPPER(apmaterno)
CREATE INDEX idx_trabajador_apm_upper
ON trabajador(UPPER(apmaterno));

-- CONSULTA ORIGINAL

SELECT numrut, fecnac, t.nombre, appaterno, t.apmaterno
FROM trabajador t
JOIN isapre i ON i.cod_isapre = t.cod_isapre
WHERE t.apmaterno = 'CASTILLO'
ORDER BY t.nombre;

--CONSULTA CON FUNCION UPPER

SELECT numrut, fecnac, t.nombre, appaterno, t.apmaterno
FROM trabajador t
JOIN isapre i ON i.cod_isapre = t.cod_isapre
WHERE UPPER(t.apmaterno) = 'CASTILLO'
ORDER BY t.nombre;
