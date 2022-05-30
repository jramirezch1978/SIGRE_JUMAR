create or replace procedure usp_mm_actualiza_cts_tablas (
  ad_fec_proceso in date ) is

ln_cts_soles     number ;
ln_haber_basico  number ;
ln_inc_afp_3     number ;
ln_asig_fam      number ;
ln_prom_gratif   number ;
ln_asig_vacac    number ;
ln_prom_he       number ;
ln_prom_btn      number ;
ln_destajo      number ;

--  Lectura de data historica de CTS
CURSOR c_data_cts is
SELECT m.cod_trabajador, m.dni, 
       trim(m.apel_paterno)||' '||trim(m.apel_materno)||', '||trim(m.nombre1)||' '||trim(nvl(m.nombre2,' ')) nombre, 
       m.cencos, '02' lugar_cts, 
       decode(hg.cod_origen,'LM','16','CN','17', 'SP', '18', 'PS', '19') lugar_proceso_cts, 
       decode(hg.moneda_cts,'S/.','01','02'), 
       hg.tipo_trabajador, hg.banco_cts, hg.nro_cuenta_cts, 
       0 tasa_int_cts, 
       0 dias_atras, 
       hg.dias_asist, 
       sum(hd.monto) rem_comp
  FROM hist_prov_cts_gratif hg, hist_prov_cts_det hd, maestro m  
 WHERE hg.fecha_proceso=hd.fecha_proceso and 
       hg.cod_trabajador=hd.cod_trabajador and 
       hg.cod_trabajador=m.cod_trabajador and 
       hd.cod_trabajador=m.cod_trabajador 
GROUP BY m.cod_trabajador, 
         m.dni, 
         trim(m.apel_paterno)||' '||trim(m.apel_materno)||', '||trim(m.nombre1)||' '||trim(nvl(m.nombre2,' ')), 
       m.cencos, '02' , 
       decode(hg.cod_origen,'LM','16','CN','17', 'SP', '18', 'PS', '19'), 
       decode(hg.moneda_cts,'S/.','01','02'), 
       hg.tipo_trabajador, hg.banco_cts, hg.nro_cuenta_cts, 
       0 , 
       0 , 
       hg.dias_asist ;

BEGIN 

--  **********************************
--  ***   ACTUALIZACION DE DATA   ***
--  **********************************

FOR c_cts IN c_data_cts LOOP
    ln_cts_soles := (c_cts.rem_comp / 360) * c_cts.dias_asist ;
    ln_haber_basico := usf_rh_calc_cts_concepto(ad_fec_proceso, c_cts.cod_trabajador, '1001') ;
    ln_inc_afp_3 := usf_rh_calc_cts_concepto(ad_fec_proceso, c_cts.cod_trabajador, '1002') ;
    ln_asig_fam := usf_rh_calc_cts_concepto(ad_fec_proceso, c_cts.cod_trabajador, '1003') ;
    ln_prom_he := USF_RH_CALC_CTS_CALCULO(ad_fec_proceso, c_cts.cod_trabajador, 20) ;
    ln_destajo := 0; --USF_RH_CALC_CTS_CALCULO(ad_fec_proceso, c_cts.cod_trabajador, 30) ;
    ln_prom_gratif := USF_RH_CALC_CTS_CALCULO(ad_fec_proceso, c_cts.cod_trabajador, 40) ;
    ln_prom_btn := USF_RH_CALC_CTS_CALCULO(ad_fec_proceso, c_cts.cod_trabajador, 50) ;
    
    -- Instartando datos 
    INSERT INTO TT_HAYDUK_CTS(COD_TRABAJADOR, DNI, NOMBRE, PERIODO, LUGAR_CTS, 
           LUGAR_PROCESO_CTS, Tipo_Planilla, DIAS_TRAB, REMUN_COMPUT, CTS_SOLES,
           HABER_BASICO, INC_AFP_3, ASIG_ALIM, ASIG_FAM, PROM_GRATIF, 
           ASIG_VACAC, PROM_HE, PROM_BTN, BANCO_CTS, NRO_CUENTA_BCO_CTS,
           TASA_INT_CTS, DIAS_ATRASADOS) 
    VALUES(c_cts.cod_trabajador, c_cts.dni, c_cts.nombre, c_cts.lugar_cts, c_cts.lugar_cts, 
           c_cts.lugar_proceso_cts, c_cts.tipo_trabajador, c_cts.dias_asist, c_cts.rem_comp, ln_cts_soles, 
           ln_haber_basico, ln_inc_afp_3, 0, ln_asig_fam, ln_prom_gratif, 
           0, ln_prom_he, ln_prom_btn, c_cts.banco_cts, c_cts.nro_cuenta_cts, 
           0, 0) ;
    
END LOOP ;

END usp_mm_actualiza_cts_tablas ;
/
