create or replace procedure usp_pla_cal_cta_cte
  ( as_codtra        in maestro.cod_trabajador%type, 
    ad_fec_proceso   in rrhhparam.fec_proceso%type ) is
   
lk_cta_cte        constant char(3) := '140' ;
ln_sldo_prestamo  number(13,2) ;
ln_mont_cuota     number(13,2) ;   
ln_imp_cta_cte    number(13,2) ;
ln_imp_cta_cted   number(13,2) ;
ln_num_reg        number(5) ;
ls_cod_concepto   concepto.concep%type ;
ls_tipdoc         cnta_crrte.tipo_doc%type ;
ls_nrodoc         cnta_crrte.nro_doc%type ;
ln_tipcam         calendario.cmp_dol_prom%type ;
ln_id             cnta_crrte_detalle.nro_dscto%type ;

ln_contador       number(15) ;
ln_acum_soles     number(13,2) ;
ln_acum_dolar     number(13,2) ;

--  Conceptos de cuentas corrientes
cursor c_rpd_concepto is 
  Select rpd.concep
    from rrhh_nivel_detalle rpd
    where rpd.cod_nivel = lk_cta_cte ;
  
--  Busca registros por trabajador
cursor c_cta_cte is 
  Select cc.tipo_doc, cc.nro_doc, cc.concep,
         cc.mont_cuota, cc.sldo_prestamo
  from cnta_crrte cc
  where cc.cod_trabajador = as_codtra and
        cc.concep = ls_cod_concepto and
        cc.flag_estado = '1' and
        cc.cod_sit_prest = 'A';
   
begin

--  Halla el tipo de cambio del dolar
Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_tipcam := nvl(ln_tipcam,1) ;
  
For rc_rpd_concepto in c_rpd_concepto Loop
  ls_cod_concepto := rc_rpd_concepto.concep ; 
  ls_cod_concepto := nvl(ls_cod_concepto,'XXXX') ;
  ln_num_reg := 0 ;
  Select count(cc.concep)
    into ln_num_reg
    from cnta_crrte cc
    where cc.cod_trabajador = as_codtra and
          cc.concep = ls_cod_concepto and
          cc.flag_estado = '1' and
          cc.cod_sit_prest = 'A';
  ln_num_reg := nvl(ln_num_reg,0);
          
  If ln_num_reg > 0 then
    ln_contador   := 0 ;
    ln_acum_soles := 0 ;
    ln_acum_dolar := 0 ;
    For rc_cta_cte in c_cta_cte Loop
      ln_contador      := ln_contador + 1 ;
      ln_mont_cuota    :=  rc_cta_cte.mont_cuota ;
      ln_sldo_prestamo := rc_cta_cte.sldo_prestamo ;
      ls_tipdoc        := rc_cta_cte.tipo_doc ;
      ls_nrodoc        := rc_cta_cte.nro_doc ;
      ln_mont_cuota    := nvl(ln_mont_cuota,0) ;
      ln_sldo_prestamo := nvl(ln_sldo_prestamo,0) ;   
     
      --  Verifica que el saldo sea mayor que cero
      If ln_sldo_prestamo > 0 Then
        If ln_mont_cuota > ln_sldo_prestamo Then
          ln_imp_cta_cte := ln_sldo_prestamo;
        Else
          ln_imp_cta_cte := ln_mont_cuota; 
        End If;
        ln_imp_cta_cted := ln_imp_cta_cte / ln_tipcam;
        ln_acum_soles := ln_acum_soles + ln_imp_cta_cte ;
        ln_acum_dolar := ln_acum_dolar + ln_imp_cta_cted ;
        
        --  Incrementa numero de descuento 
        Select max(ccd.nro_dscto)
          into ln_id
          from cnta_crrte_detalle ccd
          where ccd.cod_trabajador = as_codtra and
                ccd.tipo_doc = ls_tipdoc and
                ccd.nro_doc  = ls_nrodoc ;
        ln_id := ln_id + 1;
        ln_id := nvl(ln_id,1) ;
         
        --  Inserta registros en la tabla calculo
        If ln_num_reg = ln_contador then
          Insert into calculo
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
            ln_acum_soles , ln_acum_dolar , ' ',
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

        --  Graba registros con descuentos del mes
        Insert into cnta_crrte_detalle
          (cod_trabajador  , tipo_doc   ,
          nro_doc          , nro_dscto  ,
          fec_dscto        , imp_dscto  )
        Values
          (as_codtra       , ls_tipdoc  ,
          ls_nrodoc        , ln_id      ,
          ad_fec_proceso   , ln_imp_cta_cte );
      End If;
    End loop;
  End if;
End loop;             

End usp_pla_cal_cta_cte;
/
