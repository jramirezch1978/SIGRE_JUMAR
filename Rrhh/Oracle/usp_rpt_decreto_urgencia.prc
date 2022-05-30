create or replace procedure usp_rpt_decreto_urgencia
( ad_fec_proceso in date, as_tipo_trabajador in char ) is

ld_fec_desde          date ;
ld_fec_hasta          date ;
ls_tipo_trabajador    char(3) ;
ls_nombres            varchar2(40) ;
ls_seccion            char(3) ;
ls_desc_seccion       varchar2(40) ;

--  Lectura de la liquidaciones mensuales de C.T.S.
cursor c_liquidaciones is 
  select u.cod_trabajador, u.fec_proceso, u.remuneracion, u.liquidacion
  from cts_decreto_urgencia u
  where to_char(u.fec_proceso,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY')
  order by u.cod_trabajador ;

begin

delete from tt_rpt_decreto_urgencia ;

select p.fec_inicio, p.fec_final
  into ld_fec_desde, ld_fec_hasta
  from rrhh_param_org p
  where p.origen = 'PR' ;
  
--select p.fec_desde, p.fec_hasta
--  into ld_fec_desde, ld_fec_hasta
 -- from rrhhparam p
--  where p.reckey = '1' ;

for rc_liq in c_liquidaciones loop

  select nvl(m.tipo_trabajador,' '), m.cod_seccion
    into ls_tipo_trabajador, ls_seccion
    from maestro m
    where m.cod_trabajador = rc_liq.cod_trabajador ;
    
  if ls_tipo_trabajador = as_tipo_trabajador then
  
    ls_nombres := usf_nombre_trabajador(rc_liq.cod_trabajador) ;

    select s.desc_seccion
      into ls_desc_seccion
      from seccion s
      where s.cod_seccion = ls_seccion ;
    
    insert into tt_rpt_decreto_urgencia (
      fec_desde, fec_hasta, fec_proceso, cod_trabajador,
      nombres, seccion, desc_seccion, remuneracion,
      liquidacion )
    values (
      ld_fec_desde, ld_fec_hasta, rc_liq.fec_proceso, rc_liq.cod_trabajador,
      ls_nombres, ls_seccion, ls_desc_seccion, rc_liq.remuneracion,
      rc_liq.liquidacion ) ;
      
  end if ;
  
end loop ;

end usp_rpt_decreto_urgencia ;
/
