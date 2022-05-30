create or replace procedure usp_rh_formulario_sunat610 (
  as_origen in char, as_tipo_trabaj in char, ad_fec_proceso in date ) is

lk_sctr_ipss    char(3) ;

ls_ruc_emp      char(11) ;
ls_cod_empresa  char(8) ;
ls_seccion      seccion.cod_seccion%type ;
ls_porc_ipss    char(6) ;
ln_porc_ipss    seccion.porc_sctr_ipss%type ;
ln_imp_ipss     number(15) ;
ls_imp_ipss     char(15) ;
ls_sunat        char(55) ;
ln_contador     integer ;

--  Cursor para ubicar la seccion
cursor c_seccion is
  select s.cod_seccion, s.porc_sctr_ipss
  from seccion s
  where nvl(s.porc_sctr_ipss,0) <> 0 ;

--  Busca trabajadores para una determinada seccion
cursor c_trabajadores (ls_seccion in seccion.cod_seccion%type) is
  select m.cod_trabajador, m.dni
  from maestro m
  where m.cod_seccion = ls_seccion and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj and m.flag_estado = '1' ;

begin

--  ***********************************************
--  ***   GENERA FORMULARIO 0610 PARA LA SUNAT  ***
--  ***********************************************

select c.concep_sctr_ipss
  into lk_sctr_ipss
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

delete from  tt_sunat610 ;

--  Determina el R.U.C. de la empresa
select p.cod_empresa into ls_cod_empresa from genparam p
  where p.reckey = '1' ;
select e.ruc into ls_ruc_emp from empresa e
  where e.cod_empresa = ls_cod_empresa ;

--  Busca secciones afectas al SCTR.IPSS
for rc_s in c_seccion loop

  ln_porc_ipss := nvl(rc_s.porc_sctr_ipss,0) ;

  ls_seccion := nvl(rc_s.cod_seccion,' ') ;
  for rc_t in c_trabajadores (ls_seccion) loop

    --  Procesa informacion del S.C.T.R. I.P.S.S.
    ln_contador := 0 ;
    select count(*) into ln_contador from calculo c
      where c.cod_trabajador = rc_t.cod_trabajador and c.concep in ( select d.concepto_calc
            from grupo_calculo_det d where d.grupo_calculo = lk_sctr_ipss ) and
            c.fec_proceso = ad_fec_proceso ;
    if ln_contador > 0 then
      select sum(c.imp_soles) into ln_imp_ipss from calculo c
        where c.cod_trabajador = rc_t.cod_trabajador and c.concep in ( select d.concepto_calc
              from grupo_calculo_det d where d.grupo_calculo = lk_sctr_ipss ) and
              c.fec_proceso = ad_fec_proceso ;
      ls_imp_ipss := to_char(ln_imp_ipss) ;
      ls_imp_ipss := nvl(ls_imp_ipss,' ') ;

      ls_porc_ipss := to_char(ln_porc_ipss,'99.99') ;
      ls_sunat := '1'||'|'||rpad(rc_t.dni,15,' ')||'|'||
                  rpad(ls_ruc_emp,11,' ')||'|'||'01'||'|'||
                  lpad(trim(ls_porc_ipss),5,'0')||'|'||
                  lpad(trim(ls_imp_ipss),15,' ')||'|' ;
      insert into tt_sunat610 (col_sunat)
      values (ls_sunat) ;
    end if ;

  end loop ;

end loop ;

end usp_rh_formulario_sunat610 ;
/
