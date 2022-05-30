create or replace procedure usp_cal_sunat610_otro
 ( as_codemp in empresa.cod_empresa%type
 ) is

ls_ruc_emp char(11);
ls_seccion seccion.cod_seccion%type;
ls_porc_ipss char(5);
ls_porc_onp char(5);
ls_codtra maestro.cod_trabajador%type; 
ls_dni char(15);
ln_imp_ipss number(15);
ls_imp_ipss char(15);
ln_imp_onp number(15);
ls_imp_onp char(15);
ls_sunat char(300);
ln_count1 number(15);
ln_count2 number(15);    
    
--Cursor para buscar la seccion  
Cursor c_seccion is 
 select s.cod_seccion,
        s.porc_sctr_ipss,
        s.porc_sctr_onp
  from seccion s ;
  
--Buscamos los trab para una seccion 
Cursor c_trabaj (ls_seccion in seccion.cod_seccion%type
                 ) is 
 select m.cod_trabajador, m.dni  
  from maestro m
 where m.cod_seccion = ls_seccion and 
       m.cod_empresa = as_codemp and 
       m.flag_estado = '1';
  
begin
--Borramos datos de la Tabla
delete from  tt_sunat610_otro;

--Obtenemos el RUC de la empresa 
select e.ruc
 into ls_ruc_emp
 from empresa e
where e.cod_empresa = as_codemp;

--Primer Cursor para la seccion 
For rc_s in c_seccion Loop
 ls_porc_ipss := rc_s.porc_sctr_ipss;
 ls_porc_onp :=rc_s.porc_sctr_onp;
 
 If ls_porc_ipss <> '0' or ls_porc_onp <> '0' then 
    ls_seccion:=rc_s.cod_seccion;
    --Segundo Cursor de Trabaj
    
    For rc_t in c_trabaj(ls_seccion ) loop
        ls_codtra:=rc_t.cod_trabajador;
        ls_dni:=rc_t.dni;
        
        If ls_porc_ipss <> '0' then
          --Contador de registro 
          select count(*) 
           into ln_count1
           from calculo c 
          where c.cod_trabajador = ls_codtra and 
                SUBSTR(c.concep,1,1)= '1' and  
                c.flag_e_sctr_ipss = '1';
          ln_count1:=NVL(ln_count1,0);
          
          If ln_count1 > 0 Then
            --SUMA de imp por IPSS
            select sum(c.imp_soles)
             into ln_imp_ipss
             from calculo c 
            where c.cod_trabajador = ls_codtra and 
                  SUBSTR(c.concep,1,1)= '1' and  
                  c.flag_e_sctr_ipss = '1';
            ls_imp_ipss:=TO_CHAR(ln_imp_ipss);         
            ls_imp_ipss:=NVL(ls_imp_ipss,' ');
               
            --Unimos informacion del ipss
            ls_sunat:='1'||'|'||RPAD(ls_dni,15,' ')||'|'||
                      RPAD(ls_ruc_emp,8,' ')||'|'||'01'||'|'||
                      LPAD(ls_porc_ipss,5,'0')||'|'||
                      LPAD(ls_imp_ipss,15,' ');                                        
            --Insertamos un registro 
            insert into tt_sunat610_otro(col_sunat_otro)
            Values(ls_sunat)  ;
          End if;   
        ENd if; 
        
        If ls_porc_onp <> '0' then 
          --Contador de registro
          select count(*) 
           into ln_count2
           from calculo c 
          where c.cod_trabajador = ls_codtra and 
                SUBSTR(c.concep,1,1)= '1' and  
                c.flag_e_sctr_onp = '1';
          ln_count2:=NVL(ln_count2,0); 
         
          IF ln_count2 > 0 Then
           --SUMA de imp por ONP
            select sum(c.imp_soles)
             into ln_imp_onp
             from calculo c 
            where c.cod_trabajador = ls_codtra and 
                  SUBSTR(c.concep,1,1)= '1' and  
                  c.flag_e_sctr_onp = '1';
            ls_imp_ipss:=TO_CHAR(ln_imp_ipss);         
            ls_imp_ipss:=NVL(ls_imp_ipss,' ');
           
            ls_sunat:='1'||'|'||RPAD(ls_dni,15,' ')||'|'||
                       RPAD(ls_ruc_emp,8,' ')||'|'||'01'||'|'||
                       LPAD(ls_porc_onp,5,'0')||'|'||
                       LPAD(ls_imp_ipss,15,' ');                                        
            --Insertamos un registro 
            insert into tt_sunat610_otro(col_sunat_otro)
            Values(ls_sunat);
          End if;  
        End if;
         
    end loop;     
 end if;
end loop;     
end usp_cal_sunat610_otro;
/
