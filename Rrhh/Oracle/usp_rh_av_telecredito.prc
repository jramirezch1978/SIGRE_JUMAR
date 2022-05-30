create or replace procedure usp_rh_av_telecredito (
  as_origen in char, ad_fec_proceso in date, as_nropla in char,
  as_tipo_trabaj in char ) is

ls_codigo             char(8) ;
ln_importe            number(13,2) ;

ls_concepto           char(4) ;
ls_cod_empresa        char(8) ;
ls_nombre             varchar2(100) ;
ln_neto_emp           calculo.imp_soles%type ;
ls_neto_emp           char(15) ;
ln_neto_trab          calculo.imp_soles%type ;
ls_neto_trab          char(15) ;
ls_cnta_banco_emp     char(25) ;
ls_cnta_banco_trab    char(25) ;
ls_cuenta_ahorro      char(16) ;
ls_dia                char(2) ;
ls_mes                char(2) ;
ls_telecredito        char(176) ;
ls_nom_empresa        empresa.nombre%type ;
ls_union_emp          string(100) ;
ls_union_trab         char(59) ;
ln_trabajadores       number(15) ;
ls_trabajadores       char(6) ;

--  Lectura para determinar pago por compensacion variable
cursor c_movimiento is
  select c.cod_trabajador, c.importe
  from rrhh_compensacion_var c
  where c.ano = to_number(to_char(ad_fec_proceso,'yyyy')) and
        c.mes = to_number(to_char(ad_fec_proceso,'mm')) and c.flag_estado = '2'
  order by c.cod_trabajador, c.calif_tipo ;
rc_mov c_movimiento%rowtype ;

--  Lectura de trabajadores para pago de compensacion variable
cursor c_trabajadores is
  select p.codigo, p.importe, m.nro_cnta_ahorro
  from tt_av_pago_telecredito p, maestro m
  where p.codigo = m.cod_trabajador and m.nro_cnta_ahorro <> ' ' and
        m.tipo_trabajador like as_tipo_trabaj and m.cod_origen = as_origen ;

begin

--  ******************************************************************
--  ***   REALIZA PAGO VIA TELECREDITO POR COMPENSACION VARIABLE   ***
--  ******************************************************************

delete from tt_av_pago_telecredito ;
open c_movimiento ;
fetch c_movimiento into rc_mov ;
while c_movimiento%found loop
  ls_codigo := rc_mov.cod_trabajador ; ln_importe := 0 ;
  while rc_mov.cod_trabajador = ls_codigo and c_movimiento%found loop
    ln_importe := ln_importe + nvl(rc_mov.importe,0) ;
    fetch c_movimiento into rc_mov ;
  end loop ;
  if ln_importe > 0 then
    insert into tt_av_pago_telecredito ( codigo, importe )
    values ( ls_codigo, ln_importe ) ;
  end if ;
end loop ;
close c_movimiento ;

delete from tt_telecredito ;

--  Determina cuenta de cargo de la empresa
select bc.cod_ctabco into ls_cnta_banco_emp from banco_cnta bc
  where bc.cod_origen = as_origen and bc.cnta_ctbl = '10410419' ;

--  Determina nombre de la empresa
select p.cod_empresa into ls_cod_empresa from genparam p
  where p.reckey = '1' ;
select e.nombre into ls_nom_empresa from empresa e
  where e.cod_empresa = ls_cod_empresa ;

--  Determina monto total a pagar por la empresa
select sum(nvl(p.importe,0)) into ln_neto_emp
  from tt_av_pago_telecredito p, maestro m
  where p.codigo = m.cod_trabajador and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj and
        m.nro_cnta_ahorro <> ' ' ;

--  Determina el numero de trabajadores de la empresa
ln_trabajadores := 0 ;
select count(*) into ln_trabajadores
  from tt_av_pago_telecredito p, maestro m
  where p.codigo = m.cod_trabajador and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj and
        m.nro_cnta_ahorro <> ' ' ;
ls_trabajadores := lpad(rtrim(to_char(ln_trabajadores)),6,'0') ;

ls_neto_emp := to_char(ln_neto_emp,'99999999999.99') ;
ls_neto_emp := replace(ls_neto_emp,'.','') ;
ls_neto_emp := lpad(ltrim(rtrim(ls_neto_emp)),15,'0') ;

ls_union_emp := '1'||' '||as_nropla||rtrim(ls_cnta_banco_emp)||
                substr(ls_nom_empresa,1,21)||'00000025639200' ;

if length(ls_union_emp)< 58 then
  ls_union_emp := rpad(ls_union_emp,58,' ') ;
end if ;

--  Inserta registros de cabecera
ls_dia := to_char(ad_fec_proceso,'dd') ;
ls_mes := to_char(ad_fec_proceso,'mm') ;
ls_telecredito := ls_union_emp||' '||'S/'||ls_neto_emp||ls_dia||ls_mes||
                  'H'||'    '||lpad(rtrim(ls_cnta_banco_emp),22,'0')||'TLC'||
                  '                 '||'1'||'          '||ls_trabajadores||
                  '                          '||'000000' ;

insert into tt_telecredito (col_telecredito)
values (ls_telecredito) ;

--  Lectura por trabajador para pago de remuneraciones
for rc_t in c_trabajadores loop

  ls_cnta_banco_trab := rc_t.nro_cnta_ahorro ;
  ls_cuenta_ahorro   := substr(ls_cnta_banco_trab,1,3)||'000'||
                        substr(ls_cnta_banco_trab,4,8)||
                        substr(ls_cnta_banco_trab,13,2) ;

  ls_nombre := usf_rh_nombre_trabajador(rc_t.codigo) ;

  ln_neto_trab := nvl(rc_t.importe,0) ;
  ls_neto_trab := to_char(ln_neto_trab,'99999999999.99') ;
  ls_neto_trab := replace(ls_neto_trab,'.','') ;
  ls_neto_trab := lpad(ltrim(rtrim(ls_neto_trab)),15,'0') ;

  ls_union_trab := '4'||' '||as_nropla||ls_cuenta_ahorro||
                   substr(ls_nombre,1,36) ;

  --  Union de campos para insertar registro
  ls_telecredito := ls_union_trab||'S/'||ls_neto_trab||'0'||'   '||'H'||
                    '    '||lpad(rtrim(ls_cnta_banco_emp),22,'0')||'TLC'||
                    '                                                            '||
                    '000000' ;
  insert into tt_telecredito(col_telecredito)
  values (ls_telecredito) ;

end loop ;

end usp_rh_av_telecredito ;
/
