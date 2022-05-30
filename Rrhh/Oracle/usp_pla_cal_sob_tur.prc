create or replace procedure usp_pla_cal_sob_tur(
  as_codtra      in maestro.cod_trabajador%type, 
  as_codusr      in usuario.cod_usr%type,
  ad_fec_proceso in rrhhparam.fec_proceso%type
  ) is
   
  lk_gan_fij     constant char(3) := '080' ; 
  lk_sob_tur     constant char(3) := '081' ; 
  ld_fec_desde   rrhhparam.fec_desde%type ;
  ld_fec_hasta   rrhhparam.fec_hasta%type ;
  ln_tope        number(13,2) ;
   
  --  Determina conceptos de sobretiempos
  Cursor c_sobretiempo_turno is
    Select st.horas_sobret, st.concep
      from sobretiempo_turno st
      where st.cod_trabajador = as_codtra 
            and st.concep in (
            Select rhpd.concep
              from rrhh_nivel_detalle rhpd
              where rhpd.cod_nivel = lk_sob_tur )
            and st.fec_movim between ld_fec_desde and ld_fec_hasta
      order by st.cod_trabajador, st.concep ;
           
  ln_valor  gan_desct_fijo.imp_gan_desc%type;

  --  Determina concepto
  Cursor c_concepto ( as_concepto concepto.concep%type ) is
  Select c.flag_t_snp, c.flag_t_quinta, c.flag_t_judicial,
    c.flag_t_afp, c.flag_t_bonif_30, c.flag_t_bonif_25,
    c.flag_t_gratif, c.flag_t_cts, c.flag_t_vacacio, 
    c.flag_t_bonif_vacacio, c.flag_t_pago_quincena, 
    c.flag_t_quinquenio, 
    c.flag_e_essalud, c.flag_e_agrario, 
    c.flag_e_essalud_vida, c.flag_e_ies, 
    c.flag_e_senati, c.flag_e_sctr_ipss, 
    c.flag_e_sctr_onp, 
    c.nro_horas, c.fact_pago, c.imp_tope_min
    from concepto c
    where c.concep = as_concepto ;

  ln_horcon            concepto.nro_horas%type ;
  ln_hortra            sobretiempo_turno.horas_sobret%type;
  ln_horpag            sobretiempo_turno.horas_sobret%type;
  ln_impsol            calculo.imp_soles%type;
  ln_impdol            calculo.imp_dolar%type;
  ln_tipcam            calendario.cmp_dol_prom%type ;
  ln_factor            concepto.fact_pago%type;
  ln_contador          number(15);
  ls_flag_sobretiempo  char(1) ;

begin

Select rh.fec_desde, rh.fec_hasta
  into ld_fec_desde, ld_fec_hasta
  from rrhhparam rh
  where rh.reckey = '1' ;
      
Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_tipcam := nvl ( ln_tipcam, 1);
      
Select m.flag_juicio
  into ls_flag_sobretiempo
  from maestro m
  where m.cod_trabajador = as_codtra ;
ls_flag_sobretiempo := nvl(ls_flag_sobretiempo,'0') ;
  
If ls_flag_sobretiempo <> '1' then

  Select sum(gdf.imp_gan_desc)
    into ln_valor
    from gan_desct_fijo gdf
    where gdf.cod_trabajador = as_codtra 
          and gdf.flag_estado = '1'
          and gdf.concep in (
          Select rhpd.concep
            from rrhh_nivel_detalle rhpd
            where rhpd.cod_nivel = lk_gan_fij ) ;
 ln_valor := nvl( ln_valor, 0 ) ;

  For rc_st in c_sobretiempo_turno Loop
    For rc_c in c_concepto ( rc_st.concep ) Loop
      ln_tope := 0 ;
      ln_horcon := nvl( rc_c.nro_horas, 0);
      ln_tope   := nvl( rc_c.imp_tope_min, 0);
      ln_hortra := nvl( rc_st.horas_sobret, 0);
      ln_factor := nvl( rc_c.fact_pago, 0);
      ln_horpag := ln_hortra ;
      If substr(rc_st.concep,1,2) = '11' then
        If ln_tope > 0 then
          ln_impsol := ln_tope / ln_horcon * ln_hortra * ln_factor ;
        Else
          ln_impsol := ln_valor / ln_horcon * ln_hortra * ln_factor ;
        End if ;
      Else
        ln_impsol := ln_hortra * ln_factor ;
      End if ;
      ln_impdol := ln_impsol / ln_tipcam ;

      ln_contador := 0 ;
      Select count(*)
        into ln_contador
        from calculo c
        where c.cod_trabajador = as_codtra and
              c.concep = rc_st.concep ;
      ln_contador := nvl(ln_contador,0) ;
      If ln_contador > 0 then
        Update calculo
        Set horas_trabaj = horas_trabaj + ln_hortra ,
            horas_pag    = horas_pag + ln_horpag ,
            imp_soles    = imp_soles + ln_impsol ,
            imp_dolar    = imp_dolar + ln_impdol
        where cod_trabajador = as_codtra and
              concep = rc_st.concep ;
      Else
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
          rc_st.concep, ad_fec_proceso,
          ln_hortra, ln_horpag, '0', 
          ln_impsol, ln_impdol,  rc_c.Flag_t_Snp, 
          rc_c.Flag_t_Quinta,     rc_c.Flag_t_Judicial, 
          rc_c.Flag_t_Afp,        rc_c.Flag_t_Bonif_30, 
          rc_c.Flag_t_Bonif_25,   rc_c.Flag_t_Gratif, 
          rc_c.Flag_t_Cts,        rc_c.Flag_t_Vacacio, 
          rc_c.Flag_t_Bonif_Vacacio, rc_c.Flag_t_Pago_Quincena, 
          rc_c.Flag_t_Quinquenio, rc_c.Flag_e_Essalud, 
          rc_c.Flag_e_agrario,    rc_c.Flag_e_essalud_vida,
          rc_c.Flag_e_Ies,        rc_c.Flag_e_Senati, 
          rc_c.Flag_e_Sctr_Ipss,  rc_c.Flag_e_Sctr_Onp ) ;
      End if ;
           
    End Loop;       
  End Loop ;

End if ;
      
End usp_pla_cal_sob_tur;
/
