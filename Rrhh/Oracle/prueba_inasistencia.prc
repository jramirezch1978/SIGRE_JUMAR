create or replace procedure prueba_inasistencia
(as_cod_trab maestro.cod_trabajador%type ) is

ls_semestre char(1); --Flag del semestre
lk_inasist constant char(3):='050'; --Parm inasist
lk_sobret constant char(3):='081'; --Parm Sobret  
ls_desc_inasis rrhh_nivel.desc_nivel%type; --Nivel Inasist
ls_desc_sobret rrhh_nivel.desc_nivel%type; --Nivel Sobreti

cursor c_inas is  --Cursor dias inasistencia 
 select i.cod_trabajador, i.concep, i.fec_hasta, i.dias_inasist  
   from inasistencia i
   where i.cod_trabajador = as_cod_trab
 union 
 select hi.cod_trabajador, hi.concep, hi.fec_hasta, hi.dias_inasist
   from historico_inasistencia hi 
   where hi.cod_trabajador = as_cod_trab;
 
cursor c_sob is  --Cursor Horas sobretiempo
 select s.cod_trabajador, s.concep, s.fec_movim, s.horas_sobret
   from  sobretiempo_turno s
   where s.cod_trabajador = as_cod_trab;

begin

delete tt_lp_prueba_inasistencia 
where cod_trabajador = as_cod_trab;

 select rn.desc_nivel
 into ls_desc_inasis  --Descr de inasistencia
 from rrhh_nivel rn 
 where rn.cod_nivel = lk_inasist;
             
 select rn.desc_nivel
 into ls_desc_sobret  --Descr de sobretiempo
 from rrhh_nivel rn 
 where rn.cod_nivel = lk_sobret;
 
For rc_i in c_inas Loop  --cursor de dias
   --Calculo del semestre
   If to_char(rc_i.fec_hasta,'MM') in (1,2,3,4,5,6) Then
      ls_semestre := '1';
   Else ls_semestre := '2';
   End If;       
   
   insert into tt_lp_prueba_inasistencia
   values
     ( rc_i.cod_trabajador , rc_i.concep    , lk_inasist  ,
       ls_desc_inasis      , rc_i.fec_hasta , ls_semestre ,
       rc_i.dias_inasist   ); 
End loop;

For rc_s in c_sob Loop  --cursor de horas
   If to_char(rc_s.fec_movim,'MM') in (1,2,3,4,5,6) Then 
      ls_semestre := '1';
   Else ls_semestre := '2';
   End If;   
   
   insert into tt_lp_prueba_inasistencia
   values         
     ( rc_s.cod_trabajador , rc_s.concep    , lk_sobret   ,
       ls_desc_sobret      , rc_s.fec_movim , ls_semestre ,
       rc_s.horas_sobret   );
End Loop;
  
end prueba_inasistencia;
/
