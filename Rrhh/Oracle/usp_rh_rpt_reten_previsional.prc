create or replace procedure usp_rh_rpt_reten_previsional (
  as_origen in char, as_ano in char ) is

ls_codigo        char(8) ;
ls_quiebre       char(2) ;
ls_nombre_afp    varchar2(30) ;
ls_afp           char(15) ;
ls_ipss          char(15) ;
ls_afp_ipss      char(15) ;
ls_mes           char(2) ;
ln_contador      integer ;
ln_item          number(4) ;
ln_importe       number(13,2) ;
ln_imp01         number(13,2) ;
ln_imp02         number(13,2) ;
ln_imp03         number(13,2) ;
ln_imp04         number(13,2) ;
ln_imp05         number(13,2) ;
ln_imp06         number(13,2) ;
ln_imp07         number(13,2) ;
ln_imp08         number(13,2) ;
ln_imp09         number(13,2) ;
ln_imp10         number(13,2) ;
ln_imp11         number(13,2) ;
ln_imp12         number(13,2) ;
ln_sw            integer ;
ls_control       char(2) ;
ln_imp_total     number(13,2) ;

ls_empresa_nom        varchar2(50) ;
ls_empresa_dir        char(30) ;
ls_ruc                char(11) ;

--  Lectura de todos los trabajadores seleccionados
cursor c_maestro is 
  select m.cod_trabajador, m.apel_paterno, m.apel_materno, m.nombre1,
         m.nombre2, m.fec_cese, m.nro_ipss, m.cod_afp, m.nro_afp_trabaj
  from maestro m
  where m.cod_origen = as_origen
  order by m.cod_afp, m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2 ;

begin

--  ********************************************************************
--  ***   LIQUIDACION ANUAL DE APORTES Y RETENCIONES PREVISIONALES   ***   
--  ********************************************************************

delete from tt_det_retencion_aportes ;

select p.cod_empresa into ls_codigo from genparam p
  where p.reckey = '1' and p.cod_origen = as_origen ;
select e.nombre, e.dir_calle, e.ruc
  into ls_empresa_nom, ls_empresa_dir, ls_ruc
  from empresa e where e.cod_empresa = ls_codigo ;
  
ln_item := 0 ; ln_sw := 0 ;
for rc_mae in c_maestro loop

  ls_codigo   := nvl(rc_mae.cod_trabajador,' ') ;
  ls_quiebre  := nvl(rc_mae.cod_afp,' ') ;
  ls_afp      := nvl(rc_mae.nro_afp_trabaj,' ') ;
  ls_ipss     := nvl(rc_mae.nro_ipss,' ') ;
  
  if ln_sw = 0 then
    ls_control := nvl(rc_mae.cod_afp,' ') ;
    if ls_quiebre = ls_control then
      ln_item := 0 ;
      ln_sw := 1 ;
    end if ;
  end if ;

  if ls_quiebre <> ls_control then
    ln_item := 0 ;
    ls_control := nvl(rc_mae.cod_afp,' ') ;
  end if ;

  ln_imp01 := 0 ; ln_imp02 := 0 ; ln_imp03 := 0 ; ln_imp04 := 0 ;
  ln_imp05 := 0 ; ln_imp06 := 0 ; ln_imp07 := 0 ; ln_imp08 := 0 ;
  ln_imp09 := 0 ; ln_imp10 := 0 ; ln_imp11 := 0 ; ln_imp12 := 0 ;
  if ls_quiebre = ' ' then
    ls_afp_ipss := ls_ipss ;
    ln_item := ln_item + 1 ;
    ls_nombre_afp := 'O.N.P.' ;
    for x in 1 .. 12 loop
      ls_mes := lpad(ltrim(rtrim(to_char(x))),2,'0') ;
      ln_contador := 0 ;
      select count(*)
        into ln_contador
        from historico_calculo c
        where c.cod_trabajador = ls_codigo and substr(c.concep,1,3) = '200' and
              to_char(c.fec_calc_plan,'MM') = ls_mes and
              to_char(c.fec_calc_plan,'YYYY') = as_ano ;
      if ln_contador > 0 then
        ln_importe := 0 ;
        select sum(nvl(c.imp_soles,0))
          into ln_importe
          from historico_calculo c
          where c.cod_trabajador = ls_codigo and substr(c.concep,1,3) = '200' and
                to_char(c.fec_calc_plan,'MM') = ls_mes and
                to_char(c.fec_calc_plan,'YYYY') = as_ano ;
        if x = 1 then
          ln_imp01 := ln_importe ;
        elsif x = 2 then
          ln_imp02 := ln_importe ;
        elsif x = 3 then
          ln_imp03 := ln_importe ;
        elsif x = 4 then
          ln_imp04 := ln_importe ;
        elsif x = 5 then
          ln_imp05 := ln_importe ;
        elsif x = 6 then
          ln_imp06 := ln_importe ;
        elsif x = 7 then
          ln_imp07 := ln_importe ;
        elsif x = 8 then
          ln_imp08 := ln_importe ;
        elsif x = 9 then
          ln_imp09 := ln_importe ;
        elsif x = 10 then
          ln_imp10 := ln_importe ;
        elsif x = 11 then
          ln_imp11 := ln_importe ;
        elsif x = 12 then
          ln_imp12 := ln_importe ;
        end if ;
      end if ;
    end loop ;
  else
    ls_afp_ipss := ls_afp ;
    ln_item := ln_item + 1 ;
    select nvl(afp.desc_afp,' ')
      into ls_nombre_afp
      from admin_afp afp
      where afp.cod_afp = ls_quiebre ;
    for x in 1 .. 12 loop
      ls_mes := lpad(ltrim(rtrim(to_char(x))),2,'0') ;
      ln_contador := 0 ;
      select count(*)
        into ln_contador
        from historico_calculo c
        where c.cod_trabajador = ls_codigo and substr(c.concep,1,3) = '200' and
              to_char(c.fec_calc_plan,'MM') = ls_mes and
              to_char(c.fec_calc_plan,'YYYY') = as_ano ;
      if ln_contador > 0 then
        ln_importe := 0 ;
        select sum(nvl(c.imp_soles,0))
          into ln_importe
          from historico_calculo c
          where c.cod_trabajador = ls_codigo and substr(c.concep,1,3) = '200' and
                to_char(c.fec_calc_plan,'MM') = ls_mes and
                to_char(c.fec_calc_plan,'YYYY') = as_ano ;
        if x = 1 then
          ln_imp01 := ln_importe ;
        elsif x = 2 then
          ln_imp02 := ln_importe ;
        elsif x = 3 then
          ln_imp03 := ln_importe ;
        elsif x = 4 then
          ln_imp04 := ln_importe ;
        elsif x = 5 then
          ln_imp05 := ln_importe ;
        elsif x = 6 then
          ln_imp06 := ln_importe ;
        elsif x = 7 then
          ln_imp07 := ln_importe ;
        elsif x = 8 then
          ln_imp08 := ln_importe ;
        elsif x = 9 then
          ln_imp09 := ln_importe ;
        elsif x = 10 then
          ln_imp10 := ln_importe ;
        elsif x = 11 then
          ln_imp11 := ln_importe ;
        elsif x = 12 then
          ln_imp12 := ln_importe ;
        end if ;
      end if ;
    end loop ;
  end if ;

  ln_imp_total := ln_imp01 + ln_imp02 + ln_imp03 + ln_imp04 + ln_imp05 + ln_imp06 +
                  ln_imp07 + ln_imp08 + ln_imp09 + ln_imp10 + ln_imp11 + ln_imp12 ;

  if ln_imp_total <> 0 then                  
    insert into tt_det_retencion_aportes (
      empresa_nom, empresa_dir, ruc, periodo, quiebre, codtra,
      nombre_afp, item, nro_afp_ipss, paterno, materno,
      nombre1, nombre2, imp01, imp02, imp03, imp04,
      imp05, imp06, imp07, imp08, imp09, imp10, imp11, imp12,
      fec_cese )
    values (
      ls_empresa_nom, ls_empresa_dir, ls_ruc, as_ano, ls_quiebre, ls_codigo,
      ls_nombre_afp, ln_item, ls_afp_ipss, rc_mae.apel_paterno, rc_mae.apel_materno,
      rc_mae.nombre1, rc_mae.nombre2, ln_imp01, ln_imp02, ln_imp03, ln_imp04,
      ln_imp05, ln_imp06, ln_imp07, ln_imp08, ln_imp09, ln_imp10, ln_imp11, ln_imp12,
      rc_mae.fec_cese ) ;
  else
    ln_item := ln_item - 1 ;
  end if ;

end loop ;

end usp_rh_rpt_reten_previsional ;
/
