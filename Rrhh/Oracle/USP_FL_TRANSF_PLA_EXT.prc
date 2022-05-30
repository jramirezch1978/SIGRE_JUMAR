create or replace procedure USP_FL_TRANSF_PLA_EXT(
    adi_fec_proceso    in date,
    asi_usuario		     in usuario.cod_usr%TYPE,
    asi_origen         in origen.cod_origen%TYPE
) is

  -- Variables Locales
  ln_count		        number;
  ls_cargo		        fl_cargo_tripulantes.cargo_tripulante%TYPE;
  ln_dias             number;
  ls_ton              ap_param.und_tm%TYPE;
  ls_doc_fpla         fl_param.doc_fpla%TYPE;
  ls_cnc_pago_trip    fl_param.CONCEP_PARTICIPACION%TYPE;
  ls_cnc_bonif_esp    fl_param.concep_bonif_pesca%TYPE;
  ls_cnc_trab_tier    fl_param.concep_trab_tierra%TYPE;
  ld_fecha1           date;
  ld_fecha2           date;
  ls_cnc_cuota_supnep concepto.concep%TYPE;
  ln_fac_supnep       concepto.fact_pago%TYPE;
  ln_importe          gan_desct_variable.imp_var%TYPE;
  
  -- Cursor donde almaceno el pago a los tripulantes, por la participacion de la pesca
  -- que haya tenido el tripulante en el dia
  Cursor c_pago_trip is
	  select 	flpp.tripulante,
            trunc(flpp.fecha) as fecha,
            flpp.cargo_tripulante as cargo,
            flpp.cencos,
            tn.flag_supnep,
    				sum(flpp.participacion_pesca) as pago,
            sum(flpp.total_pesca) as pesca,
            sum(flpp.importe_trabj_tierra) as importe_trabj_tierra,
            sum(flpp.bonificacion_pesca) as bonificacion_pesca
	from fl_participacion_pesca flpp,
       tg_naves               tn
  where flpp.nave             = tn.nave
    and trunc(flpp.fecha) between trunc(ld_fecha1) and trunc(ld_fecha2)
    and flpp.sueldo_fijo = 0
	group by flpp.tripulante,
            trunc(flpp.fecha),
            flpp.cargo_tripulante,
            flpp.cencos,
            tn.flag_supnep;

  -- Cursor donde almaceno los tripulantes de la semana
  Cursor c_tripulantes is
    select 	flpp.tripulante,
            flpp.cargo_tripulante as cargo,
            flpp.cencos,
            sum(flpp.total_pesca) as pesca
  	from fl_participacion_pesca flpp
    where trunc(flpp.fecha) BETWEEN trunc(ld_fecha1) AND trunc(ld_fecha2)
      and flpp.sueldo_fijo = 0
   group by tripulante, flpp.cargo_tripulante, flpp.cencos;

  -- Cursor donde estan los conceptos de flota
  cursor c_conceptos is
     select t.concepto,
            t.flag_porc_importe,
            t.ratio,
            t.cod_moneda
       from fl_conceptos_flota t
      where t.flag_estado = '1';


begin

/*
  USP que tiene como finalidad transferir los calculos de la Planilla de Tripulantes
  que estan almacenados en la tabla fl_participacion de pesca junto con las bonificaciones
  a la tabla gan_desct_variables
  cualquier otro detalle conversar con Eduardo Gonzales

  Jhonny Ramirez Chiroque  01/Octubre/2003

*/
    -- Obtengo el concepto para la cuota Sindical de Pescadores SUPNEP
    ls_cnc_cuota_supnep := PKG_CONFIG.USF_GET_PARAMETER('CONCEP CUOTA SUPNEP', '2002');
    select count(*)
      into ln_count
      from concepto
     where concep = ls_cnc_cuota_supnep;
    
    if ln_count = 0 then
       RAISE_APPLICATION_ERROR(-20000, 'El concepto ' || ls_cnc_cuota_supnep || ' no esta registrado en el maestro de conceptos, por favor verifique!');
    end if;
    
    select c.fact_pago
      into ln_fac_supnep
      from concepto c
     where c.concep = ls_cnc_cuota_supnep;
    
    -- Parametros iniciales
    select doc_fpla, f.concep_participacion, f.concep_bonif_pesca, f.concep_trab_tierra
      into ls_doc_fpla, ls_cnc_pago_trip, ls_cnc_bonif_esp, ls_cnc_trab_tier
      from fl_param f
     where f.reckey = '1';
     
    SELECT und_tm
      INTO ls_ton
      FROM ap_param
     WHERE origen = 'XX';

  -- Obtengo las fecha de inicio y de fin de la fecha de proceso
  select count(*)
    into ln_count
    from rrhh_param_org r
   where r.origen          = asi_origen
     and r.fec_proceso     = adi_fec_proceso
     and r.tipo_trabajador = USP_SIGRE_RRHH.is_tipo_trip
     and r.tipo_planilla   = 'N';
  
  if ln_count = 0 then
     RAISE_APPLICATION_ERROR(-20000, 'NO EXISTE PARAMETROS DE PROCESO PARA LA FECHA INDICADA.'
                       || chr(13) || 'Fecha Proceso: ' || to_char(adi_fec_proceso, 'dd/mm/yyyy')
                       || chr(13) || 'Origen: ' || trim(asi_origen)
                       || chr(13) || 'Tipo Tripulante: ' || USP_SIGRE_RRHH.is_tipo_trip);
  end if;
  
  select r.fec_inicio, r.fec_final
    into ld_fecha1, ld_Fecha2
    from rrhh_param_org r
   where r.origen          = asi_origen
     and r.fec_proceso     = adi_fec_proceso
     and r.tipo_trabajador = USP_SIGRE_RRHH.is_tipo_trip
     and r.tipo_planilla   = 'N';
  
	-- Verifico que existan datos de participacion para transferir a Recursos Humanos
  select count(*)
  	into ln_count
  from fl_participacion_pesca flpp
  where trunc(flpp.fecha) BETWEEN trunc(ld_fecha1) AND trunc(ld_fecha2);

  if ln_count = 0 then
    	RAISE_APPLICATION_ERROR(-20000, 'ORACLE: NO EXISTEN DATOS DE PARTICIPACION DE PESCA PARA TRANSFERIR.'
                  || chr(13) || 'PERIODO: ' || to_char(ld_fecha1, 'dd/mm/yyyy') || ' - '
                  || to_char(ld_fecha2, 'dd/mm/yyyy'));

      return;
  end if;
  
  -- Elminino los conceptos que se tenian anteriormente
  delete gan_desct_variable gd
    where gd.concep         in (ls_cnc_pago_trip, ls_cnc_bonif_esp, ls_cnc_trab_tier, ls_cnc_cuota_supnep)
      and trunc(gd.fec_movim) = trunc(ld_fecha2);

	-- Elminino los conceptos que se tenian anteriormente
  for v_pago in c_pago_trip loop

      -- Elimino cualquier ganancia fija de Motorista
      delete gan_desct_fijo t
      where t.cod_trabajador = v_pago.tripulante
        and t.concep in (select concep
                           from fl_sueldos_fijos
                          where cod_trabajador = v_pago.tripulante
                            and flag_estado = '1');

      -- Elimino de calculo_glosa lo que no necesito
      delete calculo_glosa
      where cod_trabajador = v_pago.tripulante;
      
      
  end loop;

	-- Inserto el pago por concepto de Pago de Participacion
  for lc_reg in c_pago_trip loop


      -- Inserto la ganancia del pago del tripulante
      update gan_desct_variable gd
         set gd.imp_var = NVL(gd.imp_var,0) + lc_reg.pago
       where gd.cod_trabajador = lc_reg.tripulante
    	   and gd.concep         = ls_cnc_pago_trip
         and trunc(gd.fec_movim) = trunc(ld_fecha2);

      if SQL%NOTFOUND then
         insert into gan_desct_variable(
                          cod_trabajador     , concep        ,
                          imp_var            , cod_usr       ,
                          fec_movim          , tipo_doc      ,
                          cencos             )
         values (
                          lc_reg.tripulante  , ls_cnc_pago_trip ,
                          lc_reg.pago        , asi_usuario      ,
                          ld_fecha2    , ls_doc_fpla      ,
                          lc_reg.cencos      );
      end if;
      
      -- Ahora inserto la cuota sindical
      if lc_reg.flag_supnep = '1' then
         ln_importe := lc_reg.pago * ln_fac_supnep / 100;
          
         update gan_desct_variable gd
            set gd.imp_var = NVL(gd.imp_var,0) + ln_importe
          where gd.cod_trabajador = lc_reg.tripulante
            and gd.concep         = ls_cnc_cuota_supnep
            and trunc(gd.fec_movim) = trunc(ld_fecha2);

         if SQL%NOTFOUND then
            insert into gan_desct_variable(
                              cod_trabajador     , concep        ,
                              imp_var            , cod_usr       ,
                              fec_movim          , tipo_doc      ,
                              cencos             )
            values (
                              lc_reg.tripulante  , ls_cnc_cuota_supnep ,
                              ln_importe         , asi_usuario      ,
                              ld_fecha2          , ls_doc_fpla      ,
                              lc_reg.cencos      );
         end if;
       end if;



  end loop;

  -- Debo borrar las ganancias y descuentoa variables
  for lc_reg in c_tripulantes loop
      -- Ahora Procedo con los conceptos de flota, primero borro lo ya exista
      for lc_reg2 in c_conceptos loop
      	  delete gan_desct_variable gd
        	where gd.cod_trabajador   = lc_reg.tripulante
            and gd.concep           = lc_reg2.concepto
            and trunc(gd.fec_movim) = trunc(ld_fecha2);
      end loop;

  end loop;

  -- Ahora registro la glosa para todos los tripulantes
  for lc_reg in c_tripulantes loop
      ls_cargo := lc_reg.cargo;
      
      -- Inserto los datos en Calculo Glosa; primero inserto la Pesca
      SELECT COUNT(*)
        INTO ln_count
        FROM calculo_glosa
       WHERE cod_trabajador = lc_reg.tripulante
         AND item = 1;

      IF ln_count = 0 THEN
         Insert into calculo_glosa(
                cod_trabajador, item, fecha_reg, glosa, und , cantidad, cod_usr)
         values(
                lc_reg.tripulante, 1, adi_fec_proceso, 'PARTICIPACION PESCA', ls_ton, lc_reg.pesca, asi_usuario);
      END IF;

      -- Inserto Los Dias de Asistencia
      SELECT COUNT(*)
        INTO ln_count
        FROM calculo_glosa
       WHERE cod_trabajador = lc_reg.tripulante
         AND item = 2;

      IF ln_count = 0 THEN
         select count(*)
           into ln_dias
           from fl_asistencia t
          where t.tripulante = lc_reg.tripulante
            and trunc(t.fecha) between trunc(ld_fecha1) and trunc(ld_fecha2);

         Insert into calculo_glosa(
                 cod_trabajador, item, fecha_reg, glosa, cantidad, cod_usr)
         values(
                 lc_reg.tripulante, 2, adi_fec_proceso, 'DIAS ASISTENCIA', ln_dias, asi_usuario);
      END IF;

      -- Inserto la semana de Pesca
      SELECT COUNT(*)
        INTO ln_count
        FROM calculo_glosa
       WHERE cod_trabajador = lc_reg.tripulante
         AND item = 3;

      IF ln_count = 0 THEN
         Insert into calculo_glosa(
                 cod_trabajador, item, fecha_reg, glosa, cod_usr)
         values(
                 lc_reg.tripulante, 3, adi_fec_proceso, 'Periodo de Pesca: ' || to_char(ld_fecha1, 'dd/mm/yyyy') || '-' || to_char(ld_fecha2, 'dd/mm/yyyy') , asi_usuario);
      END IF;

  end loop;
  

	commit;

end USP_FL_TRANSF_PLA_EXT;
/
