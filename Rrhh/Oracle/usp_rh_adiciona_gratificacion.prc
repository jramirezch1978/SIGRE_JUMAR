create or replace procedure usp_rh_adiciona_gratificacion
(ac_codtra       in maestro.cod_trabajador%type ,
 ad_fec_proceso  in date                        ,
 ac_flag_mensual in maestro.flag_estado%type     ) is

lc_grat_julio        grupo_calculo.grupo_calculo%type ;
lc_grat_diciembre    grupo_calculo.grupo_calculo%type ;
lc_grat_jubilado     grupo_calculo.grupo_calculo%type ;
lc_grat_adelanto     grupo_calculo.grupo_calculo%type ;
lc_grat_conceptos    grupo_calculo.grupo_calculo%type ;
lc_grat_mensual      concepto.concep%type             ;
ls_cnc_bonif_ext     asistparam.cnc_bonif_ext%TYPE;
ls_concepto          concepto.concep%TYPE;

--  Cursor de adelanto de gratificaciones
cursor c_gratificacion is
  select g.imp_bruto, g.imp_adelanto, m.cod_seccion, g.bonif_ext
  from gratificacion g, maestro m
  where g.cod_trabajador = m.cod_trabajador 
    and g.cod_trabajador = ac_codtra 
    and g.fec_proceso    = ad_fec_proceso ;

begin

--  **************************************************************
--  ***  ADICIONA ADELANTO DE GRATIFICACIONES POR TRABAJADOR   ***
--  **************************************************************

select c.grati_medio_ano, c.grati_fin_ano, c.gratif_jubilado,c.adelanto_gratif, c.concep_gratif ,c.concep_grat_mensual
  into lc_grat_julio, lc_grat_diciembre, lc_grat_jubilado,lc_grat_adelanto, lc_grat_conceptos ,lc_grat_mensual
  from rrhhparam_cconcep c
 where c.reckey = '1' ;
 
 select c.cnc_bonif_ext
  into ls_cnc_bonif_ext
  from asistparam c
 where c.reckey = '1' ;


delete from gan_desct_variable v
 where v.cod_trabajador = ac_codtra and v.concep in
    (select g.concepto_gen from grupo_calculo g where g.grupo_calculo = lc_grat_julio
     union
     select g.concepto_gen from grupo_calculo g where g.grupo_calculo = lc_grat_diciembre
     union
     select g.concepto_gen from grupo_calculo g  where g.grupo_calculo = lc_grat_adelanto
     union
     select lc_grat_mensual from dual  ) ;


for rc_gra in c_gratificacion loop

  if nvl(rc_gra.imp_bruto,0) > 0 then
    --colocar concepto mensual en parametros 1421
    if ac_flag_mensual = '1' then --calculo mensual
        ls_concepto := lc_grat_mensual ;
    else
     if  to_char(ad_fec_proceso,'mm') = '07' then
           select g.concepto_gen 
             into ls_concepto 
             from grupo_calculo g 
            where g.grupo_calculo = lc_grat_julio ;
       elsif to_char(ad_fec_proceso,'mm') = '12' then
           select g.concepto_gen 
             into ls_concepto 
             from grupo_calculo g 
            where g.grupo_calculo = lc_grat_diciembre ;
       end if ;
    end if ;

    insert into gan_desct_variable(
           cod_trabajador, fec_movim, concep, imp_var,flag_replicacion )
    values(
           ac_codtra, ad_fec_proceso, ls_concepto, rc_gra.imp_bruto, '1' ) ;

    -- Inserto la bonificacion
    if rc_gra.bonif_ext > 0 then
      insert into gan_desct_variable (
             cod_trabajador, fec_movim, concep, imp_var, flag_replicacion )
    values (
           ac_codtra, ad_fec_proceso, ls_cnc_bonif_ext, rc_gra.bonif_ext,'1' ) ;
    end if;
    

  end if ;

  if nvl(rc_gra.imp_adelanto,0) > 0 then
    select g.concepto_gen into ls_concepto from grupo_calculo g  where g.grupo_calculo = lc_grat_adelanto ;

    insert into gan_desct_variable (
      cod_trabajador, fec_movim, concep, imp_var,
      flag_replicacion )
    values (ac_codtra, ad_fec_proceso, ls_concepto, rc_gra.imp_adelanto,'1' ) ;

  end if ;

end loop ;



end usp_rh_adiciona_gratificacion ;
/
