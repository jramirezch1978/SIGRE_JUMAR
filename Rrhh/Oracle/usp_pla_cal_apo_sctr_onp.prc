create or replace procedure usp_pla_cal_apo_sctr_onp
 ( as_codtra       in maestro.cod_trabajador%type, 
   ad_fec_proceso  in rrhhparam.fec_proceso%type
 ) is
  
lk_sctr_onp         constant char(3) := '340';
ln_porc_sctr_onp    seccion.porc_sctr_onp%type;
ln_ingtot           number(13,2);
ln_imp_sctr_onp     number(13,2);
ln_imp_sctr_onpd    number(13,2);
ls_concep           concepto.concep%type;
ls_cod_area         area.cod_area%type;
ls_cod_seccion      seccion.cod_seccion%type;
ls_concep_nivel     concepto.concep%type;
ln_tipcam           calendario.cmp_dol_prom%type;
  
cursor c_sctr_onp (as_codtra maestro.cod_trabajador%type) is 
  select  c.concep, c.imp_soles
  from calculo c
  where c.cod_trabajador = as_codtra and
        substr(c.concep,1,1) = '1' and
        c.flag_e_sctr_onp = '1' ;

begin

--  Halla el tipo de cambio del dolar
Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_tipcam := nvl(ln_tipcam,1);

--  Concepto del nivel
select rpn.concep
  into ls_concep_nivel
  from rrhh_nivel rpn
  where rpn.cod_nivel = lk_sctr_onp;

--  Halla seccion del trabajador
Select m.cod_area, m.cod_seccion
  into ls_cod_area, ls_cod_seccion
  from maestro m
  where m.cod_trabajador = as_codtra;

--  Obtiene factor deacuerdo a su seccion
Select s.porc_sctr_onp
  into ln_porc_sctr_onp
  from seccion s
  where s.cod_area = ls_cod_area and
        s.cod_seccion = ls_cod_seccion ;

ln_porc_sctr_onp := nvl(ln_porc_sctr_onp,0);

If ln_porc_sctr_onp > 0 then

  ln_ingtot := 0;
  For rc_sctr_onp in c_sctr_onp (as_codtra) Loop
    ln_ingtot := ln_ingtot + rc_sctr_onp.imp_soles ;
  End Loop;

  ln_imp_sctr_onp  := ln_ingtot*ln_porc_sctr_onp / 100 ;
  ln_imp_sctr_onpd := ln_imp_sctr_onp / ln_tipcam ;
 
  --  Inserta registros
  Insert into Calculo ( Cod_Trabajador, 
          Concep,          Fec_Proceso, 
          Horas_Trabaj,    Horas_Pag, Dias_Trabaj, 
          Imp_Soles,       Imp_Dolar, Flag_t_Snp, 
          Flag_t_Quinta,        Flag_t_Judicial, 
          Flag_t_Afp,           Flag_t_Bonif_30, 
          Flag_t_Bonif_25,      Flag_t_Gratif, 
          Flag_t_Cts,           Flag_t_Vacacio, 
          Flag_t_Bonif_Vacacio, Flag_t_Pago_Quincena, 
          Flag_t_Quinquenio,    Flag_e_Essalud, 
          Flag_e_Ies,           Flag_e_Senati, 
          Flag_e_Sctr_Ipss,     Flag_e_Sctr_Onp )
          Values ( as_codtra, 
          ls_concep_nivel, ad_fec_proceso,
          0 ,    0 ,  0 , 
          ln_imp_sctr_onp, ln_imp_sctr_onpd,  ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ' );
End if ;

End usp_pla_cal_apo_sctr_onp;
/
