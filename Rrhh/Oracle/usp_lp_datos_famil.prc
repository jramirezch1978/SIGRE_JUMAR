create or replace procedure usp_lp_datos_famil
 ( as_codtra in maestro.cod_trabajador%type
 ) is

--Busqueda de los parirntes del Trabajador
Cursor c_carga_famil is 
 select cf.apel_paterno, cf.apel_materno, cf.nombre1,
        cf.nombre2, cf.fec_nacimiento, p.desc_parent,
        cf.flag_sexo, cf.flag_vida, cf.ocupacion,
        cf.flag_trabaja_emp, a.desc_area, 
        cf.flag_dependencia, m.flag_algun_famil
 from   carga_familiar cf, parentesco p,
        area a , maestro m 
 where  cf.cod_trabajador = as_codtra and 
        cf.cod_trabajador = m.cod_trabajador and 
        cf.cod_parent = p.cod_parent and 
        cf.cod_area = a.cod_area (+);
 
begin
--Deleteo de la Tabla tt_lp_datos_famil
delete from tt_lp_datos_famil tt
where tt.cod_trabajador = as_codtra;

--Presentacion de los registros del Cursor 
For rc_c in c_carga_famil loop

   INSERT INTO tt_lp_datos_famil
    ( cod_trabajador , apel_paterno      , apel_materno ,
      nombre1        , nombre2           , fec_nacim    ,
      desc_parent    , flg_sexo          , flg_vida     ,
      ocupacion      , flg_trabaj_emp    , desc_area    ,
      flg_depen      , flg_algun_famil )
   values 
    ( as_codtra        , rc_c.apel_paterno     , rc_c.apel_materno   ,
      rc_c.nombre1     , rc_c.nombre2          , rc_c.fec_nacimiento ,
      rc_c.desc_parent , rc_c.flag_sexo        , rc_c.flag_vida      ,
      rc_c.ocupacion   , rc_c.flag_trabaja_emp , rc_c.desc_area      ,
      rc_c.flag_dependencia , rc_c.flag_algun_famil );
      
 End Loop;
   
end usp_lp_datos_famil;
/
