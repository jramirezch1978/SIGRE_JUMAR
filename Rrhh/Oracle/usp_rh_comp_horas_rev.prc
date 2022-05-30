create or replace procedure usp_rh_comp_horas_rev (
   asi_tipo_doc in string, 
   adi_ini in date, 
   adi_fin in date, 
   adi_proc in date, 
   ano_error_eliminando out number

) is
ln_sobret number(10);
   ln_inasist number(10);
   ln_dominical number(10);
   
begin

   delete 
      from sobretiempo_turno st
      where trim(st.tipo_doc) = trim(asi_tipo_doc)
         and trunc(st.fec_movim) between adi_ini and adi_fin;

   delete 
      from inasistencia i
      where trim(i.tipo_doc) = trim(asi_tipo_doc)
     	   and trunc(i.fec_movim) between adi_ini and adi_fin;

   delete 
      from gan_desct_variable gdv
      where trim(gdv.tipo_doc) = trim(asi_tipo_doc)
         and trunc(gdv.fec_movim) = adi_proc;

   commit;

   select count(*) 
      into ln_sobret
      from sobretiempo_turno st
      where trim(st.tipo_doc) = trim(asi_tipo_doc)
         and trunc(st.fec_movim) between adi_ini and adi_fin;

   select count(*) 
      into ln_inasist
      from inasistencia i
      where trim(i.tipo_doc) = trim(asi_tipo_doc)
     	   and trunc(i.fec_movim) between adi_ini and adi_fin;
   
   select count(*)
      into ln_dominical
      from gan_desct_variable gdv
      where trim(gdv.tipo_doc) = trim(asi_tipo_doc)
         and trunc(gdv.fec_movim) = adi_proc;
  
   if ln_dominical > 0 or ln_inasist > 0 or ln_sobret > 0 then
      ano_error_eliminando := 1;
   else
      ano_error_eliminando := 0;
   end if;  
end usp_rh_comp_horas_rev;
/
