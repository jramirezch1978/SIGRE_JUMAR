create or replace procedure USP_RH_FMT_RETENC_SNP_AFP(
       an_periodo           in cntbl_asiento.ano%type, 
       as_origen            in origen.cod_origen%type, 
       as_trabajador        in maestro.cod_trabajador%type, 
       ad_fec_proceso       in date,
       as_tipo              in maestro.flag_estado%type) is


CURSOR c_trabajador IS 
SELECT distinct(a.cod_trabajador), a.nombre, a.dni, a.nro_afp_trabaj
  FROM (SELECT ms.cod_trabajador, 
               TRIM(ms.apel_paterno)||' '||TRIM(ms.apel_materno)||', '||TRIM(ms.nombre1)||' '||TRIM(NVL(ms.nombre2,' ')) as nombre, 
               ms.dni, 
               ms.nro_afp_trabaj  
          FROM rrhh_formato_snp snp, maestro ms 
         WHERE snp.cod_trabajador = ms.cod_trabajador 
           AND snp.ano = an_periodo 
           AND snp.cod_origen = as_origen 
           AND snp.cod_trabajador LIKE as_trabajador 
        UNION
        SELECT ma.cod_trabajador, 
               TRIM(ma.apel_paterno)||' '||TRIM(ma.apel_materno)||', '||TRIM(ma.nombre1)||' '||TRIM(NVL(ma.nombre2,' ')) as nombre,         
               ma.dni, 
               ma.nro_afp_trabaj 
          FROM rrhh_formato_afp afp, maestro ma
         WHERE afp.cod_trabajador = ma.cod_trabajador 
           AND afp.ano = an_periodo 
           AND afp.cod_origen = as_origen 
           AND afp.cod_trabajador LIKE as_trabajador) a ;

ln_remuneracion           rrhh_formato_snp.valor_planilla%type ;
ln_retencion_snp          rrhh_formato_snp.valor_planilla%type ;
ln_comis_porc             rrhh_formato_snp.valor_planilla%type ;
ln_seguro_inv             rrhh_formato_snp.valor_planilla%type ;
ln_aporte_ind             rrhh_formato_snp.valor_planilla%type ;
ls_dni_cusp               maestro.nro_afp_trabaj%type; 
ls_comis_porc             concepto.concep%type ;
ls_seguro_inval           concepto.concep%type ;
ls_aporte_indiv           concepto.concep%type ;
ls_retenc_snp             concepto.concep%type ;
ls_grp_aport_afp          grupo_calculo.grupo_calculo%type ;
ls_grp_reten_snp          grupo_calculo.grupo_calculo%type ;
       
BEGIN

DELETE FROM tt_fmt_snp_afp ;

SELECT r.c_comis_porc, r.c_seguro_inval, r.c_aporte_indiv, r.c_retenc_snp, r.g_retenc_snp, r.g_aportac_afp 
  INTO ls_comis_porc, ls_seguro_inval, ls_aporte_indiv, ls_retenc_snp, ls_grp_reten_snp, ls_grp_aport_afp 
  FROM rrhhparam_snp_afp r WHERE r.reckey='1' ;

FOR c_tra IN c_trabajador LOOP

    -- Caso SNP
    IF as_tipo = 'S' THEN
       -- Calculando retención de SNP
       ln_remuneracion := USF_RH_REMUNER_SNP_AFP(an_periodo, as_origen,  c_tra.cod_trabajador, ls_grp_reten_snp) ;
       ln_retencion_snp := USF_RH_RETENC_SNP_AFP(an_periodo, as_origen, c_tra.cod_trabajador, ls_retenc_snp);
       ln_comis_porc    := 0 ;
       ln_seguro_inv    := 0 ;
       ln_aporte_ind    := 0 ;
       ls_dni_cusp      := c_tra.dni ;
    END IF ;

    -- Caso AFP
    IF as_tipo = 'A' THEN
       ln_remuneracion := USF_RH_REMUNER_SNP_AFP(an_periodo, as_origen,  c_tra.cod_trabajador, ls_grp_aport_afp) ;
       ln_retencion_snp := 0 ;
       ln_comis_porc    := USF_RH_RETENC_SNP_AFP(an_periodo, as_origen, c_tra.cod_trabajador, ls_comis_porc);
       ln_seguro_inv    := USF_RH_RETENC_SNP_AFP(an_periodo, as_origen, c_tra.cod_trabajador, ls_seguro_inval);
       ln_aporte_ind    := USF_RH_RETENC_SNP_AFP(an_periodo, as_origen, c_tra.cod_trabajador, ls_aporte_indiv);
       ls_dni_cusp      := c_tra.nro_afp_trabaj; 
    END IF ;

    INSERT INTO tt_fmt_snp_afp(ejercicio, cod_trabajador, 
                               nombre, cod_origen, 
                               fec_proceso, dni_cusp, 
                               imp_retencion, total_retenc_snp, 
                               total_comis_porc, total_seguro_inv, 
                               total_aporte_indiv, tipo_fmt) 
    VALUES( an_periodo, c_tra.cod_trabajador, 
            c_tra.nombre, as_origen, 
            ad_fec_proceso, ls_dni_cusp, 
            ln_remuneracion, ln_retencion_snp, 
            ln_comis_porc, ln_seguro_inv, 
            ln_comis_porc, as_tipo) ;

END LOOP ;
 
commit ;

end USP_RH_FMT_RETENC_SNP_AFP;
/
