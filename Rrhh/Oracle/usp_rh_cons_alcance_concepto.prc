create or replace procedure usp_rh_cons_alcance_concepto (
  as_tipo_trabajador in char, as_origen in char, ad_fec_hasta in date ) is

ls_nombre               varchar2(100) ;
ls_desc_area            varchar2(30) ;
ls_desc_seccion         varchar2(30) ;
ls_desc_cencos          varchar2(40) ;
ls_concepto             char(4) ;
ls_desc_concep          varchar2(30) ;

--  Cursor para la tabla de remuneraciones por conceptos
cursor c_remuneracion is 
  select c.cod_trabajador, c.fec_proceso, c.concep, c.imp_soles, m.cencos,
         m.cod_seccion, m.cod_area
  from calculo c, maestro m
  where c.cod_trabajador = m.cod_trabajador and m.cod_origen = as_origen and
        m.tipo_trabajador = as_tipo_trabajador and c.fec_proceso = ad_fec_hasta ;

begin

--  **********************************************************************
--  ***   CONSULTA DE ALCANCE DE LA PLANILLA CALCULADA POR CONCEPTOS   ***
--  **********************************************************************

delete from tt_rem_concepto ;

for rc_rem in c_remuneracion loop  

  ls_concepto := rc_rem.concep ;
  ls_nombre := usf_rh_nombre_trabajador (rc_rem.cod_trabajador) ;
    
  select a.desc_area into ls_desc_area from area a  
    where a.cod_area = rc_rem.cod_area ;
  select s.desc_seccion into ls_desc_seccion from seccion s
    where s.cod_area = rc_rem.cod_area and s.cod_seccion = rc_rem.cod_seccion ;
       
  if rc_rem.cencos is not null then
   select cc.desc_cencos into ls_desc_cencos from centros_costo cc
     where cc.cencos = rc_rem.cencos ;
  end if ;
     
  select c.desc_breve into ls_desc_concep from concepto c
    where c.concep = ls_concepto ;
     
  if ls_concepto = '1450' then
    ls_concepto := '0001' ;
  elsif ls_concepto = '2351' then
    ls_concepto := '0002' ;
  elsif ls_concepto = '2354' then
    ls_concepto := '0003' ;
  elsif ls_concepto = '3050' then
    ls_concepto := '0004' ;
  end if ;
  
  insert into tt_rem_concepto (
    cod_trabajador, nombre, cod_area, desc_area,
    cod_seccion, desc_seccion, cencos, desc_cencos,
    concep, desc_concep, fec_hasta, importe )
  values (
    rc_rem.cod_trabajador, ls_nombre, rc_rem.cod_area, ls_desc_area,
    rc_rem.cod_seccion, ls_desc_seccion, rc_rem.cencos, ls_desc_cencos,
    ls_concepto, ls_desc_concep, ad_fec_hasta, nvl(rc_rem.imp_soles,0) ) ;
      
end loop ;

end usp_rh_cons_alcance_concepto ;
/
