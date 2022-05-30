create or replace procedure usp_rrhh_jornal_comp_horas(
       asi_cod_usr         in usuario.cod_usr%type   ,
       asi_conc_sobret_sab in concepto.concep%type   ,
       asi_conc_sobret_dom in concepto.concep%type   ,
       asi_conc_sobret_fer in concepto.concep%type   ,
       asi_conc_inasist    in concepto.concep%type   ,
       ani_realiza_comp    in number                 ,
       asi_cod_origen      in origen.cod_origen%type ,
       asi_tipo_trab       in maestro.tipo_trabajador%type ,
       asi_cod_tipo_mov    in tipo_mov_asistencia.cod_tipo_mov%type  
) is

ls_cod_trab       maestro.cod_trabajador%type ;
ls_doc_cmps       rrhhparam.doc_cmps%type     ;
ln_cuenta         number                      ;
ld_ini_periodo    date                        ;
ld_fin_periodo    date                        ;

Cursor c_valida_grp_trab is
  select gcht.cod_trabajador, Nvl(m.apel_paterno,' ')||' '||Nvl(m.apel_materno,' ')||' '|| Nvl(m.nombre1,' ') as nombre,
         count(gcht.grp_cmps_hrs)
   from rh_grp_cmp_hrs_trab gcht,
        maestro             m
  where gcht.cod_trabajador = m.cod_trabajador 
    AND m.cod_origen        = asi_cod_origen    
    AND m.tipo_trabajador   = asi_tipo_trab 
  group by gcht.cod_trabajador, Nvl(m.apel_paterno,' ')||' '||Nvl(m.apel_materno,' ')||' '|| Nvl(m.nombre1,' ')
  having count(gcht.grp_cmps_hrs) > 1
  order by gcht.cod_trabajador, Nvl(m.apel_paterno,' ')||' '||Nvl(m.apel_materno,' ')||' '|| Nvl(m.nombre1,' ');

begin

select min(rch.fecha), max(rch.fecha) 
  into ld_ini_periodo, ld_fin_periodo 
from tt_rh_comp_hora rch ;

select rhp.doc_cmps 
  into ls_doc_cmps 
from rrhhparam rhp 
where rhp.reckey = '1';

-- Validación que exista rango de compensación
ln_cuenta := 0;

select count(*) 
  into ln_cuenta 
  from tt_rh_comp_hora;

if ln_cuenta <= 0 then
   raise_application_error(-20000,'ORACLE: No se han encontra datos en rango de fecha, Verificar');
end if;

-- validacion que no existan registro de compesación para esa fecha para esos trabajadores
ln_cuenta := 0;

select count(*) 
  into ln_cuenta 
  from inasistencia i
 where trunc(i.fec_movim) between trunc(ld_ini_periodo) and trunc(ld_fin_periodo)
   AND trim(i.tipo_doc)       = trim(ls_doc_cmps)                                
   AND trim(i.cod_trabajador) in (select distinct trim(a.cod_trabajador)
                                    from asistencia a,
                                         maestro    m
                                    where a.cod_trabajador  = m.cod_trabajador 
                                      AND m.cod_origen      = asi_cod_origen   
                                      AND m.tipo_trabajador = asi_tipo_trab        
                                      AND trunc(a.fec_movim) between trunc(ld_ini_periodo) and trunc(ld_fin_periodo));

if ln_cuenta < 1 then
   select count(*) 
     into ln_cuenta 
     from sobretiempo_turno st
    where trunc(st.fec_movim) between trunc(ld_ini_periodo) and trunc(ld_fin_periodo)
      AND trim(st.tipo_doc) = trim(ls_doc_cmps)                                      
      AND trim(st.cod_trabajador) in (select distinct trim(a.cod_trabajador)
                                        from asistencia a,
                                             maestro    m
                                        where a.cod_trabajador  = m.cod_trabajador 
                                          AND m.cod_origen      = asi_cod_origen    
                                          AND m.tipo_trabajador = asi_tipo_trab         
                                          AND trunc(a.fec_movim) between trunc(ld_ini_periodo) and trunc(ld_fin_periodo));
end if;

if ln_cuenta >= 1 then
   raise_application_error(-20000,'ORACLE: Ya existen registro de compensación para esos trabajadores en el' || chr(13) || 'periodo deseado, deberá elminar primero la compensación para proceder');
end if;

-- validacion que ningun trabajadaor esté asigando en más de un grupo de compensacion
ls_cod_trab := ' ';

for rc_vt in c_valida_grp_trab loop
    ls_cod_trab := trim(ls_cod_trab) || chr(13) || trim(rc_vt.cod_trabajador) || ' - ' || trim(rc_vt.nombre);
    raise_application_error(-20000 ,'ORACLE: Los Siguientes Trabajadores se encuentran en mas de un grupo' 
              || chr(13) || 'de compesación de horas, por favor corrija el error para realizar' 
              || chr(13) || 'la compensación de horas.  El proceso se ha detenido: ' 
              || chr(13) || ls_cod_trab);
end loop;


-- calculando sobretiempos
usp_rh_comphr_sobret(asi_cod_usr, ls_doc_cmps, ld_ini_periodo, ld_fin_periodo, asi_conc_sobret_sab ,
                     asi_conc_sobret_dom, asi_conc_sobret_fer, asi_cod_tipo_mov, asi_cod_origen, asi_tipo_trab );

-- calculando inasistencias
usp_rh_comphr_inasist(asi_cod_usr ,ls_doc_cmps ,ld_ini_periodo ,ld_fin_periodo ,asi_conc_inasist ,
                      asi_cod_tipo_mov, asi_cod_origen, asi_tipo_trab );

-- realizando procedimiento de compensacion de horas
if ani_realiza_comp = '1' then
   usp_rh_comphr_compensa (ld_ini_periodo, ld_fin_periodo, asi_conc_sobret_sab,
                           asi_conc_sobret_dom, asi_conc_sobret_fer, ls_doc_cmps, 
                           asi_cod_tipo_mov, asi_cod_origen, asi_tipo_trab);

end if;

COMMIT;
end usp_rrhh_jornal_comp_horas;
/
