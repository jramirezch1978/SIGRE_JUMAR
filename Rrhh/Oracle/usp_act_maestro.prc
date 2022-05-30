create or replace procedure usp_act_maestro is

ls_cencos   codigos.cencos%type;
ls_codtra   maestro.cod_trabajador%type;
ln_count    integer ;

cursor c_maestro is
  select m.cod_trabajador
  from maestro m 
  FOR UPDATE;
   
begin
  
For rc_m in c_maestro loop

 ls_codtra := rc_m.cod_trabajador;
     
 select count(*)
   into ln_count  
   from codigos c
   where c.cod_trabajador = ls_codtra;
   
 If ln_count > 0 then
    
   select c.cencos
     into ls_cencos 
     from codigos c
     where c.cod_trabajador = ls_codtra ; 
     
   ls_cencos :=nvl(ls_cencos,' '); 
         
   update maestro 
     set cencos =  ls_cencos 
     where current of c_maestro ;
     
  End if; 

End loop ;
  
end usp_act_maestro;
/
