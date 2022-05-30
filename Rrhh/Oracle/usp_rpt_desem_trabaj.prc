create or replace procedure usp_rpt_desem_trabaj 
is
ls_nomb_trabaj varchar2(100);
ls_nomb_evalu varchar2(100);
ln_punt_tot number(13,2);

--Cursor de la Eval de Desem del Trabaj
Cursor c_eval is 
select e1.cod_trabajador, e1.fec_proceso, e1.cod_plant_desem,
       p.cod_grupo_ocup, m.cod_area, a.desc_area, e1.cod_sit_eval,
       s.desc_sit_eval, e1.cod_evaluador
from eval_desempeno_trabajador e1, plantilla_desempeno p, 
     maestro m, area a, situacion_evaluacion s 
where e1.cod_plant_desem = p.cod_plant_desem and 
      e1.cod_trabajador = m.cod_trabajador and 
      m.cod_area = a.cod_area(+) and 
      e1.cod_sit_eval = s.cod_sit_eval and 
      e1.fec_proceso in (select max(e2.fec_proceso)
                         from eval_desempeno_trabajador e2
                         where e2.cod_trabajador = e1.cod_trabajador);

begin
--Delete de Tabla tt_rpt_desem_trabaj 
Delete from tt_rpt_desem_trabaj ;

--Se realiza el for para el Curosr 
For rc_eval in c_eval Loop
 ls_nomb_trabaj := usf_nombre_trabajador(rc_eval.cod_trabajador);
 ls_nomb_evalu := usf_nombre_trabajador(rc_eval.cod_evaluador);   
 
 --Suma de los puntajes de la Eval de Desem Trabaj
 select sum(ed.calificacion*ed.peso)
        into ln_punt_tot
        from eval_desem_trabajador_detalle ed
 where ed.cod_trabajador = rc_eval.cod_trabajador and 
       ed.fec_proceso = rc_eval.fec_proceso  and 
       ed.cod_plant_desem = rc_eval.cod_plant_desem;

 --Ingreso del registro
 INSERT INTO tt_rpt_desem_trabaj 
 values 
  ( rc_eval.cod_trabajador  , ls_nomb_trabaj          , 
    rc_eval.fec_proceso     , rc_eval.cod_plant_desem ,
    rc_eval.cod_grupo_ocup  , ln_punt_tot             ,
    rc_eval.cod_area        , rc_eval.desc_area       ,
    rc_eval.cod_sit_eval    , rc_eval.desc_sit_eval   ,
    rc_eval.cod_evaluador   , ls_nomb_evalu );
End Loop;
      
  
end usp_rpt_desem_trabaj;
/
