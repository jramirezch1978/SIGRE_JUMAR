create or replace procedure usp_rh_comphr_compensa(
       adi_periodo_ini       in date                   ,
       adi_periodo_fin       in date                   , 
       asi_concep_sobret_sab in concepto.concep%type   ,
       asi_concep_sobret_dom in concepto.concep%type   ,
       asi_concep_sobret_fer in concepto.concep%type   ,
       asi_doc_cmps          in doc_tipo.tipo_doc%type ,
       asi_tipo_mov          in tipo_mov_asistencia.cod_tipo_mov%type ,
       asi_origen            in origen.cod_origen%TYPE                ,
       asi_tipo_trab         in maestro.tipo_trabajador%type  
) is
 
ld_ini_periodo   date ;ld_fin_periodo    date ;ld_ini_falta       date ;
ld_fin_falta     date ;ld_fec_movimiento date ;ld_fec_sobretiempo date ;
ld_new_fec_hasta date ;ld_ini_turno      date ;ld_fin_turno       date ;
ld_fec_turno     date ;

ln_tiempo_inasistencia number ;ln_tiempo_sobretiempo number ;ln_tiempo_inas_pendiente number;
ln_item                number ;ln_new_dias_inasist   number ;ln_jornada_laboral       number;

ls_ind_sab             Char(1)          ;
ls_ind_dom             char(1)          ;
ls_turno               turno.turno%type ;


Cursor c_trabajador is
  Select distinct i.cod_trabajador
    from inasistencia i,
         maestro      m
   where i.cod_trabajador  = m.cod_trabajador                         
     AND m.cod_origen      = asi_origen                                
     AND m.tipo_trabajador = asi_tipo_trab                                 
     AND trunc(i.fec_movim) between ld_ini_periodo and ld_fin_periodo 
     AND i.tipo_doc         = asi_doc_cmps
  order by trim(i.cod_trabajador);

Cursor c_inasistencia (as_cod_trab maestro.cod_trabajador%type) is
  Select distinct i.fec_movim
    from inasistencia i
   where trunc(i.fec_movim) between ld_ini_periodo and ld_fin_periodo 
     AND i.cod_trabajador   = as_cod_trab                       
     AND i.tipo_doc         = asi_doc_cmps
  order by i.fec_movim ;

Cursor c_movimiento (as_cod_trab maestro.cod_trabajador%type) is
  Select i.fec_desde, i.fec_hasta
    from inasistencia i
   where trunc(i.fec_movim) = ld_fec_movimiento 
     AND i.cod_trabajador   = as_cod_trab 
     AND i.tipo_doc         = asi_doc_cmps
  order by i.fec_desde;

Cursor lc_concep_sobret (as_cod_trab maestro.cod_trabajador%type) is
  Select chd.concep, chd.item
    from rh_grp_cmp_hrs_det chd,
         rh_grp_cmp_hrs_trab cht
   where chd.grp_cmps_hrs = cht.grp_cmps_hrs
     AND cht.cod_trabajador = as_cod_trab
  order by chd.item desc;

Cursor c_sobret_trab is
  Select chc.concep
    from tt_rh_cmps_hrs_concep chc
  order by chc.item;

Cursor c_sobretiempo (as_cod_trab maestro.cod_trabajador%type,
                      as_concepto concepto.concep%type) is
Select st.fec_movim, st.concep, st.horas_sobret
  from sobretiempo_turno st
 where trunc(st.fec_movim) between ld_ini_periodo and ld_fin_periodo 
   AND st.cod_trabajador   = as_cod_trab                       
   AND st.concep           = as_concepto
   AND st.horas_sobret     > 0                                       
   AND st.tipo_doc         = asi_doc_cmps
order by st.fec_movim;


begin

ld_ini_periodo := trunc(adi_periodo_ini);
ld_fin_periodo := trunc(adi_periodo_fin);

For rc_it in c_trabajador loop -- trabajadores que tienen inasistencias
    
      ln_item := 0;
      -- creando arreglo de conceptos de sobretiempo para descuento
      -- el item 1 es el primer concepto a descontar
      For rc_cs in lc_concep_sobret (rc_it.cod_trabajador)loop
          ln_item := ln_item + 1;
          insert into tt_rh_cmps_hrs_concep (item, concep) values (ln_item, rc_cs.concep);
      end loop;

      if trim(asi_concep_sobret_sab) <> trim('----') then
         ln_item := ln_item + 1;
         Insert into tt_rh_cmps_hrs_concep (item, concep) values (ln_item,asi_concep_sobret_sab);
      end if;
      
      if trim(asi_concep_sobret_dom) <> trim('----') then
         ln_item := ln_item + 1;
         insert into tt_rh_cmps_hrs_concep (item, concep) values (ln_item, asi_concep_sobret_dom);
      end if;
      
      if trim(asi_concep_sobret_fer) <> trim('----') then
         ln_item := ln_item + 1;
         insert into tt_rh_cmps_hrs_concep (item, concep) values (ln_item, asi_concep_sobret_fer);
      end if;

      for rc_if in c_inasistencia (rc_it.cod_trabajador) loop -- buscando la fehca de movimietno de las inasistencias
      
         ld_fec_movimiento := trunc(rc_if.fec_movim);
         
         For rs_mi in c_movimiento (rc_it.cod_trabajador ) loop -- buscando el tiempo de inasistencia
            ld_ini_falta := rs_mi.fec_desde;
            ld_fin_falta := rs_mi.fec_hasta;
            
            ln_tiempo_inasistencia   := to_number(ld_fin_falta - ld_ini_falta) * 24;
            ln_tiempo_inas_pendiente := ln_tiempo_inasistencia; -- horas a compensar
            
            For rc_ct in c_sobret_trab loop -- buscando los conceptos de sobretiempo
                For rc_st in c_sobretiempo (rc_it.cod_trabajador,rc_ct.concep) loop -- buscando los sobretirmpos
                
                    ld_fec_sobretiempo    := rc_st.fec_movim    ;
                    ln_tiempo_sobretiempo := rc_st.horas_sobret ; -- horas de sobretiempo
                    
                    if ln_tiempo_inas_pendiente > 0 then
                       if ln_tiempo_inas_pendiente > ln_tiempo_sobretiempo then
                          ln_tiempo_inas_pendiente := ln_tiempo_inas_pendiente - ln_tiempo_sobretiempo;
                          ln_tiempo_sobretiempo := 0;
                       elsif ln_tiempo_inas_pendiente < ln_tiempo_sobretiempo then
                           ln_tiempo_sobretiempo := ln_tiempo_sobretiempo - ln_tiempo_inas_pendiente;
                           ln_tiempo_inas_pendiente := 0;
                       else
                           ln_tiempo_inas_pendiente := 0;
                           ln_tiempo_sobretiempo := 0;
                       end if;
                    end if;

                    -- actualizanod inasistencias
                    if ln_tiempo_inas_pendiente = 0 then
                       delete from inasistencia i  where (i.cod_trabajador = rc_it.cod_trabajador) and
                                                         (i.fec_desde      = ld_ini_falta        ) ;
                    else
                       ld_fec_turno := ld_fin_periodo;

                       select nvl(min(a.turno), '----')  into ls_turno from asistencia a
                        where (trunc(a.fec_movim) = trunc(ld_fec_movimiento) ) and
                              (a.cod_trabajador   = rc_it.cod_trabajador     ) and
                              (a.cod_tipo_mov     = asi_tipo_mov          );

                       while ls_turno = '----' loop
                             select nvl(min(a.turno), '----') into ls_turno from asistencia a
                              where (trunc(a.fec_movim) = trunc(ld_fec_turno)  ) and
                                    (a.cod_trabajador   = rc_it.cod_trabajador ) and
                                    (a.cod_tipo_mov     = asi_tipo_mov          );

                             ld_fec_turno := ld_fec_turno - 1 ;

                             if ld_fec_turno < ld_ini_periodo then
                                select min(a.turno) into ls_turno from asistencia a
                                 where (a.cod_trabajador = rc_it.cod_trabajador ) and
                                       (a.cod_tipo_mov   = asi_tipo_mov          );
                             end if;
                       end loop;

                       select t.sabado, t.domingo 
                         into ls_ind_sab, ls_ind_dom from tt_rh_comp_hora t
                        where trunc(t.fecha) = trunc(ld_fec_movimiento);

                       if ls_ind_sab = '1' then
                          select t.hora_ini_cmps_sab, t.hora_fin_cmps_sab  into ld_ini_turno, ld_fin_turno
                            from turno t
                           where trim(t.turno) = trim(ls_turno);
                       elsif ls_ind_dom = '1' then
                          select t.hora_ini_cmps_dom, t.hora_fin_cmps_dom   into ld_ini_turno, ld_fin_turno
                            from turno t
                           where trim(t.turno) = trim(ls_turno);
                       else
                          select t.hora_ini_cmps_norm, t.hora_fin_cmps_norm into ld_ini_turno, ld_fin_turno
                            from turno t
                           where trim(t.turno) = trim(ls_turno);
                       end if;

                       if ld_ini_turno > ld_fin_turno then
                          ld_fin_turno := to_date(to_char(ld_ini_falta, 'dd/mm/yyyy') || ' ' || to_char(ld_fin_turno, 'hh24:mi'), 'dd/mm/yyyy hh24:mi');
                       else
                          ld_fin_turno := to_date(to_char(ld_ini_falta + 1, 'dd/mm/yyyy') || ' ' || to_char(ld_fin_turno, 'hh24:mi'), 'dd/mm/yyyy hh24:mi');
                       end if;
                       
                       ld_ini_turno        := to_date(to_char(ld_ini_falta, 'dd/mm/yyyy') || ' ' || to_char(ld_ini_turno, 'hh24:mi'), 'dd/mm/yyyy hh24:mi');
                       ln_jornada_laboral  := to_number(ld_fin_turno - ld_ini_turno);
                       ld_new_fec_hasta    := ld_ini_falta + (ln_tiempo_inas_pendiente / 24);
                       ln_new_dias_inasist := round(round(to_number(ld_new_fec_hasta - ld_ini_falta), 4) / ln_jornada_laboral,2);
                       
                       
                       --actualizacion de inasistencia 
                       Update inasistencia i
                          Set i.fec_hasta = ld_new_fec_hasta,i.dias_inasist = ln_new_dias_inasist
                        where (i.cod_trabajador = rc_it.cod_trabajador ) and
                              (i.fec_desde      = ld_ini_falta         ) and
                              (i.tipo_doc       = asi_doc_cmps          );
                    end if;

                    

                    -- actualizando sobretiempos
                    if ln_tiempo_sobretiempo = 0 then
                       delete from sobretiempo_turno st  where (st.cod_trabajador = rc_it.cod_trabajador ) and
                                                               (st.concep         = rc_ct.concep         ) and
                                                               (st.fec_movim      = ld_fec_sobretiempo   ) and
                                                               (st.tipo_doc       = asi_doc_cmps          );
                    else
                        Update sobretiempo_turno st set st.horas_sobret = ln_tiempo_sobretiempo
                         Where (st.cod_trabajador = rc_it.cod_trabajador ) and
                               (st.concep         = rc_ct.concep         ) and
                               (st.fec_movim      = ld_fec_sobretiempo   ) and
                               (st.tipo_doc       = asi_doc_cmps          );
                    end if;



               end loop;
            end loop;
         end loop;
      end loop;
   end loop;

   
   

end usp_rh_comphr_compensa;
/
