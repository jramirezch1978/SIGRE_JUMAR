create or replace procedure usp_pla_cal_por_jud
  ( as_codtra       in maestro.cod_trabajador%type , 
    ad_fec_proceso  in rrhhparam.fec_proceso%type
  ) is

--  Concepto de Judicial
lk_judicial           constant char(3) :='130' ;
ln_tipcam             calendario.cmp_dol_prom%type;
ln_porc_judicial      number(4,2);
ls_cod_concepto       concepto.concep%type ; 
ln_sum_remun_judicial number(13,2); 
ln_sum_desc_judicial  number(13,2);   
ln_imp_judicial       number(13,2);
ln_imp_judiciald      number(13,2);
ln_num_reg            integer;

begin

--  Halla tipo de cambio del dolar
Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_tipcam := nvl(ln_tipcam,1) ;

--  Halla nivel para judiciales
Select rpn.concep
  into ls_cod_concepto 
  from rrhh_nivel rpn
  where rpn.cod_nivel = lk_judicial;
 
--  Halla judicial por trabajador
Select m.porc_judicial
  into ln_porc_judicial
  from maestro m
  where m.cod_trabajador = as_codtra;
ln_porc_judicial := nvl(ln_porc_judicial,0);
 
--  Suma remuneraciones afectos a este concepto
If ln_porc_judicial > 0 then
       
  Select sum(c.imp_soles)
    into ln_sum_remun_judicial
    from calculo c
    where c.cod_trabajador = as_codtra and
          c.flag_t_judicial = '1' and
          substr(c.concep,1,1) = '1' ;
  ln_sum_remun_judicial := nvl(ln_sum_remun_judicial,0);
       
  --  Suma descuentos de ley del trabajador
  Select sum(c.imp_soles)
    into ln_sum_desc_judicial
    from calculo c
    where c.cod_trabajador = as_codtra and
          substr(c.concep,1,2) = '20' ;
  ln_sum_desc_judicial := nvl(ln_sum_desc_judicial,0);

  --  Obtiene importe para Porcentaje Judicial
  ln_imp_judicial := (ln_sum_remun_judicial - 
                      ln_sum_desc_judicial)*(ln_porc_judicial/100);
                     
  ln_imp_judicial  := nvl(ln_imp_judicial,0);
  ln_imp_judiciald := ln_imp_judicial / ln_tipcam ;
 
  --  Inserta registros en la tabla Calculo
  insert into calculo
   (cod_trabajador       , concep       ,  fec_proceso,
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
          
  Values 
    (as_codtra  , ls_cod_concepto, ad_fec_proceso ,
     0          , 0              , 0              ,
     ln_imp_judicial ,ln_imp_judiciald      , ' ',
     ' '        , ' '            ,
     ' '        , ' '            ,      
     ' '        , ' '            ,             
     ' '        , ' '            ,
     ' '        , ' '            ,       
     ' '        , ' '            ,
     ' '        , ' '            ,
     ' '        , ' '            ,                                       
     ' '        , ' '            );
 
End if;

End usp_pla_cal_por_jud;
/
