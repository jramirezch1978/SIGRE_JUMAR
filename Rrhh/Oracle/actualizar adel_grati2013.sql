update gan_desct_variable c
   set c.imp_var = (select nvl(t.imp_soles,0) from adel_grati2013 t where t.cod_trabajador = c.cod_trabajador)
where c.concep = '2307'
  and c.cod_trabajador in (select cod_trabajador from adel_grati2013)
  and c.imp_var <> (select nvl(t.imp_soles,0) from adel_grati2013 t where t.cod_trabajador = c.cod_trabajador)
