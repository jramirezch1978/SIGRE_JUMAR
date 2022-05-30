create or replace procedure usp_pla_cal_des_tot
 (  as_codtra       in maestro.cod_trabajador%type,
    ad_fec_proceso  in rrhhparam.fec_proceso%type
 )  is

lk_destot   constant char(3) := '200';
ln_destot   calculo.imp_soles%type;
ln_destotd  calculo.imp_soles%type;
ls_concep   concepto.concep%type ;

begin

--  Halla concepto de total descuentos
Select rpn.concep
  into ls_concep
  from rrhh_nivel rpn
  where rpn.cod_nivel = lk_destot ;

--  Acumula descuentos
Select sum(c.imp_soles)
  into ln_destot
  from calculo c
  where  c.cod_trabajador = as_codtra and
         substr(c.concep,1,1) = '2' ;
ln_destot := nvl(ln_destot,0) ;

Select sum(c.imp_dolar)
  into ln_destotd
  from calculo c
  where c.cod_trabajador = as_codtra and
        substr(c.concep,1,1) = '2' ;
ln_destotd := nvl(ln_destotd,0) ;

--  Inserta registros en la tabla calculo
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
  ls_concep, ad_fec_proceso,
  0 ,    0 ,  0 , 
  ln_destot, ln_destotd,  ' ', 
  ' ',     ' ', 
  ' ',     ' ', 
  ' ',     ' ', 
  ' ',     ' ', 
  ' ',     ' ', 
  ' ',     ' ', 
  ' ',     ' ', 
  ' ',     ' ' );
  
End usp_pla_cal_des_tot;
/
