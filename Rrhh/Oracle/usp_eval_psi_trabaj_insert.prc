create or replace procedure usp_eval_psi_trabaj_insert
 ( as_cod_trabaj in maestro.cod_trabajador%type, 
   ad_fec_proceso in date ,
   as_cod_plant_psi in plantilla_psicologica.cod_plant_psi%type,
   as_cod_usr in usuario.cod_usr%type
 ) is
 
--Cursor de habil y personal. de la PLantilla  
Cursor c_plant is 
Select p.flag_h_p, p.cod_h_p
 From plantilla_hab_pers_psicol p
Where p.cod_plant_psi = as_cod_plant_psi;
 
begin
--Insert el Reg en el Maestro De Eval Psicol Trabaj
 INSERT INTO eval_psicologica_trabajador 
  ( cod_trabajador , fec_proceso    , cod_plant_psi ,
    interpretacion , conclusion     , observacion   ,
    cod_sit_eval   , cod_est_eval   , cod_usr)
  values 
  ( as_cod_trabaj  , ad_fec_proceso , as_cod_plant_psi , 
    ''             , ''             , ''            ,
    ''             , ''             , as_cod_usr);

--Lectuta del For 
for rc_plant in c_plant Loop
  --Insert del Reg en Eval Psicol Trabaj Detalle
  INSERT INTO eval_psicol_trabajador_detalle 
   ( cod_trabajador     , fec_proceso      , cod_plant_psi    ,
     flag_h_p           , cod_h_p          , puntaje          ,
     cod_usr)
  Values 
   ( as_cod_trabaj      , ad_fec_proceso   , as_cod_plant_psi ,  
     rc_plant.flag_h_p  , rc_plant.cod_h_p , 0                ,
     as_cod_usr);
   
End Loop;   

end usp_eval_psi_trabaj_insert;
/
