

   // CASO 1: 

SELECT 
    p.id_profesional AS "ID",
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS "PROFESIONAL",
    SUM(CASE WHEN t.cod_sector = 3 THEN 1 ELSE 0 END) AS "NRO ASESORIA BANCA",
    SUM(CASE WHEN t.cod_sector = 3 THEN t.honorario ELSE 0 END) AS "MONTO_TOTAL_BANCA",
    SUM(CASE WHEN t.cod_sector = 4 THEN 1 ELSE 0 END) AS "NRO ASESORIA RETAIL",
    SUM(CASE WHEN t.cod_sector = 4 THEN t.honorario ELSE 0 END) AS "MONTO_TOTAL_RETAIL",
    COUNT(*) AS "TOTAL ASESORIAS",
    SUM(t.honorario) AS "TOTAL HONORARIOS"
FROM (
    SELECT a.id_profesional, a.honorario, e.cod_sector
    FROM asesoria a
    JOIN empresa e ON a.cod_empresa = e.cod_empresa
    WHERE e.cod_sector = 3
    UNION ALL
    SELECT a.id_profesional, a.honorario, e.cod_sector
    FROM asesoria a
    JOIN empresa e ON a.cod_empresa = e.cod_empresa
    WHERE e.cod_sector = 4
) t
JOIN profesional p ON t.id_profesional = p.id_profesional
GROUP BY p.id_profesional, p.appaterno, p.apmaterno, p.nombre
ORDER BY p.id_profesional ASC;



   -- CASO 2:
   
DROP TABLE reporte_mes CASCADE CONSTRAINTS;    

-- 1. Crear la tabla de reporte (Sentencia DDL)

CREATE TABLE reporte_mes (
    id_prof NUMBER(10),
    nombre_completo VARCHAR2(100),
    nombre_profesion VARCHAR2(50),
    nom_comuna VARCHAR2(50),
    nro_asesorias NUMBER,
    monto_total_honorarios NUMBER,
    promedio_honorario NUMBER,
    honorario_minimo NUMBER,
    honorario_maximo NUMBER
);

-- 2. Insertar los datos en la tabla (Sentencia DML con funciones y joins)

INSERT INTO reporte_mes
SELECT 
    p.id_profesional AS id_prof,
    INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre) AS nombre_completo,
    pr.nombre_profesion AS nombre_profesion,
    c.nom_comuna AS nom_comuna,
    COUNT(*) AS nro_asesorias,
    ROUND(SUM(a.honorario)) AS monto_total_honorarios,
    ROUND(AVG(a.honorario)) AS promedio_honorario,
    ROUND(MIN(a.honorario)) AS honorario_minimo,
    ROUND(MAX(a.honorario)) AS honorario_maximo
FROM asesoria a
JOIN profesional p ON a.id_profesional = p.id_profesional
JOIN profesion pr ON p.cod_profesion = pr.cod_profesion
JOIN comuna c ON p.cod_comuna = c.cod_comuna
WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 4
  AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY p.id_profesional, p.appaterno, p.apmaterno, p.nombre, pr.nombre_profesion, c.nom_comuna
ORDER BY p.id_profesional ASC;
COMMIT;

-- 3. Consultar el reporte generado
SELECT * FROM reporte_mes ORDER BY id_prof ASC;



  -- CASO 3

-- 1. Reporte ANTES de la actualización

-- Reporte ANTES
SELECT  SUM(a.honorario) AS honorario, p.id_profesional, p.numrun_prof, p.sueldo
FROM profesional p
JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 3
  AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY p.id_profesional, p.numrun_prof, p.sueldo
ORDER BY p.id_profesional;

-- Actualización
UPDATE profesional p
SET sueldo = CASE
    WHEN (SELECT NVL(SUM(a.honorario),0)
          FROM asesoria a
          WHERE a.id_profesional = p.id_profesional
            AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
            AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
         ) < 1000000
    THEN ROUND(p.sueldo * 1.10)
    ELSE ROUND(p.sueldo * 1.15)
END
WHERE EXISTS (
    SELECT 1
    FROM asesoria a
    WHERE a.id_profesional = p.id_profesional
      AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
      AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
);

COMMIT;

-- Reporte DESPUÉS
SELECT SUM(a.honorario) AS honorario, p.id_profesional, p.numrun_prof, p.sueldo
FROM profesional p
JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 3
  AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY p.id_profesional, p.numrun_prof, p.sueldo
ORDER BY p.id_profesional;