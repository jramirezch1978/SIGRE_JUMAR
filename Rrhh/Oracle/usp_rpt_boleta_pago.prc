create or replace procedure usp_rpt_boleta_pago
  ( as_tipo_trabajador  in maestro.tipo_trabajador%type ) is
  
ln_mes_proceso            number(2) ;
ld_fecha_proceso          date ;
ls_seccion                char(3) ;
ls_codigo                 maestro.cod_trabajador%type ;
ls_nombres                varchar2(40) ;
ld_fecha_nacimiento       date ;
ls_sexo                   char(1) ;
ls_domicilio              varchar2(100) ;
ls_nacionalidad           varchar2(20) ;
ls_dni                    maestro.dni%type ;
ls_ocupacion              varchar2(40) ;
ld_fecha_ingreso          date ;
ld_fecha_cese             date ;
ld_fec_salida_vac         date ;
ld_fec_retorno_vac        date ;
ls_carnet_ipss            maestro.nro_ipss%type ;
ls_carnet_afp             maestro.nro_afp_trabaj%type ;
ls_cencos                 maestro.cencos%type ;
ls_categoria              char(2) ;
ls_nombre_afp             varchar2(20) ;
ln_sueldo_basico          number(11,2) ;
ls_concepto               concepto.concep%type ;
ls_desc_concepto          varchar2(40) ;
ln_nro_horas              number(5,2) ;
ln_nro_dias               number(5,2) ;
ln_importe                number(11,2) ;

ls_cod_cargo              maestro.cod_cargo%type ;
ls_cod_afp                maestro.cod_afp%type ;
ln_contador               number(15) ;

--  Cursor para leer todos los Obreros o Empleados
cursor c_maestro is 
  Select m.cod_trabajador, m.fec_ingreso, m.fec_nacimiento,
         m.fec_cese, m.flag_sexo, m.direccion, m.dni,
         m.nro_ipss, m.cod_cargo, m.cod_afp, m.nro_afp_trabaj,
         m.cencos, m.cod_categ_sal, m.cod_seccion
  from maestro m
  where m.flag_estado     = '1' and
        m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador
  order by m.cod_seccion, m.cod_trabajador ;

--  Cursor para leer detalle del pago por trabajador
cursor c_calculo is 
  Select c.concep, c.dias_trabaj, c.horas_pag, c.imp_soles
  from calculo c
  where c.cod_trabajador = ls_codigo and
        c.imp_soles <> 0
  order by c.cod_trabajador, c.concep ;

begin

delete from tt_boleta_pago ;

select p.fec_proceso
  into ld_fecha_proceso
  from rrhh_param_org p
  where p.origen = 'PR' ;
  
--Select rh.fec_proceso
--  into ld_fecha_proceso
 -- from rrhhparam rh where rh.reckey = '1' ;
ln_mes_proceso := to_char(ld_fecha_proceso, 'MM') ;   

--  Lectura de todos los trabajador activos
For rc_mae in c_maestro Loop

  ls_seccion          := rc_mae.cod_seccion ;
  ls_codigo           := rc_mae.cod_trabajador ;
  ld_fecha_nacimiento := rc_mae.fec_nacimiento ;
  ls_sexo             := rc_mae.flag_sexo ;
  ls_domicilio        := rc_mae.direccion ;
  ls_nacionalidad     := 'PERUANA' ;
  ls_dni              := rc_mae.dni ;
  ls_cod_cargo        := rc_mae.cod_cargo ;
  ld_fecha_ingreso    := rc_mae.fec_ingreso ;
  ld_fecha_cese       := rc_mae.fec_cese ;
  ls_carnet_ipss      := rc_mae.nro_ipss ;
  ls_carnet_afp       := rc_mae.nro_afp_trabaj ;
  ls_cod_afp          := rc_mae.cod_afp ;
  ls_cencos           := rc_mae.cencos ;
  ls_categoria        := rc_mae.cod_categ_sal ;
  ls_nombres          := usf_nombre_trabajador(ls_codigo) ;
       
  --  Determina cargo u ocupacion
  ln_contador := 0 ; ls_ocupacion := ' ' ;
  Select count(*)
    into ln_contador
    from cargo car
    where car.cod_cargo = ls_cod_cargo ;
  ln_contador := nvl(ln_contador,0) ;
  If ln_contador > 0 then
    Select car.desc_cargo
      into ls_ocupacion
      from cargo car
      where car.cod_cargo = ls_cod_cargo ;
  End if ;

  --  Determina nombre de A.F.P.
  ln_contador := 0 ; ls_nombre_afp := ' ' ;
  Select count(*)
    into ln_contador
    from admin_afp aa
    where aa.cod_afp = ls_cod_afp ;
  ln_contador := nvl(ln_contador,0) ;
  If ln_contador > 0 then
    Select aa.desc_afp
      into ls_nombre_afp
      from admin_afp aa
      where aa.cod_afp = ls_cod_afp ;
  End if ;

  --  Determina remuneracion basica
  ln_contador := 0 ; ln_sueldo_basico := 0 ;
  Select count(*)
    into ln_contador
    from gan_desct_fijo gdf
    where gdf.cod_trabajador = ls_codigo and
          gdf.concep = '1001' ;
  ln_contador := nvl(ln_contador,0) ;
  If ln_contador > 0 then
    Select gdf.imp_gan_desc
      into ln_sueldo_basico
      from gan_desct_fijo gdf
      where gdf.cod_trabajador = ls_codigo and
            gdf.concep = '1001' ;
  End if ;

  --  Determina fecha de salida y retorno de vacaciones
  ln_contador := 0 ; ld_fec_salida_vac := null ; ld_fec_retorno_vac := null ;
  Select count(*)
    into ln_contador
    from inasistencia i
    where i.cod_trabajador = ls_codigo and
          i.concep = '1413' ;
  ln_contador := nvl(ln_contador,0) ;
  If ln_contador = 1 then
    Select i.fec_desde, i.fec_hasta
      into ld_fec_salida_vac, ld_fec_retorno_vac
      from inasistencia i
      where i.cod_trabajador = ls_codigo and
            i.concep = '1413' ;
  End if ;

  --  Lectura de detalle del pago del trabajador
  For rc_cal in c_calculo Loop

    ls_concepto  := rc_cal.concep ;
    ln_nro_dias  := rc_cal.dias_trabaj ;
    ln_nro_horas := rc_cal.horas_pag ;
    ln_importe   := rc_cal.imp_soles ;
    If ln_nro_dias = 0 then
      ln_nro_dias := null ;
    End if ;
    If ln_nro_horas = 0 then
      ln_nro_horas := null ;
    End if ;
          
    --  Halla descripcion del concepto
    ls_desc_concepto := ' ' ;
    Select con.desc_breve
      into ls_desc_concepto
      from concepto con
      where con.concep = ls_concepto ;

    --  Inserta registro para imprimir boletas de pago
    Insert into tt_boleta_pago (
      mes_proceso, fecha_proceso, seccion, codigo,
      nombres, fecha_nacimiento, sexo, domicilio,
      nacionalidad, dni, ocupacion, fecha_ingreso,
      fecha_cese, fec_salida_vac, fec_retorno_vac, carnet_ipss,
      carnet_afp, cencos, categoria, nombre_afp,
      sueldo_basico, concepto, desc_concepto, nro_horas,
      nro_dias, importe )
    Values (
      ln_mes_proceso, ld_fecha_proceso, ls_seccion, ls_codigo,
      ls_nombres, ld_fecha_nacimiento, ls_sexo, ls_domicilio,
      ls_nacionalidad, ls_dni, ls_ocupacion, ld_fecha_ingreso,
      ld_fecha_cese, ld_fec_salida_vac, ld_fec_retorno_vac, ls_carnet_ipss,
      ls_carnet_afp, ls_cencos, ls_categoria, ls_nombre_afp,
      ln_sueldo_basico, ls_concepto, ls_desc_concepto, ln_nro_horas,
      ln_nro_dias, ln_importe) ;

  End loop ;

End loop ;

End usp_rpt_boleta_pago ;
/
