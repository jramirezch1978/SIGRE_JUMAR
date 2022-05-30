create or replace procedure usp_pla_cal_quinta(
  as_codtra            in maestro.cod_trabajador%type,
  ad_fec_proceso       in rrhhparam.fec_proceso%type,
  an_und_impos_tribut  in rrhhparam.und_impos_tribut%type
  ) is

ls_concepto_quinta     constant char(4) := '2010' ;
ln_factor              concepto.fact_pago%type ;
ln_tope_maximo         concepto.imp_tope_max%type ;
ls_flag_quinta         char(1) ;
ln_tipcam              calendario.cmp_dol_prom%type ;

ln_acu_proyectable     number(13,2) ;
ln_acu_imprecisa       number(13,2) ;
ln_acu_retencion       number(13,2) ;
ln_acu_gratif          number(13,2) ;

ls_concepto            concepto.concep%type ;
ln_imp_soles           number(13,2) ;
ln_gra_julio           number(13,2) ;
ln_gra_diciembre       number(13,2) ;
ln_gratificacion       number(13,2) ;
ln_proyectable         number(13,2) ;
ln_imprecisa           number(13,2) ;

ls_meses               char(2) ;
ls_mes                 char(2) ;
ld_fec_proceso         date ;

ln_proy01              number(13,2) ;
ln_proy02              number(13,2) ;
ln_proy03              number(13,2) ;
ln_proy04              number(13,2) ;
ln_proy05              number(13,2) ;
ln_proy06              number(13,2) ;
ln_proy07              number(13,2) ;
ln_proy08              number(13,2) ;
ln_proy09              number(13,2) ;
ln_proy10              number(13,2) ;
ln_proy11              number(13,2) ;
ln_proy12              number(13,2) ;

ln_prom_gratif         number(13,2) ;
ln_prom_remune         number(13,2) ;
ln_mes_saldo           number(2) ;
ln_imp_calculo         number(13,2) ;
ln_diferencia          number(13,2) ;       
ln_importe             number(13,2) ;
ln_retencion           number(13,2) ;
ln_soles_ret           number(13,2) ;
ln_dolar_ret           number(13,2) ;
ln_contador            integer ;

--  Cursor para hallar las ganancias proyectables afectas del mes
Cursor c_ganancias is
Select c.concep, c.imp_soles
  from calculo c
  where c.cod_trabajador = as_codtra and
        substr(c.concep,1,1) = '1' and
        c.flag_t_quinta = '1' ;

--  Cursor para hallar las ganancias imprecisas afectas del mes
Cursor c_imprecisas is
Select gdv.fec_movim, gdv.concep, gdv.imp_var
  from gan_desct_variable gdv
  where gdv.cod_trabajador = as_codtra and
        substr(gdv.concep,1,1) = '1' and
        gdv.concep <> '1010' and gdv.concep <> '1201' and
        gdv.concep <> '1204' and gdv.concep <> '1425' and
        gdv.concep <> '1410' and gdv.concep <> '1411' and
        gdv.concep <> '1416' ;

--  Cursor para determinar ganancias proyectables en
--  sus respectivos meses en el a?o
Cursor c_quinta is
Select qc.fec_proceso, qc.rem_proyectable
  from quinta_categoria qc
  where qc.cod_trabajador = as_codtra and
        to_char(qc.fec_proceso,'YYYY') = to_char(ad_fec_proceso,'YYYY')
  order by qc.cod_trabajador, qc.fec_proceso ;

begin

delete from quinta_categoria qc
  where qc.fec_proceso = ad_fec_proceso and
        qc.cod_trabajador = as_codtra ;
  
--  Busca concepto de quinta categoria en la tabla CONCEPTO
Select c.fact_pago, c.imp_tope_max
  into ln_factor, ln_tope_maximo
  from concepto c
  where c.concep = ls_concepto_quinta ;

--  Halla el tipo de cambio del dolar
Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_tipcam := nvl(ln_tipcam,1) ;

--  Acumula remuneraciones proyectables, imprecisas, retenciones
--  y gratificaciones del ano de proceso
Select sum(q.rem_proyectable), sum(q.rem_imprecisa),
       sum(q.rem_retencion), sum(q.rem_gratif)
  into ln_acu_proyectable, ln_acu_imprecisa,
       ln_acu_retencion, ln_acu_gratif
  from quinta_categoria q
  where q.cod_trabajador = as_codtra and
        to_char(q.fec_proceso, 'YYYY') = to_char(ad_fec_proceso, 'YYYY') ;
ln_acu_proyectable := nvl(ln_acu_proyectable,0) ;
ln_acu_imprecisa   := nvl(ln_acu_imprecisa,0) ;
ln_acu_retencion   := nvl(ln_acu_retencion,0) ;
ln_acu_gratif      := nvl(ln_acu_gratif,0) ;

--  Acumula ganancias proyectables del mes
ln_gra_julio     := 0 ;
ln_gra_diciembre := 0 ;
ln_gratificacion := 0 ;
ln_proyectable   := 0 ;
For rc_gan in c_ganancias Loop
  ls_concepto  := rc_gan.concep ;
  ln_imp_soles := rc_gan.imp_soles ;
  ln_imp_soles := nvl(ln_imp_soles,0) ;
  If ls_concepto = '1410' then
    ln_gra_julio := ln_gra_julio + ln_imp_soles ;
  Elsif ls_concepto = '1411' then
    ln_gra_diciembre := ln_gra_diciembre + ln_imp_soles ;
  Elsif ls_concepto <> '1410' and ls_concepto <> '1411' then
    ln_proyectable := ln_proyectable + ln_imp_soles ;
  End if ;
End Loop ;
If ln_gra_julio > 0 then
  ln_gratificacion := ln_gra_julio ;
Elsif ln_gra_diciembre > 0 then
  ln_gratificacion := ln_gra_diciembre ;
End if ;

--  Acumula ganancias imprecisas del mes
ln_imprecisa := 0 ;
For rc_imp in c_imprecisas Loop
  ls_concepto  := rc_imp.concep ;
  ln_imp_soles := rc_imp.imp_var ;
  ln_imp_soles := nvl(ln_imp_soles,0) ;
  Select c.flag_t_quinta
    into ls_flag_quinta
    from concepto c
    where c.concep = ls_concepto ;
  ls_flag_quinta := nvl(ls_flag_quinta,'0') ;
  If ls_flag_quinta = '1' then
    ln_imprecisa := ln_imprecisa + ln_imp_soles ;
  End if ;
End Loop ;

--  Actualiza ganancias proyectables del mes
ln_proyectable := ln_proyectable - ln_imprecisa ;

--  Inserta registros en la tabla QUINTA_CATEGORIA
Insert into quinta_categoria
  (cod_trabajador, fec_proceso, rem_proyectable,
   rem_imprecisa, rem_promedio, rem_retencion, rem_gratif)
Values
  (as_codtra, ad_fec_proceso, ln_proyectable,
   ln_imprecisa, 0, 0, ln_gratificacion ) ;

--  Actualiza remuneraciones proyectables por meses
ls_meses := to_char(ad_fec_proceso,'MM') ;

ln_proy01 := 0 ; ln_proy02 := 0 ; ln_proy03 := 0 ; ln_proy04 := 0 ;
ln_proy05 := 0 ; ln_proy06 := 0 ; ln_proy07 := 0 ; ln_proy08 := 0 ;
ln_proy09 := 0 ; ln_proy10 := 0 ; ln_proy11 := 0 ; ln_proy12 := 0 ;

For rc_qui in c_quinta Loop
  ls_mes       := to_char(rc_qui.fec_proceso,'MM') ;
  ln_imp_soles := rc_qui.rem_proyectable ;
  ln_imp_soles := nvl(ln_imp_soles,0) ;
  If ls_mes = '01' then
    ln_proy01 := ln_imp_soles ;
  Elsif ls_mes = '02' then
    ln_proy02 := ln_imp_soles ;
  Elsif ls_mes = '03' then
    ln_proy03 := ln_imp_soles ;
  Elsif ls_mes = '04' then
    ln_proy04 := ln_imp_soles ;
  Elsif ls_mes = '05' then
    ln_proy05 := ln_imp_soles ;
  Elsif ls_mes = '06' then
    ln_proy06 := ln_imp_soles ;
  Elsif ls_mes = '07' then
    ln_proy07 := ln_imp_soles ;
  Elsif ls_mes = '08' then
    ln_proy08 := ln_imp_soles ;
  Elsif ls_mes = '09' then
    ln_proy09 := ln_imp_soles ;
  Elsif ls_mes = '10' then
    ln_proy10 := ln_imp_soles ;
  Elsif ls_mes = '11' then
    ln_proy11 := ln_imp_soles ;
  Elsif ls_mes = '12' then
    ln_proy12 := ln_imp_soles ;
  End if ;
End loop ;
If ls_meses = '01' then
  ld_fec_proceso := add_months(ad_fec_proceso, - 1);
  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from quinta_categoria k
    where k.cod_trabajador = as_codtra and
          k.fec_proceso = ld_fec_proceso ;
  ln_contador := nvl(ln_contador,0) ;
  If ln_contador > 0 then
    Select k.rem_proyectable
      into ln_proy12
      from quinta_categoria k
      where k.cod_trabajador = as_codtra and
            k.fec_proceso = ld_fec_proceso ;
  End if ;
  ln_proy12 := nvl(ln_proy12,0) ;
  ld_fec_proceso := add_months(ad_fec_proceso, - 2);
  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from quinta_categoria k
    where k.cod_trabajador = as_codtra and
          k.fec_proceso = ld_fec_proceso ;
  ln_contador := nvl(ln_contador,0) ;
  If ln_contador > 0 then
    Select k.rem_proyectable
      into ln_proy11
      from quinta_categoria k
      where k.cod_trabajador = as_codtra and
            k.fec_proceso = ld_fec_proceso ;
  End if ;
  ln_proy11 := nvl(ln_proy11,0) ;
End if ;
If ls_meses = '02' then
  ld_fec_proceso := add_months(ad_fec_proceso, - 2);
  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from quinta_categoria k
    where k.cod_trabajador = as_codtra and
          k.fec_proceso = ld_fec_proceso ;
  ln_contador := nvl(ln_contador,0) ;
  If ln_contador > 0 then
    Select k.rem_proyectable
      into ln_proy12
      from quinta_categoria k
      where k.cod_trabajador = as_codtra and
            k.fec_proceso = ld_fec_proceso ;
  End if ;
  ln_proy12 := nvl(ln_proy12,0) ;
End if ;
 
--  Calcula promedio de gratificaciones y remuneraciones
ln_prom_gratif := 0 ;
ln_prom_remune := 0 ;
If ls_meses = '01' then
  ln_mes_saldo := 12 ;
  If ln_proy11 > 0 and ln_proy12 > 0 then
    ln_prom_gratif := ((ln_proy11+ln_proy12+ln_proy01)/3)*2 ;
    ln_prom_remune := ((ln_proy11+ln_proy12+ln_proy01)/3)*12 ;
  Else
    ln_prom_gratif := ln_proy01*2 ;
    ln_prom_remune := ln_proy01*12 ;
  End if ;
End if ;
If ls_meses = '02' then
  ln_mes_saldo := 11 ;
  If ln_proy12 > 0 and ln_proy01 > 0 then
    ln_prom_gratif := ((ln_proy12+ln_proy01+ln_proy02)/3)*2 ;
    ln_prom_remune := ((ln_proy12+ln_proy01+ln_proy02)/3)*11 ;
  Else
    ln_prom_gratif := ln_proy02*2 ;
    ln_prom_remune := ln_proy02*11 ;
  End if ;
End if ;
If ls_meses = '03' then
  ln_mes_saldo := 10 ;
  If ln_proy01 > 0 and ln_proy02 > 0 then
    ln_prom_gratif := ((ln_proy01+ln_proy02+ln_proy03)/3)*2 ;
    ln_prom_remune := ((ln_proy01+ln_proy02+ln_proy03)/3)*10 ;
  Else
    ln_prom_gratif := ln_proy03*2 ;
    ln_prom_remune := ln_proy03*10 ;
  End if ;
End if ;
If ls_meses = '04' then
  ln_mes_saldo := 9 ;
  If ln_proy02 > 0 and ln_proy03 > 0 then
    ln_prom_gratif := ((ln_proy02+ln_proy03+ln_proy04)/3)*2 ;
    ln_prom_remune := ((ln_proy02+ln_proy03+ln_proy04)/3)*9 ;
  Else
    ln_prom_gratif := ln_proy04*2 ;
    ln_prom_remune := ln_proy04*9 ;
  End if ;
End if ;
If ls_meses = '05' then
  ln_mes_saldo := 8 ;
  If ln_proy03 > 0 and ln_proy04 > 0 then
    ln_prom_gratif := ((ln_proy03+ln_proy04+ln_proy05)/3)*2 ;
    ln_prom_remune := ((ln_proy03+ln_proy04+ln_proy05)/3)*8 ;
  Else
    ln_prom_gratif := ln_proy05*2 ;
    ln_prom_remune := ln_proy05*8 ;
  End if ;
End if ;
If ls_meses = '06' then
  ln_mes_saldo := 7 ;
  If ln_proy04 > 0 and ln_proy05 > 0 then
    ln_prom_gratif := ((ln_proy04+ln_proy05+ln_proy06)/3)*2 ;
    ln_prom_remune := ((ln_proy04+ln_proy05+ln_proy06)/3)*7 ;
  Else
    ln_prom_gratif := ln_proy06*2 ;
    ln_prom_remune := ln_proy06*7 ;
  End if ;
End if ;
If ls_meses = '07' then
  ln_mes_saldo := 6 ;
  If ln_proy05 > 0 and ln_proy06 > 0 then
    ln_prom_gratif := ((ln_proy05+ln_proy06+ln_proy07)/3) ;
    ln_prom_remune := ((ln_proy05+ln_proy06+ln_proy07)/3)*6 ;
  Else
    ln_prom_gratif := ln_proy07*2 ;
    ln_prom_remune := ln_proy07*6 ;
  End if ;
End if ;
If ls_meses = '08' then
  ln_mes_saldo := 5 ;
  If ln_proy06 > 0 and ln_proy07 > 0 then
    ln_prom_gratif := ((ln_proy06+ln_proy07+ln_proy08)/3) ;
    ln_prom_remune := ((ln_proy06+ln_proy07+ln_proy08)/3)*5 ;
  Else
    ln_prom_gratif := ln_proy08 ;
    ln_prom_remune := ln_proy08*5 ;
  End if ;
End if ;
If ls_meses = '09' then
  ln_mes_saldo := 4 ;
  If ln_proy07 > 0 and ln_proy08 > 0 then
    ln_prom_gratif := ((ln_proy07+ln_proy08+ln_proy09)/3) ;
    ln_prom_remune := ((ln_proy07+ln_proy08+ln_proy09)/3)*4 ;
  Else
    ln_prom_gratif := ln_proy09 ;
    ln_prom_remune := ln_proy09*4 ;
  End if ;
End if ;
If ls_meses = '10' then
  ln_mes_saldo := 3 ;
  If ln_proy08 > 0 and ln_proy09 > 0 then
    ln_prom_gratif := ((ln_proy08+ln_proy09+ln_proy10)/3) ;
    ln_prom_remune := ((ln_proy08+ln_proy09+ln_proy10)/3)*3 ;
  Else
    ln_prom_gratif := ln_proy10 ;
    ln_prom_remune := ln_proy10*3 ;
  End if ;
End if ;
If ls_meses = '11' then
  ln_mes_saldo := 2 ;
  If ln_proy09 > 0 and ln_proy10 > 0 then
    ln_prom_gratif := ((ln_proy09+ln_proy10+ln_proy11)/3) ;
    ln_prom_remune := ((ln_proy09+ln_proy10+ln_proy11)/3)*2 ;
  Else
    ln_prom_gratif := ln_proy11 ;
    ln_prom_remune := ln_proy11*2 ;
  End if ;
End if ;
If ls_meses = '12' then
  ln_mes_saldo := 1 ;
  ln_prom_gratif := 0 ;
  ln_prom_remune := ln_proy12*1 ;
End if ;
ln_prom_gratif := nvl(ln_prom_gratif,0) ;
ln_prom_remune := nvl(ln_prom_remune,0) ;
    
--  Calcula retencion de quinta categoria
ln_imp_calculo := 0 ;
ln_imp_calculo := ln_prom_remune     + ln_prom_gratif +
--                  ln_acu_proyectable + ln_acu_imprecisa ;
                  ln_acu_proyectable + ln_acu_imprecisa + ln_imprecisa ;
If ls_meses > '07' and ls_meses < '12' then
  ln_imp_calculo := ln_imp_calculo + ln_acu_gratif ;
End if ;
If ls_meses = '07' or ls_meses = '12' then
  ln_imp_calculo := ln_imp_calculo + ln_gratificacion + ln_acu_gratif ;
End if ;
ln_imp_calculo := ln_imp_calculo - an_und_impos_tribut ;

If ln_imp_calculo > 0 then
  ln_diferencia := 0 ; ln_importe   := 0 ; ln_retencion := 0 ;
  ln_soles_ret  := 0 ; ln_dolar_ret := 0 ;
  --  Calcula porcentaje a retener
  If ln_imp_calculo > ln_tope_maximo then
    ln_diferencia := ln_imp_calculo - ln_tope_maximo ;
    ln_importe := ln_tope_maximo * ln_factor ;
    ln_retencion := ln_importe + ( ln_diferencia * 0.30 ) ;
  Else
    ln_retencion := ln_imp_calculo * ln_factor ;
  End if ;
  --  Realiza retencion de quinta categoria del mes de proceso
  ln_soles_ret := (ln_retencion - ln_acu_retencion) / ln_mes_saldo ;
  ln_dolar_ret := ln_soles_ret / ln_tipcam ;
  If ln_soles_ret > 0 then 
    --  Inserta registros en la tabla CALCULO
    Insert into calculo 
      (cod_trabajador      , concep       ,  fec_proceso,
      horas_trabaj         , horas_pag    ,  dias_trabaj,
      imp_soles            , imp_dolar    ,  flag_t_snp ,
      flag_t_quinta        , flag_t_judicial ,
      flag_t_afp           , flag_t_bonif_30 ,
      flag_t_bonif_25      , flag_t_gratif   ,
      flag_t_cts           , flag_t_vacacio  ,
      flag_t_bonif_vacacio , flag_t_pago_quincena,
      flag_t_quinquenio    , flag_e_essalud  ,
      flag_e_agrario       , flag_e_essalud_vida,
      flag_e_ies           , flag_e_senati      ,
      flag_e_sctr_ipss     , flag_e_sctr_onp)
    Values( as_codtra      , ls_concepto_quinta , ad_fec_proceso,
      0                    , 0                  , 0             ,
      ln_soles_ret         , ln_dolar_ret       , ' ',
      ' ',                   ' '     ,
      ' ',                   ' '     ,
      ' ',                   ' '     ,
      ' ',                   ' '     ,
      ' ',                   ' '     ,
      ' ',                   ' '     ,
      ' ',                   ' '     ,
      ' ',                   ' '     ,
      ' ',                   ' '     );
  End if ;
End if ;
          
--  Actualiza remuneracion promedio y retencion de quinta categoria
ln_contador := 0 ;
Select count(*)
  Into ln_contador
  from quinta_categoria s
  where s.cod_trabajador = as_codtra and
        s.fec_proceso    = ad_fec_proceso ;
ln_contador := nvl(ln_contador,0) ;
If ln_contador > 0 then
  --  Actualiza tabla
  Update quinta_categoria
    Set rem_promedio  = ln_prom_remune ,
        rem_retencion = ln_soles_ret
    Where cod_trabajador = as_codtra and
          fec_proceso    = ad_fec_proceso ;
Else
  --  Inserta nuevos registros
  Insert into quinta_categoria
    ( cod_trabajador, fec_proceso, rem_proyectable,
      rem_imprecisa, rem_promedio, rem_retencion, rem_gratif )
  Values
    ( as_codtra, ad_fec_proceso, 0,
      0, ln_prom_remune, ln_soles_ret, 0 ) ;
End if ;

End usp_pla_cal_quinta ;
/
