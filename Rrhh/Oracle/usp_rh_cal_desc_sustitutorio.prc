create or replace procedure usp_rh_cal_desc_sustitutorio (
  asi_codtra      in maestro.cod_trabajador%TYPE, 
  adi_fec_proceso in date, 
  asi_origen      in origen.cod_origen%TYPE,
  ani_tipcam      in number 
) is

lk_ganancias_fijas      rrhhparam_cconcep.descanso_sustitutorio%TYPE;

ln_chequea              integer ;
ln_contador             integer ;
ls_concepto             char(4) ;
ln_dias                 number(5,2) ;
ln_imp_soles            calculo.imp_soles%TYPE ;
ln_imp_dolar            calculo.imp_dolar%TYPE;

begin

--  *************************************************************
--  ***   REALIZA CALCULO POR DIAS DE DESCANSO SUSTITUTORIO   ***
--  *************************************************************

select c.descanso_sustitutorio 
  into lk_ganancias_fijas
  from rrhhparam_cconcep c 
 where c.reckey = '1' ;

ln_chequea := 0 ;
select count(*) 
  into ln_chequea 
  from grupo_calculo g
 where g.grupo_calculo = lk_ganancias_fijas ;

if ln_chequea > 0 then

   select g.concepto_gen 
     into ls_concepto 
     from grupo_calculo g
    where g.grupo_calculo = lk_ganancias_fijas ;

   ln_contador := 0 ; ln_dias := 0 ;
   select count(*) 
     into ln_contador 
     from inasistencia i
    where i.cod_trabajador = asi_codtra 
      and i.concep = ls_concepto 
      and trunc(i.fec_movim) = trunc(adi_Fec_proceso);

  if ln_contador > 0 then

     select sum(nvl(i.dias_inasist,0)) 
       into ln_dias 
       from inasistencia i
      where i.cod_trabajador = asi_codtra 
        and i.concep         = ls_concepto 
        and trunc(i.fec_movim) = trunc(adi_Fec_proceso);

    select nvl(sum(nvl(gdf.imp_gan_desc,0)),0) 
      into ln_imp_soles 
      from gan_desct_fijo gdf
      where gdf.cod_trabajador = asi_codtra 
        and gdf.flag_estado    = '1' 
        and gdf.concep in ( select d.concepto_calc 
                              from grupo_calculo_det d
                             where d.grupo_calculo = lk_ganancias_fijas ) ;

    ln_imp_soles := (ln_imp_soles / 30) * ln_dias ;
    
    if ln_imp_soles > 0 then
        ln_imp_dolar := ln_imp_soles / ani_tipcam ;

        insert into calculo (
          cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
          dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
        values (
          asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
          ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1 ) ;
     end if;

  end if ;

end if ;

end usp_rh_cal_desc_sustitutorio ;
/
