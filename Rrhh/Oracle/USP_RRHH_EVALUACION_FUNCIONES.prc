create or replace procedure USP_RRHH_EVALUACION_FUNCIONES
(ls_cod_trabajador in rrhh_funcion_cargo_eval.cod_trabajador%type,
 ls_cod_cargo      in rrhh_funcion_cargo_eval.cod_cargo%type,
 ld_fecha          in date,
 ls_user           in rrhh_funcion_cargo_eval.cod_usr%type) is

 ll_item  number;
 
   cursor c_general is
    SELECT FUNCION
    FROM RRHH_FUNCION_CARGO
   WHERE RRHH_FUNCION_CARGO.cod_cargo = ls_cod_cargo;
         
begin
 
ll_item := 0;

--llena la tabla para poder generar las evaluaciones

for c_g in c_general loop
    
    ll_item := ll_item + 1;
    
    insert into rrhh_funcion_cargo_eval
    (
    fecha, cod_trabajador, item, cod_cargo, funcion, cod_usr
    )
    values
    (
    ld_fecha, ls_cod_trabajador, ll_item, ls_cod_cargo, c_g.funcion, ls_user
    );

end loop;

end USP_RRHH_EVALUACION_FUNCIONES;
/
