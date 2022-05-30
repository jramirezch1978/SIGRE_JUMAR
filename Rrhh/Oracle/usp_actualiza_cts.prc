create or replace procedure usp_actualiza_cts is

ln_verifica       integer ;

/*
cursor c_factores is
  select f.fecha, f.factor
  from factor f
  where nvl(f.factor,0) > 0
  order by f.fecha ;
*/

cursor c_movimiento is
  select c.codigo, c.fechad, c.fechai, c.impdep
  from cts c
  where nvl(c.impdep,0) > 0
  order by c.codigo, c.fechad ;

begin

delete from cnta_crrte_cts ;

/*
for rc_fac in c_factores loop

  ln_verifica := 0 ;
  select count(*) into ln_verifica from factor_planilla f
    where trunc(f.fec_calc_int) = trunc(rc_fac.fecha) ;
    
  if ln_verifica > 0 then
    update factor_planilla f
      set f.fact_cts = rc_fac.factor
      where trunc(f.fec_calc_int) = trunc(rc_fac.fecha) ;
  else
    insert into factor_planilla (
      fec_calc_int, fact_interes, fact_cts, flag_replicacion )
    values (
      rc_fac.fecha, 0, rc_fac.factor, '1' ) ;
  end if ;
    
end loop ;
*/

for rc_mov in c_movimiento loop
  
  ln_verifica := 0 ;
  select count(*) into ln_verifica from cnta_crrte_cts c
    where c.fec_prdo_dpsto = rc_mov.fechai and c.fec_calc_int = rc_mov.fechad and
          c.cod_trabajador = rc_mov.codigo ;

  if ln_verifica > 0 then
    raise_application_error( -20000, 'Codigo '||rc_mov.codigo||' fecha de deposito '||
                                     to_char(rc_mov.fechai,'dd/mm/yyyy')||' fecha de interes'||
                                     to_char(rc_mov.fechad,'dd/mm/yyyy') ) ;
  end if ;
      
  insert into cnta_crrte_cts (
    fec_prdo_dpsto, fec_calc_int, cod_trabajador, imp_prdo_dpsto )
  values (
    rc_mov.fechai, rc_mov.fechad, rc_mov.codigo, rc_mov.impdep ) ;
    
end loop ;

end usp_actualiza_cts ;
/
