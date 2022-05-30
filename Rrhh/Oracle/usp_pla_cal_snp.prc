create or replace procedure usp_pla_cal_snp
   (as_codtra        in maestro.cod_trabajador%type,
    ad_fec_proceso   in calculo.fec_proceso%type
   ) is

lk_snp               constant char(3) := '110';
ls_cod_concepto      concepto.concep%type;
ln_fac_snp           number(9,6) ;
ln_count_snp         number(3);  
ln_sum_snp_sol       number (13,2);
ln_sum_snp_dol       number(13,2);
ln_tot_snp_imp_sol   number(13,2); 
ln_tot_snp_imp_dol   number(13,2);
ln_tope_minimo       number(13,2) ;

--  Cursor para las ganancias del trabjador afectas al SNP
Cursor c_gan_snp (as_codtra maestro.cod_trabajador%type) is 
  Select c.concep, c.imp_soles, c.imp_dolar
    from calculo c
    where c.cod_trabajador = as_codtra and
          substr(c.concep,'1','1') = '1' and 
          c.flag_t_snp = '1' ;
             
begin

--  Obtiene concepto del SNP 
Select rpn.concep
  into ls_cod_concepto
  from rrhh_nivel rpn
  where rpn.cod_nivel = lk_snp;

Select c.fact_pago, nvl(c.imp_tope_min,0)
  into ln_fac_snp, ln_tope_minimo
  from concepto c
  where c.concep = ls_cod_concepto;
ln_fac_snp := nvl(ln_fac_snp,0);
 
Select count(c.concep)
  into ln_count_snp 
  from calculo c
  where c.cod_trabajador = as_codtra and
        substr(c.concep,'1','1') = '1' and 
        c.flag_t_snp = '1' ;
      
If ln_count_snp > 0 Then
  ln_sum_snp_sol := 0 ; 
  ln_sum_snp_dol := 0 ; 
  
  For rc_gan_snp in c_gan_snp (as_codtra) Loop
    ln_sum_snp_sol := ln_sum_snp_sol + rc_gan_snp.imp_soles;
    ln_sum_snp_dol := ln_sum_snp_dol + rc_gan_snp.imp_dolar;
  End Loop;
   
  if ln_sum_snp_sol < ln_tope_minimo then
    ln_sum_snp_sol := ln_tope_minimo ;
  end if ;
  
  ln_tot_snp_imp_sol := ln_sum_snp_sol*ln_fac_snp;
  ln_tot_snp_imp_dol := ln_sum_snp_dol*ln_fac_snp;
  
  ln_tot_snp_imp_sol := nvl(ln_tot_snp_imp_sol,0);
  ln_tot_snp_imp_dol := nvl(ln_tot_snp_imp_dol,0);
  
  --  Inserta registros en la tabla CALCULO
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
     
  Values( as_codtra     , ls_cod_concepto   , ad_fec_proceso,
     ''            , ''                , ''            ,
     ln_tot_snp_imp_sol   , ln_tot_snp_imp_dol, ' ',
     ' ',                ' '     ,
     ' ',                ' '     ,
     ' ',                ' '     ,
     ' ',                ' '     ,
     ' ',                ' '     ,
     ' ',                ' '     ,
     ' ',                ' '     ,
     ' ',                ' '     ,
     ' ',                ' '     );
     
End if;
      
End usp_pla_cal_snp;
/
