create or replace procedure usp_rh_pago_gratificaciones (
  as_origen in char, ad_fec_proceso in date, as_nropla in char,
  as_tipo_trabaj in char ) is

ls_cod_empresa      char(8) ;
ls_nombre           varchar2(100) ;
ln_neto_emp         calculo.imp_soles%type ;
ls_neto_emp         char(15) ;
ln_neto_trab        calculo.imp_soles%type ;
ls_neto_trab        char(15) ;
ls_cnta_banco_emp   char(25) ;
ls_cnta_banco_trab  char(25) ;
ls_cuenta_ahorro    char(16) ;
ls_dia              char(2) ;
ls_mes              char(2) ;
ls_telecredito      char(176) ;
ls_nom_empresa      empresa.nombre%type ;
ls_union_emp        string(100) ;
ls_union_trab       char(59) ;
ln_trabajadores     number(15) ;
ls_trabajadores     char(6) ;

-- Lectura de trabajadores para pagos de gratificaciones
cursor c_trabajadores is
  select g.cod_trabajador, g.imp_adelanto, m.nro_cnta_ahorro
  from gratificacion g, maestro m
  where g.cod_trabajador = m.cod_trabajador and m.flag_cal_plnlla = '1' and
        m.flag_estado = '1' and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj and
        m.nro_cnta_ahorro <> ' ' and nvl(g.imp_adelanto,0) <> 0 ;

begin

--  **************************************************************
--  ***   REALIZA PAGO DE GRATIFICACIONES A LOS TRABAJADORES   ***
--  **************************************************************

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
select sum(nvl(g.imp_adelanto,0)) into ln_neto_emp
  from gratificacion g, maestro m
  where g.cod_trabajador = m.cod_trabajador and m.flag_cal_plnlla = '1' and
        m.flag_estado = '1' and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj and
        m.nro_cnta_ahorro <> ' ' and nvl(g.imp_adelanto,0) <> 0 ;

--  Determina numero de trabajadores de la empresa
ln_trabajadores := 0 ;
select count(*) into ln_trabajadores
  from gratificacion g, maestro m
  where g.cod_trabajador = m.cod_trabajador and m.flag_cal_plnlla = '1' and
        m.flag_estado = '1' and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj and
        m.nro_cnta_ahorro <> ' ' and nvl(g.imp_adelanto,0) <> 0 ;
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

--  Lectura por trabajador para pago de gratificaciones
for rc_t in c_trabajadores loop

  ls_cnta_banco_trab := rc_t.nro_cnta_ahorro ;
  ls_cuenta_ahorro   := substr(ls_cnta_banco_trab,1,3)||'000'||
                        substr(ls_cnta_banco_trab,4,8)||
                        substr(ls_cnta_banco_trab,13,2) ;

  ls_nombre := usf_rh_nombre_trabajador(rc_t.cod_trabajador) ;

  ln_neto_trab := nvl(rc_t.imp_adelanto,0) ;
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

end usp_rh_pago_gratificaciones ;
/
