create or replace procedure usp_rh_cal_desct_comedor (
  asi_codtra         in maestro.cod_trabajador%TYPE, 
  asi_origen         in origen.cod_origen%TYPE, 
  adi_fec_proceso    in date,
  ani_tipcam         in number,
  asi_tipo_planilla  in calculo.tipo_planilla%TYPE
) is

ls_cnc_dscto_comedor   rrhhparam.cnc_dscto_comedor%TYPE;
ln_importe_dscto       rrhhparam.imp_dscto_comedor%TYPE;
ls_turno_dia           rrhhparam.turno_dia%TYPE;
ls_flag_dscto_comedor  maestro.flag_dscto_comedor%TYPE;
ls_tipo_trabajador     maestro.tipo_trabajador%TYPE;
ln_count               number;
ln_imp_soles           calculo.imp_soles%TYPE;
ln_imp_dolar           calculo.imp_dolar%TYPE;
ld_fecha1              date;
ld_fecha2              date; 

begin

--  ***************************************************************
--  ***   GENERA DESCUENTO DE COMEDOR A LOS TRABAJADORES   ***
--  ***************************************************************

select r.cnc_dscto_comedor, r.imp_dscto_comedor, r.turno_dia
  into ls_cnc_dscto_comedor, ln_importe_dscto, ls_turno_dia
  from rrhhparam r
  where r.reckey = '1' ;

-- Obtengo los datos necesarios del maestro de trabajadores
select m.tipo_trabajador, m.flag_dscto_comedor
  into ls_tipo_trabajador, ls_flag_dscto_comedor
  from maestro m
 where m.cod_trabajador = asi_codtra;

-- si el flag esta en '0' no hago nada
if ls_flag_dscto_comedor = '0' then return; end if;

-- Obtengo el rango de fecha
select r.fec_inicio, r.fec_final
  into ld_fecha1, ld_fecha2
  from rrhh_param_org r
 where trunc(r.fec_proceso) = adi_fec_proceso
   and r.origen             = asi_origen
   and r.tipo_trabajador    = (select tipo_trabajador from maestro where cod_trabajador = asi_codtra)
   and r.tipo_planilla      = asi_tipo_planilla;
   
select count(distinct trunc(p.fec_parte))
  into ln_count
  from tg_pd_destajo p,
       tg_pd_destajo_det pd
 where p.nro_parte        = pd.nro_parte
   and pd.cod_trabajador  = asi_codtra
   and trunc(p.fec_parte) between ld_fecha1 and ld_fecha2
   and p.turno            = ls_turno_dia
   and p.flag_estado      = '1';
   
if ln_count > 0 then
    -- Obtengo primero el calculo por hora
    ln_imp_soles := ln_importe_dscto * ln_count;

    -- Calculo el importe
    ln_imp_dolar := ln_imp_soles / ani_tipcam;

    IF ln_imp_soles > 0 OR ln_imp_dolar > 0 THEN
       update calculo c
          set c.horas_trabaj = null,
              c.horas_pag    = null,
              c.dias_trabaj  = ln_count,
              c.imp_soles    = ln_imp_soles,
              c.imp_dolar    = ln_imp_dolar
        where c.cod_trabajador = asi_codtra
          and c.concep         = ls_cnc_dscto_comedor
          and c.fec_proceso    = adi_fec_proceso
          and c.tipo_planilla  = asi_tipo_planilla;
        
       if SQL%NOTFOUND then
          insert into calculo (
                       cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                       dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                       tipo_planilla )
          values (
                       asi_codtra, ls_cnc_dscto_comedor, adi_fec_proceso, null, null ,
                       ln_count, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                       asi_tipo_planilla ) ;
       end if; 
    END IF;
end if ;

end usp_rh_cal_desct_comedor ;
/
