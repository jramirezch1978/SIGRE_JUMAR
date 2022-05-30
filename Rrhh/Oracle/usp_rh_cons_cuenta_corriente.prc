create or replace procedure usp_rh_cons_cuenta_corriente (
  ad_fec_desde in date, ad_fec_hasta in date, as_tipo_trabajador in char,
  as_origen in char ) is

ls_nombre           tt_cons_cnta_crrte.nombre%type ;
ls_desc_area        area.desc_area%type ;
ls_desc_seccion     seccion.desc_seccion%type ;
ls_desc_cencos      centros_costo.desc_cencos%type ;
ls_desc_concep      concepto.desc_breve%type ;
ln_monto            number(13,2) ;
ln_cuota            number(13,2) ;
ln_saldo            number(13,2) ;
 
--  Lectura de cuenta corriente de los trabajadores seleccionados
cursor c_cons_cnta_crrte is 
  select cc.cod_trabajador, cc.concep, cc.fec_prestamo, cc.mont_original,
         cc.mont_cuota, cc.sldo_prestamo, cc.tipo_doc , cc.nro_doc,
         m.cod_area, m.cod_seccion, m.cencos
  from cnta_crrte cc, maestro m
  where cc.cod_trabajador = m.cod_trabajador and m.cod_origen = as_origen and
        m.tipo_trabajador = as_tipo_trabajador and cc.flag_estado = '1' and
        cc.fec_prestamo between ad_fec_desde and ad_fec_hasta ;
  
begin

--  *************************************************************
--  ***   CONSULTA DE CUENTA CORRIENTE POR ADMINISTRACIONES   ***
--  *************************************************************

delete from tt_cons_cnta_crrte ;

for rc_cc in c_cons_cnta_crrte loop 
     
  ln_monto := nvl(rc_cc.mont_original,0) ;
  ln_cuota := nvl(rc_cc.mont_cuota,0) ;
  ln_saldo := nvl(rc_cc.sldo_prestamo,0) ;
  ls_nombre := usf_rh_nombre_trabajador(rc_cc.cod_trabajador) ;
       
  select a.desc_area into ls_desc_area from area a  
    where a.cod_area = rc_cc.cod_area ;
       
  ls_desc_seccion := null ;
  select s.desc_seccion into ls_desc_seccion from seccion s
    where s.cod_area = rc_cc.cod_area and s.cod_seccion = rc_cc.cod_seccion ;
       
  ls_desc_cencos := null ;
  if rc_cc.cencos is not null then
    select cc.desc_cencos into ls_desc_cencos from centros_costo cc
      where cc.cencos = rc_cc.cencos ;
  end if ;
        
  select c.desc_breve into ls_desc_concep from concepto c
    where c.concep = rc_cc.concep ;
    
  if ln_monto <> 0 or ln_cuota <> 0 or ln_saldo <> 0 then
    insert into tt_cons_cnta_crrte (
      cod_trabajador, nombre, cod_area, desc_area,
      cod_seccion, desc_seccion, cencos, desc_cencos,
      concep, desc_concep, tipo_doc, nro_doc, 
      fec_prestamo, mont_original, mont_cuota,
      sldo_prestamo )
    values (
      rc_cc.cod_trabajador, ls_nombre, rc_cc.cod_area, ls_desc_area,
      rc_cc.cod_seccion, ls_desc_seccion, rc_cc.cencos, ls_desc_cencos,
      rc_cc.concep, ls_desc_concep, rc_cc.tipo_doc, rc_cc.nro_doc, 
      rc_cc.fec_prestamo, rc_cc.mont_original, rc_cc.mont_cuota,
      rc_cc.sldo_prestamo ) ;
  end if ;

end loop ;  
  
end usp_rh_cons_cuenta_corriente ;
/
