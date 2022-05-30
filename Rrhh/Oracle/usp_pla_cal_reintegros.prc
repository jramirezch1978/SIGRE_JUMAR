create or replace procedure usp_pla_cal_reintegros (
   as_codtra        in maestro.cod_trabajador%type, 
   ad_fec_proceso   in rrhhparam.fec_proceso%type ) is
    
ld_fec_desde        rrhhparam.fec_desde%type ;
ld_fec_hasta        rrhhparam.fec_hasta%type ;
ln_tipcam           calendario.cmp_dol_prom%type ;
ln_dias_reint       inasistencia.dias_inasist%type ;
ln_contador         number(15) ;
ls_bonificacion     maestro.bonif_fija_30_25%type ;
ln_ganancias        gan_desct_fijo.imp_gan_desc%type ;
ln_importe          calculo.imp_soles%type ;
ln_importe_3025     calculo.imp_soles%type ;
ln_imported         calculo.imp_soles%type ;
ln_importe_3025d    calculo.imp_soles%type ;
ls_concepto         concepto.concep%type ;

ls_snp       char(1) ;  ls_quinta    char(1) ;
ls_judicial  char(1) ;  ls_afp       char(1) ;
ls_bonif30   char(1) ;  ls_bonif25   char(1) ;
ls_gratif    char(1) ;  ls_cts       char(1) ;
ls_vacacion  char(1) ;  ls_bonif     char(1) ;
ls_quincena  char(1) ;  ls_quinque   char(1) ;
ls_essalud   char(1) ;  ls_agrario   char(1) ;
ls_vida      char(1) ;  ls_ies       char(1) ;
ls_senati    char(1) ;  ls_sctripss  char(1) ;
ls_sctronp   char(1) ;

begin
   
Select rh.fec_desde, rh.fec_hasta
  into ld_fec_desde, ld_fec_hasta
  from rrhhparam rh
  where rh.reckey = '1' ;

Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_tipcam := nvl(ln_tipcam,1) ;
  
ln_contador := 0 ;
Select count(*)
  into ln_contador
  from inasistencia i
  where (i.cod_trabajador = as_codtra and
        i.concep = '1426' and
        i.fec_movim between ld_fec_desde and ld_fec_hasta) or
        (i.cod_trabajador = as_codtra and
        i.concep = '1436' and
        i.fec_movim between ld_fec_desde and ld_fec_hasta) ;
ln_contador := nvl(ln_contador,0) ;
        
--  Pago por reintegro de dias
if ln_contador > 0 then

  ln_dias_reint := 0 ;
  Select sum(i.dias_inasist), max(i.concep)
    into ln_dias_reint, ls_concepto
    from inasistencia i
    where (i.cod_trabajador = as_codtra and
          i.concep = '1426' and
          i.fec_movim between ld_fec_desde and ld_fec_hasta) or
          (i.cod_trabajador = as_codtra and
          i.concep = '1436' and
          i.fec_movim between ld_fec_desde and ld_fec_hasta) ;
  ln_dias_reint := nvl(ln_dias_reint,0) ;
  
  Select m.bonif_fija_30_25
    into ls_bonificacion
    from maestro m
    where m.cod_trabajador = as_codtra ;
  ls_bonificacion := nvl(ls_bonificacion,' ') ;
  
  ln_ganancias := 0 ;
  Select sum(gdf.imp_gan_desc)
    into ln_ganancias
    from gan_desct_fijo gdf
    where gdf.cod_trabajador = as_codtra and
          gdf.flag_estado = '1' and
          gdf.flag_trabaj = '1' and
          substr(gdf.concep,1,2) = '10' and
          gdf.concep <> '1013' ;
  ln_ganancias := nvl(ln_ganancias,0) ;
  
  ln_importe  := 0 ; ln_importe_3025  := 0 ;
  ln_imported := 0 ; ln_importe_3025d := 0 ;
  ln_importe  := (ln_ganancias / 30) * ln_dias_reint ;
  ln_imported := ln_importe / ln_tipcam ;
  
  if ls_bonificacion = '1' then
    ln_importe_3025 := ln_importe * 0.30 ;
  elsif ls_bonificacion = '2' then
    ln_importe_3025 := ln_importe * 0.25 ;
  end if ;
  ln_importe_3025d := ln_importe_3025 / ln_tipcam ;
  
  Select c.flag_t_snp, c.flag_t_quinta, c.flag_t_judicial,
         c.flag_t_afp, c.flag_t_bonif_30, c.flag_t_bonif_25,
         c.flag_t_gratif, c.flag_t_cts, c.flag_t_vacacio, 
         c.flag_t_bonif_vacacio, c.flag_t_pago_quincena, c.flag_t_quinquenio, 
         c.flag_e_essalud, c.flag_e_agrario, c.flag_e_essalud_vida,
         c.flag_e_ies, c.flag_e_senati, c.flag_e_sctr_ipss, 
         c.flag_e_sctr_onp
    into ls_snp, ls_quinta, ls_judicial,
         ls_afp, ls_bonif30, ls_bonif25,
         ls_gratif, ls_cts, ls_vacacion,
         ls_bonif, ls_quincena, ls_quinque,
         ls_essalud, ls_agrario, ls_vida,
         ls_ies, ls_senati, ls_sctripss,
         ls_sctronp
    from concepto c
    where c.concep = ls_concepto ;

  insert into calculo ( 
    cod_trabajador, concep, fec_proceso, 
    horas_trabaj, horas_pag, dias_trabaj, 
    imp_soles, imp_dolar, flag_t_snp, 
    flag_t_quinta, flag_t_judicial, flag_t_afp,
    flag_t_bonif_30, flag_t_bonif_25, flag_t_gratif,
    flag_t_cts, flag_t_vacacio, flag_t_bonif_vacacio,
    flag_t_pago_quincena, flag_t_quinquenio, flag_e_essalud,
    flag_e_agrario, flag_e_essalud_vida, flag_e_ies,
    flag_e_senati, flag_e_sctr_ipss, flag_e_sctr_onp )
  Values ( 
    as_codtra, ls_concepto, ad_fec_proceso,
    0, 0, ln_dias_reint, 
    ln_importe, ln_imported, ls_snp,
    ls_quinta, ls_judicial, ls_afp,
    ls_bonif30, ls_bonif25, ls_gratif,
    ls_cts, ls_vacacion, ls_bonif,
    ls_quincena, ls_quinque, ls_essalud,
    ls_agrario, ls_vida, ls_ies,
    ls_senati, ls_sctripss, ls_sctronp ) ;
      
  if ln_importe_3025 > 0 then
  
    Select c.flag_t_snp, c.flag_t_quinta, c.flag_t_judicial,
           c.flag_t_afp, c.flag_t_bonif_30, c.flag_t_bonif_25,
           c.flag_t_gratif, c.flag_t_cts, c.flag_t_vacacio, 
           c.flag_t_bonif_vacacio, c.flag_t_pago_quincena, c.flag_t_quinquenio, 
           c.flag_e_essalud, c.flag_e_agrario, c.flag_e_essalud_vida,
           c.flag_e_ies, c.flag_e_senati, c.flag_e_sctr_ipss, 
           c.flag_e_sctr_onp
      into ls_snp, ls_quinta, ls_judicial,
           ls_afp, ls_bonif30, ls_bonif25,
           ls_gratif, ls_cts, ls_vacacion,
           ls_bonif, ls_quincena, ls_quinque,
           ls_essalud, ls_agrario, ls_vida,
           ls_ies, ls_senati, ls_sctripss,
           ls_sctronp
      from concepto c
      where c.concep = '1427' ;

    insert into calculo ( 
      cod_trabajador, concep, fec_proceso, 
      horas_trabaj, horas_pag, dias_trabaj, 
      imp_soles, imp_dolar, flag_t_snp, 
      flag_t_quinta, flag_t_judicial, flag_t_afp,
      flag_t_bonif_30, flag_t_bonif_25, flag_t_gratif,
      flag_t_cts, flag_t_vacacio, flag_t_bonif_vacacio,
      flag_t_pago_quincena, flag_t_quinquenio, flag_e_essalud,
      flag_e_agrario, flag_e_essalud_vida, flag_e_ies,
      flag_e_senati, flag_e_sctr_ipss, flag_e_sctr_onp )
    Values ( 
      as_codtra, '1427', ad_fec_proceso,
      0, 0, ln_dias_reint, 
      ln_importe_3025, ln_importe_3025d, ls_snp,
      ls_quinta, ls_judicial, ls_afp,
      ls_bonif30, ls_bonif25, ls_gratif,
      ls_cts, ls_vacacion, ls_bonif,
      ls_quincena, ls_quinque, ls_essalud,
      ls_agrario, ls_vida, ls_ies,
      ls_senati, ls_sctripss, ls_sctronp ) ;

  end if ;

end if ;
     
ln_contador := 0 ;
Select count(*)
  into ln_contador
  from inasistencia i
  where i.cod_trabajador = as_codtra and
        i.concep = '1428' and
        i.fec_movim between ld_fec_desde and ld_fec_hasta ;
ln_contador := nvl(ln_contador,0) ;
        
--  Pago por reintegro patronal
if ln_contador > 0 then

  ln_dias_reint := 0 ;
  Select sum(i.dias_inasist)
    into ln_dias_reint
    from inasistencia i
    where i.cod_trabajador = as_codtra and
          i.concep = '1428' and
          i.fec_movim between ld_fec_desde and ld_fec_hasta ;
  ln_dias_reint := nvl(ln_dias_reint,0) ;
  
  Select m.bonif_fija_30_25
    into ls_bonificacion
    from maestro m
    where m.cod_trabajador = as_codtra ;
  ls_bonificacion := nvl(ls_bonificacion,' ') ;
  
  ln_ganancias := 0 ;
  Select sum(gdf.imp_gan_desc)
    into ln_ganancias
    from gan_desct_fijo gdf
    where gdf.cod_trabajador = as_codtra and
          gdf.flag_estado = '1' and
          gdf.flag_trabaj = '1' and
          substr(gdf.concep,1,2) = '10' ;
  ln_ganancias := nvl(ln_ganancias,0) ;
  
  ln_importe  := 0 ; ln_importe_3025  := 0 ;
  ln_imported := 0 ; ln_importe_3025d := 0 ;
  ln_importe  := (ln_ganancias / 30) * ln_dias_reint ;
  ln_imported := ln_importe / ln_tipcam ;
  
  if ls_bonificacion = '1' then
    ln_importe_3025 := ln_importe * 0.30 ;
  elsif ls_bonificacion = '2' then
    ln_importe_3025 := ln_importe * 0.25 ;
  end if ;
  ln_importe_3025d := ln_importe_3025 / ln_tipcam ;
  
  Select c.flag_t_snp, c.flag_t_quinta, c.flag_t_judicial,
         c.flag_t_afp, c.flag_t_bonif_30, c.flag_t_bonif_25,
         c.flag_t_gratif, c.flag_t_cts, c.flag_t_vacacio, 
         c.flag_t_bonif_vacacio, c.flag_t_pago_quincena, c.flag_t_quinquenio, 
         c.flag_e_essalud, c.flag_e_agrario, c.flag_e_essalud_vida,
         c.flag_e_ies, c.flag_e_senati, c.flag_e_sctr_ipss, 
         c.flag_e_sctr_onp
    into ls_snp, ls_quinta, ls_judicial,
         ls_afp, ls_bonif30, ls_bonif25,
         ls_gratif, ls_cts, ls_vacacion,
         ls_bonif, ls_quincena, ls_quinque,
         ls_essalud, ls_agrario, ls_vida,
         ls_ies, ls_senati, ls_sctripss,
         ls_sctronp
    from concepto c
    where c.concep = '1428' ;

  insert into calculo ( 
    cod_trabajador, concep, fec_proceso, 
    horas_trabaj, horas_pag, dias_trabaj, 
    imp_soles, imp_dolar, flag_t_snp, 
    flag_t_quinta, flag_t_judicial, flag_t_afp,
    flag_t_bonif_30, flag_t_bonif_25, flag_t_gratif,
    flag_t_cts, flag_t_vacacio, flag_t_bonif_vacacio,
    flag_t_pago_quincena, flag_t_quinquenio, flag_e_essalud,
    flag_e_agrario, flag_e_essalud_vida, flag_e_ies,
    flag_e_senati, flag_e_sctr_ipss, flag_e_sctr_onp )
  Values ( 
    as_codtra, '1428', ad_fec_proceso,
    0, 0, ln_dias_reint, 
    ln_importe, ln_imported, ls_snp,
    ls_quinta, ls_judicial, ls_afp,
    ls_bonif30, ls_bonif25, ls_gratif,
    ls_cts, ls_vacacion, ls_bonif,
    ls_quincena, ls_quinque, ls_essalud,
    ls_agrario, ls_vida, ls_ies,
    ls_senati, ls_sctripss, ls_sctronp ) ;
      
  if ln_importe_3025 > 0 then
  
    Select c.flag_t_snp, c.flag_t_quinta, c.flag_t_judicial,
           c.flag_t_afp, c.flag_t_bonif_30, c.flag_t_bonif_25,
           c.flag_t_gratif, c.flag_t_cts, c.flag_t_vacacio, 
           c.flag_t_bonif_vacacio, c.flag_t_pago_quincena, c.flag_t_quinquenio, 
           c.flag_e_essalud, c.flag_e_agrario, c.flag_e_essalud_vida,
           c.flag_e_ies, c.flag_e_senati, c.flag_e_sctr_ipss, 
           c.flag_e_sctr_onp
      into ls_snp, ls_quinta, ls_judicial,
           ls_afp, ls_bonif30, ls_bonif25,
           ls_gratif, ls_cts, ls_vacacion,
           ls_bonif, ls_quincena, ls_quinque,
           ls_essalud, ls_agrario, ls_vida,
           ls_ies, ls_senati, ls_sctripss,
           ls_sctronp
      from concepto c
      where c.concep = '1429' ;

    insert into calculo ( 
      cod_trabajador, concep, fec_proceso, 
      horas_trabaj, horas_pag, dias_trabaj, 
      imp_soles, imp_dolar, flag_t_snp, 
      flag_t_quinta, flag_t_judicial, flag_t_afp,
      flag_t_bonif_30, flag_t_bonif_25, flag_t_gratif,
      flag_t_cts, flag_t_vacacio, flag_t_bonif_vacacio,
      flag_t_pago_quincena, flag_t_quinquenio, flag_e_essalud,
      flag_e_agrario, flag_e_essalud_vida, flag_e_ies,
      flag_e_senati, flag_e_sctr_ipss, flag_e_sctr_onp )
    Values ( 
      as_codtra, '1429', ad_fec_proceso,
      0, 0, ln_dias_reint, 
      ln_importe_3025, ln_importe_3025d, ls_snp,
      ls_quinta, ls_judicial, ls_afp,
      ls_bonif30, ls_bonif25, ls_gratif,
      ls_cts, ls_vacacion, ls_bonif,
      ls_quincena, ls_quinque, ls_essalud,
      ls_agrario, ls_vida, ls_ies,
      ls_senati, ls_sctripss, ls_sctronp ) ;

  end if ;

end if ;

end usp_pla_cal_reintegros ;
/
