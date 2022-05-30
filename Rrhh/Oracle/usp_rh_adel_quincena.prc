create or replace procedure usp_rh_adel_quincena (
  asi_codtra       in maestro.cod_trabajador%TYPE,
  adi_fec_proceso  in date 
) is

ls_cncp_quincena     rrhhparquin.cncp_quincena%TYPE;
ln_valor_adelanto    number(7,2) ;
ln_imp_redondeo      number(7,2) ;
ls_flag_judicial     rrhhparquin.flag_judicial%TYPE;
ls_flag_cnta_ahorro  rrhhparquin.flag_cnta_ahorro%TYPE;
ls_flag_diferido     rrhhparquin.flag_diferido%TYPE;
ls_flag_vacaciones   rrhhparquin.flag_vacaciones%TYPE;
ls_cncp_vacaciones   rrhhparquin.cncp_vacaciones%TYPE;
ln_dias_vacaciones   number(2) ;
ls_flag_dscto_fijo   rrhhparquin.flag_dscto_fijo%TYPE;
ln_porc_neto_qui     rrhhparquin.porc_ad_dsc_imp_nt%TYPE;

ls_grp_quincena      rrhhparam_cconcep.adelanto_quincena%TYPE;
ln_quincena          adelanto_quincena.imp_adelanto%TYPE ;
ln_count             number;
ln_tipo_cambio       calendario.vta_dol_prom%TYPE;
ln_nro_dias          number(5,2) ;
ls_grp_dscto_fijo    rrhhparam.grc_gnn_fija%TYPE ;
ln_porc_maestro      maestro.porc_adel_quincena%TYPE;
ld_fec_proceso       adelanto_quincena.fec_proceso%TYPE;

-- DAtos del trabajador
ld_fec_ingreso       maestro.fec_ingreso%TYPE;
ld_fec_cese          maestro.fec_ingreso%TYPE;

begin

--  ******************************************************************
--  ***   REALIZA CALCULO DEL ADELANTO DE QUINCENA AL TRABAJADOR   ***
--  ***   SIEMPRE SERÁ UN PORCENTAJE DEL BRUTO                     ***
--  ******************************************************************
-- Verifico primero si ya existe un adelanto de quincena ya procesado
select count(*)
  into ln_count
  from adelanto_quincena aq,
       maestro           m
 where aq.cod_trabajador = asi_codtra
   and to_char(aq.fec_proceso, 'mmyyyy') = to_char(adi_fec_proceso, 'mmyyyy');

if ln_count > 0 then
   select max(aq.fec_proceso)
     into ld_fec_proceso
     from adelanto_quincena aq,
          maestro           m
    where aq.cod_trabajador = asi_codtra
      and to_char(aq.fec_proceso, 'mmyyyy') = to_char(adi_fec_proceso, 'mmyyyy');
      
   ROLLBACK;
   RAISE_APPLICATION_ERROR(-20000, 'El trabajador ' || asi_codtra || ' ya tiene procesado el adelanto de quincena para el periodo ' || to_char(adi_fec_proceso, 'mm/yyyy') 
                                || '. La fecha de proceso de este calculo es ' || to_char(ld_fec_proceso, 'dd/mm/yyyy') || ', por favor verifiquen!') ;
end if;
 
select c.adelanto_quincena
  into ls_grp_quincena
  from rrhhparam_cconcep c
 where c.reckey = '1' ;

select p.grc_dsc_fijo
  into ls_grp_dscto_fijo
  from rrhhparam p
 where p.reckey = '1' ;

--  Determina el tipo de cambio para descuento de cta. cte. en dolares
ln_tipo_cambio := 0 ;
select count(*)
  into ln_count
  from calendario c
 where trunc(c.fecha) = trunc(sysdate) ;

if ln_count > 0 then
  select nvl(c.vta_dol_prom,0)
    into ln_tipo_cambio
    from calendario c
   where trunc(c.fecha) = trunc(sysdate) ;
else
  raise_application_error( -20000, 'Tipo de cambio al '||to_char(sysdate,'dd/mm/yyyy') ||
                                   ' no existe. Coordine con Contabilidad por favor') ;
end if ;

--  Determina parametros para control de calculo de quincena
select p.cncp_quincena, p.monto_adelanto, p.imp_redondeo,
       p.flag_judicial, p.flag_cnta_ahorro, p.flag_diferido, p.flag_vacaciones,
       p.cncp_vacaciones, p.dias_vacaciones, p.flag_dscto_fijo, p.porc_ad_dsc_imp_nt
  into ls_cncp_quincena, ln_valor_adelanto, ln_imp_redondeo,
       ls_flag_judicial, ls_flag_cnta_ahorro, ls_flag_diferido, ls_flag_vacaciones,
       ls_cncp_vacaciones, ln_dias_vacaciones, ls_flag_dscto_fijo, ln_porc_neto_qui
  from rrhhparquin p
  where p.reckey = '1' ;

--  Identifica datos del maestro para control de pago quincenal
select m.fec_ingreso, m.fec_cese, nvl(m.porc_adel_quincena, 0)
  into ld_fec_ingreso, ld_fec_cese, ln_porc_maestro
  from maestro m
 where m.cod_trabajador = asi_codtra ;

-- Valido si la fecha de ingreso es mayor a la quincena, de lo contrario no le tengo porque adelantar su quincena
if ld_fec_ingreso is null then
   RAISE_APPLICATION_ERROR(-20000, 'Trabajador ' || asi_codtra || ' no tiene fecha de ingreso resgistrado por favor verifique!.');
end if;

if ld_fec_ingreso > to_date('15/' || to_char(adi_fec_proceso, 'mm/yyyy'), 'dd/mm/yyyy') then
   return;
end if;

-- Si la fecha de cese es menor a la fecha de adelanto de quincena entonces tampoco lo considero
if ld_fec_cese is not null and ld_fec_cese < to_date('15/' || to_char(adi_fec_proceso, 'mm/yyyy'), 'dd/mm/yyyy') then
   return;
end if;

--
--  ***   REALIZA PAGO DE QUINCENA SEGUN CONDICIONES
--
select sum(importe)
  into ln_quincena
  from (  
       select NVL(sum(nvl(g.imp_gan_desc,0)),0) as importe
         from gan_desct_fijo g
        where g.cod_trabajador = asi_codtra
          and nvl(g.flag_estado,'0') = '1'
          AND g.concep in ( select d.concepto_calc
                              from grupo_calculo_det d
                             where d.grupo_calculo = ls_grp_quincena )
       union
       select NVL(sum(nvl(gv.imp_var,0)),0) as importe
         from gan_desct_variable gv
        where gv.cod_trabajador = asi_codtra
          AND gv.concep in ( select d.concepto_calc
                               from grupo_calculo_det d
                              where d.grupo_calculo = ls_grp_quincena ) );
                                
if ln_porc_maestro = 0 then
   ln_quincena := ln_quincena * nvl(ln_valor_adelanto,0) / 100 ;
else
   ln_quincena := ln_quincena * ln_porc_maestro / 100 ;
end if;

--  Verifica si el trabajador ha estado de vacaciones en el mes anterior
if nvl(ls_flag_vacaciones,'0') = '1' then
   ln_nro_dias := 0 ;
   select count(*)
     into ln_count
     from historico_calculo hc
    where hc.cod_trabajador = asi_codtra
      and hc.concep = ls_cncp_vacaciones
      AND to_char(hc.fec_calc_plan,'mm/yyyy') = to_char(add_months(adi_fec_proceso,-1),'mm/yyyy') ;

   if ln_count > 0 then
      select nvl(hc.dias_trabaj,0)
        into ln_nro_dias
        from historico_calculo hc
       where hc.cod_trabajador = asi_codtra
         and hc.concep = ls_cncp_vacaciones
         AND to_char(hc.fec_calc_plan,'mm/yyyy') = to_char(add_months(adi_fec_proceso,-1),'mm/yyyy') ;

      if nvl(ln_nro_dias,0) > nvl(ln_dias_vacaciones,0) then
         ln_quincena := 0 ;
      end if ;
   end if ;
end if ;


if nvl(ln_quincena,0) <> 0 then
  insert into adelanto_quincena (
    cod_trabajador, concep, fec_proceso, imp_adelanto,flag_replicacion )
  values (
    asi_codtra, ls_cncp_quincena, adi_fec_proceso, ln_quincena, '1' ) ;
  
end if ;

end usp_rh_adel_quincena ;
/
