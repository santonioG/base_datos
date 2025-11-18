
--Caso 1 - Listado de Trabajadores

SELECT
  UPPER(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS "Nombre Completo Trabajador",
  TO_CHAR(t.numrut, '99G999G999') || '-' || t.dvrut AS "RUT Trabajador",
  tt.desc_categoria AS "Tipo Trabajador",
  UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador",
  TO_CHAR(ROUND(t.sueldo_base), '$9G999G999', 'NLS_NUMERIC_CHARACTERS = '',.''') AS "Sueldo Base"
FROM trabajador t
JOIN tipo_trabajador tt      ON t.id_categoria_t = tt.id_categoria
LEFT JOIN comuna_ciudad cc   ON t.id_ciudad = cc.id_ciudad
WHERE t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY cc.nombre_ciudad DESC, t.sueldo_base ASC;

-- Caso 2 — Listado Cajeros

SELECT
  TO_CHAR(t.numrut, '99G999G999') || '-' || t.dvrut AS "RUT Trabajador",
 (INITCAP(t.nombre) || ' ' || UPPER(t.appaterno)) AS "Nombre Trabajador",
  COUNT(tc.nro_ticket) AS "Total Tickets",
  TO_CHAR(SUM(tc.monto_ticket), '$9G999G999') AS "Total Vendido",
  TO_CHAR(SUM(ct.valor_comision), '$9G999G999') AS "Comision Total",
  tt.desc_categoria AS "Tipo Trabajador",
  UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador"
FROM trabajador t
JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
LEFT JOIN tickets_concierto tc ON t.numrut = tc.numrut_t
LEFT JOIN comisiones_ticket ct ON tc.nro_ticket = ct.nro_ticket
LEFT JOIN comuna_ciudad cc ON t.id_ciudad = cc.id_ciudad
WHERE UPPER(tt.desc_categoria) = 'CAJERO'
GROUP BY t.numrut, t.dvrut, t.appaterno, t.apmaterno, t.nombre, cc.nombre_ciudad,tt.desc_categoria
HAVING SUM(NVL(tc.monto_ticket,0)) > 50000
ORDER BY SUM(NVL(tc.monto_ticket,0)) DESC;

-- Caso 3 — Listado de Bonificaciones

SELECT
  TO_CHAR(t.numrut, '99G999G999') AS "RUT Trabajador",
  INITCAP( t.nombre  || ' ' || t.appaterno) AS "Trabajador Nombre",
  EXTRACT(YEAR FROM t.fecing) AS "Año Ingreso",
  FLOOR(MONTHS_BETWEEN(SYSDATE, t.fecing)/12) AS "Años Antigüedad",
  NVL((SELECT COUNT(1) FROM asignacion_familiar af WHERE af.numrut_t = t.numrut),0) AS "Num. Cargas Familiares",
  INITCAP(i.nombre_isapre) AS "Nombre Isapre",
  TO_CHAR(ROUND(t.sueldo_base), '$9G999G999') AS "Sueldo Base",
  CASE WHEN UPPER(i.nombre_isapre) = 'FONASA' THEN 
    TO_CHAR(ROUND(t.sueldo_base * 0.01), '$9G999G999', 'NLS_NUMERIC_CHARACTERS = '',.''')
  ELSE 
   LPAD('0', 11)
END AS "Bono Fonasa",
  TO_CHAR(ROUND(CASE WHEN FLOOR(MONTHS_BETWEEN(SYSDATE, t.fecing)/12) <= 10 THEN t.sueldo_base * 0.10 ELSE t.sueldo_base * 0.15 END), '$9G999G999') AS "Bono Antigüedad",
  INITCAP(a.nombre_afp) AS "Nombre AFP",
  (SELECT UPPER(ecv.desc_estcivil) FROM est_civil ec
   JOIN estado_civil ecv ON ec.id_estcivil_est = ecv.id_estcivil
    WHERE ec.numrut_t = t.numrut
      AND (ec.fecter_estcivil IS NULL OR ec.fecter_estcivil > SYSDATE)
      AND ROWNUM = 1
  ) AS "Estado Civil"
FROM trabajador t
LEFT JOIN isapre i ON t.cod_isapre = i.cod_isapre
LEFT JOIN afp a ON t.cod_afp = a.cod_afp
WHERE EXISTS (
  SELECT 1 FROM est_civil ec
  WHERE ec.numrut_t = t.numrut
    AND (ec.fecter_estcivil IS NULL OR ec.fecter_estcivil > SYSDATE)
)
ORDER BY t.numrut;
