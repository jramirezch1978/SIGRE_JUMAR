create or replace procedure usp_rh_rpt_liquidacion_cts (
  as_tipo_trabaj in tipo_trabajador.tipo_trabajador%TYPE, 
  as_origen      in origen.cod_origen%TYPE, 
  ad_fec_proceso in date,
  ad_fec_desde   in date, 
  ad_fec_hasta   in date
) is

lk_ganancias_fijas        rrhhparam_cconcep.ganfij_provision_cts%TYPE ;
ls_codigo_emp             genparam.cod_empresa%type ;
ls_concepto               concepto.concep%TYPE ;
ls_desc_concepto          concepto.desc_concep%TYPE;
ls_empresa_nom            empresa.nombre%TYPE;
ls_empresa_dir            empresa.dir_calle%TYPE ;
ls_empresa_dis            empresa.dir_distrito%TYPE;

--  Lectura de trabajadores seleccionados
cursor c_maestro is
  select m.cod_trabajador, 
         m.fec_ingreso, 
         m.bonif_fija_30_25,
         s.cod_seccion,
         s.desc_seccion,
         SUBSTR(usf_rh_nombre_trabajador(m.cod_trabajador),1,40) as nombres,
         cts.dias_trabajados as dias_trabaj,
         cts.liquidacion as imp_cts
  from maestro m,
       seccion s,
       cts_decreto_urgencia cts
  where m.flag_estado     = '1'               
    and m.flag_cal_plnlla = '1'               
    and m.tipo_trabajador = as_tipo_trabaj    
    and m.cod_origen      = as_origen        
    and m.cod_trabajador       = cts.cod_trabajador
    and trunc(cts.fec_proceso) = trunc(ad_fec_proceso)
    and m.cod_area             = s.cod_area     (+)
    and m.cod_seccion          = s.cod_seccion  (+)
order by m.cod_seccion, m.cod_trabajador ;


begin

--  ***********************************************************************
--  ***   EMITE REPORTE DE LIQUIDACIONES DE C.T.S. A LOS TRABAJADORES   ***
--  ***********************************************************************

delete from tt_liq_cts ;

select p.cod_empresa into ls_codigo_emp from genparam p  where p.reckey = '1' ;

select e.nombre, e.dir_calle, e.dir_distrito  
  into ls_empresa_nom, ls_empresa_dir, ls_empresa_dis
  from empresa e
 where e.cod_empresa = ls_codigo_emp ;


select p.ganfij_provision_cts
  into lk_ganancias_fijas
  from rrhhparam_cconcep p where p.reckey = '1' ;



For rc_mae in c_maestro Loop


    --verificar tipo de cambio ha sido ingresado
    Insert Into tt_liq_cts
    (empresa_nom ,empresa_dir   ,empresa_dis ,fecha   ,
     fec_desde   ,fec_hasta     ,codigo      ,nombres ,
     seccion     ,desc_seccion  ,fec_ingreso ,dias    ,
     concepto    ,desc_concepto ,importe )
    Values
    (ls_empresa_nom     ,ls_empresa_dir       ,ls_empresa_dis        ,ad_fec_proceso     ,
     ad_fec_desde       ,ad_fec_hasta         ,rc_mae.cod_trabajador ,rc_mae.nombres     ,
     rc_mae.cod_seccion ,rc_mae.desc_seccion  ,rc_mae.fec_ingreso    ,rc_mae.dias_trabaj ,
     ls_concepto        ,ls_desc_concepto     ,rc_mae.imp_cts ) ;




End Loop ;

end usp_rh_rpt_liquidacion_cts ;
/
