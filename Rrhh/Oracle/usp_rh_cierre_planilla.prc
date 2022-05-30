create or replace procedure usp_rh_cierre_planilla(
       asi_origen         in origen.cod_origen%Type               ,
       asi_tipo_trab      in tipo_trabajador.tipo_trabajador%Type ,
       adi_fec_proceso    in date,
       asi_tipo_planilla  in calculo.tipo_planilla%TYPE
) is


ln_count                  Number ;
ln_saldo                  cnta_crrte_detalle.imp_dscto%Type ;
lc_flag_estado            Char (1)                      ;
lc_situac_prest           Char (1)                      ;
ls_cod_relacion           proveedor.proveedor%type      ;
ld_fec_desde              date;
ld_fec_hasta              date;

--maestro de personal calculado
Cursor c_maestro is
  select distinct m.cod_trabajador ,m.cod_moneda ,m.cencos ,m.cod_seccion ,m.cod_afp
    from maestro m,
         calculo c
   where c.cod_trabajador   = m.cod_trabajador
     and m.cod_origen       = asi_origen
     and m.tipo_trabajador  = asi_tipo_trab
     and trunc(c.fec_proceso) = trunc(adi_fec_proceso)
     and c.tipo_planilla      = asi_tipo_planilla
  order by m.cod_trabajador asc ;

--cursor de inasistencia
cursor c_inasist (as_cod_trab maestro.cod_trabajador%type) is
  Select i.cod_trabajador ,i.concep   , i.fec_desde, i.fec_hasta, i.fec_movim,
         i.dias_inasist   ,i.tipo_doc , i.nro_doc, i.cod_usr, i.periodo_inicio
    from inasistencia i
   where i.cod_trabajador   = as_cod_trab
     and trunc(i.fec_movim) = adi_fec_proceso;

-- Cursor para actualizar saldos de cuentas corrientes
cursor c_saldos (ac_cod_trab maestro.cod_trabajador%type) is
  select cc.tipo_doc      ,cc.nro_doc    ,cc.flag_estado   ,
         cc.nro_cuotas    ,cc.mont_cuota ,cc.sldo_prestamo ,
         cc.cod_sit_prest
    from cnta_crrte cc
   where cc.cod_trabajador = ac_cod_trab
     and cc.flag_estado    = '1'
  order by cc.cod_trabajador, cc.tipo_doc, cc.nro_doc ;

Cursor c_saldos_detalle (ac_cod_trabajador maestro.cod_trabajador%type     ,
                         ac_tipo_doc       doc_tipo.tipo_doc%type          ,
                         ac_nro_doc        cnta_crrte_detalle.nro_doc%type  ) is
  select Nvl(ccd.nro_dscto,0.00) as nro_dscto,Nvl(ccd.imp_dscto,0.00) as imp_dscto
    from cnta_crrte_detalle ccd
   where (ccd.cod_trabajador   = ac_cod_trabajador    ) and
         (ccd.tipo_doc         = ac_tipo_doc          ) and
         (ccd.nro_doc          = ac_nro_doc           ) and
         (trunc(ccd.fec_dscto) = trunc(adi_fec_proceso)) ;


begin

  -- Obtengo el rango de fechas
  select count(*)
    into ln_count
    from rrhh_param_org r
   where r.origen = asi_origen
     and r.tipo_trabajador = asi_tipo_trab
     and trunc(r.fec_proceso) = trunc(adi_fec_proceso)
     and r.tipo_planilla      = asi_tipo_planilla;

  if ln_count = 0 then
      RAISE_APPLICATION_ERROR(-20000, 'No existe parametros de fecha de proceso para los datos ingresados'
                            || chr(13) || 'Tipo Trabajador: ' || asi_tipo_trab
                            || chr(13) || 'Origen: ' || asi_origen
                            || chr(13) || 'Fec. Proceso: ' || to_char(adi_fec_proceso, 'dd/mm/yyyy')
                            || chr(13) || 'Tipo Planilla: ' || USP_SIGRE_RRHH.of_tipo_planilla(asi_tipo_planilla));
  end if;

  -- Fechas de inicio, fin, y codigo de relacion
  select r.fec_inicio, r.fec_final, r.cod_relacion
    into ld_fec_desde, ld_fec_hasta, ls_cod_relacion
    from rrhh_param_org r
   where r.origen             = asi_origen
     and r.tipo_trabajador    = asi_tipo_trab
     and trunc(r.fec_proceso) = trunc(adi_fec_proceso)
     and r.tipo_planilla      = asi_tipo_planilla;

  --informacion historica de calculo
  Insert Into historico_calculo(
         cod_trabajador ,concep        , fec_calc_plan    , cencos          , cod_seccion    , horas_trabaj, horas_pagad,
         dias_trabaj    ,cod_moneda    , imp_soles        , imp_dolar       , cod_origen     , item        , tipo_doc_cc,
         nro_doc_cc     ,cod_afp       , tipo_trabajador  , tipo_planilla   , pesca_capturada )
  select c.cod_trabajador ,c.concep    ,c.fec_proceso     , decode(c.cencos, null, m.cencos, c.cencos), m.cod_seccion  , c.horas_trabaj ,c.horas_pag ,
         c.dias_trabaj , m.cod_moneda  ,c.imp_soles       , c.imp_dolar     , c.cod_origen   , c.item, c.tipo_doc_cc,
         c.nro_doc_cc ,m.cod_afp       ,m.tipo_trabajador , c.tipo_planilla , c.pesca_capturada
    from calculo c,
         maestro m
   where c.cod_trabajador     = m.cod_trabajador
     and m.cod_origen         = asi_origen
     and m.tipo_trabajador    = asi_tipo_trab
     and trunc(c.fec_proceso) = adi_fec_proceso
  order by c.cod_trabajador, c.concep ;


  /*Cierro los partes de produccion*/
  update tg_pd_destajo t
     set t.flag_estado = '2'
   where flag_estado = '1'
     and t.fec_parte between ld_fec_desde and ld_fec_hasta
     and t.nro_parte in ( select distinct pd.nro_parte
                            from calculo c,
                                 maestro m,
                                 tg_pd_destajo_det pd,
                                 tg_pd_destajo     p
                           where c.cod_trabajador     = m.cod_trabajador
                             and m.cod_trabajador     = pd.cod_trabajador
                             and p.nro_parte          = pd.nro_parte
                             and m.cod_origen         = asi_origen
                             and m.tipo_trabajador    = asi_tipo_trab
                             and trunc(c.fec_proceso) = adi_fec_proceso
                             and p.fec_parte between trunc(ld_fec_desde) and trunc(ld_fec_hasta)
                             and p.flag_estado = '1');

  -- Datos para guardar historico de calculo de planilla
  select count(*)
    into ln_count
    from historico_rrhh_param_org t
   where t.cod_origen = asi_origen
     and t.tipo_trabajador = asi_tipo_trab
     and t.fec_proceso     = adi_fec_proceso
     and t.tipo_planilla   = asi_tipo_planilla;
  
  if ln_count = 0 then
      Insert Into historico_rrhh_param_org(
             cod_origen,tipo_trabajador,proveedor,fec_proceso,fec_inicio,fec_final, tipo_planilla )
      Values(
             asi_origen,asi_tipo_trab,ls_cod_relacion,adi_fec_proceso, ld_fec_desde, ld_fec_hasta, asi_tipo_planilla);
  end if;
  
  -- Cierre de planilla diversa
  For rc_maestro in c_maestro Loop

      --saldo de prestamo
      ln_saldo := 0.00 ;



      --ACTUALIZA CUENTA CORRIENTE
      For rc_saldos in c_saldos (rc_maestro.cod_trabajador) Loop
          For rc_saldos_det in c_saldos_detalle(rc_maestro.cod_trabajador ,
                                                 rc_saldos.tipo_doc        ,
                                                 rc_saldos.nro_doc          ) Loop

                 ln_saldo := Nvl(rc_saldos.sldo_prestamo,0) - rc_saldos_det.imp_dscto ;

                 if ln_saldo <= 0 then  --si saldo es igual a cero o menor prestamo se ha cancelado
                    lc_flag_estado  := '0' ;
                    lc_situac_prest := 'C' ;
                 else
                    lc_flag_estado  := rc_saldos.flag_estado   ;
                    lc_situac_prest := rc_saldos.cod_sit_prest ;
                 end if ;

                 --  Actualiza registro maestro de cuenta corriente
                 Update cnta_crrte cc
                    set flag_estado   = lc_flag_estado ,nro_cuotas    = rc_saldos_det.nro_dscto,
                        sldo_prestamo = ln_saldo       ,cod_sit_prest = lc_situac_prest
                  where (cc.cod_trabajador   = rc_maestro.cod_trabajador ) and
                        (cc.tipo_doc         = rc_saldos.tipo_doc        ) and
                        (cc.nro_doc          = rc_saldos.nro_doc         ) ;
           End Loop ;
      End Loop ;

      --historico de distribucion contable
      delete  historico_distrib_cntble d
         where d.cod_trabajador = rc_maestro.cod_trabajador
           and trunc(d.fec_calculo) = trunc(adi_fec_proceso);

      Insert into historico_distrib_cntble
        (cod_trabajador,    cencos,    fec_movimiento,    cod_labor,
         cod_usr       ,    nro_horas, fec_calculo,       centro_benef,
         cod_origen    ,    tipo_trabajador)
        select d.cod_trabajador,
               d.cencos,
               d.fec_movimiento,
               d.cod_labor,
               d.cod_usr,
               d.nro_horas,
               d.fec_calculo,
               d.centro_benef,
               asi_origen,
               asi_tipo_trab
          from distribucion_cntble d
         where d.cod_trabajador = rc_maestro.cod_trabajador
           and trunc(d.fec_calculo) = trunc(adi_fec_proceso);

      --Historico de Sobretiempo
      Insert into historico_sobretiempo(
             cod_trabajador ,fec_movim ,concep    ,cod_labor     ,
             tipo_doc       ,nro_doc   ,horas_sobret ,
             cod_usr        ,cencos    )
      Select st.cod_trabajador ,st.fec_movim  ,st.concep   ,
             st.cod_labor      ,st.tipo_doc   ,st.nro_doc  ,
             st.horas_sobret   ,st.cod_usr    ,st.cencos
        From sobretiempo_turno st
       Where st.cod_trabajador   = rc_maestro.cod_trabajador
         and trunc(st.fec_movim) between trunc(ld_fec_desde) and trunc(ld_fec_hasta) ;


      -- Historico de Ganancias Variables
      insert into hist_gan_desct_variable
      select *
        from gan_desct_variable gdv
       where trunc(gdv.fec_movim) between trunc(ld_fec_desde) and trunc(ld_fec_hasta)
         and gdv.cod_trabajador = rc_maestro.cod_trabajador ;


      --Historico de Inasistencia
      for rc_inasis in c_inasist(rc_maestro.cod_trabajador) LOOP
          SELECT COUNT(*)
            INTO ln_count
            FROM historico_inasistencia hc
           WHERE hc.cod_trabajador = rc_inasis.cod_trabajador
             AND hc.concep         = rc_inasis.concep
             AND hc.fec_desde      = rc_inasis.fec_desde
             and hc.fec_movim      = rc_inasis.fec_movim;

          IF ln_count = 0 THEN
             /*
             RAISE_APPLICATION_ERROR(-20000, 'Error, la inasistencia del trabajador ya ha sido procesada'
                               || chr(13) || 'Trabajador: ' || rc_inasis.cod_trabajador
                               || chr(13) || 'Concepto: ' || rc_inasis.concep
                               || chr(13) || 'Fec desde: ' || to_char(rc_inasis.fec_desde, 'dd/mm/yyyy')
                               || chr(13) || 'Fec Proceso: ' || to_char(rc_inasis.fec_movim, 'dd/mm/yyyy'));
             */
             Insert into historico_inasistencia(
                   cod_trabajador ,concep       ,fec_desde ,fec_hasta ,
                   fec_movim      ,dias_inasist ,tipo_doc  ,nro_doc   ,
                   cod_usr        ,periodo_inicio)
             Values(
                   rc_inasis.cod_trabajador,rc_inasis.concep      ,rc_inasis.fec_desde ,rc_inasis.fec_hasta,
                   rc_inasis.fec_movim     ,rc_inasis.dias_inasist,rc_inasis.tipo_doc  ,rc_inasis.nro_doc  ,
                   rc_inasis.cod_usr,      rc_inasis.periodo_inicio)  ;

          END IF;

      end loop ;

      --Historico Variable
      Insert into historico_variable(
             cod_trabajador ,fec_movim ,concep   ,proveedor ,
             cencos         ,cod_labor ,tipo_doc ,nro_doc   ,
             imp_var        ,cod_usr   ,nro_dias   )
      Select distinct
             gdv.cod_trabajador ,gdv.fec_movim ,gdv.concep   ,gdv.proveedor ,
             gdv.cencos         ,gdv.cod_labor ,gdv.tipo_doc ,gdv.nro_doc   ,
             gdv.imp_var        ,gdv.cod_usr   , gdv.nro_dias
        from gan_desct_variable gdv,
             (select gdv.cod_trabajador, gdv.fec_movim, gdv.concep
                from gan_desct_variable gdv
              minus
              select h.cod_trabajador, h.fec_movim, h.concep
                from historico_variable h) s
       Where gdv.cod_trabajador = s.cod_trabajador
         and gdv.fec_movim      = s.fec_movim
         and gdv.concep         = s.concep
         and gdv.cod_trabajador = rc_maestro.cod_trabajador
         and trunc(gdv.fec_movim) between trunc(ld_fec_desde) and trunc(ld_Fec_hasta);


       Insert Into hist_gan_desct_var_dstjo(
              cod_trabajador ,fec_movim,
              concep         ,nro_parte,
              nro_item       ,nro_sub_item)
       Select gdvd.cod_trabajador ,gdvd.fec_movim,
              gdvd.concep         ,gdvd.nro_parte,
              gdvd.nro_item       ,gdvd.nro_sub_item
         from gan_desct_var_dstjo gdvd
        where gdvd.cod_trabajador   = rc_maestro.cod_trabajador
          and trunc(gdvd.fec_movim) between trunc(ld_fec_desde) and trunc(ld_fec_hasta) ;

      
      delete historico_calculo_glosa hc
       where hc.tipo_planilla = asi_tipo_planilla
         and hc.cod_trabajador = rc_maestro.cod_trabajador
         and trunc(hc.fecha_calc) = adi_fec_proceso;
         
      -- Inserto el historico del calculo de la glosa
      Insert Into historico_calculo_glosa(
             cod_trabajador,item,fecha_calc,fecha_reg,glosa,cantidad,und,cod_usr, tipo_planilla)
      select cod_trabajador,item,fecha_reg, sysdate,  glosa,cantidad,und,cod_usr, asi_tipo_planilla
        from calculo_glosa cg
       where cg.cod_trabajador   = rc_maestro.cod_trabajador
         and trunc(cg.fecha_reg) = trunc(adi_fec_proceso)    ;


      --elimina informacion de sobretiempo
      delete from sobretiempo_turno st
       where trunc(st.fec_movim) between trunc(ld_fec_desde) and trunc(ld_fec_hasta)
         and st.cod_trabajador = rc_maestro.cod_trabajador ;

      --elimina descuento variable
       delete from gan_desct_var_dstjo hgdvd
       where hgdvd.cod_trabajador   = rc_maestro.cod_trabajador
         and trunc(hgdvd.fec_movim) between trunc(ld_fec_desde) and trunc(ld_fec_hasta) ;

      delete from gan_desct_variable gdv
       where trunc(gdv.fec_movim) between trunc(ld_fec_desde) and trunc(ld_fec_hasta)
         and gdv.cod_trabajador = rc_maestro.cod_trabajador ;

      --elimina informacion de tabla de calculo
      delete from calculo c
       where trunc(c.fec_proceso) = trunc(adi_fec_proceso)
         and c.cod_trabajador     = rc_maestro.cod_trabajador ;

      --elimina informacion de calculo glosa
      delete from calculo_glosa
      where cod_trabajador   = rc_maestro.cod_trabajador
        and trunc(fecha_reg) = trunc(adi_fec_proceso) ;

  End Loop ;

end usp_rh_cierre_planilla ;
/
