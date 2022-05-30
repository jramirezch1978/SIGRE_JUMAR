create or replace procedure usp_rh_actualiza_concepto_fijo (
  as_codtra in char, as_tipo in char, as_concepto in char,
  an_importe in number ) is

lk_adiciona     constant char(1) := 'A' ;
lk_modifica     constant char(1) := 'M' ;
lk_elimina      constant char(1) := 'E' ;

begin

--  **************************************************
--  ***   ACTUALIZA CONCEPTO FIJO POR TRABAJADOR   ***
--  **************************************************

if as_tipo = lk_adiciona then
  insert into gan_desct_fijo (
    cod_trabajador, concep, flag_estado, flag_trabaj, imp_gan_desc,flag_replicacion )
  values (
    as_codtra, as_concepto, '1', '1', an_importe, '1' ) ;
end if ;

if as_tipo = lk_modifica then
  update gan_desct_fijo
    set flag_estado  = '1' ,
        imp_gan_desc = imp_gan_desc + nvl(an_importe,0),
         flag_replicacion = '1'
    where cod_trabajador = as_codtra and concep = as_concepto ;
end if ;

if as_tipo = lk_elimina then
  update gan_desct_fijo
    set flag_estado  = '0',
         flag_replicacion = '1'
    where cod_trabajador = as_codtra and concep = as_concepto ;
end if ;

end usp_rh_actualiza_concepto_fijo ;
/
