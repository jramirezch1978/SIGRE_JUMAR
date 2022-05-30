create or replace trigger TIA_RRHH_SUBSIDIO_DET
  after insert on rrhh_subsidio_det  
  for each row
declare
  -- local variables here
  ln_ano             cntbl_asiento.ano%type ;  
  ln_count           number ;
  ls_cod_trabajador  maestro.cod_trabajador%type ;
  ls_tipo_subsidio   rrhh_tipo_subsidio.tipo_subsidio%type ;
  ls_cod_susp_lab    rrhh_tipo_susp_laboral_rtps.cod_suspension_lab%type ;
  ln_nro_dias_teo    Number ;
  ln_nro_dias_det    Number ;
  ln_dias_sin_sub    Number ; -- Los paga la empresa
  ln_dias_subsidi    Number ; -- Los paga el seguro
  
BEGIN

  SELECT rsu.cod_trabajador, to_number(to_char(:new.fecha_ini_pla,'yyyy')), 
         rtl.tipo_subsidio, rts.nro_dias, rsu.cod_suspension_lab
    INTO ls_cod_trabajador, ln_ano, ls_tipo_subsidio, ln_nro_dias_teo, ls_cod_susp_lab 
    FROM rrhh_subsidio rsu, rrhh_tipo_susp_laboral_rtps rtl, rrhh_tipo_subsidio rts 
   WHERE rsu.cod_suspension_lab = rtl.cod_suspension_lab 
     and rtl.tipo_subsidio = rts.tipo_subsidio 
     and rts.nro_dias > 0 
     and rsu.nro_subsidio = :new.nro_subsidio ;

  ln_nro_dias_det := TRUNC(:new.fecha_fin_pla) - TRUNC(:new.fecha_fin_pla) + 1 ;
  
  IF :new.flag_descto='1' and ln_nro_dias_teo > 0 THEN  
  
     -- Verificando si tiene historico en rrhh_subsidio_x_trabaj 
     SELECT count(*) 
       INTO ln_count 
       FROM rrhh_subsidio_x_trabaj r 
      WHERE r.ano=ln_ano AND r.cod_trabajador=ls_cod_trabajador AND r.tipo_subsidio=ls_tipo_subsidio;

     -- Adiciona registro de control sino existe
     IF ln_count = 0 THEN  
        IF ln_nro_dias_det > ln_nro_dias_teo THEN 
           ln_dias_sin_sub := ln_nro_dias_teo ;
           ln_dias_subsidi := ln_nro_dias_det - ln_dias_sin_sub ;
        ELSE
           ln_dias_sin_sub := ln_nro_dias_det ;
           ln_dias_subsidi := 0 ;
        END IF ;
        
        INSERT INTO rrhh_subsidio_x_trabaj(ano, cod_trabajador, tipo_subsidio, dias_sin_subsidio, dias_subsidiados) 
        VALUES(ln_ano, ls_cod_trabajador, ls_tipo_subsidio, ln_dias_sin_sub, ln_dias_subsidi) ;
     -- Actualiza datos si existe
     ELSE
       SELECT r.dias_sin_subsidio, r.dias_subsidiados 
         INTO ln_dias_sin_sub, ln_dias_subsidi 
         FROM rrhh_subsidio_x_trabaj r 
        WHERE r.ano=ln_ano AND r.cod_trabajador=ls_cod_trabajador AND r.tipo_subsidio=ls_tipo_subsidio; 
     END IF ;
     
     -- Adiciona registro en gan_descto_fijo
     INSERT INTO inasistencia(cod_trabajador, concep, fec_desde, fec_hasta,
            fec_movim, dias_inasist, tipo_doc, nro_doc, 
            cod_usr, flag_replicacion, periodo_inicio, 
            cod_suspension_lab, mes_periodo) 
     VALUES(ls_cod_trabajador, :new.concep, :new.fecha_ini_pla, :new.fecha_fin_pla, 
            :new.fec_proceso, (TRUNC(:new.fecha_fin_pla) - TRUNC(:new.fecha_ini_pla) +1 ), null, null, 
            :new.cod_usr, '1', to_number(to_char(:new.fec_proceso,'yyyy')), ls_cod_susp_lab, null) ;
  END IF ;
  
end TIA_RRHH_SUBSIDIO_DET;
/
