create or replace procedure usp_rh_utl_adiciona_pago (
       ani_periodo           in utl_ext_hist.periodo%TYPE, 
       adi_fec_proceso       in date, 
       asi_pago              in varchar2,
       asi_origen            in origen.cod_origen%TYPE, 
       asi_tipo_trabaj        in tipo_trabajador.tipo_trabajador%TYPE, 
       asi_usuario            in usuario.cod_usr%TYPE 
) is

ls_cncp_pago            utlparam.cncp_pago_util%TYPE;
ls_cncp_dscto           utlparam.cncp_dscto_adel_util%TYPE;

--  Lectura de movimiento a adicionar en la planilla
cursor c_movimiento is
  select u.cod_relacion, 
         nvl(u.imp_utl_remun_anual,0) + nvl(u.imp_ult_dias_efect,0) as pago_util, 
         u.adelantos, 
         u.reten_jud
  from utl_ext_hist u, 
       maestro      m
  where u.cod_relacion    = m.cod_trabajador 
    and m.cod_origen      = asi_origen 
    and m.tipo_trabajador like asi_tipo_trabaj 
    and u.periodo         = ani_periodo
  order by u.cod_relacion ;

begin

--  *****************************************************
--  ***  ADICIONA PAGOS DE UTILIDADES A LA PLANILLA   ***
--  *****************************************************

select p.cncp_pago_util, p.cncp_dscto_adel_util
  into ls_cncp_pago, ls_cncp_dscto
  from utlparam p where p.reckey = '1' ;

if asi_pago = '1' then
  delete from gan_desct_variable gd
    where trunc(gd.fec_movim) = adi_fec_proceso and
          gd.concep in ( ls_cncp_pago, ls_cncp_dscto ) ;
elsif asi_pago = '2' then
  delete from gan_desct_variable gd
    where trunc(gd.fec_movim) = adi_fec_proceso and
          gd.concep = ls_cncp_pago ;
end if ;

--  Lectura del movimiento seleccionado
for rc_mov in c_movimiento loop

  insert into gan_desct_variable (
    cod_trabajador, fec_movim, concep,
    imp_var, cod_usr, flag_replicacion )
  values (
    rc_mov.cod_relacion, adi_fec_proceso, ls_cncp_pago,
    rc_mov.pago_util - rc_mov.reten_jud - rc_mov.adelantos, 
    asi_usuario, '1' ) ;

  if asi_pago = '1' then

    insert into gan_desct_variable (
      cod_trabajador, fec_movim, concep,
      imp_var, cod_usr, flag_replicacion )
    values (
      rc_mov.cod_relacion, adi_fec_proceso, ls_cncp_dscto,
      rc_mov.pago_util - rc_mov.reten_jud - rc_mov.adelantos, 
      asi_usuario, '1' ) ;

  end if ;

end loop ;

commit;
end usp_rh_utl_adiciona_pago ;
/
