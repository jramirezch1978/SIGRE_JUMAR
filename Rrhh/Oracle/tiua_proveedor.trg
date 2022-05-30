create or replace trigger tiua_proveedor
  after insert or update on maestro
  for each row

declare

ls_codigo         maestro.cod_trabajador%type ;
ls_direccion      varchar2(40) ;
ls_telefono1      char(8) ;
ls_telefono2      char(8) ;
ls_ruc            char(11) ;
ls_email          char(25) ;
ls_pais           char(3) ;
ls_dpto           char(3) ;
ls_prov           char(3) ;
ls_dist           char(4) ;
ls_ciudad         char(3) ;
ls_nombres        char(50) ;

ls_desc_pais      varchar2(30) ;
ls_desc_dpto      varchar2(30) ;
ls_desc_prov      varchar2(40) ;
ls_desc_dist      char(8) ;
ls_desc_ciudad    varchar2(30) ;

begin

select m.cod_trabajador, m.direccion, m.telefono1,
       m.telefono2, m.ruc, m.email, m.cod_pais,
       m.cod_dpto, m.cod_prov, m.cod_distr, m.cod_ciudad,
  into ls_codigo, ls_direccion, ls_telefono1,
       ls_telefono2, ls_ruc, ls_email, ls_pais,
       ls_dpto, ls_prov, ls_dist, ls_ciudad
  from maestro m
  where m.cod_trabajador = :new.cod_trabajador ;
  
ls_nombres := usf_nombre_trabajador(ls_codigo) ;

select p.nom_pais
  into ls_desc_pais
  from pais p
  where p.cod_pais = ls_pais ;

select d.desc_dpto
  into ls_desc_dpto
  from departamento_estado d
  where d.cod_dpto = ls_dpto ;

select pro.desc_prov
  into ls_desc_prov
  from provincia_condado pro
  where pro.cod_prov = ls_prov ;

select dis.desc_distrito
  into ls_desc_dist
  from distrito dis
  where dis.cod_distr = ls_dist ;

select c.descr_ciudad
  into ls_desc_ciudad
  from ciudad c
  where c.cod_ciudad = ls_ciudad ;

--  Actualiza datos en la tabla proveedores
update proveedor
 set dir_direccion  = ls_direccion ,
     dir_distrito   = ls_desc_dist ,
     dir_ciudad     = ls_desc_ciudad ,
     dir_provincia  = ls_desc_prov ,
     dir_dep_estado = ls_desc_dpto ,
     dir_pais       = ls_desc_pais ,
     telefono1      = ls_telefono1 ,
     telefono2      = ls_telefono2 ,
     email          = ls_email ,
     ruc            = ls_ruc
 where proveedor = :new.cod_trabajador ;

--  Inserta registros en la tabla proveedores
if sql%notfound then

  insert into proveedor (
    proveedor, flag_estado, nom_proveedor,
    dir_direccion, dir_distrito, dir_ciudad,
    dir_provincia, dir_dep_estado, dir_pais,
    telefono1, telefono2, email, ruc )
  Values (
    ls_codigo, '1', ls_nombres,
    ls_direccion, ls_desc_dist, ls_desc_ciudad,
    ls_desc_prov, ls_desc_dpto, ls_desc_pais,
    ls_telefono1, ls_telefono2, ls_email, ls_ruc ) ;
    
end if ;

end tiua_proveedor ;
/
