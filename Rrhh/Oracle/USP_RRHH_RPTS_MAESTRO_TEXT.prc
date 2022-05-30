CREATE OR REPLACE PROCEDURE USP_RRHH_RPTS_MAESTRO_TEXT
       ( AN_YEAR            IN RRHH_HIST_MAESTRO.ANO%TYPE,
         AN_MES             IN RRHH_HIST_MAESTRO.MES%TYPE,
         AS_COD_ORIGEN      IN VARCHAR2 ,
         AS_FLAG_REPROCESO  IN VARCHAR2)
         
IS  
    --Declaracion de variables
    ln_count      NUMBER(4);
    ls_cadena     VARCHAR(4000);
    
    -- Variables para fechas
    ls_fec_nac        VARCHAR(11);
    ls_fec_baja       VARCHAR(11);
    ls_fec_regimen    VARCHAR(11);
    
    --Variables para controlar el ubigeo
    ls_ubigeo        VARCHAR(6);

        
      -- Cursor para crear Archivo de Texto
      CURSOR C_MAESTRO_TEXT IS
        SELECT   M.TIPO_DOC_IDENT_RTPS,
                 M.NRO_DOC_IDENT_RTPS,                      
                 M.APEL_PATERNO,
                 M.APEL_MATERNO,
                 M.NOMBRE1 || ' ' || NVL(M.NOMBRE2, '') AS NOMBRE,
                 MH.FLAG_CATEGORIA,
                 M.FLAG_PENSIONISTA,
                 MH.TIPO_PENSION,
                 M.FEC_NACIMIENTO,
                 M.FLAG_SEXO,
                 MH.TELEFONO,
                 MH.FLAG_REGIMEN,
                 MH.SITUACION_EPS,
                 MH.TIPO_TRABAJADOR,
                 MH.FECHA_BAJA,
                 MH.COD_EPS,
                 MH.ESSALUD_VIDA,
                 MH.COD_REG_PENSION,
                 MH.CUSPP,
                 MH.FLAG_SCTR,
                 MH.FLAG_SCTR_PENSION,
                 MH.FEC_REGIMEN_INS,
                 M.COD_PAIS,
                 MH.FLAG_DISCAPACIDAD,
                 M.EMAIL,
                 MH.COD_BANCO_RTPS,
                 MH.TIPO_CUENTA_DEP,
                 MH.NRO_CUENTA,
                 MH.FLAG_PERIOCIDAD,
                 MH.FLAG_TIPO_REMUNE,
                 M.FLAG_SUJETO_CONTROL_,
                 MH.FLAG_SINDICATO,
                 MH.NIVEL_EDUCATIVO,
                 MH.OCUPACION,
                 MH.TIPO_CONTRATO,
                 MH.ESTADO_CIVIL,
                 MH.FLAG_DOMICILIADO,
                 M.RUC,
                 MH.DOM_TIPO_VIA,
                 MH.DOM_NOMBRE_VIA,
                 MH.DOM_NRO_VIA,
                 MH.DOM_INTERIOR,
                 MH.DOM_TIPO_ZONA,
                 MH.DOM_NOMBRE_ZONA,
                 MH.DOM_REFERENCIA,
                 MH.DOM_UBIGEO,
                 DECODE(MH.FLAG_CATEGORIA,'3', E.RUC, '4', E.RUC, NULL) AS RUC_EMPRESA, 
                 SUBSTR(NVL(M.COD_DPTO_NAC,'  '),1,2) || SUBSTR(NVL(M.COD_PROV_NAC,'  '),1,2) || SUBSTR(NVL(M.COD_DIST_NAC,'  '),1,2) AS MUNICIPALIDAD                  
        FROM     RRHH_HIST_MAESTRO           MH,
                 MAESTRO                     M,
                 EMPRESA                     E
        WHERE    MH.COD_TRABAJADOR = M.COD_TRABAJADOR
           AND   MH.COD_EMPRESA    = E.COD_EMPRESA (+)
           AND   MH.ANO = an_year
           AND   MH.MES = an_mes
           AND   INSTR(as_cod_origen, M.COD_ORIGEN) > 0 
        
        ORDER BY M.APEL_PATERNO, M.APEL_MATERNO;
        
    
     -- Cursor para llenar tabla historica.
    CURSOR C_MAESTRO_HIST IS
          SELECT   M.COD_TRABAJADOR,
                   M.FLAG_CAT_TRAB,
                   M.FLAG_PENSIONISTA,
                   M.COD_TIPO_PENSION,
                   M.TELEFONO1,
                   M.FLAG_REG_LABORAL,
                   M.COD_SIT_EPS,
                   M.COD_TIP_TRAB,
                   M.FEC_CESE,
                   M.COD_EPS,
                   M.FLAG_ESSALUD_VIDA,
                   M.COD_REG_PENSION,
                   M.NRO_AFP_TRABAJ,
                   M.FLAG_SCTR_SALUD,
                   M.FLAG_SCTR_PENSION,
                   M.FEC_INSCRIP_REG,
                   M.FLAG_DISCAPACIDAD,
                   B.COD_BANCO_RTPS,
                   M.TIPO_CNTA_HABERES,
                   M.NRO_CNTA_AHORRO,
                   SUBSTR(M.COD_PERIOCIDAD_REM, 2,1) AS COD_PERIOCIDAD_REM ,
                   M.FLAG_TIPO_REMUN_RTPS,
                   M.Flag_Sujeto_Control_,
                   M.FLAG_SINDICATO,
                   M.COD_GRADO_INST,
                   M.COD_OCUPACION_RTPS,
                   M.COD_TIPO_CONTRATO,
                   M.COD_ESTADO_CIVIL,
                   M.FLAG_DOMICILIADO,
                   M.RUC, 
                   M.COD_VIA,
                   M.NOMBRE_VIA,
                   M.NUMERO_VIA,
                   M.INTERIOR,
                   M.COD_ZONA,
                   M.NOMBRE_ZONA,
                   M.REFERENCIA, 
                   M.COD_EMPRESA, 
                   SUBSTR(NVL(M.COD_DPTO,'  '),1,2) || SUBSTR(NVL(M.COD_PROV,'  '),1,2) || SUBSTR(NVL(M.COD_DISTR,'  '),1,2) AS UBIGEO
          FROM     MAESTRO                     M,
                   EMPRESA                     E, 
                   BANCO                       B
          WHERE    M.COD_EMPRESA = E.COD_EMPRESA (+) 
             AND   M.COD_BANCO = B.COD_BANCO (+)
             AND   M.FLAG_ESTADO = '1'
             AND   INSTR(as_cod_origen, M.COD_ORIGEN) > 0 ;

BEGIN 
  
     -- Verifico que existan datos en tabla historica de acuerdo al origen 
     SELECT COUNT(*)
         INTO  ln_count
     FROM   RRHH_HIST_MAESTRO A,
            MAESTRO           M
     WHERE  A.COD_TRABAJADOR = M.COD_TRABAJADOR
        AND A.ANO = AN_YEAR
        AND A.MES = AN_MES
        AND INSTR(as_cod_origen, M.COD_ORIGEN) > 0 ;

     -- Si flag_Reproceso = '1' 
     IF AS_FLAG_REPROCESO = '1' AND ln_count > 0 THEN
        DELETE FROM RRHH_HIST_MAESTRO
        WHERE  ANO = AN_YEAR
          AND  MES = AN_MES
          AND  COD_TRABAJADOR IN (SELECT COD_TRABAJADOR FROM MAESTRO M WHERE INSTR(as_cod_origen, M.COD_ORIGEN) > 0 ); 
     END IF;
     
     -- Si no existen datos en rrhh_hist se llenan OR si flag_reproceso = 1
     IF ln_count = 0 OR AS_FLAG_REPROCESO = '1' THEN
     
         FOR r_h IN C_MAESTRO_HIST LOOP
          --Controlo el ubigeo
          IF LENGTH(r_h.ubigeo) > 6 THEN
             ls_ubigeo := '      ' ;
          ELSE
             ls_ubigeo := r_h.ubigeo ;   
          END IF;
          
          INSERT INTO RRHH_HIST_MAESTRO 
            (ANO,             MES,                COD_TRABAJADOR,  FLAG_CATEGORIA,    TIPO_PENSION,
             RUC,             TELEFONO,           FLAG_REGIMEN,    SITUACION_EPS,     TIPO_TRABAJADOR,  
             FECHA_BAJA,      COD_EPS,            ESSALUD_VIDA,    COD_REG_PENSION,   CUSPP,          
             FLAG_SCTR,       FLAG_SCTR_PENSION,  FEC_REGIMEN_INS, FLAG_DISCAPACIDAD, COD_BANCO_RTPS,   
             TIPO_CUENTA_DEP, NRO_CUENTA,         FLAG_PERIOCIDAD, FLAG_TIPO_REMUNE,  FLAG_SUJETO_CONTROL, 
             FLAG_SINDICATO,  NIVEL_EDUCATIVO,    OCUPACION,       TIPO_CONTRATO,     ESTADO_CIVIL,    
             FLAG_DOMICILIADO,DOM_TIPO_VIA,       DOM_NOMBRE_VIA,  DOM_NRO_VIA,       DOM_INTERIOR,    
             DOM_TIPO_ZONA,   DOM_NOMBRE_ZONA,    DOM_REFERENCIA,  DOM_UBIGEO,        FLAG_PENSIONISTA, 
             COD_EMPRESA)
              VALUES  
            (an_year, an_mes, r_h.cod_Trabajador, nvl(r_h.flag_cat_trab, '0'), r_h.cod_tipo_pension, 
             r_h.ruc, r_h.telefono1, nvl(r_h.flag_reg_laboral, '0'), r_h.cod_sit_eps, r_h.cod_tip_trab, 
             r_h.fec_cese, r_h.cod_eps, r_h.flag_essalud_vida, r_h.cod_reg_pension, r_h.nro_afp_trabaj, 
             NVL(r_h.flag_sctr_salud, '0'), NVL(r_h.flag_sctr_pension, '0'), r_h.fec_inscrip_reg, nvl(r_h.flag_discapacidad, '0'), r_h.cod_banco_rtps, 
             r_h.tipo_cnta_haberes, r_h.nro_cnta_ahorro, NVL(r_h.cod_periocidad_rem, '0'), r_h.flag_tipo_remun_rtps, nvl(r_h.flag_sujeto_control_,'0'), 
             nvl(r_h.flag_sindicato, '0'), r_h.cod_grado_inst, r_h.cod_ocupacion_rtps, r_h.cod_tipo_contrato, r_h.cod_estado_civil,
             r_h.flag_domiciliado, r_h.cod_via, r_h.nombre_via, r_h.numero_via, r_h.interior, 
             r_h.cod_zona, r_h.nombre_zona, r_h.referencia, ls_ubigeo, r_h.flag_pensionista, 
             r_h.cod_empresa ) ;
         END LOOP;
      END IF;
      
     -- Eliminiar los datos de la tabla tmporal
     DELETE FROM TT_DATOS_TRABAJADOR_RTPS ; 
     -- Llenar la tabla temporal con datos     
     FOR r_t IN C_MAESTRO_TEXT LOOP
         IF r_t.fec_nacimiento IS NULL THEN
            ls_fec_nac := '          ';
         ELSE
            ls_fec_nac := to_char(r_t.fec_nacimiento,'dd/mm/yyyy');
         END IF;
         IF r_t.fecha_baja IS NULL THEN
            ls_fec_baja := '          ';
         ELSE
            ls_fec_baja := TO_CHAR(r_t.fecha_baja, 'dd/mm/yyyy');
         END IF;
         IF r_t.fec_regimen_ins IS NULL THEN
            ls_fec_regimen := '          ';
         ELSE
            ls_fec_regimen :=  TO_CHAR(r_t.fec_regimen_ins, 'dd/mm/yyyy') ;
         END IF;
         
         ls_cadena := RPAD(NVL(R_T.TIPO_DOC_IDENT_RTPS, ' '), 2) || '|' || RPAD(NVL(r_t.nro_doc_ident_rtps, ' '), 15) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.apel_paterno, ' '), 20) || '|' || RPAD(NVL(r_t.apel_materno, ' '), 20)|| '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.nombre, ' '), 20) || '|' || RPAD(NVL(r_t.flag_categoria, ' '), 1 ) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.flag_pensionista, ' '), 1) || '|' || RPAD(NVL(r_t.tipo_pension, ' '), 1)  || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.ruc_empresa, ' '), 11) || '|' || ls_fec_nac || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.flag_sexo, ' '), 1) || '|' || RPAD(NVL(r_t.telefono, ' '), 8) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.flag_regimen, ' '), 1) || '|' || RPAD(NVL(r_t.situacion_eps, ' '), 2) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.tipo_trabajador, ' '), 2) || '|' || ls_fec_baja || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.cod_eps, ' '), 1) || '|' || RPAD(NVL(r_t.essalud_vida, ' '), 1) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.cod_reg_pension, ' '), 2) || '|' || RPAD(NVL(r_t.cuspp, ' '), 12) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.flag_sctr, ' '), 1) || '|' || RPAD(NVL(r_t.flag_sctr_pension, ' '), 1) || '|' ;
         ls_cadena := ls_cadena || ls_fec_regimen || '|' || RPAD(NVL(r_t.cod_pais, ' '), 4) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.flag_discapacidad, ' '), 1) || '|' || RPAD(NVL(r_t.email, ' '), 50) || '|' ;         
         ls_cadena := ls_cadena || RPAD(NVL(r_t.cod_banco_rtps, ' '), 2) || '|' || RPAD(NVL(r_t.tipo_cuenta_dep, ' '), 1) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.nro_cuenta, ' '), 24) || '|' || RPAD(NVL(r_t.flag_periocidad, ' '), 1) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.flag_tipo_remune, ' '), 1) || '|' || RPAD(NVL(r_t.flag_sujeto_control_, ' '), 1) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.flag_sindicato, ' '), 1) || '|' || RPAD(NVL(r_t.municipalidad, ' '), 6) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.nivel_educativo, ' '), 2) || '|' || RPAD(NVL(r_t.ocupacion, ' '), 6) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.tipo_contrato, ' '), 2) || '|' || RPAD(NVL(r_t.estado_civil, ' '), 1) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.flag_domiciliado, ' '), 1) || '|' || RPAD(NVL(r_t.ruc, ' '), 11) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.dom_tipo_via, ' '), 2) || '|' || RPAD(NVL(r_t.dom_nombre_via, ' '), 20) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.dom_nro_via, ' '), 4) || '|' || RPAD(NVL(r_t.dom_interior, ' '), 4) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.dom_tipo_zona, ' '), 2) || '|' || RPAD(NVL(r_t.dom_nombre_zona, ' '), 20) || '|' ;
         ls_cadena := ls_cadena || RPAD(NVL(r_t.dom_referencia, ' '), 40) || '|' || RPAD(NVL(r_t.dom_ubigeo, ' '), 6) ;
         INSERT INTO TT_DATOS_TRABAJADOR_RTPS (ROW_EXP )
                VALUES (ls_cadena) ;
     END LOOP;  
  
  COMMIT;
  
END  USP_RRHH_RPTS_MAESTRO_TEXT;
/
