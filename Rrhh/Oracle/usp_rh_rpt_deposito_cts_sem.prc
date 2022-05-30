create or replace procedure usp_rh_rpt_deposito_cts_sem (
  as_tipo_trabajador in char, ad_fec_proceso in date, as_origen in char ) is

ls_codigo         maestro.cod_trabajador%type ;
ls_nombres        varchar2(40) ;
ls_seccion        maestro.cod_seccion%type ;
ls_desc_seccion   varchar2(40) ;
ls_cencos         maestro.cencos%type ;
ls_desc_cencos    varchar2(40) ;
ln_imp_cts        prov_cts_gratif.prov_cts_01%type ;
ln_dias           number(6,2) ;

--  Cursor para leer los trabajadores seleccionados
cursor c_maestro is
  select m.cod_trabajador, m.cod_seccion, m.cod_area, m.cencos
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen
  order by m.cod_seccion, m.cod_trabajador ;

--  Cursor para leer provisiones de C.T.S.
cursor c_provision is
  select p.cod_trabajador, p.dias_trabaj, p.prov_cts_01, p.prov_cts_02,
         p.prov_cts_03, p.prov_cts_04, p.prov_cts_05, p.prov_cts_06
  from prov_cts_gratif p
  where p.cod_trabajador = ls_codigo ;

begin

--  ***************************************************************
--  ***   REPORTE DE LOS DEPOSITOS SEMESTRALES POR TRABAJADOR   ***
--  ***************************************************************

delete from tt_rpt_deposito_cts ;

for rc_mae in c_maestro loop

  ls_codigo   := rc_mae.cod_trabajador ;
  ls_seccion  := rc_mae.cod_seccion ;
  ls_cencos   := rc_mae.cencos ;
  ls_nombres  := usf_rh_nombre_trabajador(ls_codigo) ;

  select s.desc_seccion into ls_desc_seccion from seccion s
    where s.cod_area = rc_mae.cod_area and s.cod_seccion = ls_seccion ;

  ls_desc_cencos := null ;
  if ls_cencos is not null then
    select cc.desc_cencos into ls_desc_cencos from centros_costo cc
      where cc.cencos = ls_cencos ;
  end if ;

  for rc_pro in c_provision loop

    ln_dias    := nvl(rc_pro.dias_trabaj,0) ;
    if ln_dias > 180 then
      ln_dias := 180 ;
    end if ;
    ln_imp_cts := rc_pro.prov_cts_01 + rc_pro.prov_cts_02 + rc_pro.prov_cts_03 +
                  rc_pro.prov_cts_04 + rc_pro.prov_cts_05 + rc_pro.prov_cts_06 ;
    ln_imp_cts := nvl(ln_imp_cts,0) ;

    if ln_imp_cts <> 0 then
      insert into tt_rpt_deposito_cts (
        codigo, nombres, cod_seccion, desc_seccion, cencos, desc_cencos,
         imp_cts, dias, fecha_proceso )
      values (
        ls_codigo, ls_nombres, ls_seccion, ls_desc_seccion, ls_cencos,
        ls_desc_cencos, ln_imp_cts, ln_dias, ad_fec_proceso ) ;
    end if ;

  end loop ;

end loop ;

end usp_rh_rpt_deposito_cts_sem ;
/
