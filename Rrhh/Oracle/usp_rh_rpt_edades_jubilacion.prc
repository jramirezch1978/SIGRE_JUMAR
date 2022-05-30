create or replace procedure usp_rh_rpt_edades_jubilacion (
  an_aservf in number, an_aservm in number, an_edadf_desde in number,
  an_edadf_hasta in number, an_edadm_desde in number, an_edadm_hasta in number,
  ad_fec_proy in date, as_tipo_trabajador in char, as_origen in char ) is 

ls_codigo             maestro.cod_trabajador%type ;
ln_meses_serv         number(11,2) ;   
ln_anios_serv         number(11,2) ;
ln_meses_jub          number(11,2) ;   
ln_anios_jub          number(11,2) ;
ls_area               area.cod_area%type ;
ls_desc_area          area.desc_area%type ;
ls_seccion            seccion.cod_seccion%type ;
ls_desc_seccion       seccion.desc_seccion%type ;
ls_cencos             centros_costo.cencos%type ;
ls_desc_cencos        centros_costo.desc_cencos%type ;
ls_flag_sexo          maestro.flag_sexo%type ;   
ls_nombre             varchar2(100) ;
ld_fec_ingreso        date ;
ld_fec_nacimiento     date ;
ld_fecha_tope         deuda.fec_proceso%type ;
ln_importe            number(13,2) ;
ln_indicador          number(1) ;

--  Cursor de trabajadores, solo activos
cursor c_trabajador is 
  select m.cod_trabajador, m.cod_seccion, m.cod_area, m.cencos, m.flag_sexo,
         m.fec_nacimiento, m.fec_ingreso 
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen ;
 
--  Lectura de trabajadores a quienes se les adeuda
cursor c_deuda is 
  select d.fec_proceso, d.importe
  from deuda d
  where d.cod_trabajador = ls_codigo
  order by d.cod_trabajador, d.fec_proceso ;
 
begin

--  ***********************************************************
--  ***   REPORTE DE TRABAJADORES EN EDADES DE JUBILACION   ***
--  ***********************************************************

delete from tt_edades_jubilacion ;

for c_t in c_trabajador loop

  ls_codigo  := c_t.cod_trabajador ;
  ls_nombre  := usf_rh_nombre_trabajador(c_t.cod_trabajador);
  ls_area    := c_t.cod_area ;
  ls_seccion := c_t.cod_seccion ;
  ls_cencos  := c_t.cencos ;
  
  select a.desc_area into ls_desc_area from area a  
    where a.cod_area = ls_area ;
  if ls_seccion  is not null then
    select s.desc_seccion into ls_desc_seccion from seccion s
      where s.cod_area = ls_area and s.cod_seccion = ls_seccion ;
  end if ;
       
  ls_desc_cencos := null ;
  if ls_cencos is not null then
    select cc.desc_cencos into ls_desc_cencos from centros_costo cc
    where cc.cencos = ls_cencos ;
  end if ;

  ls_desc_area      := nvl(ls_desc_area,' ') ; 
  ls_desc_seccion   := nvl(ls_desc_seccion,' '); 
  ls_desc_cencos    := nvl(ls_desc_cencos,' ') ;
  ls_flag_sexo      := nvl(c_t.flag_sexo,'N') ;
  ld_fec_ingreso    := nvl(c_t.fec_ingreso,sysdate) ;
  ld_fec_nacimiento := nvl(c_t.fec_nacimiento,sysdate) ;
  
  --  Halla anos de servicios
  ln_meses_serv := MONTHS_BETWEEN (ad_fec_proy, c_t.fec_ingreso) ;
  ln_anios_serv := ln_meses_serv / 12 ;
  ln_anios_serv := nvl(ln_anios_serv,0) ;
  
  --  Halla edad de jubilacion
  ln_meses_jub := MONTHS_BETWEEN (ad_fec_proy, c_t.fec_nacimiento) ;
  ln_anios_jub := ln_meses_jub / 12 ;
  ln_anios_jub := nvl(ln_anios_jub,0) ;
  
  if ls_flag_sexo = 'F' then 
    if ln_anios_serv >= an_aservf and 
      ln_anios_jub >= an_edadf_desde and
      ln_anios_jub <= an_edadf_hasta  then  
      for c_rd in c_deuda loop
        ld_fecha_tope := c_rd.fec_proceso ;
      end loop ;
      ln_importe := 0 ;
      for c_rd in c_deuda loop
        if c_rd.fec_proceso = ld_fecha_tope then
          ln_importe := ln_importe + c_rd.importe ;
        end if ;
      end loop ;
      ln_importe := nvl(ln_importe,0) ;
      insert into tt_edades_jubilacion (
        cod_trabajador, nombre_trabaj, cod_area,
        desc_area, cod_seccion, desc_seccion,
        cencos, desc_cencos, flag_sexo, desc_sexo,
        fec_ingreso, fec_nacimiento, indicador, importe )
      values (
        ls_codigo, ls_nombre, ls_area,
        ls_desc_area, ls_seccion, ls_desc_seccion,
        ls_cencos, ls_desc_cencos, ls_flag_sexo, 'Femenino',
        ld_fec_ingreso, ld_fec_nacimiento, 1, ln_importe );
    end if ;
  end if ; 
  
  if ls_flag_sexo = 'M' then 
    if ln_anios_serv >= an_aservm and 
      ln_anios_jub >= an_edadm_desde and
      ln_anios_jub <= an_edadm_hasta  then  
      for c_rd in c_deuda loop
        ld_fecha_tope := c_rd.fec_proceso ;
      end loop ;
      ln_importe := 0 ;
      for c_rd in c_deuda loop
        if c_rd.fec_proceso = ld_fecha_tope then
          ln_importe := ln_importe + c_rd.importe ;
        end if ;
      end loop ;
      ln_importe := nvl(ln_importe,0) ;
      insert into tt_edades_jubilacion (
        cod_trabajador, nombre_trabaj, cod_area,
        desc_area, cod_seccion, desc_seccion,
        cencos, desc_cencos, flag_sexo, desc_sexo,
        fec_ingreso, fec_nacimiento, indicador, importe )
      values (
        ls_codigo, ls_nombre, ls_area,
        ls_desc_area, ls_seccion, ls_desc_seccion,
        ls_cencos, ls_desc_cencos, ls_flag_sexo, 'Masculino',
        ld_fec_ingreso, ld_fec_nacimiento, 1, ln_importe );
    end if ;
  end if ; 
    
end loop ;

end usp_rh_rpt_edades_jubilacion ;
/
