create or replace procedure usp_rh_formulario_sunat600 (
  as_origen in char, ad_fec_proceso in date, as_tipo_trabaj in char ) is

lk_quinta_categoria   char(3) ;
lk_essalud            char(3) ;
lk_snp                char(3) ;
lk_tipo_trabajador    constant char(3) := 'EMP' ;

ls_concepto           char(4) ;
ls_dni                char(15) ;
ls_cod_afp            maestro.cod_afp%type ;
ln_dias_emp           number(4,2) ;
ln_dias_obr           number(4,2) ;
ln_dias               number(2) ;
ls_dias               char(2) ;
ln_imp_essalud_emp    number(15) ;
ls_imp_essalud_emp    char(15) ;
ln_imp_snp_no_afp     number(15) ;
ls_imp_snp_no_afp     char(15) ;
ln_imp_snp_afp        number(15) ;
ls_imp_snp_afp        char(15) ;
ls_imp_artista        char(15) ;
ln_imp_quinta         number(15) ;
ls_imp_quinta         char(15) ;
ln_desc_quinta        number(15) ;
ls_desc_quinta        char(15) ;

ls_sunat              char(117) ;
ls_cod_trab           maestro.cod_trabajador%type ;
ln_dias_mes           rrhhparam.dias_mes_obrero%type ;

--  Lectura de trabajadores para generar formulario 0600
cursor c_trabajadores is
  select distinct c.cod_trabajador, m.tipo_trabajador
  from calculo c, maestro m
  where m.cod_trabajador = c.cod_trabajador and m.flag_estado = '1' and
        m.flag_cal_plnlla = '1' and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj ;

begin

--  ************************************************
--  ***   GENERA FORMULARIO 0600 PARA LA SUNAT   ***
--  ************************************************

select c.quinta_cat_proyecta, c.concep_essalud, c.snp
  into lk_quinta_categoria, lk_essalud, lk_snp
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

delete from tt_sunat600 ;

select nvl(p.dias_mes_empleado,0), nvl(p.dias_mes_obrero,0)
  into ln_dias_emp, ln_dias_obr from rrhhparam p where p.reckey = '1' ;

select g.concepto_gen into ls_concepto from grupo_calculo g
  where g.grupo_calculo = lk_quinta_categoria ;

for rc_t in c_trabajadores loop

  select nvl(m.dni,' '), nvl(m.cod_afp,' ')
    into ls_dni, ls_cod_afp from maestro m
    where m.cod_trabajador = rc_t.cod_trabajador ;

  if rc_t.tipo_trabajador = lk_tipo_trabajador then
    ln_dias_mes := ln_dias_emp ;
  else
    ln_dias_mes := ln_dias_obr ;
  end if ;

  ls_cod_trab := rc_t.cod_trabajador ;
  ln_dias     := usf_rh_cal_dia_tra_sun (ls_cod_trab, ln_dias_mes, as_origen) ;
  ls_dias     := to_char(ln_dias) ;

  --  Suma importe afecto a essalud
  select sum(c.imp_soles) into ln_imp_essalud_emp from calculo c
   where c.cod_trabajador = ls_cod_trab and c.concep in ( select d.concepto_calc
          from grupo_calculo_det d where d.grupo_calculo = lk_essalud ) and
          to_char(c.fec_proceso,'mm')= to_char(ad_fec_proceso,'mm') ;
  ln_imp_essalud_emp := nvl(ln_imp_essalud_emp,0) ;

  if ln_imp_essalud_emp > 0 then

    ls_imp_essalud_emp := to_char(ln_imp_essalud_emp) ;
    --  Suma importe afecto al S.N.P.
    if ls_cod_afp = '  ' then
      select sum(c.imp_soles) into ln_imp_snp_no_afp from calculo c
        where c.cod_trabajador = rc_t.cod_trabajador and c.concep in ( select d.concepto_calc
              from grupo_calculo_det d where d.grupo_calculo = lk_snp ) and
              to_char(c.fec_proceso,'mm')= to_char(ad_fec_proceso,'mm') ;
      ls_imp_snp_no_afp := to_char(ln_imp_snp_no_afp) ;
      ls_imp_snp_no_afp := nvl(ls_imp_snp_no_afp,' ') ;
    else
      ls_imp_snp_no_afp := ' ' ;
    end if ;

    --  Suma importe afectos al S.N.P.
    select sum(c.imp_soles) into ln_imp_snp_afp from calculo c
      where c.cod_trabajador = rc_t.cod_trabajador and c.concep in ( select d.concepto_calc
            from grupo_calculo_det d where d.grupo_calculo = lk_snp) and
            to_char(c.fec_proceso,'mm')= to_char(ad_fec_proceso,'mm') ;
    ls_imp_snp_afp := to_char(ln_imp_snp_afp) ;
    ls_imp_snp_afp := nvl(ls_imp_snp_afp,' ') ;

    --  Inicializa datos del artista
    ls_imp_artista := ' ' ;

    --  Suma conceptos afectos a 5ta. categoria
    select sum(c.imp_soles) into ln_imp_quinta from calculo c
      where c.cod_trabajador = rc_t.cod_trabajador and c.concep in ( select d.concepto_calc
            from grupo_calculo_det d where d.grupo_calculo = lk_quinta_categoria ) and
            to_char(c.fec_proceso,'mm') = to_char(ad_fec_proceso,'mm') ;
    ls_imp_quinta := to_char(ln_imp_quinta) ;
    ls_imp_quinta := nvl(ls_imp_quinta,' ') ;

    --  Suma montos afectos al descuento de quinta categoria
    select sum(c.imp_soles) into ln_desc_quinta from calculo c
      where c.cod_trabajador = rc_t.cod_trabajador and c.concep = ls_concepto ;
    ls_desc_quinta := to_char(ln_desc_quinta) ;
    ls_desc_quinta := nvl(ls_desc_quinta,'0') ;

    --  Une informacion para generacion de registros
    ls_sunat := '1'||'|'||ls_dni||'|'||ls_dias||'|'||ls_imp_essalud_emp||'|'||
                ls_imp_snp_no_afp||'|'||ls_imp_snp_afp||'|'||
                ls_imp_artista||'|'||ls_imp_quinta||'|'||ls_desc_quinta||'|' ;

    --  Inserta registro en la tabla temporal
    insert into tt_sunat600(col_sunat)
    values (ls_sunat) ;

  end if ;

end loop ;

end usp_rh_formulario_sunat600 ;
/
