create or replace procedure usp_rh_cal_snp (
  asi_codtra            in maestro.cod_trabajador%TYPE, 
  adi_fec_proceso       in date, 
  asi_origen            in origen.cod_origen%TYPE,
  asi_tipo_planilla     in calculo.tipo_planilla%TYPE
) is

lk_snp               rrhhparam_cconcep.snp%TYPE ;

ln_verifica          integer ;
ln_contador          integer ;
ls_concepto          concepto.concep%TYPE ;
ln_factor            concepto.fact_pago%TYPE;
ln_tope_minimo       concepto.imp_tope_min%TYPE;
ln_imp_soles         calculo.imp_soles%TYPE;
ln_imp_dolar         calculo.imp_dolar%TYPE;

begin

--  ****************************************************************
--  ***   REALIZA EL CALCULO DEL SISTEMA NACIONAL DE PENSIONES   ***
--  ****************************************************************

select c.snp 
  into lk_snp 
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

ln_verifica := 0 ;
select count(*) 
  into ln_verifica 
  from grupo_calculo g
  where g.grupo_calculo = lk_snp ;

if ln_verifica > 0 then

   select g.concepto_gen, nvl(c.fact_pago,0), nvl(c.imp_tope_min,0)
     into ls_concepto, ln_factor, ln_tope_minimo 
     from grupo_calculo g, 
          concepto      c
     where g.concepto_gen = c.concep 
       and g.grupo_calculo = lk_snp ;

   ln_contador:= 0 ;
   select count(*) 
     into ln_contador 
     from calculo c
    where c.cod_trabajador = asi_codtra 
      and c.concep IN ( select d.concepto_calc 
                          from grupo_calculo_det d 
                         WHERE d.grupo_calculo = lk_snp ) 
      and tipo_planilla = asi_tipo_planilla;

   if ln_contador > 0 then
 
      select sum(nvl(c.imp_soles,0)), sum(nvl(c.imp_dolar,0))
        into ln_imp_soles, ln_imp_dolar 
        from calculo c
       where c.cod_trabajador = asi_codtra 
         and c.concep IN ( select d.concepto_calc 
                             from grupo_calculo_det d 
                            WHERE d.grupo_calculo = lk_snp ) 
         and tipo_planilla = asi_tipo_planilla;
              
      if ln_imp_soles < ln_tope_minimo then
         ln_imp_soles := ln_tope_minimo ;
      end if ;
    
      ln_imp_soles := ln_imp_soles * ln_factor ;
      ln_imp_dolar := ln_imp_dolar * ln_factor ;
      insert into calculo (
             cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
             dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, 
             item, tipo_planilla )
      values (
             asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
             0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
             asi_tipo_planilla ) ;

   end if ;

end if ;

end usp_rh_cal_snp ;
/
