create or replace procedure usp_pla_actualiza_concepto
 ( ls_concepto       in concepto.concep%type ,
   ln_importe        in gan_desct_fijo.imp_gan_desc%type ,
   ln_adiciona       in integer ,
   ln_modifica       in integer ,
   ln_elimina        in integer ,
   ls_cod_trabajador in maestro.cod_trabajador%type
 ) is

ln_importe_actual    gan_desct_fijo.imp_gan_desc%type ;

--  Cursor de la tabla Maestro
Cursor c_maestro is 
  Select m.cod_trabajador
    From maestro m
    Where m.flag_estado = '1' and
          m.flag_cal_plnlla = '1' and
          m.cod_trabajador = ls_cod_trabajador and
          (m.situa_trabaj = 'E' or m.situa_trabaj = 'S') and
          m.cod_seccion <> '950' ;

Cursor c_ganancias is
  Select gdf.concep, gdf.imp_gan_desc
    From gan_desct_fijo gdf, maestro m
    Where gdf.cod_trabajador = m.cod_trabajador and
          gdf.cod_trabajador = ls_cod_trabajador and
          gdf.concep = ls_concepto and
          gdf.flag_estado = '1' and
          gdf.flag_trabaj = '1' and
          (m.situa_trabaj = 'E' or m.situa_trabaj = 'S') and
          m.cod_seccion <> '950'
--          m.situa_trabaj = 'C' and substr(m.cod_seccion,1,1) <> '9'
    For update ;

begin

If ln_adiciona <> 0 then
  For c_rm in c_maestro Loop
    Insert into gan_desct_fijo
    ( cod_trabajador, concep, 
      flag_estado, flag_trabaj, imp_gan_desc )
    Values
    ( ls_cod_trabajador, ls_concepto,
      '1', '1', ln_importe ) ;
  End Loop ;
End if ;

If ln_modifica <> 0 then
  For c_rg in c_ganancias Loop
    ln_importe_actual := c_rg.imp_gan_desc + ln_importe ;
    Update gan_desct_fijo
    Set flag_estado  = '1' ,
        imp_gan_desc = ln_importe_actual
    Where cod_trabajador = ls_cod_trabajador and
          concep = ls_concepto ;
  End Loop ;
End if ;

If ln_elimina <> 0 then
  For c_rg in c_ganancias Loop
    Update gan_desct_fijo
      Set flag_estado  = '0'
    Where cod_trabajador = ls_cod_trabajador and
          concep = ls_concepto ;
  End Loop ;
End if ;

end usp_pla_actualiza_concepto ;
/
