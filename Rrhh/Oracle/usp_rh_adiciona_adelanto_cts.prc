create or replace procedure usp_rh_adiciona_adelanto_cts (
  as_codtra in char, ad_fec_desde in date, ad_fec_hasta in date,
  as_usuario in char ) is

lk_adelantos        char(3) ;

ln_verifica         integer ;
ln_contador         integer ;
ls_concepto         char(4) ;

--  Cursor de adelantos a cuenta de C.T.S.
cursor c_adelantos is
  select a.cod_trabajador, a.fec_proceso, a.imp_a_cuenta
  from adel_cnta_cts a
  where a.cod_trabajador = as_codtra and trunc(a.fec_proceso) between
        ad_fec_desde and ad_fec_hasta ;

begin

--  *****************************************************************
--  ***  ADICIONA ADELANTOS A CUENTA DE C.T.S. PARA LA PLANILLA   ***
--  *****************************************************************

select c.adelanto_cnta_cts
  into lk_adelantos
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

ln_verifica := 0 ;
select count(*) into ln_verifica from grupo_calculo g
  where g.grupo_calculo = lk_adelantos ;

if ln_verifica > 0 then

  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_adelantos ;

  delete from gan_desct_variable v
    where v.cod_trabajador = as_codtra and v.concep = ls_concepto and
          trunc(v.fec_movim) between ad_fec_desde and ad_fec_hasta ;

  for rc_a in c_adelantos loop

    ln_contador := 0 ;
    select count(*) into ln_contador from gan_desct_variable g
      where g.cod_trabajador = as_codtra and trunc(g.fec_movim) = trunc(rc_a.fec_proceso) and
            g.concep = ls_concepto ;

    if ln_contador > 0 then
      update gan_desct_variable
        set imp_var = imp_var + nvl(rc_a.imp_a_cuenta,0),
           flag_replicacion = '1'
        where cod_trabajador = as_codtra and trunc(fec_movim) = trunc(rc_a.fec_proceso) and
              concep = ls_concepto ;
    else
      insert into gan_desct_variable (
        cod_trabajador, fec_movim, concep, imp_var, cod_usr, flag_replicacion )
      values (
        as_codtra, rc_a.fec_proceso, ls_concepto, nvl(rc_a.imp_a_cuenta,0), as_usuario, '1' ) ;
    end if ;

  end loop ;

end if ;

end usp_rh_adiciona_adelanto_cts ;
/
