create or replace procedure usp_pla_cal_apo_sctr_ipss
 ( as_codtra       in maestro.cod_trabajador%type, 
   ad_fec_proceso  in rrhhparam.fec_proceso%type
 ) is
  
lk_sctr_ipss        constant char(3) := '330';
ln_porc_sctr_ipss   seccion.porc_sctr_ipss%type;
ln_ingtot           number(13,2);
ln_imp_sctr_ipss    number(13,2);
ln_imp_sctr_ipssd   number(13,2);
ls_concep           concepto.concep%type;
ls_cod_area         area.cod_area%type;
ls_cod_seccion      seccion.cod_seccion%type;
ls_concep_nivel     concepto.concep%type;
ln_tipcam           calendario.cmp_dol_prom%type;
  
cursor c_sctr_ipss (as_codtra maestro.cod_trabajador%type) is 
  select  c.concep, c.imp_soles
  from calculo c
  where c.cod_trabajador = as_codtra and
        substr(c.concep,1,1) = '1' and
        c.flag_e_sctr_ipss = '1' ;

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
where rpn.cod_nivel = lk_sctr_ipss;

--  Halla seccion del trabajador
select m.cod_area, m.cod_seccion
into ls_cod_area, ls_cod_seccion
from maestro m
where m.cod_trabajador = as_codtra;

--  Obtiene factor deacuerdo a su seccion
select s.porc_sctr_ipss
into ln_porc_sctr_ipss 
from seccion s
where s.cod_area = ls_cod_area and
      s.cod_seccion = ls_cod_seccion ;

ln_porc_sctr_ipss := nvl(ln_porc_sctr_ipss,0);

If ln_porc_sctr_ipss > 0 then

  ln_ingtot := 0;
  For rc_sctr_ipss in c_sctr_ipss (as_codtra)
    Loop 
    ln_ingtot := ln_ingtot + rc_sctr_ipss.imp_soles ;
  End Loop;

  ln_imp_sctr_ipss  :=ln_ingtot*ln_porc_sctr_ipss / 100 ;
  ln_imp_sctr_ipssd := ln_imp_sctr_ipss / ln_tipcam ;
 
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
          ln_imp_sctr_ipss, ln_imp_sctr_ipssd,  ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ' );
End if ;
end usp_pla_cal_apo_sctr_ipss;
/
