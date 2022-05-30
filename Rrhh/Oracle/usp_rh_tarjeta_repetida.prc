create or replace procedure usp_rh_tarjeta_repetida (as_nada in char) is

ls_tarjeta                rrhh_asigna_trjt_reloj.cod_tarjeta%type ;
ld_fecha_ini              date ;
ld_fecha_fin              date ;


--  Cursor para leer el trabajador seleccionado
CURSOR c_tarjeta is
SELECT tt.cod_trabajador, tt.cod_tarjeta, tt.fecha_ini, tt.fecha_fin, tt.flag_repetido 
  FROM tt_rh_tarjetas_repetidas tt 
 ORDER BY tt.cod_tarjeta, tt.fecha_ini, tt.cod_trabajador ;

rc_tar c_tarjeta%rowtype ;

BEGIN 

-- Elimina datos de archivo temporal
DELETE FROM tt_rh_tarjetas_repetidas ;

-- Adiciona items de tabla de tarjetas ;
INSERT INTO tt_rh_tarjetas_repetidas(cod_trabajador, cod_tarjeta, fecha_ini, fecha_fin, flag_estado, flag_repetido)
SELECT r.cod_trabajador, r.cod_tarjeta, r.fecha_inicio, r.fecha_fin, r.flag_estado, '0'  
  FROM rrhh_asigna_trjt_reloj r ;

open c_tarjeta ;
fetch c_tarjeta into rc_tar ;

WHILE c_tarjeta%found loop
      ls_tarjeta      := rc_tar.cod_tarjeta ;
      ld_fecha_ini    := rc_tar.fecha_ini ;
      ld_fecha_fin    := rc_tar.fecha_fin ;
      
      fetch c_tarjeta into rc_tar ;      

      WHILE rc_tar.cod_tarjeta = ls_tarjeta AND c_tarjeta%found LOOP
            -- Actualiza como registro error si fecha 
            IF rc_tar.fecha_ini < ld_fecha_fin THEN 
               UPDATE tt_rh_tarjetas_repetidas tt 
                  SET tt.flag_repetido = '1' 
                WHERE tt.cod_trabajador = rc_tar.cod_trabajador AND 
                      tt.cod_tarjeta = rc_tar.cod_tarjeta AND 
                      tt.fecha_ini = rc_tar.fecha_ini AND 
                      tt.fecha_fin = rc_tar.fecha_fin ;
            END IF ;            
            -- Siguiente registro
            fetch c_tarjeta into rc_tar ;       
            ld_fecha_ini      := rc_tar.fecha_ini ;
            ld_fecha_fin      := rc_tar.fecha_fin ;
            
      END LOOP ;
END LOOP ;

close c_tarjeta ;

end usp_rh_tarjeta_repetida ;
/
