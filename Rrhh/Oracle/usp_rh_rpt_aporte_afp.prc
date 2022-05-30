create or replace procedure usp_rh_rpt_aporte_afp (
  as_tipo_trabaj in char, as_origen in char, as_empresa in char,
  ad_fec_proceso in date ) is

lk_apor_oblig       constant char(3):= '033' ;
lk_apor_seguro      constant char(3):= '034' ;
lk_apor_comis       constant char(3):= '035' ;
lk_afectos_afp      constant char(3):= '036' ;

ls_codtra           maestro.cod_trabajador%type ;
ls_nombre           varchar2(100) ;
ls_concepto         char(4) ;
ls_afp              admin_afp.cod_afp%type ;
ls_nro_afp_trab     maestro.nro_afp_trabaj%type ;
ls_desc_afp         admin_afp.desc_afp%type ;
ln_apor_oblig       tt_rpt_aporte_afp.aporte_oblig%type ;
ln_tot_fon_pens     tt_rpt_aporte_afp.fondo_pension%type ;
ln_apor_seguro      tt_rpt_aporte_afp.aporte_seguro%type ;
ln_apor_comis       tt_rpt_aporte_afp.aporte_comision%type ;
ln_tot_ret_red      tt_rpt_aporte_afp.retenc_distrib%type ;
ln_contador         integer ;
ln_verifica         integer ;

--  Lectura de conceptos afectos a las A.F.P.
cursor c_calculo is
  select c.cod_trabajador, c.fec_proceso, sum(c.imp_soles) as remun_aseg
  from calculo c, maestro m
  where c.cod_trabajador = m.cod_trabajador and m.cod_origen = as_origen and
        m.tipo_trabajador = as_tipo_trabaj and c.fec_proceso = ad_fec_proceso and
        nvl(m.flag_estado,'0') = '1' and nvl(m.cod_afp,' ') <> ' ' and
        c.concep in ( select d.concepto_calc from grupo_calculo_det d where
                      d.grupo_calculo = lk_afectos_afp )
  group by c.cod_trabajador, c.fec_proceso ;

begin

--  *****************************************************************
--  ***   REPORTE A LAS ADMINISTRACIONES DE FONDOS DE PENSIONES   ***
--  *****************************************************************

delete from tt_rpt_aporte_afp ;

for rc_c in c_calculo loop

  ls_codtra := rc_c.cod_trabajador ;
  ls_nombre := usf_rh_nombre_trabajador(ls_codtra) ;

  select m.cod_afp, m.nro_afp_trabaj, a.desc_afp
    into ls_afp, ls_nro_afp_trab, ls_desc_afp
    from maestro m, admin_afp a
    where m.cod_afp = a.cod_afp(+) and m.cod_trabajador = ls_codtra ;

  if ls_afp is not null or ls_nro_afp_trab is not null then

    --  Importe de Aporte Obligatorio
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_apor_oblig ;
    ln_verifica := 0 ; ln_apor_oblig := 0 ;
    select count(*) into ln_verifica from calculo c
      where c.concep = ls_concepto and c.cod_trabajador = ls_codtra ;
    if ln_verifica > 0 then
      select c.imp_soles into ln_apor_oblig from calculo c
        where c.concep = ls_concepto and c.cod_trabajador = ls_codtra ;
    end if ;

    --  Total de Fondo de Pensiones
    ln_tot_fon_pens := ln_apor_oblig ;

    --  Importe de Aporte del Seguro
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_apor_seguro ;
    ln_verifica := 0 ; ln_apor_seguro := 0 ;
    select count(*) into ln_verifica from calculo c
      where c.concep = ls_concepto and c.cod_trabajador = ls_codtra ;
    if ln_verifica > 0 then
      select c.imp_soles into ln_apor_seguro from calculo c
        where c.concep = ls_concepto and c.cod_trabajador = ls_codtra ;
    end if ;

    --  Importe de Comision
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_apor_comis ;
    ln_verifica := 0 ; ln_apor_comis := 0 ;
    select count(*) into ln_verifica from calculo c
      where c.concep = ls_concepto and c.cod_trabajador = ls_codtra ;
    if ln_verifica > 0 then
      select c.imp_soles into ln_apor_comis from calculo c
        where c.concep = ls_concepto and c.cod_trabajador = ls_codtra ;
    end if ;

    --  Total Retencion de Retribucion
    ln_tot_ret_red := ln_apor_seguro + ln_apor_comis ;

    --  Inserta datos en la tabla temporal
    insert into tt_rpt_aporte_afp (
      cod_trabajador, cod_empresa, cod_afp, desc_afp, nro_afp, nombre,
      fec_proceso, remun_asegur, aporte_oblig, fondo_pension,
      aporte_seguro, aporte_comision, retenc_distrib )
    values (
      ls_codtra, as_empresa, ls_afp, ls_desc_afp, ls_nro_afp_trab, ls_nombre,
      rc_c.fec_proceso, rc_c.remun_aseg, ln_apor_oblig, ln_tot_fon_pens,
      ln_apor_seguro, ln_apor_comis, ln_tot_ret_red ) ;

  end if ;

end loop ;

end usp_rh_rpt_aporte_afp ;
/
