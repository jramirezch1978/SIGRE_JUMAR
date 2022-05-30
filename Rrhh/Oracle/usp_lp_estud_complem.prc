create or replace procedure usp_lp_estud_complem
 ( as_codtra in maestro. cod_trabajador%type 
 ) is

--Cursor de los cursos del Trabajador en una 
--isntitucion
Cursor c_c  is 
select cc.desc_categoria, c.desc_curso,
       ce.descr_cen_estudio, ce.direccion,
       tc.flag_estudio, tc.flag_nivel,
       tc.fec_desde,tc.fec_hasta
from   trabajador_curso tc, categoria_curso cc,
       curso c, centro_estudio ce 
where  tc.cod_trabajador = as_codtra and 
       tc.cod_categ_curso = cc.cod_categ_curso and 
       tc.cod_curso = c.cod_curso  and 
       tc.cod_cen_estudio = ce.cod_cen_estudio (+);
 
begin
--Deleteo de la Tabla tt_lp_estud_complem
delete from tt_lp_estud_complem tt
where tt.cod_trabajador = as_codtra;

--Lectura de los registros del cursor
For rc_c in c_c loop
 INSERT INTO tt_lp_estud_complem 
   ( cod_trabajador   , desc_categ_curso  ,   
     desc_curso       , desc_cen_estudio  ,
     direccion        , flg_estudio       ,
     flg_nivel        , fec_desde         ,
     fec_hasta ) 
 VALUES 
   ( as_codtra         , rc_c.desc_categoria    , 
     rc_c.desc_curso   , rc_c.descr_cen_estudio , 
     rc_c.direccion    , rc_c.flag_estudio      ,
     rc_c.flag_nivel   , rc_c.fec_desde         ,
     rc_c.fec_hasta  );
End loop;
     
end usp_lp_estud_complem;
/
