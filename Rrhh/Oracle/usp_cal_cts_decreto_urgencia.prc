create or replace procedure usp_cal_cts_decreto_urgencia
  ( as_codtra        in maestro.cod_trabajador%type,
    ad_fec_proceso   in calculo.fec_proceso%type ) is

ls_codigo          maestro.cod_trabajador%type ;
ls_concepto        calculo.concep%type ;
ln_factor          concepto.fact_pago%type ;
ln_remuneracion    number(13,2) ;
ln_liquidacion     number(13,2) ;
ln_contador        integer ;

--  Cursor de trabajadores solamente activos
Cursor c_maestro is
  Select m.cod_trabajador
  from maestro m
  where m.cod_trabajador = as_codtra and
        m.flag_estado = '1' and m.flag_cal_plnlla = '1' ;

begin

--  Halla factor de pago para calculo de C.T.S.
--  Decreto de Urgencia 127-2000
Select c.fact_pago
  into ln_factor
  from concepto c
  where c.concep = '1450' ;

--  Calcula C.T.S. mensual
For rc_mae in c_maestro loop

  ls_codigo       := rc_mae.cod_trabajador ;
  ln_remuneracion := 0 ;
  ln_liquidacion  := 0 ;

  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from gan_desct_fijo f
    where f.cod_trabajador = ls_codigo and f.concep = '1020' ;

  If ln_contador = 0 then

    ln_contador := 0 ;
    Select count(*)
      into ln_contador
      from calculo c
      where c.cod_trabajador = ls_codigo and
            c.flag_t_cts = '1' ;
    If ln_contador > 0 then
      Select sum (c.imp_soles)
        into ln_remuneracion
        from calculo c
        where c.cod_trabajador = ls_codigo and
              c.flag_t_cts = '1' ;
      ln_liquidacion := ln_remuneracion * ln_factor ;
      --  Inserta nuevos registros
      Insert into cts_decreto_urgencia
        ( cod_trabajador, fec_proceso,
          remuneracion, liquidacion )
      Values
        ( ls_codigo, ad_fec_proceso,
          ln_remuneracion, ln_liquidacion ) ;
    End if ;

  End if ;

End loop ;

End usp_cal_cts_decreto_urgencia ;
/
