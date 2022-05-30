create or replace procedure usp_actualiza_cuentas_cntbl is

lk_obrero             constant char(3) := 'OBR' ;
lk_empleado           constant char(3) := 'EMP' ;

ln_verifica           integer ;
ls_cta_deb_obr        char(10) ;
ls_cta_hab_obr        char(10) ;
ls_cta_deb_emp        char(10) ;
ls_cta_hab_emp        char(10) ;
ls_cta_pre_obr        char(10) ;
ls_cta_pre_emp        char(10) ;

--  Lee maestro conceptos
cursor c_conceptos is
  select c.concep, c.cta_haber_obr, c.cta_debe_obr, c.cta_haber_emp,
         c.cta_debe_emp, c.cnta_prsp, c.cnta_prsp_obr
  from concepto c
  where c.flag_estado = '1'
  order by c.concep ;

begin

delete from tabla ;
      
for rc_con in c_conceptos loop

  ls_cta_deb_obr := nvl(rc_con.cta_debe_obr,' ') ;
  ls_cta_hab_obr := nvl(rc_con.cta_haber_obr,' ') ;
  ls_cta_deb_emp := nvl(rc_con.cta_debe_emp,' ') ;
  ls_cta_hab_emp := nvl(rc_con.cta_haber_emp,' ') ;
  ls_cta_pre_obr := nvl(rc_con.cnta_prsp_obr,' ') ;
  ls_cta_pre_emp := nvl(rc_con.cnta_prsp,' ') ;

  if ls_cta_deb_obr <> ' ' then
    ln_verifica := 0 ;
    select count(*) into ln_verifica from tabla t
      where t.concepto = rc_con.concep and t.tipo = lk_obrero ;
    if ln_verifica > 0 then
      update tabla t
        set t.debe = ls_cta_deb_obr
        where t.concepto = rc_con.concep and t.tipo = lk_obrero ;
    else
      insert into tabla (
        concepto, tipo, debe, haber, prsp )
      values (
        rc_con.concep, lk_obrero, ls_cta_deb_obr, null, null ) ;
    end if ;
  end if ;
    
  if ls_cta_hab_obr <> ' ' then
    ln_verifica := 0 ;
    select count(*) into ln_verifica from tabla t
      where t.concepto = rc_con.concep and t.tipo = lk_obrero ;
    if ln_verifica > 0 then
      update tabla t
        set t.haber = ls_cta_hab_obr
        where t.concepto = rc_con.concep and t.tipo = lk_obrero ;
    else
      insert into tabla (
        concepto, tipo, debe, haber, prsp )
      values (
        rc_con.concep, lk_obrero, null, ls_cta_hab_obr, null ) ;
    end if ;
  end if ;
    
  if ls_cta_pre_obr <> ' ' then
    ln_verifica := 0 ;
    select count(*) into ln_verifica from tabla t
      where t.concepto = rc_con.concep and t.tipo = lk_obrero ;
    if ln_verifica > 0 then
      update tabla t
        set t.prsp = ls_cta_pre_obr
        where t.concepto = rc_con.concep and t.tipo = lk_obrero ;
    else
      insert into tabla (
        concepto, tipo, debe, haber, prsp )
      values (
        rc_con.concep, lk_obrero, null, null, ls_cta_pre_obr ) ;
    end if ;
  end if ;

  if ls_cta_deb_emp <> ' ' then
    ln_verifica := 0 ;
    select count(*) into ln_verifica from tabla t
      where t.concepto = rc_con.concep and t.tipo = lk_empleado ;
    if ln_verifica > 0 then
      update tabla t
        set t.debe = ls_cta_deb_emp
        where t.concepto = rc_con.concep and t.tipo = lk_empleado ;
    else
      insert into tabla (
        concepto, tipo, debe, haber, prsp )
      values (
        rc_con.concep, lk_empleado, ls_cta_deb_emp, null, null ) ;
    end if ;
  end if ;
    
  if ls_cta_hab_emp <> ' ' then
    ln_verifica := 0 ;
    select count(*) into ln_verifica from tabla t
      where t.concepto = rc_con.concep and t.tipo = lk_empleado ;
    if ln_verifica > 0 then
      update tabla t
        set t.haber = ls_cta_hab_emp
        where t.concepto = rc_con.concep and t.tipo = lk_empleado ;
    else
      insert into tabla (
        concepto, tipo, debe, haber, prsp )
      values (
        rc_con.concep, lk_empleado, null, ls_cta_hab_emp, null ) ;
    end if ;
  end if ;
    
  if ls_cta_pre_emp <> ' ' then
    ln_verifica := 0 ;
    select count(*) into ln_verifica from tabla t
      where t.concepto = rc_con.concep and t.tipo = lk_empleado ;
    if ln_verifica > 0 then
      update tabla t
        set t.prsp = ls_cta_pre_emp
        where t.concepto = rc_con.concep and t.tipo = lk_empleado ;
    else
      insert into tabla (
        concepto, tipo, debe, haber, prsp )
      values (
        rc_con.concep, lk_empleado, null, null, ls_cta_pre_emp ) ;
    end if ;
  end if ;

end loop ;

end usp_actualiza_cuentas_cntbl ;
/
