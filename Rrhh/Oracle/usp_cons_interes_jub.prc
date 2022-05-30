create or replace procedure usp_cons_interes_jub
  ( ad_fec_desde in date,
    ad_fec_hasta in date ) is

ls_cod_jubilado        mov_variable_jubilado.cod_jubilado%type ;
ln_nro_secuencia       mov_variable_jubilado.nro_secuencial%type ;
ls_concepto            detalle_deuda_jubilado.concep%type ;
ld_fecha_proceso       detalle_deuda_jubilado.fec_pago%type ;
ln_interes             detalle_deuda_jubilado.int_mes%type ;

ls_nombres             varchar2(35) ;
ls_descripcion         varchar2(35) ;

--  Cursor para seleccion de jubilados
cursor c_movimiento is 
  Select mvj.cod_jubilado, mvj.nro_secuencial
  from mov_variable_jubilado mvj
  where mvj.flag_estado = '1' 
  order by mvj.cod_jubilado, mvj.nro_secuencial ;

--  Cursor para hallar intereses mensuales
cursor c_intereses is 
  Select ddj.cod_jubilado, ddj.sec_herederos, ddj.concep,
         ddj.fec_pago, ddj.factor_emplear, ddj.sldo_capital_mes_ant,
         ddj.sldo_interes_mes_ant, ddj.int_mes, ddj.dscto_adel_mes,
         ddj.dscto_int_mes_ant
  from detalle_deuda_jubilado ddj
  where ddj.cod_jubilado  = ls_cod_jubilado and
        ddj.sec_herederos = ln_nro_secuencia and
        ddj.fec_pago between ad_fec_desde and ad_fec_hasta
  order by ddj.fec_pago, ddj.cod_jubilado, ddj.sec_herederos,
           ddj.concep ;

begin

delete from tt_cons_interes_jub ;

For rc_mov in c_movimiento Loop  

  ls_cod_jubilado  := rc_mov.cod_jubilado ;
  ln_nro_secuencia := rc_mov.nro_secuencial ;

  Select rtrim(hj.apel_paterno)||' '||rtrim(hj.apel_materno)||' '||
         nvl(rtrim(hj.nombre1),' ')||' '||nvl(rtrim(hj.nombre2),' ')
    into ls_nombres
    from herederos_jubilados hj
    where hj.cod_jubilado  = ls_cod_jubilado and
          hj.sec_herederos = ln_nro_secuencia ;
  ls_nombres := nvl(ls_nombres,' ') ;
  ln_interes := 0 ;

  For rc_int in c_intereses Loop  

    ls_concepto := rc_int.concep ;
    ln_interes  := rc_int.int_mes ;
    ln_interes  := nvl(ln_interes,0) ;

    --  Insertar los Registro en la tabla tt_cons_interes_jub
    If ln_interes <> 0 then

      Select c.desc_breve
        into ls_descripcion
        from concepto c
        where c.concep = ls_concepto ;

      Insert into tt_cons_interes_jub
        (codigo, secuencia, nombres, 
         concepto, descripcion, importe)
      Values
        (ls_cod_jubilado, ln_nro_secuencia, ls_nombres,
         ls_concepto, ls_descripcion, ln_interes) ;

    End if ;

  End loop ;
     
End loop ;
                     
End usp_cons_interes_jub ;
/
