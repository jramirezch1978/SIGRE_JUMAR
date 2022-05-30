create or replace procedure usp_gen_boleta_pago
 ( as_codtra in maestro.cod_trabajador%type 
  ) is
  
ls_grupo string(1);
ls_concep concepto.concep%type;
ln_impsol calculo.imp_soles%type;

--Cursor para un Trabajdor de la Tabla Calculo
Cursor c_calculo is
select c.concep, c.fec_proceso, c.horas_trabaj, 
       c.horas_pag, c.dias_trabaj, c.imp_soles
from calculo c
where c.cod_trabajador = as_codtra;

  
begin

For rc_c in c_calculo Loop
 ls_concep := rc_c.concep;
 --Generamos datos para la Tabla tt_boleta_pago  
 ls_grupo := SUBSTR(ls_concep,1,1);
  
 INSERT INTO tt_boleta_pago 
    ( cod_trabajador  ,  cod_grupo         ,
      concep          ,  fec_proceso       , 
      horas_trabaj    ,  horas_pag         ,
      dias_trabaj     ,  imp_soles )

 VALUES 
    ( as_codtra          , ls_grupo   ,
      rc_C.concep        , rc_c.fec_proceso   , 
      rc_c.horas_trabaj  , rc_c.horas_pag     , 
      rc_c.dias_trabaj   , rc_c.imp_soles  )  ;
  
END Loop;  
end usp_gen_boleta_pago;
/
