create or replace procedure usp_pla_cal_rac_coc(
   as_codtra              in maestro.cod_trabajador%type, 
   as_codusr              in usuario.cod_usr%type,
   ad_fec_proceso         in rrhhparam.fec_proceso%type,
   an_diatra              in out calculo.dias_trabaj%type, 
   an_diames              in calculo.dias_trabaj%type, 
   an_dias_racion_cocida  in calculo.dias_trabaj%type
   ) is
   
   lk_racion_cocida constant char(3) := '070' ; 

   ln_hortra     calculo.horas_trabaj%type;
   ln_diatra     calculo.dias_trabaj%type;
   ln_diapag     calculo.dias_trabaj%type;
   ln_impsol     calculo.imp_soles%type;
   ln_impdol     calculo.imp_dolar%type;
   ln_tipcam     calendario.cmp_dol_prom%type ;
   ls_concep     concepto.concep%type;
   ln_importe    gan_desct_fijo.imp_gan_desc%type;
   ln_count      number(5);
   ln_contador   number(5);
   ln_dias_vac   number(5,2) ;
   
   --  Determina ganancias fijas
   Cursor c_concepto ( as_concepto concepto.concep%type ) is
   Select c.flag_t_snp, c.flag_t_quinta, c.flag_t_judicial,
     c.flag_t_afp, c.flag_t_bonif_30, c.flag_t_bonif_25,
     c.flag_t_gratif, c.flag_t_cts, c.flag_t_vacacio, 
     c.flag_t_bonif_vacacio, c.flag_t_pago_quincena, 
     c.flag_t_quinquenio, 
     c.flag_e_essalud, c.flag_e_agrario, 
     c.flag_e_essalud_vida, c.flag_e_ies, 
     c.flag_e_senati, c.flag_e_sctr_ipss, 
     c.flag_e_sctr_onp
     from concepto c
     where c.concep = as_concepto ;

begin

Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_tipcam := nvl ( ln_tipcam, 1 );
   
Select rhpn.concep
  into ls_concep
  from rrhh_nivel rhpn
  where rhpn.cod_nivel = lk_racion_cocida  ;
    
Select count(gdf.imp_gan_desc)
  into ln_count 
  from gan_desct_fijo gdf
  where gdf.cod_trabajador = as_codtra
        and gdf.concep = ls_concep;

ln_count := nvl (ln_count,0);
If ln_count > 0 then
  Select gdf.imp_gan_desc
    into ln_importe
    from gan_desct_fijo gdf
    where gdf.cod_trabajador = as_codtra
          and gdf.concep = ls_concep;
   
  ln_contador := 0 ; ln_dias_vac := 0 ;
  Select count(i.dias_inasist)
    into ln_contador
    from inasistencia i
    where i.cod_trabajador = as_codtra
          and i.concep = '1413' ;

  If ln_contador > 0 then
    Select sum(i.dias_inasist)
      into ln_dias_vac
      from inasistencia i
      where i.cod_trabajador = as_codtra
            and i.concep = '1413' ;
    ln_dias_vac := nvl(ln_dias_vac,0) ;
  End if ;

  ln_importe := nvl (ln_importe,0); 
  an_diatra := nvl (an_diatra,0) ;
  ln_dias_vac := ln_dias_vac + an_diatra ;
  ln_hortra := 0 ;

  If ln_dias_vac >= an_diames then
    ln_impsol := ln_importe ;
    ln_diatra := an_dias_racion_cocida ;
  Else
    ln_diapag := an_dias_racion_cocida - ( an_diames - ln_dias_vac ) ;
    ln_impsol := ln_importe / an_dias_racion_cocida * ln_diapag ;
    ln_diatra := ln_diapag ;
  End if;
  ln_impdol := ln_impsol / ln_tipcam ;

  For rc_c in c_concepto ( ls_concep ) Loop
    If ln_impsol > 0 Then
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
        Flag_e_agrario,       Flag_e_essalud_vida,
        Flag_e_Ies,           Flag_e_Senati, 
        Flag_e_Sctr_Ipss,     Flag_e_Sctr_Onp )
      Values ( as_codtra, 
        ls_concep, ad_fec_proceso,
        ln_hortra,    ln_hortra, ln_diatra, 
        ln_impsol,    ln_impdol,  rc_c.Flag_t_Snp, 
        rc_c.Flag_t_Quinta,     rc_c.Flag_t_Judicial, 
        rc_c.Flag_t_Afp,        rc_c.Flag_t_Bonif_30, 
        rc_c.Flag_t_Bonif_25,   rc_c.Flag_t_Gratif, 
        rc_c.Flag_t_Cts,        rc_c.Flag_t_Vacacio, 
        rc_c.Flag_t_Bonif_Vacacio, rc_c.Flag_t_Pago_Quincena, 
        rc_c.Flag_t_Quinquenio, rc_c.Flag_e_Essalud, 
        rc_c.Flag_e_agrario,    rc_c.Flag_e_essalud_vida,
        rc_c.Flag_e_Ies,        rc_c.Flag_e_Senati, 
        rc_c.Flag_e_Sctr_Ipss,  rc_c.Flag_e_Sctr_Onp ) ;
    End if;  
  End Loop;   
End if;

End usp_pla_cal_rac_coc;
/
