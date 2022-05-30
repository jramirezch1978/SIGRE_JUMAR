create or replace procedure usp_pla_cal_sctr_onp 
(  as_codtra in maestro.cod_trabajador%type, 
   ad_fec_proceso in control.fec_proceso%type
 ) is
  
lk_sctr_onp constant char(3) := '340';
ln_porc_sctr_onp number(13,2);
ln_ingtot number(13,2);
ln_imp_soles number(13,2);
ln_imp_sctr_onp number(13,2);
ls_concep concepto.concep%type;
ls_cod_area area.cod_area%type;
ls_cod_seccion seccion.cod_seccion%type;
ls_concep_nivel concepto.concep%type;
  
cursor c_sctr_onp is
 select rpd.cod_concepto
 from rrhh_parm_detalle rpd
 where  rpd.cod_nivel = lk_sctr_onp ;
  
  
  
begin

--Obtenemos el concepto para el Nivel
select rpn.cod_concepto
into ls_concep_nivel
from rrhh_parm_nivel rpn
where rpn.cod_nivel = lk_sctr_onp;

--Obtengo el cod seccion para el trabajador
select m.cod_area, m.cod_seccion
into ls_cod_area, ls_cod_seccion
from maestro m
where m.cod_trabajador = as_codtra;

--Obtengo el factor para este trabajador deacuerdo 
--a sus seccion 
select s.porc_sctr_onp
into ln_porc_sctr_onp 
from seccion s
where s.cod_area = ls_cod_area and
      s.cod_seccion = ls_cod_seccion ;

ln_porc_sctr_onp := nvl(ln_porc_sctr_onp,0);
ln_ingtot := 0;

For rc_sctr_onp in c_sctr_onp
 Loop

   ls_concep := rc_sctr_onp.cod_concepto;
   select c.imp_soles
   into ln_imp_soles
   from calculo c
   where c.cod_trabajador = as_codtra and
      to_char(c.fec_proceso,'MM') = 
      to_char(ad_fec_proceso,'MM') and
      c.concep  in (select cp.concep 
                    from  concepto cp
                    where substr(cp.concep,1,1) = '1'and
                          cp.flag_e_sctr_onp = '1' and
                          cp.concep = ls_concep );
    
   ln_ingtot := ln_ingtot + ln_imp_soles ; 
 End loop;  
   
--Obtenemos el valor ha ingresar al Calculo
 ln_imp_sctr_onp :=ln_ingtot*ln_porc_sctr_onp;

--Insertamos el Registro

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
          ' ',    ' ',  ' ', 
          ln_imp_sctr_onp, ' ',  ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ' );

  
end usp_pla_cal_sctr_onp;
/
