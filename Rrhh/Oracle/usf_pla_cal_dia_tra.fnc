create or replace function usf_pla_cal_dia_tra(
   as_codtra      in maestro.cod_trabajador%type,
   an_dias_mes    in rrhhparam.dias_mes_obrero%type
   ) return calculo.dias_trabaj%type is
  
   --  Buscar conceptos de inasistencias a descontar
   lk_descontar    constant char(3) := '050' ; 
   ls_tipo_ina     char(3);
   ld_fec_desde    rrhhparam.fec_desde%type ;
   ld_fec_hasta    rrhhparam.fec_hasta%type ;

   Cursor c_inasistencias  is 
     Select i.fec_movim, i.dias_inasist
       from inasistencia i
       where i.cod_trabajador = as_codtra 
             and i.concep in (
             Select rhnd.concep
               from rrhh_nivel_detalle rhnd
               where rhnd.cod_nivel = ls_tipo_ina)
             and i.fec_movim between ld_fec_desde and ld_fec_hasta ;

   ln_diatra   calculo.dias_trabaj%type;
   ln_faltas   number;
  
begin

Select rh.fec_desde, rh.fec_hasta
  into ld_fec_desde, ld_fec_hasta
  from rrhhparam rh
  where rh.reckey = '1' ;
  
ln_diatra := an_dias_mes;

--  Halla faltas a descontar 
ln_faltas := 0 ;
ls_tipo_ina := lk_descontar ;
For rc_ina in c_inasistencias Loop
  ln_faltas := ln_faltas + rc_ina.dias_inasist ;
End Loop ;
ln_diatra := ln_diatra - ln_faltas; 
  
-- los dias trabajados no deben ser mayor a los dias
-- del registro de parametros de rr.hh. (30 o 31)
If ln_diatra > an_dias_mes Then 
  ln_diatra := an_dias_mes ;
End if;
   
return(ln_diatra);

End usf_pla_cal_dia_tra;
/
