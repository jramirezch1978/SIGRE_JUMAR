create or replace procedure usp_rh_cal_apo_essalud (
    asi_codtra              in maestro.cod_trabajador%TYPE,
    adi_fec_proceso         in date,
    ani_tipcam              in number,
    asi_origen              in origen.cod_origen%TYPE,
    asi_tipo_trabaj         in tipo_trabajador.tipo_trabajador%TYPE,
    asi_flag_cierre         in varchar2,
    asi_tipo_planilla       in calculo.tipo_planilla%TYPE
) is

ls_grc_essalud         grupo_calculo.grupo_calculo%TYPE;
ln_count               number ;
ls_concepto            concepto.concep%TYPE ;
ln_factor              concepto.fact_pago%TYPE ;
ln_imp_soles           calculo.imp_soles%TYPE ;
ln_imp_dolar           calculo.imp_dolar%TYPE ;
ln_rmv                 rmv_x_tipo_trabaj.rmv%TYPE;          -- Remuneracion minima vital
ln_imp_historico       calculo.imp_soles%TYPE;
ln_imp_calculo         calculo.imp_soles%TYPE;
ln_apo_essalud         calculo.imp_soles%TYPE;              -- Aportacion ESSALUD del historico
ls_cnc_cred_eps        rrhhparam_cconcep.cnc_cred_eps%TYPE;
ls_cnc_essalud_675     rrhhparam_cconcep.cnc_essalud_675%TYPE;
ls_cnc_essalud         concepto.concep%TYPE;
ls_tipo_trip           tipo_trabajador.tipo_trabajador%TYPE;
ls_afp_comision        concepto.concep%TYPE;
ls_snp                 concepto.concep%TYPE;


begin

--  ****************************************************************
--  ***   REALIZA CALCULO DE APORTACION ESSALUD POR TRABAJADOR   ***
--  ****************************************************************

-- *************************************************************************************
-- Cambiado por Jhonny Ramirez Chiroque
-- Se esta cambiando el programa para que en el calculo del impuesto de essalud se tenga
-- en cuenta el minimo vital por tipo de trabajador, si los ingresos del mes exceden este
-- tope, entonces se calcula ESSALUD de manera normal, de lo contrario se calcula en base
-- al tope indicado; para esto se debe de indicar si es cierre de mes o no
-- (flag_cierre de mes = '1')
-- *************************************************************************************
select c.concep_essalud, c.cnc_cred_eps, c.cnc_essalud_675
  into ls_grc_essalud,  ls_cnc_cred_eps, ls_cnc_essalud_675  
  from rrhhparam_cconcep c
 where c.reckey = '1' ;
 
-- Obtengo el concepto de SNP
select g.concepto_gen
 into ls_snp 
 from grupo_calculo g, 
      rrhhparam_cconcep rh
 where g.grupo_calculo = rh.snp;

 
-- Obtengo el concepto de SNP
select g.concepto_gen
 into ls_afp_comision 
 from grupo_calculo g, 
      rrhhparam_cconcep rh
 where g.grupo_calculo = rh.afp_comision;


select r.tipo_trab_tripulante
  into ls_tipo_trip
  from rrhhparam r
 where r.reckey = '1';

select count(*)
 into ln_count
 from grupo_calculo g
where g.grupo_calculo = ls_grc_essalud ;

-- Si no existe simplemente retorno
if ln_count = 0 then return ; end if;

select g.concepto_gen
  into ls_cnc_essalud
  from grupo_calculo g
 where g.grupo_calculo = ls_grc_essalud;
       
-- Obtengo el codigo y el factor para el concepto de ESSALUD
-- Verifico si tiene Cred_eps
select count(*)
  into ln_count
  from calculo c
 where c.cod_trabajador = asi_codtra
   and c.concep         = ls_cnc_cred_eps;

if ln_count = 0 then
   select g.concepto_gen, nvl(c.fact_pago,0)
      into ls_concepto, ln_factor
      from grupo_calculo g, concepto c
     where g.concepto_gen  = c.concep
       and g.grupo_calculo = ls_grc_essalud;
else
   select c.concep, nvl(c.fact_pago,0)
      into ls_concepto, ln_factor
      from concepto c
     where c.concep = ls_cnc_essalud_675;
end if;


 -- ****************************************************************
 -- Primero busco el tope por tipo de trabajador, deacuerdo a su
 -- fecha de vigencia
 --  ****************************************************************
 select count(*)
   into ln_count
   from rmv_x_tipo_trabaj t
  where t.tipo_trabajador = asi_tipo_trabaj
    and trunc(t.fecha_desde) <= trunc(adi_fec_proceso);

 if ln_count > 0 then
    select tt.rmv
      into ln_rmv
      from ( select t.rmv
               from rmv_x_tipo_trabaj t
              where t.tipo_trabajador = asi_tipo_trabaj
                and trunc(t.fecha_desde) <= trunc(adi_fec_proceso)
             order by t.fecha_desde desc ) tt
      where rownum = 1;
 else
    --ln_rmv := 0;
    RAISE_APPLICATION_ERROR(-20000, 'No ha especificado una remuneracion miniva vital para el tipo de trabajador: '
                                    || asi_tipo_trabaj);
 end if;
   
 -- En caso de tripulantes el monto debe ser 4.4 veces la RMV
 if asi_tipo_trabaj = ls_tipo_trip then
    -- Si Tiene descuento x AFP o SNP entonces no debo multiplicarlo por 4.4
    /*select count(*)
      into ln_count
      from calculo c
     where c.cod_trabajador = asi_codtra
       and c.concep         in (ls_afp_comision, ls_snp);
 
    if ln_count = 0 then 
       ln_rmv := ln_rmv * 4.4;
    end if;*/
    
    -- Se ha realizado este cambio, se procede a cambiar la aportacion de essalud para tripulantes, basados en 4.4 la rmv sin excepcion
    ln_rmv := ln_rmv * 4.4;
 end if;
   
 -- Sumo el importe historico correspondiente al mismo periodo pero sin contar
 -- lo de la tabla calculo, para ello lo filtro por la fecha de calculo
 select nvl(sum(NVL(hc.imp_soles,0)), 0)
   into ln_imp_historico
   from historico_calculo hc,
        grupo_calculo_det gcd
  where gcd.concepto_calc = hc.concep
    and hc.cod_trabajador = asi_codtra
    and gcd.grupo_calculo = ls_grc_essalud
    and to_char(hc.fec_calc_plan, 'yyyymm') = to_char(adi_fec_proceso, 'yyyymm');

 -- Sumo lo que hay en la tabla calculo
 select nvl(sum(NVL(c.imp_soles,0)), 0)
   into ln_imp_calculo
   from calculo c,
        grupo_calculo_det gcd
  where gcd.concepto_calc = c.concep
    and c.cod_trabajador = asi_codtra
    and gcd.grupo_calculo = ls_grc_essalud
    and to_char(c.fec_proceso, 'yyyymm') = to_char(adi_fec_proceso, 'yyyymm');

 -- Obtengo todo lo que se ha aportado anteriormente
 select nvl(sum(nvl(hc.imp_soles,0)),0)
   into ln_apo_essalud
   from historico_calculo hc
  where hc.concep  in(ls_cnc_essalud_675, ls_cnc_essalud)
    and hc.cod_trabajador = asi_codtra
    and to_char(hc.fec_calc_plan, 'yyyymm') = to_char(adi_fec_proceso, 'yyyymm');
   
 -- Si la remunearcion total me da cero entonces no ha trabajado nada y no tengo que pagarle algo
 if (ln_imp_calculo + ln_imp_historico) = 0 then return; end if;
   
 -- Ahora valido si excede o no a la RMV
 if asi_flag_cierre = '1' then
    if (ln_imp_calculo + ln_imp_historico) > ln_rmv then
       ln_imp_soles := ln_imp_calculo + ln_imp_historico;
    else
       ln_imp_soles := ln_rmv;
    end if;
 else
    ln_imp_soles := ln_imp_calculo;
 end if;   

 -- Procedo al calculo por el factor
 ln_imp_soles := ln_imp_soles * ln_factor;

 -- Procedo a restarle lo que se ha descontado hasta ahora
 if asi_flag_cierre = '1' then
    ln_imp_soles := ln_imp_soles - ln_apo_essalud;
 end if;

 -- Ahora si lo que queda es lo que se va a poner en la boleta
 if ln_imp_soles > 0 then
    ln_imp_dolar := ln_imp_soles / ani_tipcam ;
    
    UPDATE calculo c
       SET imp_soles     = imp_soles + ln_imp_soles,
           imp_dolar     = imp_dolar + ln_imp_dolar
     WHERE cod_trabajador = asi_codtra
       AND concep         = ls_concepto
       and tipo_planilla  = asi_tipo_planilla;

    IF SQL%NOTFOUND THEN
               
       insert into calculo (
           cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
           dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
       values (
           asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
           0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
           
    END IF;
 end if ;

end usp_rh_cal_apo_essalud ;
/
