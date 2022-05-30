create or replace procedure usp_rh_rpt_cabecera_planilla (
  as_tipo_trabajador in char, as_origen in char, as_nro_desde in string,
  as_nro_hasta in string ) is

ln_nro_desde   number(10) ;
ln_nro_hasta   number(10) ;
ls_numeracion  char(10) ;

ls_empresa_nom        varchar2(50) ;
ls_empresa_dir        char(30) ;
ls_ruc                char(11) ;
ls_codigo             char(8) ;

begin

--  ************************************************************
--  ***   GENERA NUMERACION PARA CABECERA DE LAS PLANILLAS   ***
--  ************************************************************

delete from tt_numeracion_planilla ;

select p.cod_empresa into ls_codigo from genparam p
  where p.reckey = '1' and p.cod_origen = as_origen ;
select e.nombre, e.dir_calle, e.ruc
  into ls_empresa_nom, ls_empresa_dir, ls_ruc
  from empresa e where e.cod_empresa = ls_codigo ;

ln_nro_desde := to_number(as_nro_desde) ;
ln_nro_hasta := to_number(as_nro_hasta) ;

for x in ln_nro_desde .. ln_nro_hasta loop

  ls_numeracion := to_char(x,'999999999') ;
  ls_numeracion := lpad(ltrim(rtrim(ls_numeracion)),10,'0') ;
  insert into tt_numeracion_planilla
    ( empresa_nom, empresa_dir, ruc, nro_planilla )
  values
    ( ls_empresa_nom, ls_empresa_dir, ls_ruc, ls_numeracion ) ;

end loop ;

end usp_rh_rpt_cabecera_planilla ;
/
