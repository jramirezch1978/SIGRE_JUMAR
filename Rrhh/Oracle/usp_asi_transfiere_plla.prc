create or replace procedure usp_asi_transfiere_plla (
  as_codtra      in maestro.cod_trabajador%type , 
  ad_fec_desde   in incidencia_trabajador.fecha_movim%type ,
  ad_fec_hasta   in incidencia_trabajador.fecha_movim%type )
  is

ls_codigo              maestro.cod_trabajador%type ;
ls_cencos              maestro.cencos%type ;
ls_labor               maestro.cod_labor%type ;

ld_fecha_movim         incidencia_trabajador.fecha_movim%type ;
ls_concepto            incidencia_trabajador.concep%type ;
ld_fecha_inicio        incidencia_trabajador.fecha_inicio%type ;
ld_fecha_final         incidencia_trabajador.fecha_fin%type ;
ln_nro_horas           incidencia_trabajador.nro_horas%type ;
ln_nro_dias            incidencia_trabajador.nro_dias%type ;
ls_flag_conforme       incidencia_trabajador.flag_conformidad%type ;

ln_dias_inasist        incidencia_trabajador.nro_horas%type ;

--  Cursor del personal que marca asistencia en el reloj
Cursor c_maestro is
  Select m.cod_trabajador, m.cencos, m.cod_labor
  from  maestro m
  where m.cod_trabajador = as_codtra and
        m.flag_estado = '1' ;
--        m.turno <> ' ' and
--        m.carnet_trabaj <> ' ' ;

--  Cursor de lectura diaria del reloj
Cursor c_incidencias is
  Select i.cod_trabajador, i.fecha_movim, i.concep,
         i.fecha_inicio, i.fecha_fin, i.nro_horas,
         i.nro_dias, i.flag_conformidad
  from  incidencia_trabajador i
  where i.cod_trabajador = ls_codigo and
        i.flag_conformidad = '0' and
        to_date(to_char(i.fecha_movim,'DD/MM/YYYY'), 'DD/MM/YYYY') between to_date(to_char(ad_fec_desde,'DD/MM/YYYY'), 'DD/MM/YYYY') and
        to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY')
  order by i.fecha_movim, i.concep ;

begin

--  Realiza lectura del maestro
For rc_mae in c_maestro Loop

  ls_codigo := rc_mae.cod_trabajador ;
  ls_cencos := rc_mae.cencos ;
  ls_labor  := rc_mae.cod_labor ;  
  
  --  Transfiere informacion a la planilla
  For rc_inc in c_incidencias Loop

    ld_fecha_movim  := rc_inc.fecha_movim ;
    ls_concepto     := rc_inc.concep ;
    ld_fecha_inicio := rc_inc.fecha_inicio ;
    ld_fecha_final  := rc_inc.fecha_fin ;
    ln_nro_horas    := nvl(rc_inc.nro_horas,0) ;
    ln_nro_dias     := nvl(rc_inc.nro_dias,0) ;
  
    ln_nro_horas := nvl(ln_nro_horas,0) ;
    ln_nro_dias  := nvl(ln_nro_dias,0) ;
    
    If substr(ls_concepto,1,2) = '11' or substr(ls_concepto,1,2) = '12' then
      Insert into sobretiempo_turno (
        cod_trabajador, fec_movim, concep, nro_doc,
        horas_sobret, cencos, cod_labor, cod_usr,
        tipo_doc )
      Values ( 
        ls_codigo, ld_fecha_movim, ls_concepto, 'RELOJ     ',
        ln_nro_horas, ls_cencos, ls_labor, '',
        'RELO' ) ;
    Else
      If ln_nro_dias > 0 then
        Insert into inasistencia (
          cod_trabajador, concep, fec_desde, fec_hasta,
          fec_movim, dias_inasist, tipo_doc, nro_doc,
          cod_usr )
        Values ( 
          ls_codigo, ls_concepto, ld_fecha_inicio, ld_fecha_final,
          ld_fecha_movim, ln_nro_dias, 'RELO', 'RELOJ     ',
          '' ) ;
      Else
        If ln_nro_horas > 0 and (ls_concepto = '2313' or
           ls_concepto = '2405') then
          Insert into inasistencia (
            cod_trabajador, concep, fec_desde, fec_hasta,
            fec_movim, dias_inasist, tipo_doc, nro_doc,
            cod_usr )
          Values ( 
            ls_codigo, ls_concepto, ld_fecha_inicio, ld_fecha_final,
            ld_fecha_movim, ln_nro_horas, 'RELO', 'RELOJ     ',
            '' ) ;
        Else
--          ln_dias_inasist := 0 ;
--          ln_dias_inasist := ln_nro_horas / 8 ;
          Insert into inasistencia (
            cod_trabajador, concep, fec_desde, fec_hasta,
            fec_movim, dias_inasist, tipo_doc, nro_doc,
            cod_usr )
          Values ( 
            ls_codigo, ls_concepto, ld_fecha_inicio, ld_fecha_final,
            ld_fecha_movim, ln_nro_horas, 'RELO', 'RELOJ     ',
            '' ) ;
        End if ;
      End if ;
    End if ;
  
  End loop;

End loop;
    
end usp_asi_transfiere_plla ;
/
