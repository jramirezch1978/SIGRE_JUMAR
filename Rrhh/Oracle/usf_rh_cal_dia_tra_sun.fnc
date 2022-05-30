create or replace function usf_rh_cal_dia_tra_sun (
  as_codtra in char, an_dias_mes in rrhhparam.dias_mes_obrero%type,
  as_origen in char )
  return calculo.dias_trabaj%type is

--  Buscar conceptos de inasistencias a descontar
lk_descontar    constant char(3) := '076' ;
ls_tipo_ina     char(3) ;
ld_fec_desde    date ;
ld_fec_hasta    date ;
ln_diatra       calculo.dias_trabaj%type ;
ln_faltas       number ;

cursor c_inasistencias  is
  select i.fec_movim, i.dias_inasist
  from inasistencia i
  where i.cod_trabajador = as_codtra and i.concep in ( select d.concepto_calc
        from grupo_calculo_det d where d.grupo_calculo = ls_tipo_ina ) and
        i.fec_movim between ld_fec_desde and ld_fec_hasta ;

begin

select p.fec_inicio, p.fec_final
  into ld_fec_desde, ld_fec_hasta
  from rrhh_param_org p
  where p.origen = as_origen ;
  
--select rh.fec_desde, rh.fec_hasta
--  into ld_fec_desde, ld_fec_hasta
--  from rrhhparam rh where rh.reckey = '1' ;

ln_diatra := an_dias_mes ;

--  Determina faltas a descontar
ln_faltas := 0 ;
ls_tipo_ina := lk_descontar ;
for rc_ina in c_inasistencias loop
  ln_faltas := ln_faltas + nvl(rc_ina.dias_inasist,0) ;
end loop ;
if ln_faltas > ln_diatra then
  ln_faltas := ln_diatra ;
end if ;
ln_diatra := ln_diatra - ln_faltas ;

-- los dias trabajados no deben ser mayor a los dias
-- del registro de parametros de rr.hh. (30 0 31)
if ln_diatra > an_dias_mes then
  ln_diatra := an_dias_mes ;
end if ;

return(ln_diatra) ;

end usf_rh_cal_dia_tra_sun ;
/
