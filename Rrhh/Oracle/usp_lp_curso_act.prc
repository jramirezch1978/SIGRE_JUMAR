create or replace procedure usp_lp_curso_act
 ( as_codtra in maestro.cod_trabajador%type 
  ) is

--Cursor de Actual de Curso por Trabaj
Cursor c_cur is 
select c.desc_curso, ct.desc_tema, act.nom_expositor,
       p.nom_proveedor, act.lugar_exposicion,
       act.nro_horas, act.fec_ini_capac, act.flag_int_ext

from actual_capac_trabajador act, curso c, 
     curso_tema ct, proveedor p
 
where act.cod_trabajador = as_codtra and 
      act.cod_curso = ct.cod_curso and 
      act.cod_tema  = ct.cod_tema and 
      ct.cod_curso = c.cod_curso and 
      act.proveedor = p.proveedor;

begin

--Deleteo de la Tabla tt_lp_curso_act
delete from tt_lp_curso_act tt
where tt.cod_trabajador = as_codtra;

--Lectura de los registros 
For rc_cur in c_cur loop
 insert into tt_lp_curso_act
   ( cod_trabajador ,desc_curso   ,tema      , 
     nom_expositor  ,nom_entidad  ,direccion ,
     nro_horas      ,fec_expos    ,flg_int_ext)
 values 
   ( as_codtra            ,rc_cur.desc_curso    , rc_cur.desc_tema ,
     rc_cur.nom_expositor ,rc_cur.nom_proveedor, rc_cur.lugar_exposicion, 
     rc_cur.nro_horas     ,rc_cur.fec_ini_capac, rc_cur.flag_int_ext); 
END LOOP;
  
end usp_lp_curso_act;
/
