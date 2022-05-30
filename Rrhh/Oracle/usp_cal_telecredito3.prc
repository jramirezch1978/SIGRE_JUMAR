create or replace procedure usp_cal_telecredito3
 ( as_nropla        in string ,
   ad_fec_proceso   in date ,
   as_codemp        in empresa.cod_empresa%type ) is

lk_caltel           constant char(2) := 'PR' ;

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

-- Cursor por codigo de trabajador
Cursor c_trabaj is
  select  distinct g.cod_trabajador, g.imp_adelanto, m.nro_cnta_ahorro
  from gratificacion g, maestro m
  where m.flag_cal_plnlla = '1' and
        m.flag_estado = '1' and
        m.nro_cnta_ahorro <> ' ' and
        m.cod_trabajador = g.cod_trabajador and
        g.imp_adelanto <> 0 and
        m.cod_empresa = as_codemp ;

begin

delete from tt_telecredito ;

--  Halla cuenta de cargo de la empresa
Select bc.cod_ctabco
 into ls_cnta_banco_emp
 from banco_cnta bc
where bc.cod_origen = lk_caltel and bc.cnta_ctbl = '10410419' ;

--  Halla nombre de la empresa
Select e.nombre
 into ls_nom_empresa
 from empresa e
where e.cod_empresa = as_codemp ;

--  Monto total a pagar por la empresa
Select sum(nvl(gra.imp_adelanto,0))
 into ln_neto_emp
 from gratificacion gra, maestro maes
where gra.imp_adelanto <> 0 and
      (gra.cod_trabajador = maes.cod_trabajador and maes.nro_cnta_ahorro <> ' ') and
      maes.flag_cal_plnlla = '1' and
      maes.flag_estado = '1' ;

--  Halla numero de trabajadores
Select count(*)
  into ln_trabajadores
  from gratificacion gr, maestro ma
  where gr.imp_adelanto <> 0 and
        (gr.cod_trabajador = ma.cod_trabajador and ma.nro_cnta_ahorro <> ' ') and
        ma.flag_cal_plnlla = '1' and
        ma.flag_estado = '1' ;
        
ln_trabajadores := nvl(ln_trabajadores,0) ;
ls_trabajadores := lpad(rtrim(to_char(ln_trabajadores)),6,'0') ;

ls_neto_emp := to_char(ln_neto_emp,'99999999999.99') ;
ls_neto_emp := replace(ls_neto_emp,'.','') ;
ls_neto_emp := lpad(ltrim(rtrim(ls_neto_emp)),15,'0') ;

--  Dia y mes de proceso segun fecha
ls_dia := to_char(ad_fec_proceso,'DD') ;
ls_mes := to_char(ad_fec_proceso,'MM') ;

ls_union_emp := '1'||' '||as_nropla||rtrim(ls_cnta_banco_emp)||
                substr(ls_nom_empresa,1,21)||'00000025639200' ;

If length(ls_union_emp)< 58 then  
  ls_union_emp := rpad(ls_union_emp,58,' ') ;
End if ;
  
--  Inserta registros de cabecera
ls_telecredito := ls_union_emp||' '||'S/'||ls_neto_emp||ls_dia||ls_mes||
                  'H'||'    '||lpad(rtrim(ls_cnta_banco_emp),22,'0')||'TLC'||
                  '                 '||'1'||'          '||ls_trabajadores||
                  '                          '||'000000' ;

Insert into tt_telecredito (col_telecredito)
Values (ls_telecredito) ;

--  Lectura por trabajador
For rc_t in c_trabaj Loop

  ls_cnta_banco_trab := rc_t.nro_cnta_ahorro ;
  ls_cuenta_ahorro   := substr(ls_cnta_banco_trab,1,3)||'000'||
                        substr(ls_cnta_banco_trab,4,8)||
                        substr(ls_cnta_banco_trab,13,2) ;
                      
  ls_nombre := usf_nombre_trabajador(rc_t.cod_trabajador) ;
         
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
  Insert into tt_telecredito(col_telecredito)
  Values (ls_telecredito) ;
    
End loop ;

end usp_cal_telecredito3 ;
/
