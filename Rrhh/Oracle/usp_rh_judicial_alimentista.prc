create or replace procedure usp_rh_judicial_alimentista (
  as_codtra in char, ad_fec_proceso in date ) is

lk_judicial             char(3) ;
lk_judicial_fijo        char(3) ;
lk_judicial_devengado   char(3) ;

ln_contador             integer ;
ls_concepto             char(4) ;
ls_concepto_fijo        char(4) ;
ls_concepto_deve        char(4) ;
ln_importe              number(13,2) ;
ln_imp_soles            number(13,2) ;
ln_secuencia            number(13,2) ;
ln_porcentaje           number(13,2) ;
ln_portot               number(13,2) ;
ln_imp_total            number(13,2) ;

--  Cursor de conceptos de judiciales
cursor c_judiciales is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = lk_judicial ;

--  Cursor para leer la alimentistas
cursor c_alimentistas (ls_concepto concepto.concep%type) is
  select j.porcentaje, j.secuencia
  from judicial j
  where j.cod_trabajador = as_codtra and j.concep = ls_concepto and
        j.flag_estado = '1' ;

begin

--  ********************************************************
--  ***   DISTRIBUYE DESCUENTO JUDICIAL A ALIMENTISTAS   ***
--  ********************************************************

select c.concep_afecto_judicial, c.dscto_judicial_fijo, c.dsct_judicial_dvgado
  into lk_judicial, lk_judicial_fijo, lk_judicial_devengado
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

select g.concepto_gen into ls_concepto_fijo from grupo_calculo g
  where g.grupo_calculo = lk_judicial_fijo ;

select g.concepto_gen into ls_concepto_deve from grupo_calculo g
  where g.grupo_calculo = lk_judicial_devengado ;

select nvl(m.porc_judicial,0) into ln_portot from maestro m
  where m.cod_trabajador = as_codtra ;

for rc_j in c_judiciales loop

  ls_concepto := rc_j.concepto_calc ;
  ln_contador := 0 ;
  select count(*) into ln_contador from calculo c
    where c.concep = ls_concepto and c.fec_proceso = ad_fec_proceso and
          c.cod_trabajador = as_codtra ;

  if ln_contador > 0 then

    select nvl(c.imp_soles,0) into ln_imp_soles from calculo c
      where c.cod_trabajador = as_codtra  and c.concep = ls_concepto and
            c.fec_proceso = ad_fec_proceso ;

    ln_imp_total := 0 ;
    for rc_a in c_alimentistas (ls_concepto) loop

      ln_secuencia  := nvl(rc_a.secuencia,0) ;
      ln_porcentaje := nvl(rc_a.porcentaje,1) ;

      if ls_concepto = ls_concepto_fijo or ls_concepto = ls_concepto_deve then
        ln_importe   := ln_imp_soles ;
        ln_imp_total := ln_imp_soles ;
      else
        ln_importe   := ln_imp_soles * ln_porcentaje / ln_portot ;
        ln_imp_total := ln_imp_total + ln_importe ;
      end if ;

      update judicial
        set importe = ln_importe,
           flag_replicacion = '1' 
        where cod_trabajador = as_codtra and concep = ls_concepto and
              secuencia = ln_secuencia;

    end loop ;

    if ln_imp_soles <> ln_imp_total then
      ln_importe := ln_importe + (ln_imp_soles - ln_imp_total) ;
      update judicial
        set importe = ln_importe,
           flag_replicacion = '1' 
        where cod_trabajador = as_codtra and concep = ls_concepto and
              secuencia = ln_secuencia ;
    end if ;

  end if ;

end loop ;

end usp_rh_judicial_alimentista ;
/
