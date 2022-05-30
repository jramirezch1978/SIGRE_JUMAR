create or replace procedure usp_rh_cons_quinquenios (
  as_tipo_trabajador in char, as_origen in char, ad_fec_proy in date ) is

lk_nivel_quin          char(3) ;

ls_nombre              varchar2(100) ;
ls_cod_seccion         seccion.cod_seccion%type ;
ls_desc_mes            char(10) ;
ln_imp_quinq           number(13,2) ;
ln_imp_basico          number(13,2) ;
ln_anio_ing            number(4) ;
ln_anio_proy           number(4) ;
ln_mes_ing             number(2) ;
ln_quinq               number(2) ;
ln_jornal              number(4,2) ;
ln_resto               number(1) ;
ln_cociente            number(5,3) ;
ln_cociente_round      number(5,3) ;
ls_concepto            char(4) ;

--  Lectura de los trabajadores seleccionados
cursor c_maestro is
  select m.cod_trabajador, m.fec_ingreso, m.cod_seccion, m.cod_area, s.desc_seccion
  from  maestro m, seccion s
  where (m.cod_area = s.cod_area and m.cod_seccion = s.cod_seccion) and
        m.flag_estado = '1' and m.tipo_trabajador = as_tipo_trabajador and
        m.cod_origen = as_origen ;

begin

--  *****************************************************
--  ***   CONSULTA DE PROYECCION DE LOS QUINQUENIOS   ***
--  *****************************************************

delete from tt_cons_proy_quinq ;

select p.remunerac_basica
  into lk_nivel_quin
  from rrhhparam_cconcep p
  where p.reckey = '1' ;

select g.concepto_gen
  into ls_concepto
  from grupo_calculo g
  where g.grupo_calculo = lk_nivel_quin ;
    
for rc_m in c_maestro loop

  ls_cod_seccion := nvl(rc_m.cod_seccion,'0') ;
  ln_anio_ing  := to_char(rc_m.fec_ingreso,'YYYY') ;
  ln_anio_proy := to_char(ad_fec_proy,'YYYY') ;

  ln_quinq := ln_anio_proy - ln_anio_ing ;
  ln_resto := mod(ln_quinq,5) ;
  ln_cociente := ln_quinq / 5 ;
  ln_cociente_round := round(ln_cociente) ;

  if ln_resto = 0 and ls_cod_seccion <> '0' and ln_cociente = ln_cociente_round then

    ls_nombre := usf_rh_nombre_trabajador(rc_m.cod_trabajador) ;
    ln_jornal := 0 ;
    select sum(nvl(q.jornal,0)) into ln_jornal from quinquenio q
      where q.quinquenio = ln_quinq ;

    if ln_jornal > 0 then

      select nvl(sum(gdf.imp_gan_desc),0) into ln_imp_basico
        from  gan_desct_fijo gdf
        where gdf.cod_trabajador = rc_m.cod_trabajador and
              gdf.concep = ls_concepto ;

      if ln_imp_basico > 0 then
         ln_imp_quinq := ln_imp_basico / 30 * ln_jornal ;
         ln_mes_ing := to_char(rc_m.fec_ingreso,'MM') ;
         ls_desc_mes := to_char(rc_m.fec_ingreso,'MONTH') ;
         insert into tt_cons_proy_quinq (
           cod_trabajador, tipo_trabaj, cod_seccion,
           desc_seccion, nombre, cod_mes, desc_mes,
           fec_ingreso, quinquenio, imp_basico, jornal, imp_quin )
          values (
            rc_m.cod_trabajador, as_tipo_trabajador, rc_m.cod_seccion,
            rc_m.desc_seccion, ls_nombre, ln_mes_ing, ls_desc_mes,
            rc_m.fec_ingreso, ln_quinq, ln_imp_basico, ln_jornal, ln_imp_quinq ) ;
      end if ;

    end if ;

  end if ;

end loop ;

end usp_rh_cons_quinquenios ;
/
