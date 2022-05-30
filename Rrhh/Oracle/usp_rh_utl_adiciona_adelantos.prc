create or replace procedure usp_rh_utl_adiciona_adelantos (
       ani_periodo      in utl_ext_hist.periodo%TYPE, 
       adi_fec_pago     in date, 
       asi_pago         in varchar2,
       asi_origen       in origen.cod_origen%TYPE, 
       asi_tipo_trabaj  in tipo_trabajador.tipo_trabajador%TYPE, 
       adi_fec_proceso  in date,
       asi_usuario      in usuario.cod_usr%TYPE 
) is

ls_cncp_adelan          concepto.concep%TYPE;
ls_cncp_dscto           concepto.concep%TYPE;

--  Lectura de movimiento a adicionar en la planilla
cursor c_movimiento is
  select a.cod_relacion, a.imp_utl_remun_anual, a.imp_ult_dias_efect
  from utl_ext_hist a, 
       maestro      m
  where a.cod_relacion    = m.cod_trabajador 
    and m.cod_origen      = asi_origen 
    and m.tipo_trabajador like asi_tipo_trabaj 
    and a.periodo         = ani_periodo
  order by a.cod_relacion ;

begin

--  ******************************************************************
--  ***  ADICIONA ADELANTOS A CUENTA DE UTILIDADES A LA PLANILLA   ***
--  ******************************************************************

select p.cncp_adelanto_util, p.cncp_dscto_adel_util
  into ls_cncp_adelan, ls_cncp_dscto
  from utlparam p 
 where p.reckey = '1' ;

if asi_pago = '1' then
  delete from gan_desct_variable gd
    where trunc(gd.fec_movim) = adi_fec_proceso and
          gd.concep in ( ls_cncp_adelan, ls_cncp_dscto ) ;
elsif asi_pago = '2' then
  delete from gan_desct_variable gd
    where trunc(gd.fec_movim) = adi_fec_proceso and
          gd.concep = ls_cncp_adelan ;
end if ;

--  Lectura del movimiento seleccionado
for rc_mov in c_movimiento loop

  insert into gan_desct_variable (
    cod_trabajador, fec_movim, concep,
    imp_var, cod_usr, flag_replicacion )
  values (
    rc_mov.cod_relacion, adi_fec_proceso, ls_cncp_adelan,
    (nvl(rc_mov.imp_ult_dias_efect,0) + nvl(rc_mov.imp_utl_remun_anual,0)), asi_usuario, '1' ) ;

  if asi_pago = '1' then
    insert into gan_desct_variable (
      cod_trabajador, fec_movim, concep,
      imp_var, cod_usr, flag_replicacion )
    values (
      rc_mov.cod_relacion, adi_fec_proceso, ls_cncp_dscto,
      nvl(rc_mov.imp_ult_dias_efect,0), asi_usuario, '1' ) ;
  end if ;

end loop ;

end usp_rh_utl_adiciona_adelantos ;
/
