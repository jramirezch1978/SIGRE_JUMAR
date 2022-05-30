create or replace procedure usp_rh_cal_apo_ies(
       asi_codtra      in maestro.cod_trabajador%type ,
       adi_fec_proceso in date                        ,
       ani_tipcam      in calendario.vta_dol_bnc%type ,
       asi_origen      in origen.cod_origen%type      ,
       asi_cod_area    in maestro.cod_area%type       ,
       asi_cod_seccion in maestro.cod_seccion%type      
) is

ls_grc_concep_ies     grupo_calculo.grupo_calculo%type ;
ls_flag_seccion       grupo_calculo.flag_seccion%type  ;
ln_verifica           Number ;
ln_count              Number ;
ls_concepto           concepto.concep%Type             ;
ln_factor             concepto.fact_pago%TYPE ;
ln_imp_soles          calculo.imp_soles%TYPE ;
ln_imp_dolar          calculo.imp_dolar%TYPE ;

begin

--  ****************************************************************************
--  ***   REALIZA CALCULO DE SEGURO IMPUESTO EXTRAORDINARIO DE SOLIDARIDAD   ***
--  ****************************************************************************

select c.calculo_ies 
  into ls_grc_concep_ies  
  from rrhhparam_cconcep c 
 where c.reckey = '1' ;

select count(*) 
  into ln_verifica 
  from grupo_calculo g 
 where g.grupo_calculo = ls_grc_concep_ies ;

if ln_verifica = 0 then Return ; end if ;

select g.concepto_gen, nvl(c.fact_pago,0),Nvl(g.flag_seccion,'0') 
  into ls_concepto ,ln_factor ,ls_flag_seccion
  from grupo_calculo g, 
       concepto      c
 where g.concepto_gen  = c.concep      
   and g.grupo_calculo = ls_grc_concep_ies;
       
       
if ls_flag_seccion = '1'  then
   /*verificar q seccion este afecta a este grupo de conceptos*/
   select Count(*) 
     into ln_count
     from grupo_calc_x_seccion gcs
    where gcs.grupo_calculo = ls_grc_concep_ies  
      and gcs.cod_area      = asi_cod_area    
      and gcs.cod_seccion   = asi_cod_seccion 
      and gcs.flag_estado   = '1' ;
end if ;

select sum(nvl(c.imp_soles,0)) 
  into ln_imp_soles 
  from calculo c 
 where c.cod_trabajador = asi_codtra 
   and c.concep         in ( select d.concepto_calc 
                               from grupo_calculo_det d
                              where d.grupo_calculo = ls_grc_concep_ies ) ;

if ln_imp_soles > 0 and ((ls_flag_seccion = '1' and ln_count > 0) or ls_flag_seccion = '0' ) then
   ln_imp_soles := ln_imp_soles * ln_factor ;
   ln_imp_dolar := Round(ln_imp_soles / ani_tipcam,2) ;
  
   Insert into calculo(
          cod_trabajador ,concep    ,fec_proceso ,horas_trabaj ,horas_pag        ,
          dias_trabaj    ,imp_soles ,imp_dolar   ,cod_origen   ,flag_replicacion ,
          item )
   Values(
          asi_codtra ,ls_concepto  ,adi_fec_proceso ,0         ,0  ,
          0         ,ln_imp_soles ,ln_imp_dolar   ,asi_origen ,'1',
          1 ) ;
end if ;

end usp_rh_cal_apo_ies ;
/
