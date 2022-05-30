create or replace procedure usp_eval_desem_trabaj_insert
 ( as_cod_trabaj in maestro.cod_trabajador%type, 
   ad_fec_proceso in date ,
   as_cod_plant_desem in plantilla_desempeno.cod_plant_desem%type,
   as_cod_usr in usuario.cod_usr%type
 ) is
 
--Cursor de factores de Desempeño de la Plantilla  
Cursor c_plant is 
Select pfd.cod_fact_desem, pfd.peso
 From plantilla_fact_desem pfd
Where pfd.cod_plant_desem = as_cod_plant_desem;
 
begin
--Insert del Reg en Eval Desem Trabaj
 INSERT INTO eval_desempeno_trabajador 
  ( cod_trabajador , fec_proceso    , cod_plant_desem ,
    cod_evaluador  , cod_sit_eval   , cod_est_eval    ,
    cod_usr)
  values 
  ( as_cod_trabaj  , ad_fec_proceso , as_cod_plant_desem , 
    ''             , ''             , ''            ,
    as_cod_usr);

--Lectuta del For 
for rc_plant in c_plant Loop
  --Insert del Reg en Eval Desem Trabaj Detalle
  INSERT INTO eval_desem_trabajador_detalle 
   ( cod_trabajador          , fec_proceso   , cod_plant_desem  ,
     cod_fact_desem          , calificacion  , peso             ,
     cod_usr)                 
  Values 
   ( as_cod_trabaj           , ad_fec_proceso , as_cod_plant_desem ,  
     rc_plant.cod_fact_desem , 0              , rc_plant.peso      ,
     as_cod_usr);
   
End Loop;   

end usp_eval_desem_trabaj_insert;
/
