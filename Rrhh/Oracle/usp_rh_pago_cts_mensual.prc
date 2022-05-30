create or replace procedure usp_rh_pago_cts_mensual (
  as_origen in char, ad_fec_proceso in date, an_porcentaje in number,
  as_tipo_trabaj in char ) is

ls_nombre           char(40) ;
ls_nom_empresa      char(40) ;
ls_cod_empresa      char(8) ;
ls_direccion        char(40) ;
ln_neto_emp         calculo.imp_soles%type ;
ls_neto_emp         char(15) ;
ln_neto_trab        calculo.imp_soles%type ;
ls_neto_trab        char(15) ;
ls_cuenta_ahorro    char(11) ;
ls_telecredito      char(200) ;
ln_trabajadores     number(15) ;
ls_trabajadores     char(5) ;
ls_ruc              empresa.ruc%type ;

--  Lectura de pagos por C.T.S. del decreto de urgencia
cursor c_pagos is
  select d.cod_trabajador, d.liquidacion, m.fec_nacimiento, m.dni, m.nro_cnta_cts
  from cts_decreto_urgencia d, maestro m
  where d.cod_trabajador = m.cod_trabajador and nvl(d.liquidacion,0) <> 0 and
        to_char(d.fec_proceso,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') and
        m.flag_estado = '1' and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj ;
begin

--  ******************************************************
--  ***   GENERA PAGOS DE C.T.S. DECRETO DE URGENCIA   ***
--  ******************************************************

delete from tt_telecredito ;

--  Determina monto total a pagar por la empresa
select sum(nvl(d.liquidacion,0))
  into ln_neto_emp from cts_decreto_urgencia d, maestro m
  where d.cod_trabajador = m.cod_trabajador and nvl(d.liquidacion,0) <> 0 and
        to_char(d.fec_proceso,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') and
        m.flag_estado = '1' and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj ;

--  Determia el numero de trabajadores
ln_trabajadores := 0 ;
select count(*) into ln_trabajadores
  from cts_decreto_urgencia d, maestro m
  where d.cod_trabajador = m.cod_trabajador and nvl(d.liquidacion,0) <> 0 and
        to_char(d.fec_proceso,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') and
        m.flag_estado = '1' and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj ;
ls_trabajadores := lpad(rtrim(to_char(ln_trabajadores)),5,'0') ;

ln_neto_emp := ln_neto_emp + (ln_neto_emp * an_porcentaje) ;
ls_neto_emp := to_char(ln_neto_emp,'99999999999.99') ;
ls_neto_emp := replace(ls_neto_emp,'.','') ;
ls_neto_emp := lpad(ltrim(rtrim(ls_neto_emp)),15,'0') ;

--  Determina nombre de la empresa
select p.cod_empresa into ls_cod_empresa from genparam p
  where p.reckey = '1' ;
select substr(e.nombre,1,40), e.ruc, e.dir_calle
  into ls_nom_empresa, ls_ruc, ls_direccion
  from empresa e where e.cod_empresa = ls_cod_empresa ;

ls_telecredito := '2'||'              '||'MN'||'      '||ls_ruc||
                  '00000000000'||'      '||ls_neto_emp||ls_trabajadores||'          '||
                  'R1 '||ls_nom_empresa|| ls_direccion||
                  '                                   @' ;

insert into tt_telecredito (col_telecredito)
values (ls_telecredito) ;

--  Lectura de pagos de C.T.S. por trabajador
for rc_pag in c_pagos loop

  ls_cuenta_ahorro := substr(rc_pag.nro_cnta_cts,1,11) ;
  ls_nombre := usf_rh_nombre_trabajador(rc_pag.cod_trabajador) ;

  ln_neto_trab := nvl(rc_pag.liquidacion,0) ;
  ln_neto_trab := ln_neto_trab + (nvl(rc_pag.liquidacion,0) * an_porcentaje) ;
  ls_neto_trab := to_char(ln_neto_trab,'99999999999.99') ;
  ls_neto_trab := replace(ls_neto_trab,'.','') ;
  ls_neto_trab := lpad(ltrim(rtrim(ls_neto_trab)),15,'0') ;

  ls_telecredito := '3'||'              '||'MN'||'      '||ls_ruc||
                    ls_cuenta_ahorro||'      '||ls_neto_trab||'00000'||'          '||
                    'R1C'||ls_nombre||ls_direccion||'19'||to_char(rc_pag.fec_nacimiento,'yymmdd')||
                    rc_pag.dni||' 1'||'                  ' ;

  insert into tt_telecredito(col_telecredito)
  values (ls_telecredito) ;

end loop ;

end usp_rh_pago_cts_mensual ;
/
