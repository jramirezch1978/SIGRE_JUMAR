create or replace procedure usp_rh_rpt_boleta_pago(
       asi_tipo_trabajador in tipo_trabajador.tipo_trabajador%TYPE, 
       asi_origen          in origen.cod_origen%TYPE, 
       asi_codigo          in maestro.cod_trabajador%TYPE,
       adi_fec_proceso     in DATE 
) is

ln_valida                 Number       ;
ln_sw                     Integer      ;
ln_verifica               Integer      ;
ls_grp_rem_basica         rrhhparam_cconcep.remunerac_basica%TYPE  ;
ls_grp_vacaciones         rrhhparam_cconcep.gan_fij_calc_vacac%TYPE;
ls_simbolo_moneda         moneda.simbolo%TYPE;

ls_nacionalidad           Varchar2(20) ;
ln_mes_proceso            Number(2)    ;
ls_ruc                    tt_boleta_pago.ruc_empresa%type     ;
ls_empresa                tt_boleta_pago.empresa%type         ;
ls_decreto_supremo        tt_boleta_pago.decreto_supremo%type ;
ls_codigo                 maestro.cod_trabajador%type         ;
ls_nombres                varchar2(40) ;
ln_contador               integer      ;
ls_ocupacion              varchar2(40) ;
ls_banda_sal              varchar2(40) ;
ls_nombre_afp             varchar2(20) ;
ls_concepto               concepto.concep%type ;
ln_sueldo_basico          number(11,2) ;
ld_fec_salida_vac         date ;
ld_fec_retorno_vac        date ;
ln_nro_horas              tt_boleta_pago.nro_horas%TYPE  ;
ln_nro_dias               tt_boleta_pago.nro_dias%TYPE ;
ls_desc_concepto          varchar2(40) ;
ls_direccion              varchar2(100) ;
ls_pers_confianza         char(15)     ;
ln_saldo_prestamo         number(13,2) ;
ls_cod_moneda             moneda.cod_moneda%TYPE      ;
ls_ganfij                 rrhhparam.grc_gnn_fija%TYPE      ;
ls_label_ingreso          tt_boleta_pago.label_ingreso%TYPE;
ln_item                   number;

-- rango de Fechas de Proceso
ld_fecha_inicio           rrhh_param_org.fec_inicio%TYPE;
ld_fecha_final            rrhh_param_org.fec_final%TYPE;

-- Variables para recorrer las fechas
ln_dias_periodo           number;
ln_dia                    number;
ld_fecha                  date;
ln_total_pesca            number;
ln_precio_pesca           number;
ln_porc_nave              number;


--  Cursor de lectura de trabajadores seleccionados
cursor c_maestro is
  select distinct 
         s.cod_trabajador , S.fec_ingreso     , s.fec_nacimiento , s.fec_cese      , 
         s.flag_sexo      , s.direccion       , s.dni            , s.nro_ipss      ,
         s.cod_cargo      , s.cod_afp         , s.banda          , s.cod_origen    , 
         s.nro_afp_trabaj , s.tipo_trabajador , s.cencos         , S.cod_categ_sal ,
         s.cod_seccion    , s.cod_pais        , s.cod_empresa    , s.cod_moneda    ,
         s.flag_ingreso_boleta, s.desc_tipo_tra
         
    from (
      select m.cod_trabajador , m.fec_ingreso     , m.fec_nacimiento , m.fec_cese      , 
             m.flag_sexo      , m.direccion       , m.dni            , m.nro_ipss      ,
             m.cod_cargo      , m.cod_afp         , m.banda          , m.cod_origen    , 
             m.nro_afp_trabaj , m.tipo_trabajador , m.cencos         , m.cod_categ_sal ,
             m.cod_seccion    , m.cod_pais        , m.cod_empresa    , m.cod_moneda    ,
             t.flag_ingreso_boleta, t.desc_tipo_tra
      from maestro m,
           tipo_trabajador t
      where m.tipo_trabajador = t.tipo_trabajador
        AND m.cod_trabajador like asi_codigo 
        AND m.tipo_trabajador like asi_tipo_trabajador 
        and m.cod_origen like asi_origen
     union
      select distinct
             m.cod_trabajador , m.fec_ingreso     , m.fec_nacimiento , m.fec_cese      , 
             m.flag_sexo      , m.direccion       , m.dni            , m.nro_ipss      ,
             m.cod_cargo      , m.cod_afp         , m.banda          , m.cod_origen    , 
             m.nro_afp_trabaj , m.tipo_trabajador , m.cencos         , m.cod_categ_sal ,
             m.cod_seccion    , m.cod_pais        , m.cod_empresa    , m.cod_moneda    ,
             t.flag_ingreso_boleta, t.desc_tipo_tra
      from maestro m,
           historico_Calculo hc,
           tipo_trabajador t
      where m.cod_trabajador        = hc.cod_trabajador
        and hc.tipo_trabajador      = t.tipo_trabajador  
        AND m.cod_trabajador        like asi_codigo 
        AND hc.tipo_trabajador      like asi_tipo_trabajador 
        and m.cod_origen            like asi_origen
        and trunc(hc.fec_calc_plan) = trunc(adi_fec_proceso)
    ) s
    
  order by cod_seccion, cod_trabajador ;

--  Cursor para leer detalle del pago por trabajador del mes actual
cursor c_calculo is
  select c.concep, c.dias_trabaj, c.horas_pag,Sum( c.imp_soles) as imp_soles, Sum(c.imp_dolar) as imp_dolar,
         c.tipo_doc_cc, c.nro_doc_cc 
  from calculo c
  where c.cod_trabajador = ls_codigo and nvl(c.imp_soles,0) <> 0 
    AND c.fec_proceso = adi_fec_proceso
group by c.cod_trabajador,c.concep, c.dias_trabaj, c.horas_pag, c.tipo_doc_cc, c.nro_doc_cc      
  order by c.cod_trabajador, c.concep ;

--  Cursor para leer detalle del pago por trabajador del historico
cursor c_historico is
  select h.concep, h.dias_trabaj, h.horas_pagad, Sum(h.imp_soles) as imp_soles,h.tipo_doc_cc,h.nro_doc_cc
  from historico_calculo h
  where h.cod_trabajador = ls_codigo and nvl(h.imp_soles,0) <> 0 
    AND h.fec_calc_plan = adi_fec_proceso
group by h.cod_trabajador,h.concep, h.dias_trabaj, h.horas_pagad, h.tipo_doc_cc, h.nro_doc_cc              
  order by h.cod_trabajador, h.concep ;

Cursor c_glosa (ac_cod_trabajador maestro.cod_trabajador%type )is
  select cg.glosa,cg.cantidad,cg.und,cg.item
    from calculo_glosa cg
   where (cg.cod_trabajador   = ac_cod_trabajador     ) 
     AND (trunc(cg.fecha_reg) = trunc(adi_fec_proceso) );
       
Cursor c_glosa_hist (ac_cod_trabajador maestro.cod_trabajador%type )is
  select cg.glosa,cg.cantidad,cg.und,cg.item
    from historico_calculo_glosa cg
   where (cg.cod_trabajador   = ac_cod_trabajador     ) 
     AND (trunc(cg.fecha_reg) = trunc(adi_fec_proceso) );       
  
Cursor c_glosa_destajo (ac_cod_trabajador maestro.cod_trabajador%type,ad_fecha_inicio date,ad_fecha_final date ) is  
select   gvd.concep,   
         trim(Nvl(concepto.desc_breve,''))||' '||trim(Nvl(l.desc_labor,'')) as descrip,
         l.und,   
         sum(poad.cant_destajada) as cantidad  ,
         count(gvd.cod_trabajador) as item
    from gan_desct_var_dstjo gvd,   
         pd_ot_asist_destajo poad,   
         pd_ot_det pod,   
         labor l,   
         concepto  
   where ( gvd.nro_parte    = poad.nro_parte      ) and  
         ( gvd.nro_item     = poad.nro_item       ) and  
         ( gvd.nro_sub_item = poad.nro_sub_item   ) and  
         ( poad.nro_parte   = pod.nro_parte       ) and  
         ( poad.nro_item    = pod.nro_item        ) and  
         ( pod.cod_labor    = l.cod_labor         ) and  
         ( concepto.concep  = gvd.concep          ) and
         ( gvd.cod_trabajador = ac_cod_trabajador ) and
         (trunc(gvd.fec_movim) between ad_fecha_inicio and ad_fecha_final )
group by gvd.cod_trabajador ,gvd.concep          ,l.cod_labor,   
         l.desc_labor       ,concepto.desc_breve ,l.und   
order by gvd.cod_trabajador ,gvd.concep          ,l.cod_labor ;

Cursor c_dias_destajo (ac_cod_trabajador maestro.cod_trabajador%type ,ad_fecha_inicio date,ad_fecha_final date  )is
  select Sum(Count(Distinct gdvd.fec_movim))as dias
    from gan_desct_var_dstjo gdvd
   where (gdvd.cod_trabajador = ac_cod_trabajador ) and
         (trunc(gdvd.fec_movim) between ad_fecha_inicio and ad_fecha_final )
  group by gdvd.fec_movim,gdvd.cod_trabajador   ;

Cursor c_hist_glosa_destajo (ac_cod_trabajador maestro.cod_trabajador%type,ad_fecha_inicio date,ad_fecha_final date ) is  
  select   hgvd.concep,   
           trim(Nvl(concepto.desc_breve,''))||' '||trim(Nvl(l.desc_labor,'')) as descrip,
           l.und,   
           sum(poad.cant_destajada) as cantidad  ,
           count(hgvd.cod_trabajador) as item
      from hist_gan_desct_var_dstjo hgvd,   
           pd_ot_asist_destajo poad,   
           pd_ot_det pod,   
           labor l,   
           concepto  
     where ( hgvd.nro_parte    = poad.nro_parte      ) and  
           ( hgvd.nro_item     = poad.nro_item       ) and  
           ( hgvd.nro_sub_item = poad.nro_sub_item   ) and  
           ( poad.nro_parte   = pod.nro_parte       ) and  
           ( poad.nro_item    = pod.nro_item        ) and  
           ( pod.cod_labor    = l.cod_labor         ) and  
           ( concepto.concep  = hgvd.concep          ) and
           ( hgvd.cod_trabajador = ac_cod_trabajador ) and
           (trunc(hgvd.fec_movim) between ad_fecha_inicio and ad_fecha_final )
  group by hgvd.cod_trabajador ,hgvd.concep          ,l.cod_labor,   
           l.desc_labor       ,concepto.desc_breve ,l.und   
  order by hgvd.cod_trabajador ,hgvd.concep          ,l.cod_labor ;


Cursor c_hist_dias_destajo (ac_cod_trabajador  maestro.cod_trabajador%type , 
                            ad_fecha_inicio    date,
                            ad_fecha_final     date  )is
  select Sum(Count(Distinct hgdvd.fec_movim))as dias
    from hist_gan_desct_var_dstjo hgdvd
   where (hgdvd.cod_trabajador = ac_cod_trabajador ) and
         (trunc(hgdvd.fec_movim) between ad_fecha_inicio and ad_fecha_final )
  group by hgdvd.fec_movim,hgdvd.cod_trabajador   ;

Cursor c_produccion (ac_cod_trabajador  maestro.cod_trabajador%type , 
                     ad_fecha_inicio    date,
                     ad_fecha_final     date  )is
  select p.cod_tarea, tt.desc_tarea,
         p.precio_unit as tarifa, ta.und,
         Sum(decode(ta.flag_destajo, '1', pd.cant_producida, pd.cant_horas_diu + pd.cant_horas_noc))as cantidad
    from tg_pd_destajo p,
         tg_pd_destajo_det pd,
         tg_tarifario      ta,
         tg_tareas         tt
   where p.nro_parte        = pd.nro_parte
     and p.cod_especie      = ta.cod_especie
     and p.cod_presentacion = ta.cod_presentacion
     and p.cod_tarea        = ta.cod_tarea
     and p.cod_tarea        = tt.cod_tarea
     and pd.cod_trabajador  = ac_cod_trabajador 
     and trunc(p.fec_parte) between ad_fecha_inicio and ad_fecha_final 
     and p.flag_estado <> '0'
  group by p.cod_tarea, tt.desc_tarea,
         p.precio_unit, ta.und   
  having Sum(decode(ta.flag_destajo, '1', pd.cant_producida, pd.cant_horas_diu + pd.cant_horas_noc)) > 0;

Cursor c_datos_pesca (asi_trabajador  maestro.cod_trabajador%TYPE,
                      adi_fecha       date) is
select flpp.tripulante,
       flpp.fecha,
       flpp.total_pesca,
       flpp.precio_pesca,
       flpp.total_partes,
       tn.porc_partic
  from fl_participacion_pesca flpp,
       tg_naves               tn
where flpp.nave               = tn.nave
  and flpp.tripulante         = asi_trabajador
  and trunc(flpp.fecha)       = trunc(adi_fecha);
                         
begin

--  ******************************************************
--  ***   EMITE BOLETAS DE PAGOS DE LOS TRABAJADORES   ***
--  ******************************************************

delete from tt_boleta_pago ;

ln_sw := 0 ;

select count(*) 
  into ln_contador 
  from calculo c,maestro m
 where c.cod_trabajador  = m.cod_trabajador      
   and c.fec_proceso     = adi_fec_proceso        
   and c.cod_origen      like asi_origen          
   and m.tipo_trabajador like asi_tipo_trabajador 
   and c.cod_trabajador  like asi_codigo ;

if ln_contador = 0 then
   select count(*) 
     into ln_contador 
     from historico_calculo hc
    where hc.fec_calc_plan   = adi_fec_proceso        
      and hc.cod_origen      like asi_origen          
      and hc.tipo_trabajador like asi_tipo_trabajador 
      and hc.cod_trabajador  like asi_codigo ;
   
   if ln_contador = 0 then
      RAISE_APPLICATION_ERROR(-20000, 'No existen boletas de trabajadores para los datos ingresados por favor verifique!'
                || chr(13) || 'Código Trabajador: ' || asi_codigo
                || chr(13) || 'Tipo Trabajador: ' || asi_tipo_trabajador
                || chr(13) || 'Fecha Proceso: ' || trim(to_char(adi_fec_proceso, 'dd/mm/yyyy')));
   end if;
else
  ln_sw := 1 ;
end if ;

select p.remunerac_basica, p.gan_fij_calc_vacac
  into ls_grp_rem_basica, ls_grp_vacaciones
  from rrhhparam_cconcep p
  where p.reckey = '1' ;

--  Decreto supremo para la emision de boletas
select count(*) 
  into ln_valida 
  from rrhhparam rhp
  where rhp.reckey = '1' ;
  
if ln_valida <> 1 then
   raise_application_error(-20000,'ORACLE: No Existen registros activos en parametros') ;
END IF;

select p.grc_gnn_fija, nvl(p.decreto_supremo, '')
  into ls_ganfij, ls_decreto_supremo
  from rrhhparam p
  where p.reckey = '1' ;
  
if ls_decreto_supremo <> '' then
   ls_decreto_supremo := 'D.S. N? ' || trim(ls_decreto_supremo) ;
end if ;

--  Lectura del maestro de trabajadores
for rc_mae in c_maestro loop

    ls_direccion   := PKG_LOGISTICA.of_get_direccion(rc_mae.cod_origen);
    ln_mes_proceso := to_number(to_char(adi_fec_proceso,'mm')) ;
  

  ls_codigo       := rc_mae.cod_trabajador ;
  ls_nombres      := Substr(usf_rh_nombre_trabajador(ls_codigo),1,40) ;

  -- Determina la empresa y el R.U.C.
  ln_valida := 0 ; ls_empresa := null ; ls_ruc := null ;
  select count(*) into ln_valida from empresa e
    where trim(e.cod_empresa) = trim(rc_mae.cod_empresa) ;
  if ln_valida > 0 then
    select nvl(e.nombre,' '), 'RUC: ' || nvl(e.ruc, ' ')
      into ls_empresa, ls_ruc
      from empresa e where trim(e.cod_empresa) = trim(rc_mae.cod_empresa) ;
  end if ;

  --  Determina el tipo de moneda
  ln_valida := 0 ; ls_simbolo_moneda := null ;
  select count(*) into ln_valida from moneda m
    where trim(m.cod_moneda) = trim(rc_mae.cod_moneda) ;
  if ln_valida > 0 then
    select m.simbolo into ls_simbolo_moneda from moneda m
      where trim(m.cod_moneda) = trim(rc_mae.cod_moneda) ;
  end if ;

  --  Determina la nacionalidad del trabajador
  ln_valida := 0 ; ls_nacionalidad := null ;
  select count(*) into ln_valida from pais p
    where p.cod_pais = rc_mae.cod_pais ;
  if ln_valida > 0 then
    select substr(p.nacionalidad,1,20)
      into ls_nacionalidad
      from pais p where p.cod_pais = rc_mae.cod_pais ;
  end if ;

  --  Determina cargo u ocupacion
  ln_valida := 0 ; ls_ocupacion := null ;
  select count(*) into ln_valida from cargo car
    where car.cod_cargo = rc_mae.cod_cargo ;
  if ln_valida > 0 then
    select car.desc_cargo into ls_ocupacion from cargo car
      where car.cod_cargo = rc_mae.cod_cargo ;
  end if ;

  --  Determina banda salarial del trabajador
  ln_valida := 0 ; ls_banda_sal := null ;
  select count(*) into ln_valida from rrhh_banda_salarial bs
    where bs.banda = rc_mae.banda ;
  if ln_valida > 0 then
    select bs.descripcion into ls_banda_sal
      from rrhh_banda_salarial bs
      where bs.banda = rc_mae.banda ;
  end if ;

  ls_pers_confianza := null ;
  if rc_mae.banda = 'NIVELA' or rc_mae.banda = 'NIVELB' then
    ls_pers_confianza := 'Pers. Confianza' ;
  end if ;

  --  Determina nombre de A.F.P. del trabajador
  ln_valida := 0 ; ls_nombre_afp := null ;
  select count(*) into ln_valida from admin_afp aa
    where aa.cod_afp = rc_mae.cod_afp ;
  if ln_valida > 0 then
    select aa.desc_afp into ls_nombre_afp from admin_afp aa
      where aa.cod_afp = rc_mae.cod_afp ;
  end if ;

  --  Determina remuneracion basica
  ln_contador := 0 ; ln_sueldo_basico := 0 ;
  select count(*) 
    into ln_contador 
    from gan_desct_fijo gdf
    where gdf.cod_trabajador = ls_codigo 
      and substr(gdf.concep,1,2) = ls_ganfij ;
      
  if ln_contador > 0 then
    select sum(nvl(gdf.imp_gan_desc,0)) into ln_sueldo_basico 
      from gan_desct_fijo gdf
      where gdf.cod_trabajador     = ls_codigo 
        and substr(gdf.concep,1,2) = ls_ganfij ;
  end if ;
  
  IF rc_mae.flag_ingreso_boleta = 'J' THEN
     if rc_mae.tipo_trabajador in ('JOR') then
        ln_sueldo_basico := ln_sueldo_basico / 30;
     else
        ln_sueldo_basico := null;
     end if;
     ls_label_ingreso := 'Jornal';
  ELSE
     ls_label_ingreso := 'Sueldo';
  END IF;

  --  Determina fecha de salida y retorno de vacaciones
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grp_vacaciones ;

  if ln_sw = 1 then
    ln_contador := 0 ; ld_fec_salida_vac := null ; ld_fec_retorno_vac := null ;
    select count(*) into ln_contador from inasistencia i
      where i.cod_trabajador = ls_codigo and i.concep = ls_concepto ;
    if ln_contador = 1 then
      select i.fec_desde, i.fec_hasta into ld_fec_salida_vac, ld_fec_retorno_vac
        from inasistencia i
        where i.cod_trabajador = ls_codigo and i.concep = ls_concepto ;
    end if ;
  else
    ln_contador := 0 ; ld_fec_salida_vac := null ; ld_fec_retorno_vac := null ;
    select count(*) into ln_contador from historico_inasistencia hi
      where hi.cod_trabajador = ls_codigo and hi.concep = ls_concepto and
            to_char(hi.fec_movim,'mm/yyyy') = to_char(adi_fec_proceso,'mm/yyyy') ;
    if ln_contador = 1 then
      select hi.fec_desde, hi.fec_hasta into ld_fec_salida_vac, ld_fec_retorno_vac
        from historico_inasistencia hi
        where hi.cod_trabajador = ls_codigo and hi.concep = ls_concepto and
              to_char(hi.fec_movim,'mm/yyyy') = to_char(adi_fec_proceso,'mm/yyyy') ;
    end if ;
  end if ;

  if ln_sw = 1 then
     select hrpo.fec_inicio,hrpo.fec_final into ld_fecha_inicio,ld_fecha_final
      from rrhh_param_org hrpo
     where (hrpo.tipo_trabajador    = rc_mae.tipo_trabajador ) and
           (hrpo.origen             = rc_mae.cod_origen      ) and
           (trunc(hrpo.fec_proceso) = adi_fec_proceso         ) ;
           
     --  Lectura al detalle del pago del trabajador del mes de proceso
     For rc_cal in c_calculo Loop
         ln_nro_dias  := nvl(rc_cal.dias_trabaj,0) ;
         ln_nro_horas := nvl(rc_cal.horas_pag,0) ;

      if ln_nro_dias  = 0 then ln_nro_dias  := null ; end if ;
      if ln_nro_horas = 0 then ln_nro_horas := null ; end if ;

      --  Determina la descripcion del concepto
      ls_desc_concepto := null ;
      select con.desc_breve into ls_desc_concepto from concepto con
        where con.concep = rc_cal.concep ;

      --  Verifica y determina saldos de prestamos de cuenta corriente
      ln_verifica := 0 ; ln_saldo_prestamo := 0 ; ls_cod_moneda := null ;
      
      select count(*) into ln_verifica from cnta_crrte cc
        where cc.cod_trabajador         = ls_codigo           and
              cc.concep                 = rc_cal.concep       and
              cc.tipo_doc               = rc_cal.tipo_doc_cc  and
              cc.nro_doc                = rc_cal.nro_doc_cc and
              nvl(cc.flag_estado,'0')   = '1'               and
              nvl(cc.cod_sit_prest,'0') = 'A'               and
              nvl(cc.sldo_prestamo,0)   > 0 ;
              
      if ln_verifica > 0 then
      
       select Nvl(cc.mont_original,0) - Sum(ccd.imp_dscto) 
         into ln_saldo_prestamo
         from cnta_crrte cc, cnta_crrte_detalle ccd
        where (cc.cod_trabajador = ccd.cod_trabajador ) and
              (cc.tipo_doc       = ccd.tipo_doc       ) and
              (cc.nro_doc        = ccd.nro_doc        ) and
              (cc.cod_trabajador = ls_codigo          ) and
              (cc.concep         = rc_cal.concep      ) and
              (cc.tipo_doc       = rc_cal.tipo_doc_cc ) and
              (cc.nro_doc        = rc_cal.nro_doc_cc  ) and
              (nvl(cc.flag_estado,'0')   = '1'        ) and
              (nvl(cc.cod_sit_prest,'0') = 'A'        ) and
              (nvl(cc.sldo_prestamo,0)   > 0          ) 
      group by  cc.mont_original,cc.cod_moneda ;
                
     
      end if ;
      
      --Verificacion y detrminacion de Saldos

      --  Inserta registro para imprimir boletas de pago
      Insert into tt_boleta_pago (
             mes_proceso ,fecha_proceso    ,seccion ,codigo    ,
             nombres     ,fecha_nacimiento ,sexo    ,domicilio ,
             nacionalidad, dni, ocupacion, fecha_ingreso,
             fecha_cese, fec_salida_vac, fec_retorno_vac, carnet_ipss,
             carnet_afp, cencos, categoria, nombre_afp,
             sueldo_basico, concepto, desc_concepto, nro_horas,
             nro_dias, importe, direccion, origen,
             tipo_trabaj, desc_trabajador, banda_sal, pers_confianza,
             decreto_supremo, empresa, ruc_empresa, moneda,
             cod_moneda, saldo_prestamo,flag_glosa, label_ingreso )
      Values (
             ln_mes_proceso         ,adi_fec_proceso        ,rc_mae.cod_seccion   ,ls_codigo          ,
             ls_nombres             ,rc_mae.fec_nacimiento ,rc_mae.flag_sexo     ,rc_mae.direccion   ,
             ls_nacionalidad        ,rc_mae.dni            ,ls_ocupacion         ,rc_mae.fec_ingreso ,
             rc_mae.fec_cese        ,ld_fec_salida_vac     ,ld_fec_retorno_vac   ,rc_mae.nro_ipss    ,
             rc_mae.nro_afp_trabaj  ,rc_mae.cencos         ,rc_mae.cod_categ_sal ,ls_nombre_afp      ,
             ln_sueldo_basico       ,rc_cal.concep         ,ls_desc_concepto     ,ln_nro_horas       ,
             ln_nro_dias            ,rc_cal.imp_soles      ,ls_direccion         ,rc_mae.cod_origen  ,
             rc_mae.tipo_trabajador ,rc_mae.desc_tipo_tra  ,ls_banda_sal         ,ls_pers_confianza  ,
             ls_decreto_supremo     ,ls_empresa            ,ls_ruc               ,ls_simbolo_moneda  ,
             ls_cod_moneda          ,ln_saldo_prestamo     ,'0', ls_label_ingreso) ;
        
    End loop ;

    
    --ingresa detalle de glosa
    For rc_glosa in c_glosa (rc_mae.cod_trabajador) loop
        Insert Into tt_boleta_pago
        (codigo   ,concepto    ,desc_concepto ,fecha_proceso ,
         origen   ,tipo_trabaj ,flag_glosa    ,cantidad      ,
         unidad   ,seccion     ,nombres       ,mes_proceso)
        Values
        (rc_mae.cod_trabajador ,'999'||trim(to_char(rc_glosa.item)),rc_glosa.glosa ,adi_fec_proceso    ,
         rc_mae.cod_origen     ,rc_mae.tipo_trabajador ,'1'            ,rc_glosa.cantidad ,
         rc_glosa.und          ,rc_mae.cod_seccion     ,ls_nombres,ln_mes_proceso);
         

    End Loop ;
    
    
    For rc_glosa_destajo in c_glosa_destajo (rc_mae.cod_trabajador,ld_fecha_inicio,ld_fecha_final) Loop
  
        Insert Into tt_boleta_pago    
        (codigo   ,concepto    ,desc_concepto ,fecha_proceso ,
         origen   ,tipo_trabaj ,flag_glosa    ,cantidad      ,
         unidad   ,seccion     ,nombres       ,mes_proceso)
        Values
        (rc_mae.cod_trabajador     ,'999'||trim(to_char(rc_glosa_destajo.item)) ,rc_glosa_destajo.descrip ,
         adi_fec_proceso            ,rc_mae.cod_origen                           ,rc_mae.tipo_trabajador   ,
         '1'                       ,rc_glosa_destajo.cantidad                   ,rc_glosa_destajo.und     ,
         rc_mae.cod_seccion        ,ls_nombres                                  ,ln_mes_proceso) ;
    End Loop ;
    
    
   --dias de destajo
   For rc_ddestajo in c_dias_destajo (rc_mae.cod_trabajador,ld_fecha_inicio,ld_fecha_final) Loop
       if rc_ddestajo.dias > 0 then
          Insert Into tt_boleta_pago
          (codigo   ,concepto    ,desc_concepto ,fecha_proceso ,
           origen   ,tipo_trabaj ,flag_glosa    ,cantidad      ,
           unidad   ,seccion     ,nombres       ,mes_proceso)
          Values
          (rc_mae.cod_trabajador,'9991','DIAS DESTAJO ' ,adi_fec_proceso     ,
           rc_mae.cod_origen    ,rc_mae.tipo_trabajador   ,'1'                ,
           rc_ddestajo.dias     ,''                      ,rc_mae.cod_seccion ,
           ls_nombres           ,ln_mes_proceso) ;
       end if ;
    End Loop ;
    
    -- Para los datos de prodiccion
    select count(*)
      into ln_contador
     from tg_pd_destajo p,
          tg_pd_destajo_det pd,
          tg_tarifario      ta,
          tg_tareas         tt
    where p.nro_parte        = pd.nro_parte
      and p.cod_especie      = ta.cod_especie
      and p.cod_presentacion = ta.cod_presentacion
      and p.cod_tarea        = ta.cod_tarea
      and p.cod_tarea        = tt.cod_tarea
      and pd.cod_trabajador  = rc_mae.cod_trabajador
      and trunc(p.fec_parte) between ld_fecha_inicio and ld_fecha_final 
      and p.flag_estado <> '0';
   
    if ln_contador > 0 then
      
       select count(*)
         into ln_contador
         from calculo c
        where c.cod_trabajador = rc_mae.cod_trabajador
          and c.fec_proceso    = trunc(adi_fec_proceso)
          and c.imp_soles      > 0;
        
        if ln_contador > 0 then
           ln_item := 1;
           For lc_reg in c_produccion (rc_mae.cod_trabajador, ld_fecha_inicio, ld_fecha_final) Loop
                
                Insert Into tt_boleta_pago    
                (codigo   ,concepto    ,desc_concepto ,fecha_proceso ,
                 origen   ,tipo_trabaj ,flag_glosa    ,cantidad      ,
                 unidad   ,seccion     ,nombres       ,mes_proceso)
                Values(
                 rc_mae.cod_trabajador     ,lpad(trim(to_char(ln_item)),5,'9') ,
                 substr(lc_reg.desc_tarea,1,20) || ' ' || to_char(lc_reg.tarifa, '999,990.0000') || '/' || lc_reg.und ,
                 adi_fec_proceso            ,rc_mae.cod_origen                           ,rc_mae.tipo_trabajador   ,
                 '1'                       ,lc_reg.cantidad                              ,null     ,
                 rc_mae.cod_seccion        ,ls_nombres                                   ,ln_mes_proceso) ;
                 
                ln_item := ln_item + 1;
           End Loop ;

        end if;
      
    end if;

    -- Para la glosa de pesca
    select count(*)
      into ln_contador
      from tt_boleta_pago t
     where t.codigo       = rc_mae.cod_trabajador;
    
    if ln_contador > 0 and rc_mae.tipo_trabajador = USP_SIGRE_RRHH.is_tipo_trip then
        ln_dias_periodo := ld_fecha_final - ld_fecha_inicio + 1;
        ln_item := 1;
        FOR ln_dia IN 0..ln_dias_periodo - 1 LOOP
           ld_fecha := ld_fecha_inicio + ln_dia;
           
           select count(*)
             into ln_contador
             from fl_participacion_pesca flpp,
                  tg_naves               tn
            where flpp.nave               = tn.nave
              and flpp.tripulante         = rc_mae.cod_trabajador
              and trunc(flpp.fecha)       = trunc(ld_fecha);
           
            if ln_contador = 0 then
                Insert Into tt_boleta_pago(
                       codigo   ,concepto    ,desc_concepto ,fecha_proceso ,
                       origen   ,tipo_trabaj ,flag_glosa    ,cantidad      ,
                       unidad   ,seccion     ,nombres       ,mes_proceso)
                Values(
                       rc_mae.cod_trabajador     ,lpad(trim(to_char(ln_item)),5,'9') ,
                       substr('DIA ' || trim(to_char(ln_item, '00')) || ' TOTAL PARTES: 00 - PESCA TM:  0.000',1,100),
                       adi_fec_proceso            ,rc_mae.cod_origen                           ,
                       rc_mae.tipo_trabajador   ,
                       '1'                       ,null                             ,null     ,
                       rc_mae.cod_seccion        ,ls_nombres                     ,ln_mes_proceso) ;
               
            else
              
                 For lc_reg in c_datos_pesca (rc_mae.cod_trabajador, ld_fecha) Loop
                        
                      Insert Into tt_boleta_pago    
                      (codigo   ,concepto    ,desc_concepto ,fecha_proceso ,
                       origen   ,tipo_trabaj ,flag_glosa    ,cantidad      ,
                       unidad   ,seccion     ,nombres       ,mes_proceso)
                      Values(
                       rc_mae.cod_trabajador     ,lpad(trim(to_char(ln_item)),5,'9') ,
                       substr('DIA ' || trim(to_char(ln_item, '00')) || ' TOTAL PARTES: ' || trim(to_char(lc_reg.total_partes, '00')) || ' - PESCA TM: ' 
                       || trim(to_char(lc_reg.total_pesca , '999,990.000')),1,100),
                       adi_fec_proceso            ,rc_mae.cod_origen                           ,rc_mae.tipo_trabajador   ,
                       '1'                       ,null                             ,null     ,
                       rc_mae.cod_seccion        ,ls_nombres                                   ,ln_mes_proceso) ;

                 End Loop ;

            end if;

            
            ln_item := ln_item + 1;
           
        END LOOP;
        
        -- Acumulo los totales
        select nvl(sum(flpp.total_pesca),0),
                 case 
                   when nvl(sum(flpp.total_pesca),0) = 0 then 0
                   else nvl(sum(flpp.total_pesca * flpp.precio_pesca),0) / nvl(sum(flpp.total_pesca),0)
                 end,
                 nvl(max(tn.porc_partic),0)
           into ln_total_pesca, ln_precio_pesca, ln_porc_nave
           from fl_participacion_pesca flpp,
                tg_naves               tn
          where flpp.nave               = tn.nave
            and flpp.tripulante         = rc_mae.cod_trabajador
            and trunc(flpp.fecha)       between trunc(ld_fecha_inicio) and trunc(ld_fecha_final);


        -- Inserto los totales finales
        Insert Into tt_boleta_pago(
                 codigo   ,concepto    ,desc_concepto ,fecha_proceso ,
                 origen   ,tipo_trabaj ,flag_glosa    ,cantidad      ,
                 unidad   ,seccion     ,nombres       ,mes_proceso)
        Values(
               rc_mae.cod_trabajador     ,lpad(trim(to_char(ln_item)),6,'9') ,
               substr('PRECIO PESCA S/.: ',1, 100),
               adi_fec_proceso            ,rc_mae.cod_origen                           ,rc_mae.tipo_trabajador   ,
               '1'                       ,ln_precio_pesca                              ,null     ,
               rc_mae.cod_seccion        ,ls_nombres                                  ,ln_mes_proceso) ;
        ln_item := ln_item + 1;

        -- Inserto el porcentaje de participacion
        Insert Into tt_boleta_pago(
                 codigo   ,concepto    ,desc_concepto ,fecha_proceso ,
                 origen   ,tipo_trabaj ,flag_glosa    ,cantidad      ,
                 unidad   ,seccion     ,nombres       ,mes_proceso)
        Values(
               rc_mae.cod_trabajador     ,lpad(trim(to_char(ln_item)),6,'9') ,
               substr('PORCENTAJE DE PARTICIPACION (%) :',1, 100),
               adi_fec_proceso            ,rc_mae.cod_origen                           ,rc_mae.tipo_trabajador   ,
               '1'                       ,ln_porc_nave                              ,null     ,
               rc_mae.cod_seccion        ,ls_nombres                                  ,ln_mes_proceso) ;

          
        ln_item := ln_item + 1;

    end if;        
  else
    --lectura de parametros en historicos
     select hrpo.fec_inicio,hrpo.fec_final into ld_fecha_inicio,ld_fecha_final
      from rrhh_param_org hrpo
     where (hrpo.tipo_trabajador    = rc_mae.tipo_trabajador ) and
           (hrpo.origen             = rc_mae.cod_origen      ) and
           (trunc(hrpo.fec_proceso) = adi_fec_proceso         ) ;
    
    
  
  
    --  Lectura al detalle del pago del trabajador del historico
    for rc_his in c_historico loop

      ln_nro_dias  := nvl(rc_his.dias_trabaj,0) ;
      ln_nro_horas := nvl(rc_his.horas_pagad,0) ;

      if ln_nro_dias  = 0 then ln_nro_dias  := null ; end if ;
      if ln_nro_horas = 0 then ln_nro_horas := null ; end if ;

      --  Determina la descripcion del concepto
      ls_desc_concepto := null ;
      select con.desc_breve into ls_desc_concepto from concepto con
        where con.concep = rc_his.concep ;
        
        
      --  Verifica y determina saldos de prestamos de cuenta corriente
      ln_verifica := 0 ; ln_saldo_prestamo := 0 ; ls_cod_moneda := null ;
      
      select count(*) into ln_verifica from cnta_crrte cc
        where cc.cod_trabajador         = ls_codigo           and
              cc.concep                 = rc_his.concep       and
              cc.tipo_doc               = rc_his.tipo_doc_cc  and
              cc.nro_doc                = rc_his.nro_doc_cc   ;
              
      if ln_verifica > 0 then
         select Nvl(cc.mont_original,0) - Sum(ccd.imp_dscto) 
           into ln_saldo_prestamo
           from cnta_crrte cc, cnta_crrte_detalle ccd
          where (cc.cod_trabajador = ccd.cod_trabajador ) and
                (cc.tipo_doc       = ccd.tipo_doc       ) and
                (cc.nro_doc        = ccd.nro_doc        ) and
                (cc.cod_trabajador = ls_codigo          ) and
                (cc.concep         = rc_his.concep      ) and
                (cc.tipo_doc       = rc_his.tipo_doc_cc ) and
                (cc.nro_doc        = rc_his.nro_doc_cc  ) and
                (trunc(ccd.fec_dscto) <= adi_fec_proceso )
         group by  cc.mont_original,cc.cod_moneda ;
                
      end if ;
  
      --  Inserta registro para imprimir boletas de pago
      Insert into tt_boleta_pago(
             mes_proceso     , fecha_proceso    ,seccion         , codigo         ,
             nombres         , fecha_nacimiento ,sexo            , domicilio      ,
             nacionalidad    , dni              ,ocupacion       , fecha_ingreso  ,
             fecha_cese      , fec_salida_vac   ,fec_retorno_vac , carnet_ipss    ,
             carnet_afp      , cencos           ,categoria       , nombre_afp     ,
             sueldo_basico   , concepto         ,desc_concepto   , nro_horas      ,
             nro_dias        , importe          ,direccion       , origen         ,
             tipo_trabaj     , desc_trabajador  ,banda_sal       , pers_confianza ,
             decreto_supremo , empresa          ,ruc_empresa     , moneda         ,
             cod_moneda      , saldo_prestamo   ,flag_glosa      , label_ingreso  )
      Values(
             ln_mes_proceso        , adi_fec_proceso      , rc_mae.cod_seccion  , ls_codigo,
             ls_nombres            , rc_mae.fec_nacimiento, rc_mae.flag_sexo    , rc_mae.direccion,
             ls_nacionalidad       , rc_mae.dni           , ls_ocupacion        , rc_mae.fec_ingreso,
             rc_mae.fec_cese       , ld_fec_salida_vac    , ld_fec_retorno_vac  , rc_mae.nro_ipss,
             rc_mae.nro_afp_trabaj , rc_mae.cencos        , rc_mae.cod_categ_sal, ls_nombre_afp,
             ln_sueldo_basico      , rc_his.concep        , ls_desc_concepto    , ln_nro_horas,
             ln_nro_dias           , rc_his.imp_soles     , ls_direccion        , rc_mae.cod_origen,
             rc_mae.tipo_trabajador, rc_mae.desc_tipo_tra , ls_banda_sal        , ls_pers_confianza,
             ls_decreto_supremo    , ls_empresa           , ls_ruc              , ls_simbolo_moneda,
             null                  , ln_saldo_prestamo    , '0'                 , ls_label_ingreso ) ;

    end loop ;


    --ingresa detalle de glosa
    For rc_glosa_hist in c_glosa_hist(rc_mae.cod_trabajador) loop
        Insert Into tt_boleta_pago
        (codigo   ,concepto    ,desc_concepto ,fecha_proceso ,
         origen   ,tipo_trabaj ,flag_glosa    ,cantidad      ,
         unidad   ,seccion     ,nombres       ,mes_proceso   )
        Values
        (rc_mae.cod_trabajador ,'999'||trim(to_char(rc_glosa_hist.item)),rc_glosa_hist.glosa    ,
         adi_fec_proceso        ,rc_mae.cod_origen                       ,rc_mae.tipo_trabajador ,
         '1'                   ,rc_glosa_hist.cantidad                  ,rc_glosa_hist.und      ,
         rc_mae.cod_seccion    ,ls_nombres                              ,ln_mes_proceso         );
         

    End Loop ;
    
     For rc_glosa_destajo in c_hist_glosa_destajo (rc_mae.cod_trabajador,ld_fecha_inicio,ld_fecha_final) Loop
  
        Insert Into tt_boleta_pago    
        (codigo   ,concepto    ,desc_concepto ,fecha_proceso ,
         origen   ,tipo_trabaj ,flag_glosa    ,cantidad      ,
         unidad   ,seccion     ,nombres       ,mes_proceso)
        Values
        (rc_mae.cod_trabajador     ,'999'||trim(to_char(rc_glosa_destajo.item)) ,rc_glosa_destajo.descrip ,
         adi_fec_proceso            ,rc_mae.cod_origen                           ,rc_mae.tipo_trabajador   ,
         '1'                       ,rc_glosa_destajo.cantidad                   ,rc_glosa_destajo.und     ,
         rc_mae.cod_seccion        ,ls_nombres                                  ,ln_mes_proceso) ;
    End Loop ;


    --dias de destajo
   For rc_ddestajo in c_hist_dias_destajo (rc_mae.cod_trabajador,ld_fecha_inicio,ld_fecha_final) Loop
       if rc_ddestajo.dias > 0 then
          Insert Into tt_boleta_pago
          (codigo   ,concepto    ,desc_concepto ,fecha_proceso ,
           origen   ,tipo_trabaj ,flag_glosa    ,cantidad      ,
           unidad   ,seccion     ,nombres       ,mes_proceso)
          Values
          (rc_mae.cod_trabajador,'9991','DIAS DESTAJO ' ,adi_fec_proceso     ,
           rc_mae.cod_origen    ,rc_mae.tipo_trabajador   ,'1'                ,
           rc_ddestajo.dias     ,''                      ,rc_mae.cod_seccion ,
           ls_nombres           ,ln_mes_proceso) ;
       end if ;
    End Loop ;
    
    -- Para los datos de prodiccion
    select count(*)
      into ln_contador
     from tg_pd_destajo p,
          tg_pd_destajo_det pd,
          tg_tarifario      ta,
          tg_tareas         tt
    where p.nro_parte        = pd.nro_parte
      and p.cod_especie      = ta.cod_especie
      and p.cod_presentacion = ta.cod_presentacion
      and p.cod_tarea        = ta.cod_tarea
      and p.cod_tarea        = tt.cod_tarea
      and pd.cod_trabajador  = rc_mae.cod_trabajador
      and trunc(p.fec_parte) between ld_fecha_inicio and ld_fecha_final 
      and p.flag_estado <> '0';
   
    if ln_contador > 0 then
      
       select count(*)
         into ln_contador
         from historico_calculo c
        where c.cod_trabajador = rc_mae.cod_trabajador
          and c.fec_calc_plan  = trunc(adi_fec_proceso)
          and c.imp_soles      > 0;
        
        if ln_contador > 0 then
            
           ln_item := 1;
           For lc_reg in c_produccion (rc_mae.cod_trabajador, ld_fecha_inicio, ld_fecha_final) Loop
                
                Insert Into tt_boleta_pago    
                (codigo   ,concepto    ,desc_concepto ,fecha_proceso ,
                 origen   ,tipo_trabaj ,flag_glosa    ,cantidad      ,
                 unidad   ,seccion     ,nombres       ,mes_proceso)
                Values(
                 rc_mae.cod_trabajador     ,lpad(trim(to_char(ln_item)),5,'9') ,
                 substr(lc_reg.desc_tarea,1,20) || ' ' || to_char(lc_reg.tarifa, '999,990.0000') || '/' || lc_reg.und ,
                 adi_fec_proceso            ,rc_mae.cod_origen                           ,rc_mae.tipo_trabajador   ,
                 '1'                       ,lc_reg.cantidad                              ,null     ,
                 rc_mae.cod_seccion        ,ls_nombres                                   ,ln_mes_proceso) ;
                 
                ln_item := ln_item + 1;
           End Loop ;

        end if;
      
    end if;


  end if ;

end loop ;

commit;


end usp_rh_rpt_boleta_pago ;
/
