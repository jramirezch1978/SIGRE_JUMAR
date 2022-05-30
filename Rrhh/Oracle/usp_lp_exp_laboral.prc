create or replace procedure usp_lp_exp_laboral
 ( as_codtra maestro.cod_trabajador%type
  ) is
--Variables Locales 
ls_direccion char(46);
  
--Cursor de la Exp lab del Trabajador
Cursor c_elt is 
select elt.nro_secuencial, e.nombre,
       e.dir_calle,e.dir_numero,e.dir_lote,
       e.dir_mnz, gn.desc_giro_negoc, 
       elt.imp_sueldo, c.desc_cargo ,
       elt.nom_jefe_direct, elt.fec_inicio,
       elt.fec_final

from  experiencia_laboral_trabajador elt, maestro m,
      empresa e, giro_negocio gn, cargo c 
      
where elt.cod_trabajador = as_codtra and 
      elt.cod_trabajador = m.cod_trabajador and 
      elt.cod_empresa = e.cod_empresa and
      elt.cod_giro_negoc = gn.cod_giro_negoc (+) and 
      elt.cod_cargo = c.cod_cargo (+); 
--Fin del Cursor   
  
begin
--deleteo de la Tabla tt_lp_exp_laboral 
delete from tt_lp_exp_laboral tt
where tt.cod_trabajador = as_codtra;

--Busqueda de los Registros
For rc_elt in c_elt loop 

--La Direccion de la Empresa
ls_direccion := RTRIM(rc_elt.dir_calle)+ RTRIM(rc_elt.dir_numero) +
                RTRIM(rc_elt.dir_lote)+ RTRIM(rc_elt.dir_mnz); 
 
  INSERT INTO tt_lp_exp_laboral
    ( cod_trabajador , nro_secuencial  ,  desc_empresa ,
      direccion      , desc_giro_neg   ,  imp_sueldo   ,
      desc_cargo     , nombre_jefe     ,  fec_desde    ,
      fec_hasta ) 
  values 
    ( as_codtra         , rc_elt.nro_secuencial  , rc_elt.nombre     ,     
      ls_direccion      , rc_elt.desc_giro_negoc , rc_elt.imp_sueldo ,
      rc_elt.desc_cargo , rc_elt.nom_jefe_direct , rc_elt.fec_inicio ,
      rc_elt.fec_final ) ; 
--Fin de la recuper de registros
end loop;
  
end usp_lp_exp_laboral;
/
