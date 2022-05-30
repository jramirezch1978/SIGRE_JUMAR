CREATE OR REPLACE Procedure USP_RH_ASIST_COSTO(
       adi_fecha1           in DATE,
       adi_fecha2           IN DATE

) Is

ln_basico              rrhh_obr_costo_diario.imp_hor_diu_nor%TYPE;                    
ln_bas_dia             rrhh_obr_costo_diario.imp_hor_diu_nor%TYPE;
ln_bas_hor             rrhh_obr_costo_diario.imp_hor_diu_nor%TYPE;                    
ln_asig_fam            rrhh_obr_costo_diario.imp_hor_diu_nor%TYPE;
ls_conc_basico         concepto.concep%type;            
ls_conc_asig_fam       concepto.concep%type;
ls_cod_trabajador      maestro.cod_trabajador%type;     
ln_porc_diu_hor_norm   Number;
ln_porc_diu_hor_ext1   Number;                          
ln_porc_diu_hor_ext2   Number;
ln_porc_noc_hor_norm   Number;                          
ln_porc_noc_hor_ext1   Number;
ln_porc_noc_hor_ext2   Number;                          
ls_conc_aport          concepto.concep%type;
ln_porc_aportes        Number;

ln_imp_diu_hor_norm    rrhh_obr_costo_diario.imp_hor_diu_nor%TYPE;
ln_imp_diu_hor_ext1    rrhh_obr_costo_diario.imp_hor_diu_ext1%TYPE;
ln_imp_diu_hor_ext2    rrhh_obr_costo_diario.imp_hor_diu_ext2%TYPE;
ln_imp_noc_hor_norm    rrhh_obr_costo_diario.imp_hor_noc_nor%TYPE;
ln_imp_noc_hor_ext1    rrhh_obr_costo_diario.imp_hor_noc_ext1%TYPE;
ln_imp_noc_hor_ext2    rrhh_obr_costo_diario.imp_hor_noc_ext2%TYPE;
ln_imp_domin           rrhh_obr_costo_diario.imp_dominical%TYPE;
ln_imp_asig_fam        rrhh_obr_costo_diario.imp_asig_fam%TYPE;
ln_imp_rem_total       rrhh_obr_costo_diario.imp_asig_fam%TYPE;
ln_imp_vacac           rrhh_obr_costo_diario.imp_vacaciones%TYPE;
ln_imp_cts             rrhh_obr_costo_diario.imp_cts%TYPE;
ln_imp_afec_afp        rrhh_obr_costo_diario.imp_asig_fam%TYPE;
ln_imp_afp_jub         rrhh_obr_costo_diario.imp_afp_jub%TYPE;
ln_imp_afp_inval       rrhh_obr_costo_diario.imp_afp_inval%TYPE;
ln_imp_afp_com         rrhh_obr_costo_diario.imp_afp_comis%TYPE;
ln_imp_gratificacion   rrhh_obr_costo_diario.imp_gratificacion%TYPE;
ln_imp_aportacion      rrhh_obr_costo_diario.imp_aportacion%TYPE;

ln_count_reg_dia       Number;

Cursor c_trabajador IS
  Select DISTINCT a.cod_trabajador, m.cod_afp, af.porc_jubilac, af.porc_invalidez,
         decode(m.flag_comision_afp, '1', af.porc_comision1, af.porc_Comision2) as porc_comision

    From asistencia a,
         maestro m,
         admin_afp af
   Where a.cod_trabajador = m.cod_trabajador
     and m.cod_afp = af.cod_afp(+)
     and trunc(a.fec_movim) BETWEEN trunc(adi_fecha1) AND trunc(adi_fecha2);

Cursor c_asistencia Is
  Select a.cod_trabajador, trunc(a.fec_movim) AS fecha, a.flag_feriado, a.flag_descanso, a.flag_1mayo,
         Sum(a.hor_diu_nor) as hor_diu_nor,  Sum(a.hor_ext_diu_1) as hor_ext_diu_1,
         Sum(a.hor_ext_diu_2) as hor_ext_diu_2, Sum(a.hor_noc_nor) as hor_noc_nor ,
         Sum(a.hor_ext_noc_1) as hor_ext_noc_1, Sum(a.hor_ext_noc_2) as hor_ext_noc_2,
         Sum((Nvl(a.hor_diu_nor,0) + Nvl(a.hor_noc_nor,0))) as hor_trabaj
    From asistencia a
   Where trunc(a.fec_movim) BETWEEN trunc(adi_fecha1) AND trunc(adi_fecha2)
     and a.cod_trabajador = ls_cod_trabajador
   Group by a.cod_trabajador, trunc(a.fec_movim),a.flag_feriado, a.flag_descanso, a.flag_1mayo
   Order by a.cod_trabajador, trunc(a.fec_movim);

Begin

 ln_porc_diu_hor_norm   := 0;    ln_porc_diu_hor_ext1 := 0;   ln_porc_diu_hor_ext2  := 0;
 ln_porc_noc_hor_norm   := 0;    ln_porc_noc_hor_ext1 := 0;   ln_porc_noc_hor_ext2  := 0;

 --Se Capturan los porcentajes equivalentes por horario de trabajo.
 Select Nvl(asp.porc_diu_nor,0), Nvl(asp.porc_diu_ext1,0), Nvl(asp.porc_diu_ext2,0),
        Nvl(asp.porc_noc_nor,0), Nvl(asp.porc_noc_ext1,0), Nvl(asp.porc_noc_ext2,0)
   Into ln_porc_diu_hor_norm, ln_porc_diu_hor_ext1, ln_porc_diu_hor_ext2,
        ln_porc_noc_hor_norm, ln_porc_noc_hor_ext1, ln_porc_noc_hor_ext2
   from asistparam asp
  Where asp.reckey = 1;

 -- Se Capturan los conceptos de Basico y Asignacion Familiar

 ls_conc_basico     := 1001;
 ls_conc_asig_fam   := 1003;
 ls_conc_aport      := 3001;

 Select Nvl(c.fact_pago,0) Into ln_porc_aportes
   from concepto c
  where c.concep = ls_conc_aport;


 For c_t in c_trabajador Loop

     ls_cod_trabajador := c_t.cod_trabajador;
     ln_basico := 0;
     ln_imp_gratificacion := 0;

     Begin
        Select g.imp_gan_desc Into ln_basico
          from gan_desct_fijo g
         Where g.cod_trabajador = ls_cod_trabajador
           and g.concep = ls_conc_basico;
     Exception
     When No_Data_Found Then
          ln_basico := 0;
     End ;

     Begin
        Select Nvl(g.imp_gan_desc,0) Into ln_asig_fam
          from gan_desct_fijo g
         Where g.cod_trabajador = ls_cod_trabajador
           and g.concep = ls_conc_asig_fam;
     Exception
     When No_Data_Found Then
          ln_asig_fam := 0;
     End ;

     -- Cuento el nro de dias de asistencia, solamente aquellas que tienen mas de 4 horas hormales
     SELECT COUNT(*)
       INTO ln_count_reg_dia
       FROM (SELECT A.COD_TRABAJADOR,
                    TRUNC(A.FEC_MOVIM) AS FECHA
               FROM ASISTENCIA A
              WHERE TRUNC(A.FEC_MOVIM) BETWEEN TRUNC(ADI_FECHA1) AND TRUNC(ADI_FECHA2)
                AND A.COD_TRABAJADOR = LS_COD_TRABAJADOR
              GROUP BY A.COD_TRABAJADOR, TRUNC(A.FEC_MOVIM)
              HAVING SUM(a.hor_diu_nor + a.hor_noc_nor) >= 4);
     
     if ln_count_reg_dia = 0 then
        SELECT nvl(sum((a.hor_diu_nor + a.hor_noc_nor) / 8 ), 0)
          into ln_count_reg_dia
          FROM ASISTENCIA A
         WHERE TRUNC(A.FEC_MOVIM) BETWEEN TRUNC(ADI_FECHA1) AND TRUNC(ADI_FECHA2)
           AND A.COD_TRABAJADOR = LS_COD_TRABAJADOR;
     end if;
     
     If ln_basico > 0 and ln_count_reg_dia > 0 Then

        ln_bas_dia := Nvl(ln_basico / 30,0);
        ln_bas_hor := Nvl(ln_bas_dia / 8,0);
        For c_a in c_asistencia Loop

            -- Primero los importes brutos por cada hora trabajada
            ln_imp_diu_hor_norm := c_a.hor_diu_nor * ( ln_bas_hor * (ln_porc_diu_hor_norm / 100));
            ln_imp_diu_hor_ext1 := c_a.hor_ext_diu_1 * ((ln_bas_hor * ln_porc_diu_hor_ext1 / 100));
            ln_imp_diu_hor_ext2 := c_a.hor_ext_diu_2 * ((ln_bas_hor * ln_porc_diu_hor_ext2 / 100));

            ln_imp_noc_hor_norm := c_a.hor_noc_nor * ( (ln_bas_hor * ln_porc_noc_hor_norm / 100) );
            ln_imp_noc_hor_ext1 := c_a.hor_ext_noc_1 * ( (ln_bas_hor * ln_porc_noc_hor_ext1 / 100) );
            ln_imp_noc_hor_ext2 := c_a.hor_ext_noc_2 * ( (ln_bas_hor * ln_porc_noc_hor_ext2 / 100) );

            -- Calculo cuanto le toca por la asignacion familiar
            ln_imp_asig_fam := Nvl(ln_asig_fam / 26,0);
            -- Calculo el dominical
            If Nvl(c_a.hor_trabaj,0) >= 4 and Nvl(c_a.flag_descanso,'0') <>'1' then
               ln_imp_domin := Nvl(ln_bas_dia / 6, 0);
            Else
               ln_imp_domin := 0;
            End If; --dw

            -- Si es dia de descanso, percibe un 100% adicional por las horas trabajadas
            If Nvl(c_a.flag_descanso,'0')= '1' OR (Nvl(c_a.flag_feriado,'0') = '1' and Nvl(c_a.flag_descanso,'0')<> '1') then
               ln_imp_diu_hor_norm := ln_imp_diu_hor_norm * 2;
               ln_imp_diu_hor_ext1 := ln_imp_diu_hor_ext1 * 2;
               ln_imp_diu_hor_ext2 := ln_imp_diu_hor_ext2 * 2;
               ln_imp_noc_hor_norm := ln_imp_noc_hor_norm * 2;
               ln_imp_noc_hor_ext1 := ln_imp_noc_hor_ext1 * 2;
               ln_imp_noc_hor_ext2 := ln_imp_noc_hor_ext2 * 2;
            End If;

            ln_imp_rem_total := ln_imp_diu_hor_norm + ln_imp_diu_hor_ext1 + ln_imp_diu_hor_ext2 + ln_imp_noc_hor_norm
                              + ln_imp_noc_hor_ext1 + ln_imp_noc_hor_ext2;

            ln_imp_gratificacion := (ln_imp_rem_total / 6);
            ln_imp_vacac     := ln_imp_rem_total / 12;
            ln_imp_cts       := (ln_imp_rem_total + ln_imp_gratificacion)/ 12;
            ln_imp_afec_afp  := ln_imp_rem_total + ln_imp_vacac + ln_imp_gratificacion;

            ln_imp_afp_jub   :=  Nvl(ln_imp_afec_afp  * (c_t.porc_jubilac /100),0) / ln_count_reg_dia;
            ln_imp_afp_inval :=  Nvl(ln_imp_afec_afp  * (c_t.porc_invalidez /100),0) / ln_count_reg_dia;
            ln_imp_afp_com   :=  Nvl(ln_imp_afec_afp  * (c_t.porc_comision /100),0) / ln_count_reg_dia;

            ln_imp_aportacion:=  (Nvl(ln_imp_rem_total,0) + Nvl(ln_imp_domin,0) + Nvl(ln_imp_asig_fam,0) +
                                 Nvl(ln_imp_vacac,0)) * ln_porc_aportes;

            Update RRHH_OBR_COSTO_DIARIO a
               Set a.imp_hor_diu_nor   = ln_imp_diu_hor_norm,
                   a.imp_hor_diu_ext1  = ln_imp_diu_hor_ext1,
                   a.imp_hor_diu_ext2  = ln_imp_diu_hor_ext2,
                   a.imp_hor_noc_nor   = ln_imp_noc_hor_norm,
                   a.imp_hor_noc_ext1  = ln_imp_noc_hor_ext1,
                   a.imp_hor_noc_ext2  = ln_imp_noc_hor_ext2,
                   a.imp_dominical     = ln_imp_domin,
                   a.imp_asig_fam      = ln_imp_asig_fam,
                   a.imp_vacaciones    = ln_imp_vacac,
                   a.imp_cts           = ln_imp_cts,
                   a.imp_afp_jub       = ln_imp_afp_jub,
                   a.imp_afp_inval     = ln_imp_afp_inval,
                   a.imp_afp_comis     = ln_imp_afp_com,
                   a.imp_gratificacion = ln_imp_gratificacion,
                   a.imp_aportacion    = ln_imp_aportacion
             Where a.cod_trabajador   = ls_cod_trabajador
               and trunc(a.fecha) = trunc(c_a.fecha);

            IF SQL%NOTFOUND THEN
               INSERT INTO RRHH_OBR_COSTO_DIARIO(
                      COD_TRABAJADOR,FECHA, IMP_HOR_DIU_NOR, IMP_HOR_DIU_EXT1, IMP_HOR_DIU_EXT2,
                      IMP_HOR_NOC_NOR,IMP_HOR_NOC_EXT1, IMP_HOR_NOC_EXT2, IMP_DOMINICAL, IMP_ASIG_FAM,
                      IMP_VACACIONES, IMP_AFP_JUB, IMP_AFP_INVAL, IMP_AFP_COMIS, IMP_CTS, Imp_Gratificacion,
                      IMP_APORTACION)
               VALUES(
                      c_a.cod_trabajador, c_a.fecha, ln_imp_diu_hor_norm, ln_imp_diu_hor_ext1, ln_imp_diu_hor_ext2,
                      ln_imp_noc_hor_norm, ln_imp_noc_hor_ext1, ln_imp_noc_hor_ext2, ln_imp_domin, ln_imp_asig_fam,
                      ln_imp_vacac, ln_imp_afp_jub, ln_imp_afp_inval, ln_imp_afp_com, ln_imp_cts, ln_imp_gratificacion,
                      ln_imp_aportacion);

            END IF;
        End Loop;


     End If;

 End Loop;

 COMMIT;

End USP_RH_ASIST_COSTO;
/
