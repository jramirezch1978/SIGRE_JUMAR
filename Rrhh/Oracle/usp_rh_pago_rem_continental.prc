create or replace procedure usp_rh_pago_rem_continental (
  as_origen in char, as_cod_banco in char, as_tipo_trabaj in char,
  as_cnta_banco in char, ad_fec_proceso in date ) is

ls_concepto        char(4) ;
ln_verifica        integer ;
ls_neto_trab       char(14) ;
ls_cadena          char(269) ;

ls_dni             char(10) ;
ls_nombre          char(35) ;
ls_direccion       char(35) ;
ls_distrito        char(35) ;
ls_provincia       char(25) ;
ls_departamento    char(25) ;
ls_banco_cnta      char(4) ;
ls_oficina_cnta    char(4) ;
ls_control_cnta    char(2) ;
ls_persona_cnta    char(10) ;
ls_importe         char(14) ;
ls_pago_descri     char(35) ;
ls_pago_descmes    char(35) ;

-- Lectura de trabajadores para pago de remuneraciones
cursor c_trabajadores is
  select c.cod_trabajador, c.imp_soles, m.direccion, m.dni, m.nro_cnta_ahorro,
          m.cod_pais, m.cod_distr, m.cod_prov, m.cod_dpto
  from calculo c, maestro m
  where m.cod_trabajador = c.cod_trabajador and m.flag_cal_plnlla = '1' and
        m.flag_estado = '1' and trim(m.nro_cnta_ahorro) is not null and
        m.tipo_trabajador like as_tipo_trabaj and m.cod_origen = as_origen and
        m.cod_banco = as_cod_banco and c.concep = ls_concepto and
        nvl(c.imp_soles,0) <> 0
  order by m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2 ;

begin

--  *************************************************************
--  ***   REALIZA PAGO DE REMUNERACIONES A LOS TRABAJADORES   ***
--  *************************************************************

delete from tt_pago_bco_continental ;

select p.cnc_total_pgd into ls_concepto from rrhhparam p
  where p.reckey = '1' ;

for rc_tra in c_trabajadores loop

  ls_dni       := rc_tra.dni ;
  ls_nombre    := usf_rh_nombre_trabajador(rc_tra.cod_trabajador) ;
  ls_direccion := substr(rc_tra.direccion,1,35) ;
  
  ln_verifica := 0 ; ls_distrito := null ;
  select count(*) into ln_verifica from distrito d
    where d.cod_pais = rc_tra.cod_pais and d.cod_dpto = rc_tra.cod_dpto and
          d.cod_prov = rc_tra.cod_prov and d.cod_distr = rc_tra.cod_distr ;
  if ln_verifica > 0 then  
    select d.desc_distrito into ls_distrito from distrito d
      where d.cod_pais = rc_tra.cod_pais and d.cod_dpto = rc_tra.cod_dpto and
            d.cod_prov = rc_tra.cod_prov and d.cod_distr = rc_tra.cod_distr ;
  end if ;
  
  ln_verifica := 0 ; ls_provincia := null ;
  select count(*) into ln_verifica from provincia_condado p
    where p.cod_pais = rc_tra.cod_pais and p.cod_dpto = rc_tra.cod_dpto and
          p.cod_prov = rc_tra.cod_prov ;
  if ln_verifica > 0 then      
    select p.desc_prov into ls_provincia from provincia_condado p
      where p.cod_pais = rc_tra.cod_pais and p.cod_dpto = rc_tra.cod_dpto and
            p.cod_prov = rc_tra.cod_prov ;
  end if ;

  ln_verifica := 0 ; ls_departamento := null ;
  select count(*) into ln_verifica from departamento_estado d
    where d.cod_pais = rc_tra.cod_pais and d.cod_dpto = rc_tra.cod_dpto ;
  if ln_verifica > 0 then
    select d.desc_dpto into ls_departamento from departamento_estado d
      where d.cod_pais = rc_tra.cod_pais and d.cod_dpto = rc_tra.cod_dpto ;
  end if ;
    
  ls_banco_cnta   := as_cnta_banco ;
  ls_oficina_cnta := substr(rc_tra.nro_cnta_ahorro,1,4) ;
  ls_control_cnta := substr(rc_tra.nro_cnta_ahorro,5,2) ;
  ls_persona_cnta := substr(rc_tra.nro_cnta_ahorro,7,10) ;

  ls_importe := to_char(nvl(rc_tra.imp_soles,0),'9999999999.99') ;
  ls_importe := replace(ls_importe,'.','') ;
  ls_importe := lpad(ltrim(rtrim(ls_importe)),14,'0') ;

  ls_pago_descri := 'Pago de Haberes' ;
  
  if to_char(ad_fec_proceso,'mm') = '01' then
    ls_pago_descmes := 'Mes de '||'Enero' ;
  elsif to_char(ad_fec_proceso,'mm') = '02' then
    ls_pago_descmes := 'Mes de '||'Febrero' ;
  elsif to_char(ad_fec_proceso,'mm') = '03' then
    ls_pago_descmes := 'Mes de '||'Marzo' ;
  elsif to_char(ad_fec_proceso,'mm') = '04' then
    ls_pago_descmes := 'Mes de '||'Abril' ;
  elsif to_char(ad_fec_proceso,'mm') = '05' then
    ls_pago_descmes := 'Mes de '||'Mayo' ;
  elsif to_char(ad_fec_proceso,'mm') = '06' then
    ls_pago_descmes := 'Mes de '||'Junio' ;
  elsif to_char(ad_fec_proceso,'mm') = '07' then
    ls_pago_descmes := 'Mes de '||'Julio' ;
  elsif to_char(ad_fec_proceso,'mm') = '08' then
    ls_pago_descmes := 'Mes de '||'Agosto' ;
  elsif to_char(ad_fec_proceso,'mm') = '09' then
    ls_pago_descmes := 'Mes de '||'Setiembre' ;
  elsif to_char(ad_fec_proceso,'mm') = '10' then
    ls_pago_descmes := 'Mes de '||'Octubre' ;
  elsif to_char(ad_fec_proceso,'mm') = '11' then
    ls_pago_descmes := 'Mes de '||'Noviembre' ;
  elsif to_char(ad_fec_proceso,'mm') = '12' then
    ls_pago_descmes := 'Mes de '||'Diciembre' ;
  end if ;

  ls_cadena := ls_dni||ls_nombre||ls_direccion||ls_distrito||ls_provincia||
               ls_departamento||ls_banco_cnta||ls_oficina_cnta||ls_control_cnta||
               ls_persona_cnta||ls_importe||ls_pago_descri||ls_pago_descmes ;

  insert into tt_pago_bco_continental( cadena )
  values ( ls_cadena ) ;

end loop ;

end usp_rh_pago_rem_continental ;
/
