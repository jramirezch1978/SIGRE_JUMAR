create or replace procedure usp_rh_cal_diferidos (
  as_codtra in char, ad_fec_proceso in date, an_tipcam in number,
  as_total_ingreso in char ) is

ln_verifica             integer ;
ln_ingreso_total        number(13,2) ;
ln_descuento_total      number(13,2) ;
ln_importe_acumulado    number(13,2) ;
ln_importe_diferido     number(13,2) ;
ln_imp_soles            number(13,2) ;
ln_imp_dolar            number(13,2) ;

--  Lectura de conceptos que pueden ser diferidos
cursor c_diferido is
  select c.concep, c.imp_soles
  from  calculo c
  where c.cod_trabajador = as_codtra and c.fec_proceso = ad_fec_proceso and
        substr(c.concep,1,1) = '2'
  order by c.cod_trabajador, c.concep ;

begin

--  ******************************************************
--  ***  REALIZA CALCULO DE DIFERIDOS POR TRABAJADOR   ***
--  ******************************************************

--ln_verifica := 0 ;
--select count(*) into ln_verifica from calculo c
--  where c.cod_trabajador = as_codtra and c.fec_proceso = ad_fec_proceso and
--        c.concep = as_total_ingreso ;

--if ln_verifica > 0 then

  ln_verifica := 0 ; ln_ingreso_total := 0 ;
  select count(*) into ln_verifica from calculo c
    where c.cod_trabajador = as_codtra and c.fec_proceso = ad_fec_proceso and
          c.concep = as_total_ingreso ;
  if ln_verifica > 0 then
    select nvl(c.imp_soles,0) into ln_ingreso_total from calculo c
      where c.cod_trabajador = as_codtra and c.fec_proceso = ad_fec_proceso and
            c.concep = as_total_ingreso ;
  end if ;

  select sum(nvl(c.imp_soles,0)) into ln_descuento_total from calculo c
    where c.cod_trabajador = as_codtra and c.fec_proceso = ad_fec_proceso and
          substr(c.concep,1,1) = '2' ;

  if ln_descuento_total > ln_ingreso_total then

    ln_importe_acumulado := 0 ; ln_importe_diferido := 0 ;
    for rc_d in c_diferido loop
      if ln_importe_diferido = 0 then
        ln_importe_acumulado := ln_importe_acumulado + nvl(rc_d.imp_soles,0) ;
        if ln_ingreso_total < ln_importe_acumulado then
          ln_imp_soles := ln_ingreso_total - ( ln_importe_acumulado -
                          nvl(rc_d.imp_soles,0) ) ;
          ln_imp_dolar := ln_imp_soles / an_tipcam ;
          update calculo
            set imp_soles       = ln_imp_soles,
                imp_dolar       = ln_imp_dolar,
                flag_replicacion = '1'
            where cod_trabajador = as_codtra and concep = rc_d.concep ;
          ln_importe_diferido := (nvl(rc_d.imp_soles,0) - ln_imp_soles) ;
          insert into diferido (
            cod_trabajador, concep, importe, fec_proceso, flag_replicacion )
          values (
            as_codtra, rc_d.concep, ln_importe_diferido, ad_fec_proceso, '0' ) ;
        end if ;
      else
        ln_importe_diferido := nvl(rc_d.imp_soles,0) ;
        update calculo
          set imp_soles        = 0,
              imp_dolar        = 0,
              flag_replicacion = '1'
          where cod_trabajador = as_codtra and concep = rc_d.concep ;
        insert into diferido (
          cod_trabajador, concep, importe, fec_proceso, flag_replicacion )
        values (
          as_codtra, rc_d.concep, ln_importe_diferido, ad_fec_proceso, '0' ) ;
      end if ;
    end loop ;

  end if ;

--end if ;

end usp_rh_cal_diferidos ;
/
