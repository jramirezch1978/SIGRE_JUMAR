create or replace procedure usp_add_concep_rrhh
 ( as_nivel in rrhh_nivel.cod_nivel%type ,
   as_concep in concepto.concep%type ,
   as_desc_concep in concepto.desc_concep%type 
   ) is
   
begin

--Inserta un nuevo registro a la tabla de 
--parametros de rrhh_parm_detalle
Insert Into rrhh_nivel_detalle
 ( cod_nivel, concep  , desc_nivel_detalle)

values 
 ( as_nivel , as_concep , as_desc_concep) ;

  
end usp_add_concep_rrhh;
/
