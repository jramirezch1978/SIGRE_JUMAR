create or replace procedure usp_cal_telecredito
 ( as_nropla in string ,
   ad_fec_proceso in control.fec_proceso%type,
   as_codemp in empresa.cod_empresa%type 
 ) is

lk_caltel constant char(2):= '50';  --Param del Cal Planlla

ls_nombre VARCHAR2(100);            
lk_neto constant char(4) :='2354';   --Concepto para el neto ha pagar  
                                    --a los trabahadores    
ln_neto_emp calculo.imp_soles%type;  --Monto de la empresa 
ls_neto_emp string(15);             
ln_neto_trab calculo.imp_soles%type;  --MOnto del trabajador
ls_neto_trab string(15);             
ln_importe calculo.imp_soles%type;
ln_impsol calculo.imp_soles%type;
ls_importe char(15);  
ls_impsol string(15);
ls_cnta_banco_emp string(25);     
ls_cnta_banco_trab string (25);   
ls_dia char(2);                   
ls_mes char(2);                     
ls_telecredito tt_telecredito.col_telecredito%type;  
ls_nom_empresa empresa.nombre%type; 

--Cursor del Codigo de Trabajador de la Tabla Calculo
cursor c_trabaj is 
  select c.cod_trabajador
  from calculo c, maestro m
  where m.cod_trabajador = c.cod_trabajador and 
        m.cod_empresa = as_codemp; 

begin

--Obtenemos la cnta de deposito de la empresa 
--en un banco 
select bc.cod_ctabco
 into ls_cnta_banco_emp
 from banco_ctacte bc
where bc.cod_origen = lk_caltel;
--El nombre de la empresa 
select e.nombre
 into ls_nom_empresa
 from empresa e
where e.cod_empresa = as_codemp;
--Monto total ha pagar por la empresa 
select c.imp_soles
into ln_neto_emp
from calculo c
where c.concep = lk_neto;

ls_neto_emp := TO_CHAR(ln_neto_emp);
--desaparecemos la coma del importe neto emp
ls_neto_emp :=REPLACE(ls_neto_emp,'.','');
ls_neto_emp := LPAD(ls_neto_emp,15,'0');

--Fecha de proceso para la tabla tt_telecredito
ls_dia := TO_CHAR(ad_fec_proceso,'DD');
ls_mes := TO_CHAR(ad_fec_proceso,'MM');
  

--Ingresamos la cabecera para la tt_telecredito
ls_telecredito:='1'||' '||as_nropla||RTRIM(ls_cnta_banco_emp,
                ' ')||ls_nom_empresa||'00000025639200';
IF LENGTH(ls_telecredito)< 58 then  
    ls_telecredito:=RPAD(ls_telecredito,58,' ');
END IF;

ls_telecredito:=' '||'S/'||ls_neto_emp||ls_dia||ls_mes||
                'H'||'    '||LPAD(ls_cnta_banco_emp,15,'0')||
                'TLC'||'                 '||'1'||'          '||
                '001092'||'                          '||'000000';
                                 
--Insercion de regixtros en la tabla Temporal
INSERT INTO tt_telecredito (col_telecredito)
VALUES  (ls_telecredito);   

--Llamada del Cursor                      
For rc_t in c_trabaj Loop
  --Cuenta de Banco del Tabajador
  select m.nro_cnta_ahorro 
   into ls_cnta_banco_trab
   from maestro m
  where m.cod_trabajador = rc_t.cod_trabajador ;
  --Si se presenta un valor Nulo
  ls_cnta_banco_trab := nvl(ls_cnta_banco_trab,'0');
     
  IF ls_cnta_banco_trab <> '0' THEN --Cnta de Ahorro
     ls_nombre := usf_nombre_trabajador(rc_t.cod_trabajador);   
         
     Select sum(c.imp_soles)
      into ln_neto_trab 
      from calculo c
     Where c.cod_trabajador = rc_t.cod_trabajador and 
           c.concep = lk_neto   and 
           c.fec_proceso = ad_fec_proceso;
     
     ls_neto_trab := TO_CHAR(ln_neto_trab);
     ls_neto_trab :=REPLACE(ls_neto_trab,'.','');
     ls_neto_trab := LPAD(ls_neto_trab,15,'0');
     
      
  
     --Union de informacion para la tabla tt_telecredito 
     ls_telecredito := '4'||' '||as_nropla||RTRIM(ls_cnta_banco_trab,' ')||
                       ls_nombre;
     
     IF LENGTH(ls_telecredito)< 58 then  
         ls_telecredito:=RPAD(ls_telecredito,58,' ');
     END IF;
     
     ls_telecredito:=' '||'S/'||ls_neto_trab||'0'||'   '||
                     'H'||'    '||LPAD(ls_cnta_banco_emp,15,'0')||
                     'TLC'||'                 '||' '||'          '||
                     '      '||'                          '||'000000';
     
     INSERT INTO tt_telecredito(col_telecredito)
     VALUES (ls_telecredito);
END IF;
end loop;                   
end usp_cal_telecredito;
/
