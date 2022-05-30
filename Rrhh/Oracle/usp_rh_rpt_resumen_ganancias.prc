create or replace procedure usp_rh_rpt_resumen_ganancias (
  ln_estable in integer, ln_contratado in integer,
  as_tipo_trabajador in char, as_origen in char ) is

lk_bonificacion_25      constant char(3) := '030' ;
lk_bonificacion_30      constant char(3) := '031' ;
lk_basico               constant char(3) := '054' ;

ls_concepto_25          char(4) ;
ls_concepto_30          char(4) ;
ls_concepto_basico      char(4) ;
ls_concepto_gan         char(2) ;
ls_cod_trabajador       maestro.cod_trabajador%type ;
ls_concepto             char(4) ;
ls_desc_concepto        varchar2(25) ;
ls_desc_25              varchar2(25) ;
ls_desc_30              varchar2(25) ;
ls_bonif                char(1) ;
ls_situacion            char(1) ;
ln_importe              number(13,2) ;
ln_importe_30           number(13,2) ;
ln_importe_25           number(13,2) ;
ln_nro_trabajadores     number(4) ;
ln_nro_trabajadores_25  number(4) ;
ln_nro_trabajadores_30  number(4) ;
ln_contador             integer ;

--  Lectura de conceptos de ganancias fijas
cursor c_concepto is
  select c.concep, c.desc_breve
  from concepto c
  where c.flag_estado = '1' and substr(c.concep,1,2) = ls_concepto_gan and
        c.concep <> ls_concepto_25 and c.concep <> ls_concepto_30
  order by c.concep ;

--  Lectura de ganancias fijas
cursor c_ganancias is
  select gdf.cod_trabajador, gdf.concep, gdf.flag_trabaj, gdf.flag_estado,
         gdf.imp_gan_desc
  from gan_desct_fijo gdf
  where gdf.concep = ls_concepto and gdf.flag_estado = '1'
  order by gdf.concep ;

begin

--  *****************************************************
--  ***   GENERA RESUMEN GENERAL DE GANANCIAS FIJAS   ***
--  *****************************************************

delete from tt_rpt_ganancias ;

select p.grc_gnn_fija into ls_concepto_gan from rrhhparam p
  where p.reckey = '1' ;
  
select g.concepto_gen into ls_concepto_25 from grupo_calculo g
  where g.grupo_calculo = lk_bonificacion_25 ;
select g.concepto_gen into ls_concepto_30 from grupo_calculo g
  where g.grupo_calculo = lk_bonificacion_30 ;
select g.concepto_gen into ls_concepto_basico from grupo_calculo g
  where g.grupo_calculo = lk_basico ;

ln_importe_25 := 0 ; ln_nro_trabajadores_25 := 0 ;
ln_importe_30 := 0 ; ln_nro_trabajadores_30 := 0 ;

for rc_con in c_concepto loop

  ls_concepto := rc_con.concep ;
  ls_desc_concepto := rc_con.desc_breve ;
  ln_importe := 0 ; ln_nro_trabajadores := 0 ;

  for rc_gan in c_ganancias loop

    ln_contador := 0 ;
    select count(*) into ln_contador from maestro m
      where m.cod_trabajador = rc_gan.cod_trabajador and
            m.tipo_trabajador = as_tipo_trabajador and
            m.flag_estado = '1' and m.cod_origen = as_origen ;

    if ln_contador > 0 then

      select nvl(m.bonif_fija_30_25,'0'), nvl(m.situa_trabaj,' ')
        into ls_bonif, ls_situacion from maestro m
        where m.cod_trabajador = rc_gan.cod_trabajador and
              m.tipo_trabajador = as_tipo_trabajador and
              m.flag_estado = '1' and m.cod_origen = as_origen ;

      --  Proceso solo para estables
      if ln_estable <> 0 then
        if ls_situacion = 'E' or ls_situacion = 'S' then
          rc_gan.imp_gan_desc := nvl(rc_gan.imp_gan_desc,0) ;
          ln_importe := ln_importe + rc_gan.imp_gan_desc ;
          ln_nro_trabajadores := ln_nro_trabajadores + 1 ;
          if ls_bonif = '1' then
            ln_importe_30 := ln_importe_30 + (rc_gan.imp_gan_desc * 0.30) ;
            if rc_gan.concep = ls_concepto_basico then
              ln_nro_trabajadores_30 := ln_nro_trabajadores_30 + 1 ;
            end if ;
          end if ;
          if ls_bonif = '2' then
            ln_importe_25 := ln_importe_25 + (rc_gan.imp_gan_desc * 0.25) ;
            if rc_gan.concep = ls_concepto_basico then
              ln_nro_trabajadores_25 := ln_nro_trabajadores_25 + 1 ;
            end if ;
          end if ;
        end if ;
      end if ;

      --  Proceso solo para contratados
      if ln_contratado <> 0 then
        if ls_situacion = 'C' then
          rc_gan.imp_gan_desc := nvl(rc_gan.imp_gan_desc,0) ;
          ln_importe := ln_importe + rc_gan.imp_gan_desc ;
          ln_nro_trabajadores := ln_nro_trabajadores + 1 ;
          if ls_bonif = '1' then
            ln_importe_30 := ln_importe_30 + (rc_gan.imp_gan_desc * 0.30) ;
            if rc_gan.concep = ls_concepto_basico then
              ln_nro_trabajadores_30 := ln_nro_trabajadores_30 + 1 ;
            end if ;
          end if ;
          if ls_bonif = '2' then
            ln_importe_25 := ln_importe_25 + (rc_gan.imp_gan_desc * 0.25) ;
            if rc_gan.concep = ls_concepto_basico then
              ln_nro_trabajadores_25 := ln_nro_trabajadores_25 + 1 ;
            end if ;
          end if ;
        end if ;
      end if ;

    end if ;

  end loop ;

  --  Insertar los Registro en la tabla temporal
  if ln_importe > 0 then
    insert into tt_rpt_ganancias (
      concep, desc_concep, nro_trabajadores, importe )
    values (
      ls_concepto, ls_desc_concepto, ln_nro_trabajadores, ln_importe ) ;
  end if ;

end loop ;

--  Insertar los Registro en la tabla temporal para 30%
if ln_importe_30 > 0 then
  select c.desc_breve into ls_desc_30 from concepto c
    where c.concep = ls_concepto_30 ;
  insert into tt_rpt_ganancias (
    concep, desc_concep, nro_trabajadores, importe )
  values (
    ls_concepto_30, ls_desc_30, ln_nro_trabajadores_30, ln_importe_30 ) ;
end if ;

--  Insertar los Registro en la tabla temporal para 25%
if ln_importe_25 > 0 then
  select c.desc_breve into ls_desc_25 from concepto c
    where c.concep = ls_concepto_25 ;
  insert into tt_rpt_ganancias (
    concep, desc_concep, nro_trabajadores, importe )
  values (
    ls_concepto_25, ls_desc_30, ln_nro_trabajadores_25, ln_importe_25 ) ;
end if ;

end usp_rh_rpt_resumen_ganancias ;
/
