create or replace procedure usp_rh_comphr_sobret
(ac_cod_usr        in usuario.cod_usr%type   ,ac_tipo_doc       in doc_tipo.tipo_doc%type ,
 ad_ini            in date                   ,ad_fin            in date                   ,
 ac_concep_sob_sab in concepto.concep%type   ,ac_concep_sob_dom in concepto.concep%type   ,
 ac_concep_sob_fer in concepto.concep%type   ,ac_cod_tipo_mov   in tipo_mov_asistencia.cod_tipo_mov%type ,
 ac_origen         in origen.cod_origen%type ,ac_ttrab          in tipo_trabajador.tipo_trabajador%type  ) is
   
    

lc_hora_ini     char(5)              ; lc_hora_fin     char(5) ;
ld_ini          date                 ; ld_fin          date    ;
ln_horas_sobret number               ; ln_horas_pagar  number  ;
lc_ind_sab      char(1)              ; lc_ind_dom      char(1) ;
lc_ind_fer      char(1)              ; lc_ind_sob      char(1) ;
lc_concepto     concepto.concep%type ;lc_cntrl_normal  char(1) ;
ln_count        number               ;lc_cod_trabajador maestro.cod_trabajador%type ;

Cursor rc_asistencia is
select a.cod_trabajador     ,a.fec_desde          ,a.fec_hasta         ,a.fec_movim         ,a.turno ,
       t.hora_ini_cmps_sab  ,t.hora_fin_cmps_sab  ,t.hora_ini_cmps_dom ,t.hora_fin_cmps_dom ,
       t.hora_ini_cmps_norm ,t.hora_fin_cmps_norm
  from asistencia a,turno t,maestro m
 where (trunc(a.fec_movim)   between trunc(ad_ini) and trunc(ad_fin) ) and
       (a.turno              = t.turno                               ) and
       (a.cod_trabajador     = m.cod_trabajador                      ) and
       (m.cod_origen         = ac_origen                             ) and
       (m.tipo_trabajador    = ac_ttrab                              ) and
       (a.cod_tipo_mov       = ac_cod_tipo_mov                       ) ;

Cursor rc_concep_sobret is
select chd.concep, chd.nro_horas
  from rh_grp_cmp_hrs_det chd
 where chd.grp_cmps_hrs in (select cht.grp_cmps_hrs
                             from rh_grp_cmp_hrs_trab cht
                            where cht.cod_trabajador = lc_cod_trabajador)
order by chd.item ;

begin



For rc_at in rc_asistencia loop
    lc_cod_trabajador := rc_at.cod_trabajador;
    lc_cntrl_normal   := '0' ;    --no se sabe si dia sera normal o especial
    
    -- definiendo tipo de día
    select tcm.sabado, tcm.domingo, tcm.feriado, tcm.sobretiempo  
      into lc_ind_sab, lc_ind_dom, lc_ind_fer, lc_ind_sob
      from tt_rh_comp_hora tcm  where trunc(tcm.fecha) = trunc(rc_at.fec_movim);
        
    if lc_ind_sob = '1' then  --verifica si dia esta marcado como dia con sobretiempo
       if lc_ind_sab = '1' then --verifica si dia con sobretiempo es sabado
          -- definiendo hora de ingreso y salida en sabado
          ld_ini := rc_at.hora_ini_cmps_sab ;
          ld_fin := rc_at.hora_fin_cmps_sab ;
       elsif lc_ind_dom = '1' then
          -- definiendo hora de ingreso y salida en domingo
          ld_ini := rc_at.hora_ini_cmps_dom  ;
          ld_fin := rc_at.hora_fin_cmps_dom ;
       else
         -- definiendo hora de ingreso y salida en dias normales (no domingo ni sabado)
         ld_ini := rc_at.hora_ini_cmps_norm  ;
         ld_fin := rc_at.hora_fin_cmps_norm ;
       end if;
    end if;
    
    --hora inicio y hora final
    lc_hora_ini := to_char(ld_ini, 'hh24:mi');
    lc_hora_fin := to_char(ld_fin, 'hh24:mi');
    
    --concateno fecha y hora de asistencia
    ld_ini := to_date(to_char(rc_at.fec_desde, 'dd/mm/yyyy') || ' ' ||lc_hora_ini, 'dd/mm/yyyy hh24:mi');
    ld_fin := to_date(to_char(rc_at.fec_hasta, 'dd/mm/yyyy') || ' ' ||lc_hora_fin, 'dd/mm/yyyy hh24:mi');

    ln_horas_sobret := 0;

    if lc_ind_dom = '1' or lc_ind_fer = '1' then  --si dia es domingo considerar concepto de 100 %
       ln_horas_sobret := to_number(rc_at.fec_hasta - rc_at.fec_desde) * 24;
       
    else
       -- sobretiempo antes de su hora de entrada
       if rc_at.fec_desde < ld_ini then
          ln_horas_sobret := ln_horas_sobret + to_number(ld_ini - rc_at.fec_desde);
       end if ;
       -- sobretiempo antes de su hora de salida
       if rc_at.fec_hasta > ld_fin then
          ln_horas_sobret := ln_horas_sobret + to_number(rc_at.fec_hasta - ld_fin);
       end if;

       ln_horas_sobret := ln_horas_sobret * 24;
    end if;

    if ln_horas_sobret > 0 then
       -- Definiendo concepto de pago
       if lc_ind_sab = '1'    then --concepto para dia sabado
          lc_concepto := ac_concep_sob_sab ;
       elsif lc_ind_dom = '1' then --concepto para dia domingo 
          lc_concepto := ac_concep_sob_dom ;  
       elsif lc_ind_fer = '1' then --concepto para dias feriados
          lc_concepto := ac_concep_sob_fer ;
       else                        --concepto para dias normales de acuerdo a grupos configurados
          --crear flag para no ingresar informacon en sobretiempo turno
          ln_horas_pagar := 0 ;
          For rc_cs in rc_concep_sobret Loop
              if ln_horas_sobret > 0 then
                 if rc_cs.nro_horas < ln_horas_sobret then
                    ln_horas_pagar := rc_cs.nro_horas;
                    ln_horas_sobret:= ln_horas_sobret - rc_cs.nro_horas;
                 else
                    ln_horas_pagar := ln_horas_sobret;
                    ln_horas_sobret := 0;
                 end if;
                 
                 --actualizar
                 Update sobretiempo_turno st
                    Set st.horas_sobret = Nvl(st.horas_sobret,0) + ln_horas_pagar
                  Where (st.cod_trabajador   = rc_at.cod_trabajador  ) and
                        (trunc(st.fec_movim) = trunc(rc_at.fec_movim)) and
                        (st.concep           = rc_cs.concep          ) ;
                        
                  
                 if sql%notfound then
                    Insert Into sobretiempo_turno (cod_trabajador,fec_movim, concep, horas_sobret, cod_usr, tipo_doc)
                    Values (rc_at.cod_trabajador, trunc(rc_at.fec_movim),rc_cs.concep, ln_horas_pagar, ac_cod_usr, ac_tipo_doc);
                 end if ; 
                                         
              end if ;    
              
              --ACTIVO DIAS NORMALES
              lc_cntrl_normal := '1' ;
              
          End Loop ;       
       end if;
       
       --INSERTO DATO PARA CUANDO NO SEA DIA NORMAL
       if lc_cntrl_normal = '0' then
       
          select count(*) into ln_count from sobretiempo_turno st
           where (st.cod_trabajador   = rc_at.cod_trabajador  ) and
                 (st.concep           = lc_concepto           ) and
                 (trunc(st.fec_movim) = trunc(rc_at.fec_movim)) ;
          
          if ln_count = 0 then       

             Insert Into sobretiempo_turno (cod_trabajador,fec_movim, concep, horas_sobret, cod_usr, tipo_doc)
             Values (rc_at.cod_trabajador, trunc(rc_at.fec_movim) ,lc_concepto, ln_horas_sobret, ac_cod_usr, ac_tipo_doc);
          else
             --insertar en tabla temporal errores
             insert into tt_rrhh_error_cmphrs
             (cod_trabajador,fec_movim,concepto,obs)
             values
             (rc_at.cod_trabajador,trunc(rc_at.fec_movim),lc_concepto,'Dia de Asistencia ya existe ,Verifique!') ;
             
          end if ;
       end if ;
       
          
       
    end if ;
      
   end loop;


end usp_rh_comphr_sobret;
/
