create or replace procedure usp_rh_liq_seleccion_pago (
  ad_fec_desde in date, ad_fec_hasta in date, as_usuario in char ) is

ls_tipo_doc         char(4) ;
ls_nombres          varchar2(60) ;
ln_verifica         integer ;

--  Lectura de liquidaciones de creditos laborales aprobadas
cursor c_liquidaciones is
  select l.cod_trabajador, l.nro_liquidacion, l.imp_liq_befef_soc, l.imp_liq_remun,
         (nvl(l.imp_liq_befef_soc,0) + nvl(l.imp_liq_remun,0)) as imp_liquidacion
  from rh_liq_credito_laboral l
  where l.flag_estado = '2' and nvl(l.flag_juicio,'0') = '0' and nvl(l.flag_reposicion,'0') = '0' and
        l.fec_liquidacion between ad_fec_desde and ad_fec_hasta
  order by l.fec_liquidacion ;

begin

--  *********************************************************
--  ***   SELECCION DE LIQUIDACIONES PARA GENERAR PAGOS   ***
--  *********************************************************

delete from tt_liq_seleccion_pago ;

select p.tipo_doc into ls_tipo_doc from rh_liqparam p
  where p.reckey = '1' ;
  
for rc_liq in c_liquidaciones loop

  ls_nombres := usf_rh_nombre_trabajador(rc_liq.cod_trabajador) ;

  ln_verifica := 0 ;
  select count(*) into ln_verifica from rh_liq_cnta_crrte_cred_lab l
    where l.cod_trabajador = rc_liq.cod_trabajador and nvl(l.flag_estado,'0') <> '3' ;

  if ln_verifica = 0 then    
    insert into tt_liq_seleccion_pago (
      nro_liquidacion, cod_trabajador, nombres, fec_proceso, imp_bensoc,
      imp_remune, imp_total, forma_pago, nro_cuotas, tipo_doc, usuario )
    values (
      rc_liq.nro_liquidacion, rc_liq.cod_trabajador, ls_nombres, sysdate, rc_liq.imp_liq_befef_soc,
      rc_liq.imp_liq_remun, rc_liq.imp_liquidacion, null, 1, ls_tipo_doc, as_usuario ) ;
  end if ;
  
end loop ;

end usp_rh_liq_seleccion_pago ;
/
