create or replace procedure usp_rh_pago_cts_semestral (
  asi_origen       in origen.cod_origen%TYPE, 
  adi_fec_proceso  in date, 
  asi_tipo_trabaj  in tipo_trabajador.tipo_trabajador%TYPE,
  asi_cta_banco    IN banco_cnta.cod_ctabco%TYPE
) is

ls_nombre           char(40) ;
ls_nom_empresa      char(40) ;
ls_cod_empresa      char(8) ;
ls_direccion        char(40) ;
ln_neto_emp         calculo.imp_soles%type ;
ls_neto_emp         char(15) ;
ln_neto_trab        calculo.imp_soles%type ;
ls_neto_trab        char(15) ;
ls_cuenta_ahorro    char(17) ;
ls_telecredito      char(200) ;
ln_trabajadores     number(15) ;
ls_trabajadores     char(5) ;
ls_ruc              empresa.ruc%type ;
lc_soles            moneda.cod_moneda%Type ;
lc_dolares          moneda.cod_moneda%Type ;
lc_mon              char(2) ;
lc_mon_emp          char(2) ;
ln_tcambio          calendario.vta_dol_prom%type ;

ls_banco_bcp        finparam.banco_bcp%TYPE;
ls_moneda           moneda.cod_moneda%TYPE;

--  Pagos por Compensacion Tiempo de Servicio Semestral
cursor c_pagos is
  select p.cod_trabajador, (nvl(p.liquidacion, 0)) as importe,
         m.fec_nacimiento, m.dni, m.nro_cnta_cts,m.moneda_cts
  from cts_decreto_urgencia p, maestro m
  where p.cod_trabajador  = m.cod_trabajador
    and m.flag_estado     = '1'             
    and m.cod_origen      = asi_origen       
    and m.tipo_trabajador like asi_tipo_trabaj  
    and m.cod_banco_cts   = ls_banco_bcp        
    and m.nro_cnta_cts is not null
    and m.moneda_cts      = ls_moneda
    and trunc(p.fec_proceso)   = trunc(adi_fec_proceso)
order by m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2 ;

begin

--  *************************************************************
--  ***   GENERA ARCHIVO TEXTO DE PAGOS DE C.T.S. SEMESTRAL   ***
--  *************************************************************

select l.cod_soles, l.cod_dolares into lc_soles, lc_dolares
  from logparam l where l.reckey = '1' ;
  
select f.banco_bcp
  into ls_banco_bcp
  from finparam f
 where f.reckey = '1';

delete from tt_telecredito_cts_semestral ;

select bc.cod_moneda
  into ls_moneda
  from banco_cnta bc
 where bc.cod_banco = ls_banco_bcp
   and bc.cod_ctabco = asi_cta_banco;


--conversion de monto a pagar
IF ls_moneda = lc_dolares then


  select nvl(c.vta_dol_prom,0.000) into ln_tcambio
    from calendario c 
    where trunc(c.fecha) = trunc(adi_fec_proceso) ;

    if ln_tcambio = 0 then
      raise_application_error(-20000,'TIPO DE CAMBIO NO EXISTE VERIFIQUE!');
    end if ;

  select sum( round(  ( nvl(p.liquidacion, 0) ) / ln_tcambio ,2))
  into ln_neto_emp
  from cts_decreto_urgencia p, maestro m
  where p.cod_trabajador  = m.cod_trabajador
    and m.flag_estado     = '1'             
    and m.cod_origen      = asi_origen       
    and m.tipo_trabajador like asi_tipo_trabaj  
    and m.cod_banco_cts   = ls_banco_bcp        
    and m.nro_cnta_cts is not null
    and m.moneda_cts      = ls_moneda;

  lc_mon_emp := 'ME' ;

ELSE

  --  Determina monto total a pagar por la empresa
  select sum(nvl(p.liquidacion, 0))
    into ln_neto_emp
  from cts_decreto_urgencia p, maestro m
  where p.cod_trabajador  = m.cod_trabajador
    and m.flag_estado     = '1'             
    and m.cod_origen      = asi_origen       
    and m.tipo_trabajador like asi_tipo_trabaj  
    and m.cod_banco_cts   = ls_banco_bcp        
    and m.nro_cnta_cts is not null
    and m.moneda_cts      = ls_moneda;

    lc_mon_emp := 'MN' ;

END IF ;

--  Determia el numero de trabajadores
ln_trabajadores := 0 ;
select count(*) into ln_trabajadores
    from cts_decreto_urgencia p, maestro m
  where p.cod_trabajador  = m.cod_trabajador
    and m.flag_estado     = '1'             
    and m.cod_origen      = asi_origen       
    and m.tipo_trabajador like asi_tipo_trabaj  
    and m.cod_banco_cts   = ls_banco_bcp        
    and m.nro_cnta_cts is not null
    and m.moneda_cts      = ls_moneda;

ls_trabajadores := lpad(rtrim(to_char(ln_trabajadores)),5,'0') ;

ls_neto_emp := to_char(ln_neto_emp,'99999999999.99') ;
ls_neto_emp := replace(ls_neto_emp,'.','') ;
ls_neto_emp := lpad(ltrim(rtrim(ls_neto_emp)),15,'0') ;

--  Determina nombre de la empresa
select p.cod_empresa into ls_cod_empresa from genparam p
  where p.reckey = '1' ;
  
select substr(e.nombre,1,40), e.ruc, substr(e.dir_calle, 1, 40)
  into ls_nom_empresa, ls_ruc, ls_direccion
  from empresa e where e.cod_empresa = ls_cod_empresa ;

ls_telecredito := '2'||'              '||lc_mon_emp||'      '||ls_ruc||
                  '00000000000'||'      '||ls_neto_emp||ls_trabajadores||'          '||
                  'R1 '||ls_nom_empresa|| ls_direccion||
                  '                                   @' ;

insert into tt_telecredito_cts_semestral (col_telecredito)
values (ls_telecredito) ;

--  Lectura de pagos de C.T.S. semestral por trabajador
for rc_pag in c_pagos loop

  if nvl(rc_pag.importe,0) <> 0 then

--    ls_cuenta_ahorro := RPAD(trim(substr(rc_pag.nro_cnta_cts,1,17)),17,' ') ;
    ls_cuenta_ahorro := RPAD( REPLACE(trim(substr(rc_pag.nro_cnta_cts,1,17)),'-','') ,17 ,' ') ;
    --ls_cuenta_ahorro := substr(rc_pag.nro_cnta_cts,1,11) ;
    ls_nombre := Substr(usf_rh_nombre_trabajador(rc_pag.cod_trabajador),1,40) ;

    ln_neto_trab := nvl(rc_pag.importe,0) ;
    if rc_pag.moneda_cts = lc_soles then
      lc_mon := TRIM('MN');
    elsif rc_pag.moneda_cts = lc_dolares then
      lc_mon := TRIM('ME');
      ln_neto_trab := Round(ln_neto_trab / ln_tcambio,2);
    end if ;

    ls_neto_trab := to_char(ln_neto_trab,'99999999999.99') ;
    ls_neto_trab := replace(ls_neto_trab,'.','') ;
    ls_neto_trab := lpad(ltrim(rtrim(ls_neto_trab)),15,'0') ;

      ls_telecredito := '3'||'              '||lc_mon||'      '||ls_ruc||
                      ls_cuenta_ahorro||ls_neto_trab||'00000'||'          '||
                      'R1C'||ls_nombre||ls_direccion||'19'||to_char(rc_pag.fec_nacimiento,'yymmdd')||
                      rc_pag.dni||' 1'||'                  ' ;

    insert into tt_telecredito_cts_semestral (col_telecredito)
    values (ls_telecredito) ;

  end if ;

end loop ;

end usp_rh_pago_cts_semestral ;
/
