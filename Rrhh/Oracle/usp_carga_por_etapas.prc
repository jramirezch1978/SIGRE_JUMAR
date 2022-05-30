create or replace procedure usp_carga_por_etapas(
   ad_fecini in date, ad_fecfin in date) is
   
   cursor c_etapa_corte (cad_fecini date, cad_fecfin date) is 
      select le.cod_fase, l.cod_etapa, o.corr_corte,
             o.nro_operacion, cc.cod_campo, cc.has_netas, 
             o.fec_inicio, o.fec_fin, o.dias_duracion_proy,
             o.cant_real
         from operaciones o, campo_ciclo cc, 
              labor l, labor_etapa le
         where usf_operaciones_fechas ( cad_fecini, cad_fecfin, 
                  o.fec_inicio, 
                  o.fec_fin, o.dias_duracion_proy )=1 and 
               o.corr_corte=cc.corr_corte and 
               o.cod_labor=l.cod_labor and 
               le.cod_etapa=l.cod_etapa
      order by le.cod_fase, l.cod_etapa, o.corr_corte;
   ld_hoy       date;         -- fecha actual del sistema
   ls_clave     char(23);     -- fase+etapa+corr rc_etapa_corte
   lb_registros boolean;      -- existieron registros en c_
   ln_dias      int;          -- dmas entre fecini y fecfin+1    
   -- variables de comparacion del c_etapa_corte
   ln_lectura  number(7);      -- nzmero de registro
   ld_fec_fin  date;           -- fecha fin de labor
   ln_cant_real number(13,4);  -- cant_real del registro
   ln_tot_cant  number(13,4);  -- acumula cant_reales
   ln_sin_fin   int;           -- sin fecha de fin 
   -- variables para el insert
   ls_cod_campo campo_ciclo.cod_campo%type;
   ls_cod_fase  labor_etapa.cod_fase%type;
   ls_cod_etapa labor.cod_etapa%type;
   ld_fec_ini_ins  date;    -- menor fecha encontrada
   ld_fec_fin_ins  date;    -- mayor fecha enocntrada
   ls_estado_ins   char(1); -- 0_Plan, 1_Comn, 2=Term (*)
   ln_sin_fin_ins  int;     -- encontrs fechas sin fin
   ln_has_netas    number(8,2); -- original 4,2
   ln_dias_ins     int;     -- dmas a insertar
   ln_factor       number(14,8); -- %dmasreal/dias_parametros
   -- variables del resumen
   ln_res_has      number(10,2); -- para el resumen
   ln_nro_operacion operaciones.nro_operacion%type;
begin

   ln_dias := ad_fecfin - ad_fecini + 1;
   -- determina fecha actual
   select sysdate
      into ld_hoy from dual;
   
   -- Recorriendo 
   lb_registros := false;
   ln_cant_real := 0;
   ln_lectura   := 0;
   For rc_opes in c_etapa_corte(ad_fecini, ad_fecfin) 
   Loop

      lb_registros := true; -- encontrs al menos un registro
      ln_nro_operacion  := rc_opes.nro_operacion;
      
      -- Determinar fecha final
      If rc_opes.fec_fin is not null Then
         ld_fec_fin := rc_opes.fec_fin;
         ln_sin_fin := 0;
      Else
         ln_sin_fin := 1;
         ld_fec_fin := rc_opes.fec_inicio + 
                       rc_opes.dias_duracion_proy - 1;
         If ld_fec_fin < ld_hoy Then
            --azn no termina... asume termine hoy
            ld_fec_fin := ld_hoy;
         End if;
      End If;
            
      -- Determinar cantidad real 
      If rc_opes.cant_real is not null  or
         rc_opes.cant_real = 0 Then
         ln_cant_real := rc_opes.cant_real;
      End If;
      
      If ln_lectura = 0 Then
         ls_clave := rc_opes.cod_fase || 
            rc_opes.cod_etapa || rc_opes.corr_corte;
         ls_cod_fase  := rc_opes.cod_fase;
         ls_cod_etapa := rc_opes.cod_etapa;
         ls_cod_campo := rc_opes.cod_campo;
         ln_has_netas := rc_opes.has_netas;
         ld_fec_ini_ins := rc_opes.fec_inicio;
         ld_fec_fin_ins := ld_fec_fin;
         ln_tot_cant    := ln_cant_real;
         ln_sin_fin_ins := ln_sin_fin;
         ln_lectura := 1;
         ln_res_has := rc_opes.has_netas;
      Else -- no es primera lectura
         If ls_clave = rc_opes.cod_fase || 
            rc_opes.cod_etapa || rc_opes.corr_corte Then
            ln_tot_cant    := ln_tot_cant + ln_cant_real;
            If ld_fec_ini_ins > rc_opes.fec_inicio Then
               ld_fec_ini_ins := rc_opes.fec_inicio;
            End If;
            If ld_fec_fin_ins > ld_fec_fin Then
               ld_fec_fin_ins := ld_fec_fin;
            End If;
         ElsIf ls_cod_campo = rc_opes.cod_campo 
               and ls_cod_fase = rc_opes.cod_fase 
               and ls_cod_etapa = rc_opes.cod_etapa Then
            ln_has_netas := ln_has_netas + rc_opes.has_netas;
            if ln_sin_fin = 1 Then
               ln_sin_fin_ins := 1;
            End If;
         Else
            if ln_sin_fin_ins = 0 Then
               ls_estado_ins := '2' ; -- Terminado
            elsif ln_tot_cant > 0 Then
               ls_estado_ins := '1' ; -- Comenzado
            else
               ls_estado_ins := '0' ; -- Planeado
            End If;
            ln_dias_ins := ld_fec_fin_ins-ld_fec_ini_ins + 1;
            ln_factor := usf_carga_etapas( ad_fecini, ad_fecfin , 
               ld_fec_ini_ins, ld_fec_fin_ins );
            Insert into tt_carga_por_etapas 
               ( Fase, Etapa, Campo, Has, fec_inicio, fec_fin,
                 dias, flag_estado) Values 
               ( ls_cod_fase, ls_cod_etapa, ls_cod_campo, 
                 Round(ln_has_netas * ln_factor, 2), 
                 ld_fec_ini_ins, ld_fec_fin_ins,
                 ln_dias_ins, ls_estado_ins );
            ln_lectura := 0;
            if ls_cod_fase || ls_cod_etapa =
               rc_opes.cod_fase || rc_opes.cod_etapa Then
               ln_res_has := ln_res_has + rc_opes.has_netas;
            Else
               Insert into tt_carga_por_etapas_res
                  ( Fase, Etapa, Has) Values 
                  ( ls_cod_fase, ls_cod_etapa, ln_res_has );
               ln_res_has := rc_opes.has_netas;
            end if;
            -- fiel copia de arriba
            ls_clave := rc_opes.cod_fase || 
               rc_opes.cod_etapa || rc_opes.corr_corte;
            ls_cod_fase  := rc_opes.cod_fase;
            ls_cod_etapa := rc_opes.cod_etapa;
            ls_cod_campo := rc_opes.cod_campo;
            ln_has_netas := rc_opes.has_netas;
            ld_fec_ini_ins := rc_opes.fec_inicio;
            ld_fec_fin_ins := ld_fec_fin;
            ln_tot_cant    := ln_cant_real;
            ln_sin_fin_ins := ln_sin_fin;
            ln_lectura := 1;

         End If ;

      End If; -- primera lectura
      
    End Loop;
    
    If lb_registros = True Then 
            if ln_sin_fin_ins = 0 Then
               ls_estado_ins := '2' ; -- Terminado
            elsif ln_tot_cant > 0 Then
               ls_estado_ins := '1' ; -- Comenzado
            else
               ls_estado_ins := '0' ; -- Planeado
            End If;
            ln_dias_ins := ld_fec_fin_ins-ld_fec_ini_ins + 1;
            ln_factor := usf_carga_etapas( ad_fecini, ad_fecfin , 
               ld_fec_ini_ins, ld_fec_fin_ins );
          --  Insert into tt_edg ( fase ) values ( ls_cod_fase );
            Insert into tt_carga_por_etapas 
               ( Fase, Etapa, Campo, Has, fec_inicio, fec_fin,
                 dias, flag_estado) Values 
               ( ls_cod_fase, ls_cod_etapa, ls_cod_campo, 
                 ln_has_netas * ln_factor, 
                 ld_fec_ini_ins, ld_fec_fin_ins,
                 ln_dias_ins, ls_estado_ins );
            Insert into tt_carga_por_etapas_res
                  ( Fase, Etapa, Has) Values 
                  ( ls_cod_fase, ls_cod_etapa, ln_res_has );
    End if;
end usp_carga_por_etapas;
-- Consideraciones
-- ls_estado_ins char(1)
--   0_Planeado (Cant_real = 0) , 
--   1_Comenzado (Cant_Real > 0)
--   2=Terminado (Fecha_final is not null)
/
