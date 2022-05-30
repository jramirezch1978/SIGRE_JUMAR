create or replace view prueba as
  select m.cod_trabajador,m.cod_area, m.cod_seccion,
         a.desc_area, s.desc_seccion 
    from maestro m, area a, seccion s
    where m.cod_area = a.cod_area and 
          m.cod_seccion = s.cod_seccion and
          a.cod_area = s.cod_area; 
   