create or replace procedure usp_rh_asiento_prov_cts(
       asi_origen      in origen.cod_origen%type ,
       asi_ttrab       in tipo_trabajador.tipo_trabajador%type ,
       asi_usuario     in usuario.cod_usr%type   ,
       adi_fec_proceso in date                                  
) is

ls_soles           moneda.cod_moneda%type           ;
ln_tcambio         calendario.cmp_dol_libre%type    ;
ln_nro_libro       cntbl_libro.nro_libro%type       ;
ls_des_libro       cntbl_libro.desc_libro%type      ;
ln_num_provisional cntbl_libro.num_provisional%type ;
ls_cnta_debe       cntbl_cnta.cnta_ctbl%type        ;
ls_cnta_haber      cntbl_cnta.cnta_ctbl%type        ;
ls_flag_ctrl_deb   Char(1)                          ;
ln_item            Number                           ;
ln_tot_sum_soldeb  Number (13,2)                    ;
ln_tot_sum_doldeb  Number (13,2)                    ;
ln_tot_sum_solhab  Number (13,2)                    ;
ln_tot_sum_dolhab  Number (13,2)                    ;


--  Personal activo para generacion de asientos
Cursor c_cts_mensual is
select m.cod_trabajador, m.tipo_trabajador, m.cencos,d.liquidacion as imp_soles,
       Round(d.liquidacion / ln_tcambio,2) as imp_dolar,m.centro_benef
  from maestro m, cts_decreto_urgencia d
 where (m.cod_trabajador     = d.cod_trabajador     ) and
       (m.cod_origen         = asi_origen            ) and
       (m.tipo_trabajador    = asi_ttrab             ) and
       (d.liquidacion        <> 0                   ) and
       (trunc(d.fec_proceso) = trunc(adi_fec_proceso))
order by m.cod_seccion, m.cencos, m.cod_trabajador ;


begin


--inicializacion
ln_tot_sum_soldeb := 0.00 ;
ln_tot_sum_doldeb := 0.00 ;
ln_tot_sum_solhab := 0.00 ;
ln_tot_sum_dolhab := 0.00 ;

--eliminacion de tabla temporal
delete from TT_RH_INC_ASIENTOS ;


--parametros de moneda
select l.cod_soles into ls_soles from logparam l where l.reckey = '1' ;


--RECUPERO TIPO DE CAMBIO DE ACUERDO A FECHA DE PROCESO
ln_tcambio := usf_fin_tasa_cambio(adi_fec_proceso) ;

if ln_tcambio = 0 then
   Raise_Application_Error(-20000,'Fecha de Proceso No tiene tipo de Cambio ,Comuniquese con Contabilidad!') ;
end if ;

--Recupero nro de libro de cts por tipo de trbajador
select t.cnta_ctbl_cts_cargo,t.cnta_ctbl_cts_abono,t.libro_prov_cts ,cl.desc_libro ,cl.num_provisional
  into ls_cnta_debe,ls_cnta_haber ,ln_nro_libro ,ls_des_libro,ln_num_provisional
  from tipo_trabajador t,cntbl_libro cl
 where (t.libro_prov_cts  = cl.nro_libro (+)) and
       (t.tipo_trabajador = asi_ttrab        ) ;

if ln_nro_libro is null or ln_nro_libro = 0 then
   Raise_Application_Error(-20000,'Nro de Libro no esta Asignado al tipo de trabajador ,Comuniquese con RRHH!') ;
end if ;

if ls_des_libro is null then
   Raise_Application_Error(-20000,'Descripcion de Libro no existe ,Comuniquese con Contabilidad!') ;
end if ;

if ln_num_provisional is null  then
   ln_num_provisional := 1 ;
end if ;

ls_flag_ctrl_deb := '1'                    ; --controlador en caso sean importes negativos 1 = positivo
                                                 --                                            0 = negativo

--  Elimina movimiento de asiento contable generado
usp_cnt_borrar_pre_asiento( asi_origen, ln_nro_libro, adi_fec_proceso, adi_fec_proceso) ;



--inserta asiento unico de cabecera
Insert Into cntbl_pre_asiento
(origen     ,nro_libro  ,nro_provisional ,cod_moneda ,tasa_cambio ,
 desc_glosa ,fec_cntbl  ,fec_registro    ,cod_usr    ,flag_estado ,
 tot_soldeb ,tot_solhab ,tot_doldeb      ,tot_dolhab)
Values
(asi_origen    ,ln_nro_libro  ,ln_num_provisional ,ls_soles  ,ln_tcambio,
 ls_des_libro ,adi_fec_proceso,adi_fec_proceso     ,asi_usuario,'1'       ,
 0.00         ,0.00          ,0.00               ,0.00);

--contador de detalles de pre asientos
ln_item := 0 ;

For rc_cts in c_cts_mensual Loop

/*
create or replace procedure USP_RH_INSERT_ASIENTO(
       adi_fec_proceso    in date                                   ,
       asi_origen         in origen.cod_origen%type                 ,
       asi_cencos         in centros_costo.cencos%type              ,
       asi_cnta_ctbl      in cntbl_cnta.cnta_ctbl%type              ,
       asi_tipo_doc       in doc_tipo.tipo_doc%type                 ,
       asi_nro_doc        in calculo.nro_doc_cc%type                ,
       asi_cod_relacion   in cntbl_asiento_det.cod_relacion%TYPE   ,
       asi_flag_ctrl_debh in cntbl_asiento_det.flag_debhab%TYPE     ,
       asi_flag_debhab    in cntbl_asiento_det.flag_debhab%TYPE     ,                                   
       ani_nro_libro      in cntbl_libro.nro_libro%type             ,
       asi_desc_libro     in cntbl_libro.desc_libro%type            ,
       ani_item           in out cntbl_pre_asiento_det.item%type    ,
       ani_num_prov       in cntbl_libro.num_provisional%type       ,
       ani_imp_soles      in cntbl_pre_asiento_det.imp_movsol%type  ,
       ani_imp_dolares    in cntbl_pre_asiento_det.imp_movsol%type  ,
       asi_cbenef         in maestro.centro_benef%type              ,
       asi_cod_trabajador in maestro.cod_trabajador%TYPE            
) is
*/
    --INSERTA ASIENTO
    USP_RH_INSERT_ASIENTO(adi_fec_proceso        ,asi_origen              ,rc_cts.cencos ,ls_cnta_debe ,null         ,null    ,
                          rc_cts.cod_trabajador ,ls_flag_ctrl_deb       ,'D'          ,ln_nro_libro  ,ls_des_libro ,ln_item ,
                          ln_num_provisional  ,Abs(rc_cts.imp_soles) ,Abs(rc_cts.imp_dolar)   , null,
                          rc_cts.centro_benef, rc_cts.cod_trabajador);


    --INSERTA ASIENTO
    USP_RH_INSERT_ASIENTO(adi_fec_proceso        ,asi_origen              ,rc_cts.cencos ,ls_cnta_haber ,null         ,null    ,
                          rc_cts.cod_trabajador ,ls_flag_ctrl_deb       ,'H'          ,ln_nro_libro  ,ls_des_libro ,ln_item ,
                          ln_num_provisional  ,Abs(rc_cts.imp_soles) ,Abs(rc_cts.imp_dolar)   , null,
                          rc_cts.centro_benef, rc_cts.cod_trabajador);
End Loop;


--INSERTA TOTALES DE ASIENTO
--suma total de detalle del debe
select Sum(cpad.imp_movsol),Sum(cpad.imp_movdol) into ln_tot_sum_soldeb,ln_tot_sum_doldeb from cntbl_pre_asiento_det cpad
 where (cpad.origen          = asi_origen         ) and
       (cpad.nro_libro       = ln_nro_libro      ) and
       (cpad.flag_debhab     = 'D'               ) and
       (cpad.nro_provisional = ln_num_provisional) ;



--suma total de detalle del haber
select Sum(cpad.imp_movsol),Sum(cpad.imp_movdol) into ln_tot_sum_solhab,ln_tot_sum_dolhab from cntbl_pre_asiento_det cpad
 where (cpad.origen          = asi_origen         ) and
       (cpad.nro_libro       = ln_nro_libro      ) and
       (cpad.flag_debhab     = 'H'               ) and
       (cpad.nro_provisional = ln_num_provisional) ;


--Actualiza totales de asiento
Update cntbl_pre_asiento cpa
  set cpa.tot_soldeb = ln_tot_sum_soldeb,cpa.tot_solhab = ln_tot_sum_solhab ,
      cpa.tot_doldeb = ln_tot_sum_doldeb,cpa.tot_dolhab = ln_tot_sum_dolhab
 where (cpa.origen          = asi_origen         ) and
       (cpa.nro_libro       = ln_nro_libro      ) and
       (cpa.nro_provisional = ln_num_provisional) ;




--ACTUALIZA NUMERADOR DE LIBRO CONTABLE
--incrementa contador de Asiento
ln_num_provisional := ln_num_provisional + 1 ;

Update cntbl_libro cl
   set cl.num_provisional = ln_num_provisional
 Where (cl.nro_libro = ln_nro_libro ) ;



end usp_rh_asiento_prov_cts ;
/
