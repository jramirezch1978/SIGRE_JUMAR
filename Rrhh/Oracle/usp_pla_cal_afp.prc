create or replace procedure usp_pla_cal_afp
   ( as_codtra        in maestro.cod_trabajador%type,
     ad_fec_proceso   in rrhhparam.fec_proceso%type
   ) is

 ln_tipcam             calendario.cmp_dol_prom%type;
 ln_count_afp          number(4);  
 ln_sum_afp            number(13,2); 
 ln_sum_afpd           number(13,2); 
 ln_porc_jubilac       number(9,6);
 ln_porc_invalidez     number(9,6);
 ln_porc_comision      number(9,6);
 ln_imp_invalidezd     number(13,2);
 ln_imp_invalidez      number(13,2);
 ls_cod_concepto       concepto.concep%type;
 ln_imp_var_jubilac    number(13,2);
 ln_imp_var_invalidez  number(13,2);
 ln_imp_var_comision   number(13,2);
 ln_imp_var_jubilacd   number(13,2);
 ln_imp_var_invalidezd number(13,2);
 ln_imp_var_comisiond  number(13,2);
 ls_flag_afp           char(1);

begin
 
Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_tipcam := nvl (ln_tipcam,1) ;

Select count(c.imp_soles)
  into ln_count_afp
  from calculo c
  where c.cod_trabajador = as_codtra and
        substr(c.concep,'1','1') = '1' and 
        c.flag_t_afp = '1' ;

If ln_count_afp >0 then

  Select sum(c.imp_soles)
    into ln_sum_afp
    from calculo c
    where c.cod_trabajador = as_codtra and
          substr(c.concep,'1','1') = '1' and 
          c.flag_t_afp = '1' ;
 
  Select sum(c.imp_dolar)
    into ln_sum_afpd
    from calculo c
    where c.cod_trabajador = as_codtra and
          substr(c.concep,'1','1') = '1' and 
          c.flag_t_afp = '1' ;

  --  Asigna AFP para el trabajador y los factores de pago
  Select m.flag_algun_famil, aa.porc_jubilac, aa.porc_invalidez,
         aa.porc_comision, aa.imp_tope_invalidez
    into ls_flag_afp, ln_porc_jubilac, ln_porc_invalidez,
         ln_porc_comision, ln_imp_invalidez
    from maestro m, admin_afp aa 
    where m.cod_trabajador = as_codtra and
          m.cod_afp = aa.cod_afp and
          aa.flag_estado = '1' ;
  ls_flag_afp := nvl(ls_flag_afp,' ') ;

  ln_imp_invalidez  := nvl(ln_imp_invalidez,0) ;
  ln_imp_invalidezd := ln_imp_invalidez/ln_tipcam ;
              
  --  Concepto de AFP Jubilacion
  ln_imp_var_jubilac  := ln_sum_afp*ln_porc_jubilac/100 ;
  ln_imp_var_jubilacd := ln_sum_afpd*ln_porc_jubilac/100 ;

  If ln_sum_afp > ln_imp_invalidez then
    ln_imp_var_invalidez  := ln_imp_invalidez*ln_porc_invalidez/100 ;
    ln_imp_var_invalidezd := ln_imp_invalidezd*ln_porc_invalidez/100 ;
  Else
    ln_imp_var_invalidez  := ln_sum_afp*ln_porc_invalidez/100 ;
    ln_imp_var_invalidezd := ln_sum_afpd*ln_porc_invalidez/100 ;
  End if ;
  
  ln_imp_var_comision  := ln_sum_afp*ln_porc_comision/100 ;
  ln_imp_var_comisiond := ln_sum_afpd*ln_porc_comision/100 ;

  If ls_flag_afp = '1' then
    ln_imp_var_jubilac   := 0 ;
    ln_imp_var_invalidez := 0 ;
    ln_imp_var_comision  := 0 ;
  Elsif ls_flag_afp = '2' then
    ln_imp_var_invalidez := 0 ;
  End if ;

  If ln_imp_var_jubilac > 0 then
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
    Values 
      (as_codtra , '2002'         , ad_fec_proceso ,
      0          , 0              , 0              ,
      ln_imp_var_jubilac , ln_imp_var_jubilacd , ' ',
      ' '        , ' '            ,
      ' '        , ' '            ,      
      ' '        , ' '            ,             
      ' '        , ' '            ,
      ' '        , ' '            ,       
      ' '        , ' '            ,
      ' '        , ' '            ,
      ' '        , ' '            ,                                       
      ' '        , ' '            );
  End if ;
  
  If ln_imp_var_invalidez > 0 then
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
    Values 
      (as_codtra , '2003'         , ad_fec_proceso ,
      0          , 0              , 0              ,
      ln_imp_var_invalidez , ln_imp_var_invalidezd , ' ',
      ' '        , ' '            ,
      ' '        , ' '            ,      
      ' '        , ' '            ,             
      ' '        , ' '            ,
      ' '        , ' '            ,       
      ' '        , ' '            ,
      ' '        , ' '            ,
      ' '        , ' '            ,                                       
      ' '        , ' '            );
  End if ;
  
  If ln_imp_var_comision > 0 then
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
    Values 
      (as_codtra , '2004'         , ad_fec_proceso ,
       0          , 0              , 0              ,
       ln_imp_var_comision , ln_imp_var_comisiond , ' ',
       ' '        , ' '            ,
       ' '        , ' '            ,      
       ' '        , ' '            ,             
       ' '        , ' '            ,
       ' '        , ' '            ,       
       ' '        , ' '            ,
       ' '        , ' '            ,
       ' '        , ' '            ,                                       
       ' '        , ' '            );
  End if ;
  
End if;

End usp_pla_cal_afp;
/
