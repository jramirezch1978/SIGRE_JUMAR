create or replace function usf_rh_dias_tot_util(
       as_trabajador       in maestro.cod_trabajador%type, 
       as_tipo_trabajador  in tipo_trabajador.tipo_trabajador%type, 
       ad_fecha_ini        in date, 
       ad_fecha_fin        in date
) return number is
       
  
  ln_dias_tot_periodo      number ;
  ln_dias_tope_ano         number ;
  
  ls_tipo_tri              rrhhparam.tipo_trab_tripulante%TYPE;
  ls_tipo_des              rrhhparam.tipo_trab_destajo%TYPE;
  ls_tipo_ser              rrhhparam.tipo_trab_servis%TYPE;
  ls_tipo_obr              rrhhparam.tipo_trab_obrero%TYPE;
  ls_tipo_emp              rrhhparam.tipo_trab_empleado%TYPE;

BEGIN 

  SELECT u.dias_tope_ano 
    INTO ln_dias_tope_ano 
    FROM utlparam u 
   WHERE reckey='1' ; 
  
  select r.tipo_trab_tripulante, r.tipo_trab_destajo, r.tipo_trab_servis, r.tipo_trab_obrero, r.tipo_trab_empleado
    into ls_tipo_tri, ls_tipo_des, ls_tipo_ser, ls_tipo_obr, ls_tipo_emp
    from rrhhparam r
   where r.reckey = '1';
   
    
  IF as_tipo_trabajador = ls_tipo_tri THEN 
     -- Si tipo de trabajador es tripulante
     SELECT count(distinct fla.fecha)
       into ln_dias_tot_periodo   
       FROM fl_asistencia fla
      WHERE FLA.TRIPULANTE = as_trabajador 
        AND trunc(FLA.FECHA) between trunc(ad_fecha_ini) and trunc(ad_fecha_fin);
  ELSIF as_tipo_trabajador in (ls_tipo_des, ls_tipo_ser) THEN 
     -- Si tipo de trabajador en destajero
     SELECT count(distinct a.fec_parte)
       into ln_dias_tot_periodo   
       FROM tg_pd_destajo     a,
            tg_pd_destajo_det b
      WHERE a.nro_parte   = b.nro_parte
        AND trunc(a.fec_parte) between trunc(ad_fecha_ini) and trunc(ad_fecha_fin)
        and b.cod_trabajador = as_trabajador;
  ELSIF as_tipo_trabajador = ls_tipo_obr THEN 
     -- Si tipo de trabajador en destajero
     SELECT count(distinct a.fecha)
       into ln_dias_tot_periodo   
       FROM pd_jornal_campo   a
      WHERE trunc(a.fecha) between trunc(ad_fecha_ini) and trunc(ad_fecha_fin)
        and a.cod_trabajador = as_trabajador;

  ELSE
    -- Otros tipos de trabajador
    SELECT ad_fecha_fin - ad_fecha_ini + 1 INTO ln_dias_tot_periodo FROM dual ;
  END IF ;

  --ln_dias_ajuste := TRUNC(ln_dias_tot_periodo * ln_dias_tope_ano / an_dias_ano) ;
  
  if ln_dias_tot_periodo > ln_dias_tope_ano then ln_dias_tot_periodo := ln_dias_tope_ano; end if;
  
  if ln_dias_tot_periodo < 0 then ln_dias_tot_periodo := 0; end if;
  
  return(ln_dias_tot_periodo);
  
end usf_rh_dias_tot_util;
/
