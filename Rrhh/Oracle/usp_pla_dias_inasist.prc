create or replace procedure usp_pla_dias_inasist(

   as_cod_trabaj in maestro.cod_trabajador%type,
   as_tip_trabaj in maestro.tipo_trabajador%type, 
   as_tip_empresa in maestro.cod_empresa%type,
   ad_fec_proceso in inasistencia.fec_movim%type
   
    )
    
   is
ls_cod_trabaj char(8);
ls_concep char(4);
ln_dias_planilla number(4);
ln_dias_trabaj number(4,2);   
ln_dias_inasist number(4,2); 
   
--Obtengo los dias de inasistencia por concepto con 
--respecto aun trabajador  

--Los cocneptos pertenecen al grupo '24', las inasistencias 
--descontar   

 cursor c_inasist_trabaj is 
   select i.concep, i.dias_inasist
   from inasistencia i, maestro m
   where i.cod_trabajador = as_cod_trabaj and
         m.cod_trabajador = i.cod_trabajador and
         m.tipo_trabajador = as_tip_trabaj and 
         m.cod_empresa = as_tip_empresa and 
         m.flag_cal_plnlla = '1' and
         m.flag_estado = '1' and
         substr(i.concep,1,2) = '24'
         ;
 begin

  --Escogemos los dias del mes en Proceso para el calculo 
  --de planilla de los Empleados
 If as_tip_trabaj='Empleados' then      
      select c.dias_mes_empleado
      into ln_dias_planilla 
      from control c    
      where TO_CHAR(c.fec_proceso,'MM') = TO_CHAR(ad_fec_proceso,'MM');
 End if;

  --Escogemos los dias del mes en Proceso para el calculo 
  --de planilla de los Obreros
 If as_tip_trabaj='Obreros' then      
      select c.dias_mes_obrero
      into ln_dias_planilla 
      from control c    
      where TO_CHAR(c.fec_proceso,'MM') = TO_CHAR(ad_fec_proceso,'MM');
 End if;

 ln_dias_inasist:=0;
 
 --Acumulamos los dias de inasistencias por cada trabajador mediante 
 --un Loop del cursor 
 
 For rc_inasist_trabaj in c_inasist_trabaj
 Loop
   ln_dias_inasist:=ln_dias_inasist + rc_inasist_trabaj.dias_inasist;
 End Loop; 
 
 --Obtenemos los dias Trabjados por trabajador 
 ln_dias_trabaj:=ln_dias_planilla - ln_dias_inasist;
 
 --Insertamos los datos en la Tabla tt_pla_concep
 Insert into tt_pla_concepto (concep,formula,
             debe_haber,valor)
        values ('DPLA','TABL ','0',ln_dias_planilla);
 insert into tt_pla_concepto (concep,formula,
             debe_haber,valor)
        values ('DINA','TABL ','0',ln_dias_inasist);
 insert into tt_pla_concepto (concep,formula,
             debe_haber,valor)
        values ('DTRB','TABL ','0',ln_dias_trabaj);     

 --Capturo la formula de un determinado Concepto
-- usp_pla_gan_desct_fijo('R1070','1001');
 

end usp_pla_dias_inasist;
/
