create or replace view vw_rh_ganvar as 

   select gdv.cod_trabajador, gdv.concep, gdv.nro_doc, gdv.imp_var, gdv.cod_usr, gdv.fec_movim 
      from gan_desct_variable gdv
   
   union all
   
   select hv.cod_trabajador, hv.concep, hv.nro_doc, hv.imp_var, hv.cod_usr, hv.fec_movim 
      from historico_variable hv
      left outer join gan_desct_variable gdv
         on gdv.cod_trabajador = hv.cod_trabajador
         and gdv.concep = hv.cod_trabajador
         and trunc(gdv.fec_movim) = trunc(hv.fec_movim)
      where gdv.concep is null
