


-- PRY2205_S5 - Solución Caso 1: Listado de Clientes

SELECT
  TO_CHAR(c.numrun, '99G999G999') || '-' || c.dvrun AS "RUT Cliente",
  INITCAP(c.pnombre || ' ' || c.appaterno)         AS "Nombre Cliente",
  UPPER(p.nombre_prof_ofic)                        AS "Profesión Cliente",
  TO_CHAR(c.fecha_inscripcion, 'DD-MM-YYYY')       AS "Fecha de Inscripción",
  NVL(c.direccion, '')                             AS "Dirección Cliente"
FROM cliente c
JOIN profesion_oficio p
  ON c.cod_prof_ofic = p.cod_prof_ofic
LEFT JOIN tipo_cliente tc
  ON c.cod_tipo_cliente = tc.cod_tipo_cliente
WHERE
  UPPER(p.nombre_prof_ofic) IN ('CONTADOR', 'VENDEDOR')
  AND UPPER(NVL(tc.nombre_tipo_cliente, '')) LIKE '%DEPENDIENT%'
  AND EXTRACT(YEAR FROM c.fecha_inscripcion) >
      (SELECT ROUND(AVG(EXTRACT(YEAR FROM fecha_inscripcion))) FROM cliente)
ORDER BY c.numrun, c.dvrun;



-- CASO 2: Aumento de crédito


CREATE TABLE CLIENTES_CUPOS_COMPRA AS

SELECT
  TO_CHAR(c.numrun, '99G999G999') || '-' || c.dvrun                               AS RUT_CLIENTE,
  TRUNC(MONTHS_BETWEEN(SYSDATE, c.fecha_nacimiento) / 12)                          AS EDAD,
  TO_CHAR(t.cupo_disp_compra, '$999G999G999')                                      AS CUPO_DISPONIBLE_COMPRA,
  UPPER(NVL(tc.nombre_tipo_cliente, ''))                                           AS TIPO_CLIENTE
FROM cliente c
JOIN tarjeta_cliente t
  ON c.numrun = t.numrun
LEFT JOIN tipo_cliente tc
  ON c.cod_tipo_cliente = tc.cod_tipo_cliente
WHERE
  t.cupo_disp_compra >= (
    SELECT NVL(MAX(t2.cupo_disp_compra), 0)
    FROM tarjeta_cliente t2
    WHERE EXTRACT(YEAR FROM t2.fecha_solic_tarjeta) = EXTRACT(YEAR FROM SYSDATE) - 1
  )
ORDER BY EDAD
;
