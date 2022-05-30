create or replace procedure usp_cal_prov_vac_bonif
  ( as_codtra maestro.cod_trabajador%type,
    ad_fec_proceso rrhhparam.fec_proceso%type
   ) is

lk_vac_bonif        constant char(3) := '370';
lk_seccion          constant char(3) := '950';
lk_concep_vac       constant char(4) := '1413';
lk_concep_bonif     constant char(4) := '1414';
ld_fec_ingreso      maestro.fec_ingreso%type;
ld_fec_ingreso_l    maestro.fec_ingreso%type;
ln_dias             vacac_bonif_deveng.sldo_dias_vacacio%type;
ln_meses            vacac_bonif_deveng.sldo_dias_vacacio%type;
ln_dias_vac         number(8,2);
ln_dias_bonif       number(8,2);
ln_vacac            vacac_bonif_deveng.sldo_dias_vacacio%type;
ln_importe          gan_desct_fijo.imp_gan_desc%type;
ln_imp              gan_desct_fijo.imp_gan_desc%type;
ln_imp1             gratificacion.imp_bruto%type;
ln_imp2             gratificacion.imp_bruto%type;
ln_importe_vac      gan_desct_fijo.imp_gan_desc%type;
ln_importe_bonif    gan_desct_fijo.imp_gan_desc%type;
ln_periodo          vacac_bonif_deveng.periodo%type;
ls_flag             maestro.bonif_fija_30_25%type;
ls_dia_l            char(2);
ls_mes_l            char(2);
ls_year_l           char(4); 
  
--  Conceptos afectos al calculo de provsiones de vacaciones y bonificaciones
CURSOR c_prov IS    
  Select rhnd.concep
  from rrhh_nivel_detalle rhnd 
  where rhnd.cod_nivel = lk_vac_bonif;

BEGIN

Select sum(bd.sldo_dias_vacacio) as dias_vac ,
       sum(bd.sldo_dias_bonif) as dias_bonif 
  into ln_dias_vac, ln_dias_bonif 
  from vacac_bonif_deveng bd, maestro m 
  where bd.cod_trabajador = m.cod_trabajador and 
        m.cod_trabajador = as_codtra and 
        m.cod_seccion <> lk_seccion ;
 
ln_dias_vac := nvl(ln_dias_vac,0);
ln_dias_bonif := nvl(ln_dias_bonif,0);
 
IF ln_dias_vac <> 0 or ln_dias_bonif <> 0 Then

  ln_importe := 0;
  FOR rc_p IN c_prov LOOP
    Select sum(gdf.imp_gan_desc ) 
      into ln_imp
      from gan_desct_fijo gdf 
      where gdf.cod_trabajador = as_codtra and
            gdf.concep = rc_p.concep and
            gdf.flag_estado = '1' and
            gdf.flag_trabaj = '1' ;
    ln_imp     := nvl(ln_imp,0);    
    ln_importe := ln_importe + ln_imp ;  
  END LOOP;  
   
  Select m.bonif_fija_30_25, m.fec_ingreso
    into ls_flag , ld_fec_ingreso
    from  maestro m
    where m.cod_trabajador = as_codtra ;
   
  IF ls_flag = '1' THEN 
    ln_importe := ln_importe * 1.3;    
  END IF;
  IF ls_flag = '2' THEN   
    ln_importe := ln_importe *  1.25;  
  END IF; 
   
  --  Calculo del importe por Bonificacion Vacacional 
  ln_importe_bonif := ln_importe * ln_dias_bonif / 30;
  --  Determinamos el maximo valor para el periodo
  Select max(bd.periodo)
    into ln_periodo 
    from vacac_bonif_deveng bd 
    where bd.cod_trabajador = as_codtra;
   
  ln_periodo := nvl(ln_periodo,0);      
  IF ln_periodo > 0 THEN
    IF (ln_periodo - TO_CHAR(ad_fec_proceso,'YYYY') + 1 ) = 0 THEN
      Select bd.sldo_dias_vacacio
        Into ln_vacac
        From vacac_bonif_deveng bd
        Where bd.cod_trabajador = as_codtra and
              bd.periodo = ln_periodo ;
         
      IF ln_vacac <> 0 THEN
        --  Dias de Bonificaciones menos el Penultimo Periodo 
        ln_dias_vac := ln_dias_vac - ln_vacac;
        --  Determinamos los dias del Mes de vacaciones 
        ls_dia_l  := TO_CHAR(ld_fec_ingreso,'DD');
        ls_mes_l  := TO_CHAR(ld_fec_ingreso,'MM');
        ls_year_l := TO_CHAR(ad_fec_proceso,'YYYY');
          
        ld_fec_ingreso_l := TO_DATE(ls_dia_l||'/'||ls_mes_l||
                               '/'||ls_year_l,'DD/MM/YYYY');
        ln_dias := TO_CHAR(LAST_DAY(ld_fec_ingreso_l),'DD') - 
                      TO_CHAR(ld_fec_ingreso,'DD') + 1;
           
        IF ln_dias < 0 THEN
          ln_dias := 0;
        END IF;
              
        ln_meses := 12 - TO_CHAR(ld_fec_ingreso,'MM');
        ln_imp1  := ln_importe * ln_dias_vac / 30;
        ln_imp2  := ln_importe * ln_meses / 12 + ln_importe * ln_dias / 360;     
        ln_importe_vac := ln_imp1 + ln_imp2;        
      END IF ;

    ELSE  
      --  Importe de las Bonificaciones
      ln_importe_vac := ln_importe * ln_dias_vac / 30;    
         
    END IF;
   
  END IF;

  --  Insertar registro por Vacaciones
  INSERT INTO prov_vac_bonif 
    ( cod_trabajador , concep ,
      fec_proceso    , importe )
  VALUES 
    ( as_codtra , lk_concep_vac ,
      ad_fec_proceso  , ln_importe_vac );
      
  --  Insertar registro por Bonificacion
  INSERT INTO prov_vac_bonif 
    ( cod_trabajador , concep ,
      fec_proceso    , importe )
  VALUES 
    ( as_codtra , lk_concep_bonif ,
      ad_fec_proceso  , ln_importe_bonif );
   
  END IF;
  
END usp_cal_prov_vac_bonif;
/
