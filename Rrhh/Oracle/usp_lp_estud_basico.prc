create or replace procedure usp_lp_estud_basico
 ( as_codtra in maestro.cod_trabajador%type
  ) is

--Me determina los grado de isntruc del Trabajador  
Cursor c_ce is 
select c.descr_cen_estudio, g.desc_instruc,
       c.direccion, e.fec_desde, e.fec_hasta,
       p.desc_profesion
from  estudio_basico e, centro_estudio c,
      grado_instruccion g, profesion p 
where e.cod_trabajador = as_codtra and 
      e.cod_cen_estudio = c.cod_cen_estudio and 
      e.cod_grado_inst = g.cod_grado_inst and 
      e.cod_profesion = p.cod_profesion;
  
begin
--Deleteo de la Tabla tt_lp_estud_basico
delete from tt_lp_estud_basico tt
where tt.cod_trabajador = as_codtra;

--Lectura de los registros del Cursor  
For rc_ce in c_ce loop
 
  INSERT INTO tt_lp_estud_basico
   ( cod_trabajador  ,  desc_cen_estudio , 
     desc_instruc    ,  direccion        ,
     fec_desde       ,  fec_hasta        ,
     desc_profesion )
  VALUES 
   ( as_codtra          , rc_ce.descr_cen_estudio ,
     rc_ce.desc_instruc , rc_ce.direccion         ,
     rc_ce.fec_desde    , rc_ce.fec_hasta         , 
     rc_ce.desc_profesion );
 End loop;
  
end usp_lp_estud_basico;
/
