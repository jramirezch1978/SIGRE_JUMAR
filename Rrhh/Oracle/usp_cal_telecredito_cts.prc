create or replace procedure usp_cal_telecredito_cts
 ( ad_fec_proceso in date, an_porcentaje in number ) is

ls_nombre           char(40) ;
ln_neto_emp         calculo.imp_soles%type ;
ls_neto_emp         char(15) ;
ln_neto_trab        calculo.imp_soles%type ;
ls_neto_trab        char(15) ;
ls_cuenta_ahorro    char(11) ;
ls_telecredito      char(200) ;
ln_trabajadores     number(15) ;
ls_trabajadores     char(5) ;

--  Lectura de pagos por C.T.S. del decreto de urgencia
cursor c_pagos is
  select distinct d.cod_trabajador, d.liquidacion, m.fec_nacimiento,
         m.dni, m.nro_cnta_cts
  from cts_decreto_urgencia d, maestro m
  where to_char(d.fec_proceso,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') and
        d.liquidacion <> 0 and d.cod_trabajador = m.cod_trabajador and
        m.cod_empresa = 'AIPSA' and m.flag_estado = '1' ;

begin

delete from tt_telecredito ;

--  Monto total a pagar por la empresa
select sum(nvl(d.liquidacion,0))
  into ln_neto_emp from cts_decreto_urgencia d, maestro m
  where to_char(d.fec_proceso,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') and
        d.liquidacion <> 0 and d.cod_trabajador = m.cod_trabajador and
        m.cod_empresa = 'AIPSA' and m.flag_estado = '1' ;

ln_neto_emp := ln_neto_emp + (ln_neto_emp * an_porcentaje) ;
ls_neto_emp := to_char(ln_neto_emp,'99999999999.99') ;
ls_neto_emp := replace(ls_neto_emp,'.','') ;
ls_neto_emp := lpad(ltrim(rtrim(ls_neto_emp)),15,'0') ;

--  Halla numero de trabajadores
select count(*)
  into ln_trabajadores from cts_decreto_urgencia d, maestro m
  where to_char(d.fec_proceso,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') and
        d.liquidacion <> 0 and d.cod_trabajador = m.cod_trabajador and
        m.cod_empresa = 'AIPSA' and m.flag_estado = '1' ;
        
ln_trabajadores := nvl(ln_trabajadores,0) ;
ls_trabajadores := lpad(rtrim(to_char(ln_trabajadores)),5,'0') ;

ls_telecredito := '2'||'              '||'MN'||'      '||'20135948641'||
                  '00000000000'||'      '||ls_neto_emp||ls_trabajadores||'          '||
                  'R1 '||'AGRO INDUSTRIAL PARAMONGA S.A.          '||
                  'Av. Ferrocarril Nro. 212                '||
                  '                                   @' ;
  
insert into tt_telecredito (col_telecredito)
values (ls_telecredito) ;

--  Lectura de pagos de C.T.S. por trabajador
for rc_pag in c_pagos loop

  ls_cuenta_ahorro := substr(rc_pag.nro_cnta_cts,1,11) ;
  ls_nombre := usf_nombre_trabajador(rc_pag.cod_trabajador) ;
         
  ln_neto_trab := nvl(rc_pag.liquidacion,0) ;
  ln_neto_trab := ln_neto_trab + (nvl(rc_pag.liquidacion,0) * an_porcentaje) ;
  ls_neto_trab := to_char(ln_neto_trab,'99999999999.99') ;
  ls_neto_trab := replace(ls_neto_trab,'.','') ;
  ls_neto_trab := lpad(ltrim(rtrim(ls_neto_trab)),15,'0') ;
     
  ls_telecredito := '3'||'              '||'MN'||'      '||'20135948641'||
                    ls_cuenta_ahorro||'      '||ls_neto_trab||'00000'||'          '||
                    'R1C'||ls_nombre||
                    'Av. Ferrocarril Nro. 212                '||'19'||to_char(rc_pag.fec_nacimiento,'YYMMDD')||
                    rc_pag.dni||' 1'||'                  ' ;

  insert into tt_telecredito(col_telecredito)
  values (ls_telecredito) ;
    
end loop ;

end usp_cal_telecredito_cts ;
/
