create or replace procedure usp_pla_dev_adiciona
   (as_codtra       in maestro.cod_trabajador%type ,
    ad_fec_proceso  in rrhhparam.fec_proceso%type
   ) is

lk_dev_gra         constant char(3) := '005';
lk_dev_rem         constant char(3) := '006';
lk_dev_rac         constant char(3) := '007';
ls_concep          concepto.concep%type ;
ld_fec_proceso     calculo.fec_proceso%type ;
ln_imp_soles       calculo.imp_soles%type ;
      
--  Concepto de gratificaciones
Cursor c_gratificacion is
  Select c.concep, c.fec_proceso, c.imp_soles
  from calculo c
  where c.cod_trabajador = as_codtra 
        and c.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_gra ) ;

--  Concepto de remuneraciones
Cursor c_remuneracion is
  Select c.concep, c.fec_proceso, c.imp_soles
    from calculo c
    where c.cod_trabajador = as_codtra 
          and c.concep in (
          Select rhpn.concep
            from rrhh_nivel rhpn
            where rhpn.cod_nivel = lk_dev_rem ) ;

--  Concepto de raciones de azucar
Cursor c_racion_azucar is
  Select c.concep, c.fec_proceso, c.imp_soles
    from calculo c
    where c.cod_trabajador = as_codtra 
          and c.concep in (
          Select rhpn.concep
            from rrhh_nivel rhpn
            where rhpn.cod_nivel = lk_dev_rac ) ;

begin

For rc_gra in c_gratificacion Loop

Select c.concep, c.fec_proceso, c.imp_soles
  into ls_concep, ld_fec_proceso, ln_imp_soles
  from calculo c
  where c.cod_trabajador = as_codtra 
        and c.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_gra ) ;

    Insert into maestro_remun_gratif_dev (
      Cod_Trabajador, Fec_calc_int, Concep,      Flag_estado,
      Fec_pago,       Tipo_doc,     Nro_doc,     Fact_pago,
      Fact_emplear,   Capital,      Imp_int_gen, Imp_int_ant,
      Adel_pago,      Nvo_capital,  Nvo_interes, Int_pagado,
      Mont_pagado )
    Values (     
      as_codtra     , ad_fec_proceso, ls_concep,   '1',         
      ld_fec_proceso, 'auto',         ' ',         0,        
      0,              0,              0,           0,          
      ln_imp_soles,   0,              0,           0,         
      0               ) ;
  End Loop ;
      
For rc_rem in c_remuneracion Loop

Select c.concep, c.fec_proceso, c.imp_soles
  into ls_concep, ld_fec_proceso, ln_imp_soles
  from calculo c
  where c.cod_trabajador = as_codtra 
        and c.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_rem ) ;

    Insert into maestro_remun_gratif_dev (
      Cod_Trabajador, Fec_calc_int, Concep,      Flag_estado,
      Fec_pago,       Tipo_doc,     Nro_doc,     Fact_pago,
      Fact_emplear,   Capital,      Imp_int_gen, Imp_int_ant,
      Adel_pago,      Nvo_capital,  Nvo_interes, Int_pagado,
      Mont_pagado )
    Values (     
      as_codtra     , ad_fec_proceso, ls_concep,   '1',         
      ld_fec_proceso, 'auto',         ' ',         0,        
      0,              0,              0,           0,          
      ln_imp_soles,   0,              0,           0,         
      0               ) ;
  End Loop ;
      
For rc_rac in c_racion_azucar Loop

Select c.concep, c.fec_proceso, c.imp_soles
  into ls_concep, ld_fec_proceso, ln_imp_soles
  from calculo c
  where c.cod_trabajador = as_codtra 
        and c.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_rac ) ;

    Insert into racion_azucar_deveng (
      Cod_Trabajador, Fec_proceso   , Imp_pag_mes )
    Values (     
      as_codtra     , ad_fec_proceso, ln_imp_soles ) ;         
  End Loop ;
      
End usp_pla_dev_adiciona ;
/
