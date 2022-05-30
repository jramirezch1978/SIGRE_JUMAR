create or replace procedure usp_rh_actualiza is

ld_fecha_evaluacion      rh_evaluacion_personal.fecha_evaluacion%type ;
ls_cod_trabajador        rh_evaluacion_personal.cod_trabajador%type ;
ls_cod_area              rh_evaluacion_personal.cod_area%type ;
ls_cod_cargo             rh_evaluacion_personal.cod_cargo%type ;
  
ls_cod_competencia       rh_cargo_compet_comport.cod_competencia%type ;
ls_cod_comportamiento    rh_cargo_compet_comport.cod_comport%type ;

ln_contador              integer ;

--  Cursor de lectura de las evaluaciones del personal
cursor c_evaluacion is
  Select ep.fecha_evaluacion, ep.cod_trabajador,
         ep.cod_area, ep.cod_cargo
  from rh_evaluacion_personal ep
  where ep.flag_estado = '1'
  order by ep.cod_trabajador, ep.fecha_evaluacion ;

--  Cursor de lectura de competencias y comportamientos
cursor c_competencias is
  Select cc.cod_competencia, cc.cod_comport
  from rh_cargo_compet_comport cc
  where cc.cod_area = ls_cod_area and
        cc.cod_cargo = ls_cod_cargo and
        cc.flag_estado = '1'
  order by cc.cod_competencia, cc.cod_comport ;

begin

--  ************************************************
--  ***   LECTURA DE EVALUACIONES DEL PERSONAL   ***
--  ************************************************
for rc_eva in c_evaluacion loop

  ld_fecha_evaluacion := rc_eva.fecha_evaluacion ;
  ls_cod_trabajador   := nvl(rc_eva.cod_trabajador,' ') ;
  ls_cod_area         := nvl(rc_eva.cod_area,' ') ;
  ls_cod_cargo        := nvl(rc_eva.cod_cargo,' ') ;

  --  *****************************************************
  --  ***   LECTURA DE COMPETENCIAS Y COMPORTAMINETOS   ***
  --  *****************************************************
  for rc_com in c_competencias loop

    ls_cod_competencia    := nvl(rc_com.cod_competencia,' ') ;
    ls_cod_comportamiento := nvl(rc_com.cod_comport,' ') ;
    
    ln_contador := 0 ;
    select count(*)
      into ln_contador
      from rh_evaluacion_personal_det epd
      where epd.fecha_evaluacion = ld_fecha_evaluacion and
            epd.cod_trabajador = ls_cod_trabajador and
            epd.cod_competencia = ls_cod_competencia and
            epd.cod_comport = ls_cod_comportamiento ;
            
    if ln_contador = 0 then
      
      insert into rh_evaluacion_personal_det (
        fecha_evaluacion, cod_trabajador, cod_competencia,
        cod_comport, puntaje )
      values (
        ld_fecha_evaluacion, ls_cod_trabajador, ls_cod_competencia,
        ls_cod_comportamiento, 0 ) ;
      
    end if ;
    
  end loop ;
  
end loop ;

end usp_rh_actualiza ;
/
