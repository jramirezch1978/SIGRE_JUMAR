CREATE OR REPLACE PROCEDURE usp_cnt_borrar_pre_asiento_tipo (
  asi_origen          in cntbl_pre_asiento.origen%type,
  ani_nro_libro       in cntbl_pre_asiento.nro_libro%type,
  asi_tipo_proceso    in cntbl_pre_asiento.tipo_proceso%type ;
  adi_fini            in cntbl_pre_asiento.fec_cntbl%type,
  adi_ffin            in cntbl_pre_asiento.fec_cntbl%type
) is

--  Lectura de transferencia matriz segun secuencia
CURSOR c_asiento IS 
select origen, nro_provisional
from cntbl_pre_asiento
where nro_libro = ani_nro_libro 
  and origen    = asi_origen   
  and tipo_proceso = asi_tipo_proceso 
  and trunc(fec_cntbl) between trunc(adi_fini) and trunc(adi_ffin) ;

CURSOR c_asiento_det(
  as_origen          cntbl_pre_asiento.origen%type,
  an_nro_libro       cntbl_pre_asiento.nro_libro%type,
  an_nro_provisional cntbl_pre_asiento.nro_provisional%type) IS 
select item
from cntbl_pre_asiento_det c
where origen          = as_origen 
  and nro_libro       = an_nro_libro 
  and nro_provisional = an_nro_provisional ;

ln_contador           number ;

BEGIN

--  ***************************************************************
--  ***  ELIMINA DETALLE DE CNTBL_PRE_ASIENTO_DET               ***
--  ***************************************************************
FOR rc_cab in c_asiento LOOP

    FOR rc_det in c_asiento_det(rc_cab.origen, ani_nro_libro, rc_cab.nro_provisional) LOOP

        select count(*) 
          into ln_contador
          from cntbl_pre_asiento_det_aux
         where origen          = rc_cab.origen 
           and nro_libro       = ani_nro_libro 
           and nro_provisional = rc_cab.nro_provisional 
           and item            = rc_det.item ;

        if ln_contador > 0 then
           delete cntbl_pre_asiento_det_aux
           where origen          = rc_cab.origen 
             and nro_libro       = ani_nro_libro 
             and nro_provisional = rc_cab.nro_provisional 
             and item            = rc_det.item ;
        end if;
        
        delete cntbl_pre_asiento_det
        where origen          = rc_cab.origen 
          and nro_libro       = ani_nro_libro 
          and nro_provisional = rc_cab.nro_provisional 
          and item            = rc_det.item ;

    END LOOP ;

    --  Elimina registro de cabecera del pre asiento
    delete cntbl_pre_asiento
    where origen          = rc_cab.origen 
      and nro_libro       = ani_nro_libro 
      and nro_provisional = rc_cab.nro_provisional ;

END LOOP ;

END usp_cnt_borrar_pre_asiento_tipo ;
/
