create or replace procedure usp_rh_insert_dist_ctbl
(ac_cod_trabajador in maestro.cod_trabajador%type    ,
 ac_cencos         in centros_costo.cencos%type      ,
 ad_fecha          in date                           ,
 ac_labor          in labor.cod_labor%type           ,
 ac_usuario        in usuario.cod_usr%type           ,
 an_horas          in pd_ot_asistencia.nro_horas%type,
 ad_fec_proceso    in date                           ,
 ac_centro_benef   in distribucion_cntble.centro_benef%type,
 asi_origen        in origen.cod_origen%TYPE,
 asi_tipo_trabaj   in tipo_trabajador.tipo_trabajador%TYPE
 ) is


begin

Insert Into distribucion_cntble(
       cod_trabajador ,cencos ,fec_movimiento ,cod_labor ,cod_usr ,nro_horas ,fec_calculo ,centro_benef, 
       cod_origen, tipo_trabajador )
values(
       ac_cod_trabajador,ac_cencos ,ad_fecha ,ac_labor ,ac_usuario ,an_horas ,ad_fec_proceso , 
       ac_centro_benef, asi_origen, asi_tipo_trabaj ) ;

end usp_rh_insert_dist_ctbl ;
/
