create or replace procedure usp_rpt_emision_planilla
 ( as_tipo_trabaj in tipo_trabajador.tipo_trabajador%type
  ) is

ls_codtra maestro.cod_trabajador%type; 

--Cursor de Lectura de los Trabaj de T Calculo  
Cursor c_t is 
Select distinct c.cod_trabajador
From  calculo c, maestro m
Where c.cod_trabajador = m.cod_trabajador and 
      m.tipo_trabajador = as_tipo_trabaj;

begin
--Deleteo de la Tabla tt_rpt_emis_plan
Delete from tt_rpt_emis_plan;



For rc_t in c_t Loop
  ls_codtra := rc_t.cod_trabajador; 
  
  --Procedimiento de Cabecera de Emision de Planilla 
  usp_rpt_emis_plan_cabecera(ls_codtra);
  --Procedimiento de Ganancia de Emision de Planilla
  usp_rpt_emis_plan_ganancia(ls_codtra);
  --Procedimiento de Descuento de Emision de Planilla
  usp_rpt_emis_plan_descto(ls_codtra);
  --Procedimiento de Aporte de Emision de Planilla 
  usp_rpt_emis_plan_aporte(ls_codtra);
  --Procedimiento de Otros de Emision de Planilla  
  usp_rpt_emis_plan_otros(ls_codtra); 
  
End loop;

end usp_rpt_emision_planilla;
/
