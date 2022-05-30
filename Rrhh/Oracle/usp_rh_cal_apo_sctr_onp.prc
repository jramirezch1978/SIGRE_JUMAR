create or replace procedure usp_rh_cal_apo_sctr_onp (
    asi_codtra            in maestro.cod_trabajador%TYPE, 
    adi_fec_proceso       in date, 
    ani_tipcam            in number,
    asi_origen            in origen.cod_origen%TYPE, 
    asi_tipo_planilla     in calculo.tipo_planilla%TYPE 
) is

lk_sctr_onp         rrhhparam_cconcep.concep_sctr_onp%TYPE ;

ln_verifica         integer ;
ls_area             maestro.cod_area%TYPE;
ls_concepto         concepto.concep%TYPE;
ln_porcentaje       seccion.porc_sctr_onp%TYPE;
ln_imp_soles        calculo.imp_soles%TYPE;
ln_imp_dolar        calculo.imp_soles%TYPE;
ls_seccion          maestro.cod_seccion%TYPE;

begin

--  *****************************************************************
--  ***   CALCULA APORTACIONES DEL SEGURO COMPLEMENTARIO O.N.P.   ***
--  *****************************************************************

select c.concep_sctr_onp 
  into lk_sctr_onp
  from rrhhparam_cconcep c 
 where c.reckey = '1' ;

ln_verifica := 0 ;
select count(*) 
  into ln_verifica 
  from grupo_calculo g
 where g.grupo_calculo = lk_sctr_onp ;

if ln_verifica > 0 then

  select g.concepto_gen 
    into ls_concepto 
    from grupo_calculo g
   where g.grupo_calculo = lk_sctr_onp ;

  select m.cod_area, m.cod_seccion
    into ls_area, ls_seccion
    from maestro m
   where m.cod_trabajador = asi_codtra ;

  select nvl(s.porc_sctr_onp,0) 
    into ln_porcentaje 
    from seccion s
   where s.cod_area = ls_area 
     and s.cod_seccion = ls_seccion ;

  if ln_porcentaje > 0 then
     select sum(nvl(c.imp_soles,0)) 
       into ln_imp_soles 
       from calculo c
      where c.cod_trabajador = asi_codtra 
        and c.concep in ( select d.concepto_calc
                           from grupo_calculo_det d 
                           where d.grupo_calculo = lk_sctr_onp ) 
        and c.tipo_planilla   = asi_tipo_planilla;
                           
     ln_imp_soles := ln_imp_soles * ln_porcentaje / 100 ;
     ln_imp_dolar := ln_imp_soles / ani_tipcam ;
     insert into calculo (
            cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
            dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
            tipo_planilla )
     values (
            asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
            0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
            asi_tipo_planilla ) ;
  end if ;

end if ;

end usp_rh_cal_apo_sctr_onp ;
/
