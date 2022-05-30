create or replace view vc_cam_trabajador_proveedor as
select p.proveedor, p.nom_proveedor, p.flag_estado 
    from proveedor p, maestro m
   where p.proveedor = m.cod_trabajador AND
         m.flag_estado <> '0'



