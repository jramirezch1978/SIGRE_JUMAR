create or replace procedure usp_pla_cal_tardanzas (
  as_codtra       in maestro.cod_trabajador%type, 
  ad_fec_proceso  in rrhhparam.fec_proceso%type ) is
   
ln_imp_tardanza   number(9,6) ;
ln_importe        number(11,2) ;
ln_imported       number(11,2) ;
ln_imp_acum       number(11,2) ;
ln_tardanza       number(11,2) ;
ln_min_tardanza   number(11,2) ;
ln_valor_minuto   number(9,6) ;
ld_fec_desde      date ;
ld_fec_hasta      date ;
ln_contador       number(15) ;
ln_tipcam         number(11,2) ;
ls_bonificacion   maestro.bonif_fija_30_25%type ;

--  Cursor que acumula minutos de inasistencias
Cursor c_inasistencia is
  Select i.dias_inasist
  from inasistencia i
  where i.cod_trabajador = as_codtra and
        i.concep = '2405' and
        i.fec_movim between ld_fec_desde and ld_fec_hasta ;
          
begin

Select rh.fec_desde, rh.fec_hasta
  into ld_fec_desde, ld_fec_hasta
  from rrhhparam rh
  where rh.reckey = '1' ;
  
--  Tipo de cambio del dia
Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_tipcam := nvl(ln_tipcam, 1) ;

ln_min_tardanza := 0 ;
For rc_ina in c_inasistencia Loop
  ln_tardanza     := rc_ina.dias_inasist ;
  ln_tardanza     := nvl(ln_tardanza,0) ;
  ln_tardanza     := ln_tardanza * 100 ;
  ln_min_tardanza := ln_min_tardanza + ln_tardanza ;
End loop ;
ln_min_tardanza := nvl(ln_min_tardanza,0) ;

If ln_min_tardanza > 0 then

  --  Acumula ganancias fijas
  ln_imp_acum := 0 ;
  Select sum(gdf.imp_gan_desc)
    into ln_imp_acum
    from gan_desct_fijo gdf
    where gdf.cod_trabajador = as_codtra and
          gdf.flag_estado = '1' and
          gdf.flag_trabaj = '1' and
          substr(gdf.concep,1,2) = '10' ;
  ln_imp_acum := nvl(ln_imp_acum,0) ;
  
  Select m.bonif_fija_30_25
    into ls_bonificacion
    from maestro m
    where m.cod_trabajador = as_codtra and
          m.flag_estado = '1' ;
    ls_bonificacion := nvl( ls_bonificacion, ' ' ) ;

  If ls_bonificacion = '1' then
    ln_imp_acum := ln_imp_acum * 1.30 ;
  Elsif ls_bonificacion = '2' then
    ln_imp_acum :=  ln_imp_acum * 1.25 ;
  End if ;

  --  Calcula importe por tardanzas
  ln_valor_minuto := 0 ; ln_importe := 0 ;
  ln_valor_minuto := (ln_imp_acum / 240) / 60 ;
  ln_imp_tardanza := ln_valor_minuto * ln_min_tardanza ;  
  ln_importe      := round(ln_imp_tardanza,2) ;
  ln_imported     := ln_importe / ln_tipcam ;
  
  If ln_importe > 0 then

    ln_contador := 0 ;
    Select count(*)
      into ln_contador
      from calculo c
      where c.cod_trabajador = as_codtra and
            c.concep = '2313' ;

    ln_contador := nvl(ln_contador,0) ;
    If ln_contador > 0 then
      Update calculo
      Set imp_soles = imp_soles + ln_importe ,
          imp_dolar = imp_dolar + ln_imported
      where cod_trabajador = as_codtra and
            concep = '2313' ;
    Else
    --  Inserta registros para descontar tardanzas
      Insert into Calculo ( Cod_Trabajador, 
        Concep,          Fec_Proceso, 
        Horas_Trabaj,    Horas_Pag, Dias_Trabaj, 
        Imp_Soles,       Imp_Dolar, Flag_t_Snp, 
        Flag_t_Quinta,        Flag_t_Judicial, 
        Flag_t_Afp,           Flag_t_Bonif_30, 
        Flag_t_Bonif_25,      Flag_t_Gratif, 
        Flag_t_Cts,           Flag_t_Vacacio, 
        Flag_t_Bonif_Vacacio, Flag_t_Pago_Quincena, 
        Flag_t_Quinquenio,    Flag_e_Essalud, 
        Flag_e_Ies,           Flag_e_Senati, 
        Flag_e_Sctr_Ipss,     Flag_e_Sctr_Onp )
      Values ( as_codtra, 
        '2313', ad_fec_proceso,
        0     ,     0,     0, 
        ln_importe,    ln_imported,  ' ', 
        ' '      , ' '  , 
        ' '      , ' '  , 
        ' '      , ' '  , 
        ' '      , ' '  , 
        ' '      , ' '  , 
        ' '      , ' '  , 
        ' '      , ' '  , 
        ' '      ,  ' ' ) ;
    End if ;         
  End if ;

End if ;
      
End usp_pla_cal_tardanzas ;
/
