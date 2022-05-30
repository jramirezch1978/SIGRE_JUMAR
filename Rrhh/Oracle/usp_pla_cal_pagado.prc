create or replace procedure usp_pla_cal_pagado
   (as_codtra      in maestro.cod_trabajador%type,
    ad_fec_proceso in calculo.fec_proceso%type
   ) is

lk_gan_tot         constant char(3) := '100';
lk_des_tot         constant char(3) := '200';
lk_pag_tot         constant char(3) := '210';
ls_concep_gan      concepto.concep%type;
ls_concep_des      concepto.concep%type;
ls_concep_tot      concepto.concep%type;
ln_imp_soles_gan   calculo.imp_soles%type;
ln_imp_soles_des   calculo.imp_soles%type;
ln_imp_dolar_gan   calculo.imp_soles%type;
ln_imp_dolar_des   calculo.imp_soles%type;
ln_imp_soles       calculo.imp_soles%type;
ln_imp_dolar       calculo.imp_soles%type;

begin

--  Halla conceptos para ganancias, descuentos y pagos
Select rhpn.concep
  into ls_concep_gan
  from rrhh_nivel rhpn
  where rhpn.cod_nivel = lk_gan_tot ;
           
Select rhpn.concep
  into ls_concep_des
  from rrhh_nivel rhpn
  where rhpn.cod_nivel = lk_des_tot ;
           
Select rhpn.concep
  into ls_concep_tot
  from rrhh_nivel rhpn
  where rhpn.cod_nivel = lk_pag_tot ;

--  Halla importes del total ganando
Select sum( c.imp_soles )
  into ln_imp_soles_gan
  from calculo c
  where c.cod_trabajador = as_codtra
  and c.concep = ls_concep_gan ;
ln_imp_soles_gan := nvl( ln_imp_soles_gan, 0 ) ;

Select sum( c.imp_dolar )
  into ln_imp_dolar_gan
  from calculo c
  where c.cod_trabajador = as_codtra
        and c.concep = ls_concep_gan ;
ln_imp_dolar_gan := nvl( ln_imp_dolar_gan, 0 ) ;

--  Halla importes del total descuentos
Select sum( c.imp_soles )
  into ln_imp_soles_des
  from calculo c
  where c.cod_trabajador = as_codtra
        and c.concep = ls_concep_des ;
ln_imp_soles_des := nvl( ln_imp_soles_des, 0 ) ;

Select sum( c.imp_dolar )
  into ln_imp_dolar_des
  from calculo c
  where c.cod_trabajador = as_codtra
        and c.concep = ls_concep_des ;
ln_imp_dolar_des := nvl( ln_imp_dolar_des, 0 ) ;

ln_imp_soles := 0 ;
ln_imp_dolar := 0 ;
ln_imp_soles := ln_imp_soles_gan - ln_imp_soles_des ;
ln_imp_dolar := ln_imp_dolar_gan - ln_imp_dolar_des ;

  Insert into Calculo ( Cod_Trabajador, 
    Concep,               Fec_Proceso, 
    Horas_Trabaj,         Horas_Pag, Dias_Trabaj, 
    Imp_Soles,            Imp_Dolar, Flag_t_Snp, 
    Flag_t_Quinta,        Flag_t_Judicial, 
    Flag_t_Afp,           Flag_t_Bonif_30, 
    Flag_t_Bonif_25,      Flag_t_Gratif, 
    Flag_t_Cts,           Flag_t_Vacacio, 
    Flag_t_Bonif_Vacacio, Flag_t_Pago_Quincena, 
    Flag_t_Quinquenio,    Flag_e_Essalud, 
    Flag_e_Ies,           Flag_e_Senati, 
    Flag_e_Sctr_Ipss,     Flag_e_Sctr_Onp )
  Values ( as_codtra, 
    ls_concep_tot, ad_fec_proceso,
    0            , 0             , 0, 
    ln_imp_soles , ln_imp_dolar  , ' ', 
    ' '          , ' '           , 
    ' '          , ' '           , 
    ' '          , ' '           , 
    ' '          , ' '           , 
    ' '          , ' '           , 
    ' '          , ' '           , 
    ' '          , ' '           , 
    ' '          , ' '           ) ; 
      
End usp_pla_cal_pagado ;
/
