create or replace procedure usp_pla_gan_desct_fijo1(
   as_cod_trabajador in maestro.cod_trabajador%type,
   as_concepto in concepto.concep%type, 
   as_desc_formula in out formula.desc_formula%type) 
   
   is

 
--ls_desc_formula varchar2(200);
ln_imp_fijo number(13,2);

--Cursor para obtener el importe y la formula para un determinado 
--concepto de la tabla de gan_desct_fijo

cursor c_gan_desct_fijo is 
  select gdf.imp_gan_desc,
         f.desc_formula
  from   gan_desct_fijo gdf ,
         formula f ,
         concepto c
  where gdf.cod_trabajador = as_cod_trabajador and
        gdf.concep = as_concepto and
        c.concep = gdf.concep and 
        c.cod_formula = f.cod_formula 
  order by  gdf.concep;

begin

--Se recupera la informacion del cursor,tanto para el importe 
--y la formula   
  For rc_gan_desct_fijo in c_gan_desct_fijo
    Loop
      --ls_desc_formula := as_desc_formula;       
      as_desc_formula:=rc_gan_desct_fijo.desc_formula;
      ln_imp_fijo:=rc_gan_desct_fijo.imp_gan_desc;
      --as_desc_formula := ls_desc_formula;
      
      If ln_imp_fijo is null then
         ln_imp_fijo:=0;
      End if;
    End Loop;
    
   
  Insert into tt_pla_concepto(concep,formula,
                debe_haber,valor)
  values ('IMPO','TABL','0',ln_imp_fijo);
  
  Insert into tt_pla_concepto(concep,formula,
                debe_haber,valor)
  values ('IMPB',as_desc_formula,'0',0);
    

end usp_pla_gan_desct_fijo1;
/
