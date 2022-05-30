create or replace procedure usp_eval_desem_trabaj_delete
 (as_cod_trabaj in maestro.cod_trabajador%type,
  ad_fec_proceso  in date ,
  as_cod_plant_desem in plantilla_desempeno.cod_plant_desem%type
 ) is

begin

--Delete de Conl Eval Desem Trabaj
Delete concl_eval_desem_trabaj cedt
 where  cedt.cod_trabajador = as_cod_trabaj and 
        cedt.fec_proceso = ad_fec_proceso and 
        cedt.cod_plant_desem = as_cod_plant_desem;

--Delete de la Eval Desem del Trabaj Detalle
Delete eval_desem_trabajador_detalle edtd 
 where edtd.cod_trabajador = as_cod_trabaj and 
       edtd.fec_proceso = ad_fec_proceso and 
       edtd.cod_plant_desem = as_cod_plant_desem ;

--Delete de la Eval Desem del Trsbsj
Delete eval_desempeno_trabajador edt
 where edt.cod_trabajador = as_cod_trabaj and 
       edt.fec_proceso = ad_fec_proceso and 
       edt.cod_plant_desem = as_cod_plant_desem; 


end usp_eval_desem_trabaj_delete ;
/
