create or replace procedure usp_cntbl_rpt_libro_mayor (
       as_cta_desde in char, 
       as_cta_hasta in char,
       as_mes_desde in char, 
       as_mes_hasta in char, 
       as_ano in char 
) is

--  Variables
ln_ano                   number(4) ;
ln_mes_desde             number(2) ;
ln_mes_hasta             number(2) ;
ls_mes_desde             char(2) ;
ls_mes_hasta             char(2) ;

ls_cuenta         char(10) ;
ls_desc_cuenta    varchar2(60) ;
ls_origen         char(2) ;
ln_mes            number(2) ;
ln_libro          number(3) ;
ln_asiento        number(10) ;
ln_item           number(6) ;
ln_mes_ant        number(2) ;
ln_sw             integer ;

ln_soldeb         number(13,2) ;   ln_doldeb         number(13,2) ;
ln_solhab         number(13,2) ;   ln_dolhab         number(13,2) ;
ln_imp_soldeb     number(13,2) ;   ln_imp_doldeb     number(13,2) ;
ln_imp_solhab     number(13,2) ;   ln_imp_dolhab     number(13,2) ;
ln_sol_sal_deb    number(13,2) ;   ln_sol_acu_deb    number(13,2) ;
ln_sol_sal_hab    number(13,2) ;   ln_sol_acu_hab    number(13,2) ;
ln_dol_sal_deb    number(13,2) ;   ln_dol_acu_deb    number(13,2) ;
ln_dol_sal_hab    number(13,2) ;   ln_dol_acu_hab    number(13,2) ;

--  Lectura del detalle de los asientos segun rangos
cursor c_asientos is
  select d.origen, d.ano, d.mes, d.nro_libro, d.nro_asiento, d.item,
         d.cnta_ctbl, d.fec_cntbl, d.det_glosa, d.flag_debhab,
         d.cencos, d.tipo_docref1, d.nro_docref1, d.cod_relacion,
         d.imp_movsol, d.imp_movdol,a.cod_moneda, d.centro_benef
  from cntbl_asiento_det d, cntbl_asiento a
  where d.origen = a.origen and d.ano = a.ano and d.mes = a.mes and
        d.nro_libro = a.nro_libro and d.nro_asiento = a.nro_asiento and
        (d.ano = ln_ano) and (d.mes between ln_mes_desde and ln_mes_hasta) and
        (d.cnta_ctbl between as_cta_desde and as_cta_hasta) and
        nvl(a.flag_estado,'0') <> '0'
  order by d.cnta_ctbl, d.origen, d.ano, d.mes, d.nro_libro,
           d.nro_asiento, d.item ;
  rc_asi c_asientos%rowtype ;

begin

delete from tt_cntbl_libro_mayor ;

ln_sw := 0 ;
ls_mes_desde := lpad(as_mes_desde,2,'0') ; ln_mes_desde := to_number(ls_mes_desde) ;
ls_mes_hasta := lpad(as_mes_hasta,2,'0') ; ln_mes_hasta := to_number(ls_mes_hasta) ;
ln_ano       := to_number(as_ano) ;
ln_mes_ant   := ln_mes_desde - 1 ;
if ln_mes_ant < 0 then
  ln_sw := 1 ;
end if ;

--  **********************************************************
--  ***   DETALLE DE LOS ASIENTOS CONTABLES SEGUN RANGOS   ***
--  **********************************************************
open c_asientos ;
fetch c_asientos into rc_asi ;

while c_asientos%found loop

  ls_cuenta := nvl(rc_asi.cnta_ctbl,' ') ;
  select substr(nvl(c.desc_cnta,' '),1,60)
    into ls_desc_cuenta
    from cntbl_cnta c
    where c.cnta_ctbl = ls_cuenta ;

  ln_sol_sal_deb := 0 ; ln_sol_acu_deb := 0 ;
  ln_sol_sal_hab := 0 ; ln_sol_acu_hab := 0 ;
  ln_dol_sal_deb := 0 ; ln_dol_acu_deb := 0 ;
  ln_dol_sal_hab := 0 ; ln_dol_acu_hab := 0 ;
  ln_imp_soldeb  := 0 ; ln_imp_doldeb  := 0 ;
  ln_imp_solhab  := 0 ; ln_imp_dolhab  := 0 ;

  while rc_asi.cnta_ctbl = ls_cuenta and c_asientos%found loop

    ls_origen  := nvl(rc_asi.origen,' ') ;
    ln_ano     := nvl(rc_asi.ano,0) ;
    ln_mes     := nvl(rc_asi.mes,0) ;
    ln_libro   := nvl(rc_asi.nro_libro,0) ;
    ln_asiento := nvl(rc_asi.nro_asiento,0) ;
    ln_item    := nvl(rc_asi.item,0) ;

    ln_soldeb := 0 ; ln_doldeb := 0 ;
    ln_solhab := 0 ; ln_dolhab := 0 ;

    if rc_asi.flag_debhab = 'D' then
      ln_soldeb     := nvl(rc_asi.imp_movsol,0) ;
      ln_doldeb     := nvl(rc_asi.imp_movdol,0) ;
      ln_imp_soldeb := ln_imp_soldeb + ln_soldeb ;
      ln_imp_doldeb := ln_imp_doldeb + ln_doldeb ;
    elsif rc_asi.flag_debhab = 'H' then
      ln_solhab     := nvl(rc_asi.imp_movsol,0) ;
      ln_dolhab     := nvl(rc_asi.imp_movdol,0) ;
      ln_imp_solhab := ln_imp_solhab + ln_solhab ;
      ln_imp_dolhab := ln_imp_dolhab + ln_dolhab ;
    end if ;

    insert into tt_cntbl_libro_mayor (
      mes_desde, mes_hasta, ano_proceso, cta_desde, cta_hasta, cuenta,
      desc_cuenta, origen, ano, mes, nro_libro, nro_asiento,
      item, fec_cntbl, det_glosa, cencos,
      cod_relacion, tipo_docref1, nro_docref1,
      sol_sal_deb, soldeb, sol_acu_deb, sol_sal_hab, solhab,
      sol_acu_hab, dol_sal_deb, doldeb, dol_acu_deb,
      dol_sal_hab, dolhab, dol_acu_hab,cod_moneda,
      centro_benef )
    values (
      as_mes_desde, as_mes_hasta, as_ano, as_cta_desde, as_cta_hasta, ls_cuenta,
      ls_desc_cuenta, ls_origen, ln_ano, ln_mes, ln_libro, ln_asiento,
      ln_item, rc_asi.fec_cntbl, rc_asi.det_glosa, rc_asi.cencos,
      rc_asi.cod_relacion, rc_asi.tipo_docref1, substr(rc_asi.nro_docref1,1,10),
      ln_sol_sal_deb, ln_soldeb, ln_sol_acu_deb, ln_sol_sal_hab, ln_solhab,
      ln_sol_acu_hab, ln_dol_sal_deb, ln_doldeb, ln_dol_acu_deb,
      ln_dol_sal_hab, ln_dolhab, ln_dol_acu_hab ,rc_asi.cod_moneda,
      rc_asi.centro_benef) ;

    fetch c_asientos into rc_asi ;

  end loop ;

  --  Determina saldo anterior por cuenta
  if ln_sw = 0 then
    select sum(nvl(d.imp_movsol,0)), sum(nvl(d.imp_movdol,0))
      into ln_sol_sal_deb, ln_dol_sal_deb
      from cntbl_asiento_det d
      where ( d.ano = ln_ano ) and ( d.cnta_ctbl = ls_cuenta ) and
            ( d.mes <= ln_mes_ant ) and d.flag_debhab = 'D' ;
    select sum(nvl(d.imp_movsol,0)), sum(nvl(d.imp_movdol,0))
      into ln_sol_sal_hab, ln_dol_sal_hab
      from cntbl_asiento_det d
      where ( d.ano = ln_ano ) and ( d.cnta_ctbl = ls_cuenta ) and
            ( d.mes <= ln_mes_ant ) and d.flag_debhab = 'H' ;
  end if ;

  ln_sol_sal_deb := nvl(ln_sol_sal_deb,0) ;
  ln_dol_sal_deb := nvl(ln_dol_sal_deb,0) ;
  ln_sol_sal_hab := nvl(ln_sol_sal_hab,0) ;
  ln_dol_sal_hab := nvl(ln_dol_sal_hab,0) ;

  --  Determina saldo actual por cuenta
  ln_sol_acu_deb := ln_sol_sal_deb + ln_imp_soldeb ;
  ln_sol_acu_hab := ln_sol_sal_hab + ln_imp_solhab ;
  ln_dol_acu_deb := ln_dol_sal_deb + ln_imp_doldeb ;
  ln_dol_acu_hab := ln_dol_sal_hab + ln_imp_dolhab ;

  --  Actualiza saldo anterior y saldo acumulado por cuenta
  update tt_cntbl_libro_mayor
    set sol_sal_deb = ln_sol_sal_deb ,
        sol_acu_deb = ln_sol_acu_deb ,
        sol_sal_hab = ln_sol_sal_hab ,
        sol_acu_hab = ln_sol_acu_hab ,
        dol_sal_deb = ln_dol_sal_deb ,
        dol_acu_deb = ln_dol_acu_deb ,
        dol_sal_hab = ln_dol_sal_hab ,
        dol_acu_hab = ln_dol_acu_hab
    where cuenta = ls_cuenta and origen = ls_origen and
          ano = ln_ano and mes = ln_mes and nro_libro = ln_libro and
          nro_asiento = ln_asiento and item = ln_item ;

end loop ;

end usp_cntbl_rpt_libro_mayor ;
/
