create or replace procedure USP_PLA_CONCEP (
       as_cod_trabajador in maestro.cod_trabajador%type,
       ad_fec_desde  in date ,
       ad_fec_hasta in date 
       )

is
ls_concepto char(4);
ls_cod_formula char(3);
ln_count number;
   --Cursor para la tabla concepto 
   cursor c_pla_concepto is 
       select c.concep, c.cod_formula 
       from concepto c;

begin
   For rc_pla_concepto  in c_pla_concepto
     Loop   
        ls_concepto := rc_pla_concepto.concep;
        ls_cod_formula:= rc_pla_concepto.cod_formula;
     
        select count(), 
        into ln_count
        from gan_desct_fijo
        where gan_desct_fijo.concep = ls_concepto and 
              gan_desct_fijo.cod_trabajador = as_cod_trabajador;
              
             If ln-count <> 0  then
                Insert tt_pla_concept values (ls_concepto,ls_cod_formula)
             Else  
               
               Select count()
               into ln_count
               where gan_desct_variable
                       
             
     
     
     
     End loop;
  
  
    
  
  
  
end USP_PLA_CONCEP;
/
