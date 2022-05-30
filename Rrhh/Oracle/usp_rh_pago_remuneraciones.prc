create or replace procedure usp_rh_pago_remuneraciones (
  asi_origen       in origen.cod_origen%TYPE, 
  adi_fec_proceso  in date, 
  asi_nropla       in VARCHAR2,
  asi_tipo_trabaj  in tipo_trabajador.tipo_trabajador%TYPE,
  asi_cta_banco    IN banco_cnta.cod_ctabco%TYPE 
) is

ls_dia                char(2) ;
ls_mes                char(2) ;
ls_ano                char(4) ;
ln_neto_trab          calculo.imp_soles%type ;
lc_neto_trab          char(15) ;
lc_cuenta_ahorro      char(16) ;
lc_nombres            varchar2(100) ;

lc_telecredito        tt_telecredito.col_telecredito%TYPE;
ln_neto_emp           calculo.imp_soles%type ;
lc_neto_emp           char(15) ;
lc_ctas               char(15) ;
ln_trabajadores       number(15) ;
lc_trabajadores       char(6) ;
lc_nom_empresa        empresa.nombre%type ;
ls_concepto           concepto.concep%TYPE;
ln_suma_ctas          NUMBER;
ln_val_cta_emp        NUMBER;

-- Lectura de trabajadores para pago de remuneraciones
cursor c_trabajadores is
  SELECT c.imp_soles AS pagos, 
         m.nro_cnta_ahorro AS cuenta, 
         upper(m.apel_paterno || ' ' || m.apel_materno || ' ' || m.nombre1 || ' ' || m.nombre2) AS nombre,
         m.nro_doc_ident_rtps AS dni
  from calculo c, 
       maestro m
  where m.cod_trabajador = c.cod_trabajador 
    and m.flag_cal_plnlla = '1' 
    AND m.flag_estado = '1' 
    and (m.nro_cnta_ahorro <> ' ' AND m.nro_cnta_ahorro IS NOT NULL)
    AND c.concep = ls_concepto 
    and nvl(c.imp_soles,0) <> 0 
    AND m.tipo_trabajador like asi_tipo_trabaj 
    and m.cod_origen = asi_origen
 order by nombre;

begin

--  *************************************************************
--  ***   REALIZA PAGO DE REMUNERACIONES A LOS TRABAJADORES   ***
--  *************************************************************

delete from tt_telecredito ;

-- Determino el concepto de pago de remuneraciones
select p.cnc_total_pgd 
  into ls_concepto 
  from rrhhparam p
 where p.reckey = '1';

-- Determina nombre de la empresa
select e.nombre 
  into lc_nom_empresa 
  from empresa e,
       genparam g
  where g.cod_empresa = e.cod_empresa
    AND g.reckey = '1';

--  Determina monto total a pagar por la empresa
select sum(nvl(c.imp_soles,0)), COUNT(*)
  into ln_neto_emp, ln_trabajadores
  from calculo c, maestro m
  where c.cod_trabajador = m.cod_trabajador 
    and m.flag_cal_plnlla = '1' 
    AND m.flag_estado = '1' 
    and m.cod_origen = asi_origen 
    AND m.tipo_trabajador like asi_tipo_trabaj 
    AND (m.nro_cnta_ahorro <> ' ' AND m.nro_cnta_ahorro IS NOT NULL)
    and c.concep = ls_concepto 
    AND nvl(c.imp_soles,0) <> 0 ;

-- cuentas de baco
--select replace(rtrim(to_char(sum(substr(replace(m.nro_cnta_ahorro,'-',''),4)),'999999999999999')),'.','')
SELECT sum(substr(replace(m.nro_cnta_ahorro,'-',''),4))  
  into ln_suma_ctas
  from calculo c, maestro m
  where c.cod_trabajador = m.cod_trabajador 
    and m.flag_cal_plnlla = '1' 
    AND m.flag_estado = '1' 
    and m.cod_origen = asi_origen 
    AND m.tipo_trabajador like asi_tipo_trabaj 
    AND (m.nro_cnta_ahorro <> ' ' AND m.nro_cnta_ahorro IS NOT NULL)
    and c.concep = ls_concepto 
    AND nvl(c.imp_soles,0) <> 0 ;

-- Obtengo los ultimos digistos de la cuenta de la empresa
ln_val_cta_emp := to_number(substr(ltrim(rtrim(asi_cta_banco)),4));
ln_suma_ctas := ln_suma_ctas + ln_val_cta_emp;
lc_ctas      := replace(rtrim(to_char(ln_suma_ctas,'999999999999999')),'.','');

lc_trabajadores := lpad(rtrim(to_char(ln_trabajadores)),6,'0') ;

lc_neto_emp := to_char(ln_neto_emp,'99999999999.99') ;
lc_neto_emp := replace(lc_neto_emp,'.','') ;
lc_neto_emp := lpad(ltrim(rtrim(lc_neto_emp)),15,'0') ;

--  Inserta registros de cabecera
ls_dia := to_char(adi_fec_proceso,'dd') ;
ls_mes := to_char(adi_fec_proceso,'mm') ;
ls_ano := to_char(adi_fec_proceso,'yyyy') ;
lc_telecredito := '#' || asi_nropla || ltrim(rtrim(asi_cta_banco)) || '      S/'||lc_neto_emp||ls_dia||ls_mes||ls_ano||'PAGO HABERES        '
                      ||ltrim(ltrim(lc_ctas))||ltrim(rtrim(lc_trabajadores))||'1               1';

insert into tt_telecredito (col_telecredito)
values (lc_telecredito) ;



--  Lectura por trabajador para pago de remuneraciones
for rc_t in c_trabajadores loop
    lc_nombres       := Substr(rc_t.nombre,1,36)  ;
    lc_cuenta_ahorro := REPLACE(rc_t.cuenta,'-','') ;

   ln_neto_trab := nvl(rc_t.pagos,0) ;
   lc_neto_trab := to_char(ln_neto_trab,'99999999999.99') ;
   lc_neto_trab := replace(lc_neto_trab,'.','') ;
   lc_neto_trab := lpad(ltrim(rtrim(lc_neto_trab)),15,'0') ;

  lc_telecredito := ' 2A'||rPAD(lc_cuenta_ahorro,20,' ')||rpad(substr(lc_nombres,1,36),40,' ')||'S/'||
                   lc_neto_trab||rpad('PAGO TELECREDITO', 40, ' ')||'0'||'DNI'||rpad(substr(rc_t.dni,1,8),12,' ')||'1' ;
  
  insert into tt_telecredito(col_telecredito)
  values (lc_telecredito) ;

end loop ;



end  usp_rh_pago_remuneraciones ;
/
