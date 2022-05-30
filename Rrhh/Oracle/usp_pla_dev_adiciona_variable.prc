create or replace procedure usp_pla_dev_adiciona_variable
  ( as_codtra       in maestro.cod_trabajador%type ,
    ad_fec_proceso  in rrhhparam.fec_proceso%type
  ) is

lk_dev_gra         constant char(3) := '005';
lk_dev_rem         constant char(3) := '006';
lk_dev_rac         constant char(3) := '007';
ls_concep          concepto.concep%type ;
ld_fec_proceso     calculo.fec_proceso%type ;
ln_imp_soles       calculo.imp_soles%type ;
ln_contador        integer ;
      
--  Concepto de gratificaciones
Cursor c_gratificacion is
  Select md.concep, md.fec_pago, md.importe
  from mov_devengado md
  where md.cod_trabajador = as_codtra 
        and md.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_gra ) ;

--  Concepto de remuneraciones
Cursor c_remuneracion is
  Select md.concep, md.fec_pago, md.importe
    from mov_devengado md
    where md.cod_trabajador = as_codtra 
          and md.concep in (
          Select rhpn.concep
            from rrhh_nivel rhpn
            where rhpn.cod_nivel = lk_dev_rem ) ;

--  Concepto de raciones de azucar
Cursor c_racion_azucar is
  Select md.concep, md.fec_pago, md.importe
    from mov_devengado md
    where md.cod_trabajador = as_codtra 
          and md.concep in (
          Select rhpn.concep
            from rrhh_nivel rhpn
            where rhpn.cod_nivel = lk_dev_rac ) ;

begin

For rc_gra in c_gratificacion Loop

Select md.concep, md.fec_pago, md.importe
  into ls_concep, ld_fec_proceso, ln_imp_soles
  from mov_devengado md
  where md.cod_trabajador = as_codtra 
        and md.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_gra ) ;

  ln_contador := 0 ;
  Select count(*)
    Into ln_contador
    from maestro_remun_gratif_dev grd
    where grd.cod_trabajador = as_codtra
        and grd.fec_calc_int = ld_fec_proceso
        and grd.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_gra ) ;
    
  If ln_contador > 0 then
      Update maestro_remun_gratif_dev
      Set Adel_pago = adel_pago + ln_imp_soles
      where cod_trabajador = as_codtra
        and fec_calc_int = ld_fec_proceso
        and concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_gra ) ;
  Else
    Insert into maestro_remun_gratif_dev (
      Cod_Trabajador, Fec_calc_int, Concep,      Flag_estado,
      Fec_pago,       Tipo_doc,     Nro_doc,     Fact_pago,
      Fact_emplear,   Capital,      Imp_int_gen, Imp_int_ant,
      Adel_pago,      Nvo_capital,  Nvo_interes, Int_pagado,
      Mont_pagado )
    Values (     
      as_codtra     , ad_fec_proceso, ls_concep,   '1',         
      ld_fec_proceso, ' ',            ' ',         0,        
      0,              0,              0,           0,          
      ln_imp_soles,   0,              0,           0,         
      0               ) ;
  End if ;
  
  End Loop ;
      
For rc_rem in c_remuneracion Loop

Select md.concep, md.fec_pago, md.importe
  into ls_concep, ld_fec_proceso, ln_imp_soles
  from mov_devengado md
  where md.cod_trabajador = as_codtra 
        and md.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_rem ) ;

  ln_contador := 0 ;
  Select count(*)
    Into ln_contador
    from maestro_remun_gratif_dev grd
    where grd.cod_trabajador = as_codtra
        and grd.fec_calc_int = ld_fec_proceso
        and grd.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_rem ) ;
    
  If ln_contador > 0 then
      Update maestro_remun_gratif_dev
      Set Adel_pago = adel_pago + ln_imp_soles
      where cod_trabajador = as_codtra
        and fec_calc_int = ld_fec_proceso
        and concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_rem ) ;
  Else
    Insert into maestro_remun_gratif_dev (
      Cod_Trabajador, Fec_calc_int, Concep,      Flag_estado,
      Fec_pago,       Tipo_doc,     Nro_doc,     Fact_pago,
      Fact_emplear,   Capital,      Imp_int_gen, Imp_int_ant,
      Adel_pago,      Nvo_capital,  Nvo_interes, Int_pagado,
      Mont_pagado )
    Values (     
      as_codtra     , ad_fec_proceso, ls_concep,   '1',         
      ld_fec_proceso, ' ',            ' ',         0,        
      0,              0,              0,           0,          
      ln_imp_soles,   0,              0,           0,         
      0               ) ;
  End if ;
  
  End Loop ;
      
For rc_rac in c_racion_azucar Loop

Select md.concep, md.fec_pago, md.importe
  into ls_concep, ld_fec_proceso, ln_imp_soles
  from mov_devengado md
  where md.cod_trabajador = as_codtra 
        and md.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_rac ) ;

  ln_contador := 0 ;
  Select count(*)
    Into ln_contador
    from mov_devengado md
    where md.cod_trabajador = as_codtra
        and md.fec_pago     = ld_fec_proceso
        and md.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_rac ) ;
    
  If ln_contador > 0 then
      Update racion_azucar_deveng
      Set Imp_pag_mes = imp_pag_mes + ln_imp_soles
      where cod_trabajador = as_codtra
            and fec_proceso = ld_fec_proceso ;
  Else
    Insert into racion_azucar_deveng (
      Cod_Trabajador, Fec_proceso   , Imp_pag_mes )
    Values (     
      as_codtra     , ad_fec_proceso, ln_imp_soles ) ;         
  End if ;
  
  End Loop ;
      
End usp_pla_dev_adiciona_variable ;
/
