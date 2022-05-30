create or replace procedure usp_presup_gasto_mes
  ( ad_mensaje in out char ) is

--  Variables
ls_cod_origen       presupuesto_ejec.cod_origen%type ;
ln_nro_mov          presupuesto_ejec.nro_mov%type ;
ln_ano              presupuesto_ejec.ano%type ;
ls_cencos           presupuesto_ejec.cencos%type ;
ls_cnta_prsp        presupuesto_ejec.cnta_prsp%type ;
ld_fecha            presupuesto_ejec.fecha%type ;
ls_descripcion      presupuesto_ejec.descripcion%type ;
ln_importe          presupuesto_ejec.importe%type ;
ls_origen_ref       presupuesto_ejec.origen_ref%type ;
ls_tipo_doc_ref     presupuesto_ejec.tipo_doc_ref%type ;
ls_nro_doc_ref      presupuesto_ejec.nro_doc_ref%type ;
ln_item_ref         presupuesto_ejec.item_ref%type ;

ld_fec_proceso      rrhhparam.fec_proceso%type ;
ls_codigo           calculo.cod_trabajador%type ;
ls_concepto         calculo.concep%type ;
ls_tipo_trabaj      maestro.tipo_trabajador%type ;
ls_cuenta_emp       concepto.cnta_prsp%type ;
ls_cuenta_obr       concepto.cnta_prsp_obr%type ;
ln_nro_registro     number(15) ;
ln_contador         number(15) ;

--  Cursor del movimiento de la planilla mensual
cursor c_calculo is
  select cal.cod_trabajador, cal.concep, cal.imp_dolar
  from calculo cal
  where cal.concep <> '1450' and cal.concep <> '2351' and
        cal.concep <> '2354' and cal.concep <> '3050'
  order by cal.cod_trabajador, cal.concep ;

--  Cursor de gastos por centros de costos y cuenta presupuestal
cursor c_gastos is 
  select gm.ano, gm.cencos, gm.cnta_prsp, gm.fecha, gm.importe
  from tt_presupuesto_gasto_mes gm
  order by gm.cencos, gm.cnta_prsp ;
rc_gastos c_gastos%rowtype ;

begin

select rh.fec_proceso
  into ld_fec_proceso from rrhhparam rh
  where rh.reckey = '1' ;
ln_ano := to_number(to_char(ld_fec_proceso,'YYYY')) ;
  
--  Elimina registros de gastos mensuales de la planilla
delete from presupuesto_ejec pe
  where to_char(pe.fecha,'DD/MM/YYYY') = to_char(ld_fec_proceso,'DD/MM/YYYY') and
        pe.tipo_doc_ref = 'GPM ' ;

delete from tt_presupuesto_gasto_mes ;

--  Realiza proceso por trabajador
for rc_cal in c_calculo loop

  ls_codigo   := rc_cal.cod_trabajador ;
  ls_concepto := rc_cal.concep ;
  ln_importe  := nvl(rc_cal.imp_dolar,0) * -1 ;
  ld_fecha    := ld_fec_proceso ;

  select m.tipo_trabajador, m.cencos
    into ls_tipo_trabaj, ls_cencos
    from maestro m
    where m.cod_trabajador = ls_codigo ;
    
  select nvl(con.cnta_prsp,' '), nvl(con.cnta_prsp_obr,' ')
    into ls_cuenta_emp, ls_cuenta_obr
    from concepto con
    where con.concep = ls_concepto ;
    
  if ls_tipo_trabaj = 'EMP' then
    ls_cnta_prsp := ls_cuenta_emp ;
  else
    ls_cnta_prsp := ls_cuenta_obr ;
  end if ;
  
  if ls_cnta_prsp <> ' ' and ln_importe <> 0 then
    insert into tt_presupuesto_gasto_mes (
      ano, cencos, cnta_prsp,
      fecha, importe )
    values (
      ln_ano, ls_cencos, ls_cnta_prsp,
      ld_fecha, ln_importe ) ;
  end if ;
  
end loop ;

--  Acumula gastos por centros de costos y cuenta presupuestal
open c_gastos ;
fetch c_gastos into rc_gastos ;

while c_gastos%found loop

  ln_ano        := rc_gastos.ano ;
  ls_cencos     := rc_gastos.cencos ;
  ls_cnta_prsp  := rc_gastos.cnta_prsp ;
  ld_fecha      := rc_gastos.fecha ;
  ln_importe    := 0 ;  

  --  Quiebre por centro de costo y cuenta presupuestal
  while rc_gastos.cencos    = ls_cencos and
        rc_gastos.cnta_prsp = ls_cnta_prsp and c_gastos%found loop

    ln_importe := ln_importe + nvl(rc_gastos.importe,0) ;
    fetch c_gastos into rc_gastos ;
    ln_nro_registro := ln_nro_registro + 1 ;
        
  end loop ;

  select nvl(pc.descripcion,' ')
    into ls_descripcion
    from presupuesto_cuenta pc
    where pc.cnta_prsp = ls_cnta_prsp ;

  --  Verifica que el centro de costo y cuenta presupuestal
  --  Existan como partida presupuestal
  ln_contador := 0 ;
  select count(*)
    into ln_contador
    from presupuesto_partida pp
    where pp.ano = ln_ano and pp.cencos = ls_cencos and
          pp.cnta_prsp = ls_cnta_prsp ;

  if ln_contador = 0 then
    ad_mensaje := 'Centro de Costo '||ls_cencos||'Cnta. Prsp. '||ls_cnta_prsp||'  No Tiene Presupuesto' ;
    return ;
  end if ;

  --  Inserta registros en tabla de Presupuesto 
  insert into presupuesto_ejec (
    cod_origen, ano, cencos,
    cnta_prsp, fecha, descripcion,
    importe, origen_ref, tipo_doc_ref,
     nro_doc_ref, item_ref )
  values (
    'PR', ln_ano, ls_cencos,
    ls_cnta_prsp, ld_fecha, ls_descripcion,
    ln_importe, 'PR', 'GPM ',
    '', 0 ) ;
     
end loop ;

commit ;

end usp_presup_gasto_mes ;



/*
create or replace procedure usp_presup_gasto_mes
  ( ad_mensaje   in out char ) is

--  Variables
ls_cod_origen       presupuesto_ejec.cod_origen%type ;
ln_nro_mov          presupuesto_ejec.nro_mov%type ;
ln_ano              presupuesto_ejec.ano%type ;
ls_cencos           presupuesto_ejec.cencos%type ;
ls_cnta_prsp        presupuesto_ejec.cnta_prsp%type ;
ld_fecha            presupuesto_ejec.fecha%type ;
ls_descripcion      presupuesto_ejec.descripcion%type ;
ln_importe          presupuesto_ejec.importe%type ;
ls_origen_ref       presupuesto_ejec.origen_ref%type ;
ls_tipo_doc_ref     presupuesto_ejec.tipo_doc_ref%type ;
ls_nro_doc_ref      presupuesto_ejec.nro_doc_ref%type ;
ln_item_ref         presupuesto_ejec.item_ref%type ;

ld_fec_proceso      rrhhparam.fec_proceso%type ;
ls_codigo           calculo.cod_trabajador%type ;
ls_concepto         calculo.concep%type ;
ls_tipo_trabaj      maestro.tipo_trabajador%type ;
ls_cuenta_emp       concepto.cnta_prsp%type ;
ls_cuenta_obr       concepto.cnta_prsp_obr%type ;
ln_nro_registro     number(15) ;
ln_contador         number(15) ;

--  Cursor del movimiento de la planilla mensual
Cursor c_calculo is
  Select cal.cod_trabajador, cal.concep, cal.imp_dolar
  from calculo cal
  where cal.concep <> '1450' and
        cal.concep <> '2351' and
        cal.concep <> '2354' and
        cal.concep <> '3050'
  order by cal.cod_trabajador, cal.concep ;

--  Cursor de gastos por centros de costos y cuenta presupuestal
Cursor c_gastos is 
  Select gm.ano, gm.cencos, gm.cnta_prsp,
         gm.fecha, gm.importe
  from tt_presupuesto_gasto_mes gm
  order by gm.cencos, gm.cnta_prsp ;

rc_gastos c_gastos%RowType ;

begin

Select rh.fec_proceso
  into ld_fec_proceso
  from rrhhparam rh
  where rh.reckey = '1' ;
  
--  Elimina registros de gastos mensuales de la planilla
delete from presupuesto_ejec pe
  where to_char(pe.fecha,'DD/MM/YYYY') = to_char(ld_fec_proceso,'DD/MM/YYYY') and
        pe.tipo_doc_ref = 'GPM ' ;

delete from tt_presupuesto_gasto_mes ;

--  Realiza proceso por trabajador
For rc_cal in c_calculo loop

  ls_codigo   := rc_cal.cod_trabajador ;
  ls_concepto := rc_cal.concep ;
  ln_importe  := nvl(rc_cal.imp_dolar,0) * -1 ;
  ln_ano      := to_number(to_char(ld_fec_proceso,'YYYY')) ;
  ld_fecha    := ld_fec_proceso ;

  Select m.tipo_trabajador, m.cencos
    into ls_tipo_trabaj, ls_cencos
    from maestro m
    where m.cod_trabajador = ls_codigo ;
    
  Select nvl(con.cnta_prsp,' '), nvl(con.cnta_prsp_obr,' ')
    into ls_cuenta_emp, ls_cuenta_obr
    from concepto con
    where con.concep = ls_concepto ;
    
  If ls_tipo_trabaj = 'EMP' then
    ls_cnta_prsp := ls_cuenta_emp ;
  Else
    ls_cnta_prsp := ls_cuenta_obr ;
  End if ;
  
  If ls_cnta_prsp <> ' ' and ln_importe <> 0 then
    Insert into tt_presupuesto_gasto_mes (
      ano, cencos, cnta_prsp,
      fecha, importe )
    Values (
      ln_ano, ls_cencos, ls_cnta_prsp,
      ld_fecha, ln_importe ) ;
  End if ;
  
End loop ;
      
--  Acumula gastos por centros de costos y cuenta presupuestal
Open c_gastos ;
Fetch c_gastos into rc_gastos ;

while c_gastos%FOUND loop

  ln_ano        := rc_gastos.ano ;
  ls_cencos     := rc_gastos.cencos ;
  ls_cnta_prsp  := rc_gastos.cnta_prsp ;
  ld_fecha      := rc_gastos.fecha ;
  ln_importe    := 0 ;  

  --  Quiebre por centro de costo y cuenta presupuestal
  while rc_gastos.cencos    = ls_cencos and
        rc_gastos.cnta_prsp = ls_cnta_prsp and c_gastos%FOUND loop

    ln_importe := ln_importe + nvl(rc_gastos.importe,0) ;
    Fetch c_gastos into rc_gastos ;
    ln_nro_registro := ln_nro_registro + 1 ;
        
  End loop ;

  Select nvl(pc.descripcion,' ')
    into ls_descripcion
    from presupuesto_cuenta pc
    where pc.cnta_prsp = ls_cnta_prsp ;
      
  --  Verifica que el centro de costo y cuenta presupuestal
  --  Existan como partida presupuestal
  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from presupuesto_partida pp
    where pp.ano = ln_ano and
          pp.cencos = ls_cencos and
          pp.cnta_prsp = ls_cnta_prsp ;
  ln_contador := nvl(ln_contador,0) ;

  If ln_contador > 0 then
    --  Inserta registros en tabla de Presupuesto 
    Insert into presupuesto_ejec (
      cod_origen, ano, cencos,
      cnta_prsp, fecha, descripcion,
      importe, origen_ref, tipo_doc_ref,
      nro_doc_ref, item_ref )
    Values (
      'PR', ln_ano, ls_cencos,
      ls_cnta_prsp, ld_fecha, ls_descripcion,
      ln_importe, 'PR', 'GPM ',
      '', 0 ) ;
  Else
    ad_mensaje := 'Centro de Costo '||ls_cencos||' No Tiene Presupuesto' ;
  End if ;
     
End loop ;

End usp_presup_gasto_mes ;
*/
/
