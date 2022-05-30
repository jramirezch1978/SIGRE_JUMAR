create or replace procedure usp_rpt_psicol_trabaj
is

ls_nombre varchar2(100); 
ls_desc_area  area.desc_area%type;
ls_desc_cargo  cargo.desc_cargo%type;
ls_desc_instruc  grado_instruccion.desc_instruc%type;
ls_tipo_eval  tipo_eval_psicologica.tipo_eval_psi%type;
ls_desc_tipo  tipo_eval_psicologica.desc_eval_psi%type;
ls_cod_grado_instr  grado_instruccion.cod_grado_inst%type;
ln_edad number(4,2);
ls_cod_area area.cod_area%type;
ls_cod_cargo cargo.cod_cargo%type;

--Cursor de la Tabla de Eval Psicol Trabaj 
Cursor c_eval is 
select e1.cod_trabajador,e1.fec_proceso, e1.cod_sit_eval, 
       s.desc_sit_eval, e1.cod_plant_psi, m.fec_nacimiento, 
       m.cod_area, m.cod_cargo, m.cod_grado_inst 
from eval_psicologica_trabajador e1,
     maestro m, situacion_evaluacion s
where e1.cod_trabajador = m.cod_trabajador and 
      e1.cod_sit_eval = s.cod_sit_eval(+) and 
      e1.fec_proceso in ( select max(e2.fec_proceso)
                          from eval_psicologica_trabajador e2
                          where e2.cod_trabajador = e1.cod_trabajador); 

begin

--Delete de la Tabla Eval Psicol Trabaj
Delete from tt_rpt_psicol_trabaj;

--For del Cursor 
For rc_eval in c_eval Loop
  ls_nombre :=usf_nombre_trabajador(rc_eval.cod_trabajador);
  
  ls_cod_area := rc_eval.cod_area;
  ls_cod_area := nvl(ls_cod_area,'a');   
  If ls_cod_area <> 'a' Then
    --Descr de  area 
    select a.desc_area
     into  ls_desc_area
     from area a
    where a.cod_area = rc_eval.cod_area;
   End if;
   
  If ls_cod_area = 'a' Then
     ls_desc_area := '';
  End if;         

  ls_cod_cargo := rc_eval.cod_cargo;
  ls_cod_cargo := nvl(ls_cod_cargo,'b');
  If ls_cod_cargo <> 'b' Then
     --Descr de cargo
     select c.desc_cargo
       into ls_desc_cargo
       from cargo c
     where c.cod_cargo = rc_eval.cod_cargo;
  end if;
  If ls_cod_cargo ='b' Then
    ls_desc_cargo := '';
  End if;   
  
  ls_cod_grado_instr := rc_eval.cod_grado_inst;
  ls_cod_grado_instr := nvl(ls_cod_grado_instr,'c');
  if ls_cod_grado_instr <> 'c' Then 
    --Descr de Grado Instruc
    select g.desc_instruc
     into ls_desc_instruc
     from grado_instruccion g
    where g.cod_grado_inst = rc_eval.cod_grado_inst; 
  End if;
    
  If ls_cod_grado_instr = 'c' Then 
    ls_desc_instruc := '';
  End if;  

  --Edad
  ln_edad := (MONTHS_BETWEEN(sysdate , rc_eval.fec_nacimiento))/12;
  ln_edad  := nvl(ln_edad,0); 
  
  --Tipo de Evalacion Psicologica 
  select t.tipo_eval_psi, t.desc_eval_psi 
   into ls_tipo_eval, ls_desc_tipo
   from plantilla_psicologica p, tipo_eval_psicologica t
   where p.cod_plant_psi = rc_eval.cod_plant_psi and 
         p.tipo_eval_psi = t.tipo_eval_psi;
  
  INSERT INTO tt_rpt_psicol_trabaj
  values 
   (rc_eval.cod_trabajador , ls_nombre , ln_edad , rc_eval.cod_area   ,
    ls_desc_area           , rc_eval.cod_cargo   , ls_desc_cargo      ,
    rc_eval.cod_grado_inst , ls_desc_instruc     , rc_eval.fec_proceso, 
    rc_eval.cod_plant_psi  , ls_tipo_eval        , ls_desc_tipo       ,
    rc_eval.cod_sit_eval   , rc_eval.desc_sit_eval); 
    








End loop; 
  
end usp_rpt_psicol_trabaj;
/
