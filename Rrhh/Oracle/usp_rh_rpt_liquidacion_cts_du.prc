create or replace procedure usp_rh_rpt_liquidacion_cts_du(
       adi_fec_proceso     in date                                 ,
       asi_tipo_trabajador in tipo_trabajador.tipo_trabajador%type ,
       asi_origen          in origen.cod_origen%type                 
) is

ld_fec_desde          date ; --fecha de inicio de cts
ld_fec_hasta          date ; --fecha final de cts
lc_dir_calle          origen.dir_calle%type   ;
lc_ciudad             Varchar2(60)            ;
lc_empresa_nom        empresa.nombre%type     ;

--  Lectura de la liquidaciones mensuales de C.T.S.
Cursor c_liquidaciones is
select u.cod_trabajador, u.fec_proceso, 
       u.remuneracion, u.liquidacion, u.gratificacion, 
       u.rem_variable, u.dias_trabajados,
       m.tipo_trabajador, m.cod_seccion, m.cod_area ,
       trim(m.apel_paterno)||' '||trim(m.apel_materno)||' '||trim(m.nombre1)||' '||trim(m.nombre2) as nombres,
       s.desc_seccion,tt.desc_tipo_tra
  from cts_decreto_urgencia u, 
       maestro              m,
       seccion              s,
       tipo_trabajador      tt
  where u.cod_trabajador     = m.cod_trabajador       
    and m.cod_area           = s.cod_area          (+)
    and m.cod_seccion        = s.cod_seccion       (+)
    and m.tipo_trabajador    = tt.tipo_trabajador    
    and trunc(u.fec_proceso) = trunc(adi_fec_proceso)  
    and m.tipo_trabajador    = asi_tipo_trabajador     
    and m.cod_origen         = asi_origen              
order by u.cod_trabajador ;

begin

--  **********************************************************************
--  ***   EMITE REPORTE DE LIQUIDACION DE C.T.S. DECRETO DE URGENCIA   ***
--  **********************************************************************




delete from tt_rpt_decreto_urgencia ;

if to_char(adi_fec_proceso, 'mm') = '11' then
   ld_fec_desde := to_date('01/05/'||to_char(adi_fec_proceso,'yyyy'),'dd/mm/yyyy') ;
   ld_fec_hasta := last_day(to_date('01/10/'||to_char(adi_fec_proceso,'yyyy'),'dd/mm/yyyy')) ;
else
   ld_fec_desde := to_date('01/11/'||to_char(to_number(to_char(adi_fec_proceso,'yyyy')) - 1),'dd/mm/yyyy') ;
   ld_fec_hasta := last_day(to_date('01/04/'||to_char(adi_fec_proceso,'yyyy'),'dd/mm/yyyy')) ;
end if;



--datos de direccion por origen
select o.dir_calle, o.dir_distrito||'-'||o.dir_departamento 
into lc_dir_calle,lc_ciudad 
from origen o 
where (o.cod_origen = asi_origen );

select e.nombre  into lc_empresa_nom
  from empresa e
 where (e.cod_empresa in (select p.cod_empresa from genparam p where p.reckey = '1' and p.cod_origen = asi_origen  )) ;



For rc_liq in c_liquidaciones Loop
    Insert Into tt_rpt_decreto_urgencia
    (empresa_nom ,empresa_dir  ,empresa_dis    ,fec_desde   ,
     fec_hasta   ,fec_proceso  ,cod_trabajador ,nombres     ,
     seccion     ,desc_seccion ,remuneracion   ,liquidacion ,
     desc_trabajador, dias_laborados, rem_Variable, gratificacion )
    Values
    (lc_empresa_nom     ,lc_dir_calle        ,lc_ciudad             ,ld_fec_desde       ,
     ld_fec_hasta       ,adi_fec_proceso      ,rc_liq.cod_trabajador ,rc_liq.nombres     ,
     rc_liq.cod_seccion ,rc_liq.desc_seccion ,rc_liq.remuneracion   ,rc_liq.liquidacion ,
     rc_liq.desc_tipo_tra, rc_liq.dias_trabajados, rc_liq.rem_variable, rc_liq.gratificacion     ) ;
End Loop ;


end usp_rh_rpt_liquidacion_cts_du ;
/
