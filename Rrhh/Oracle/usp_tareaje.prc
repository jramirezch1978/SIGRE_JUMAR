create or replace procedure usp_tareaje (
   ad_fecini in date, ad_fecfin in date, as_cod_zona in string ) is
   
   cursor c_operaciones (cad_fecini date, cad_fecfin date) is 
      --Flag de estado, Puede ser: 
      --   0 = Anulado, 1 = Activo, 2 = Terminado
      --Flag de mano de obra o maquinaria. Puede ser: 
      --   M = Maquina, O = Mano de Obra
      Select c.cod_zona, c.cod_campo, c.desc_campo, 
          o.corr_corte, o.nro_operacion, 
          l.cod_labor, l.desc_labor,
          o.fec_inicio, o.fec_fin, o.dias_duracion_proy, 
          o.cant_proyect
      from operaciones o, labor l, campo_ciclo cc, campo c
      where o.cod_labor  = l.cod_labor   and l.flag_maq_mo='O' and
            o.corr_corte = cc.corr_corte and o.flag_estado='1' and
            cc.cod_campo = c.cod_campo   and cc.flag_estado=1  and
            c.cod_zona = as_cod_zona ;
            /*and
            usf_operaciones_fechas ( 
               ad_fecini, ad_fecfin, 
               o.fec_inicio, o.fec_fin, o.dias_duracion_proy ) > 0; */

   ld_hoy       date;         -- fecha actual del sistema
   ld_fec_fin   date;         -- fecha final de labor
   ln_dias       int;         -- contador de dias a insertar
   ld_fecha     date;         -- fecha en proceso
   ln_cant   number(6,2);     -- cantidad 
   ln_cant_tot number(7,2);
   
begin

   -- Asignando fecha actual
   Select sysdate into ld_hoy from dual ;
   

   -- Recorriendo 
   For rc_opes in c_operaciones( ad_fecini, ad_fecfin ) 
   Loop

      -- Determinar fecha final
      If rc_opes.fec_fin is not null Then
         ld_fec_fin := rc_opes.fec_fin;
      Else
         ld_fec_fin := rc_opes.fec_inicio + 
                       Nvl(rc_opes.dias_duracion_proy, 0) -1;
         If ld_fec_fin < ld_hoy Then
            --aun no termina... asume termine hoy
            ld_fec_fin := ld_hoy;
         End if;
      End If;
      
      -- Determinar la cantidad de dias a generar
      ln_dias  := ld_fec_fin - rc_opes.fec_inicio; -- + 1 ;
      if ln_dias=null then
         ln_dias:=1 ;
      elsif ln_dias=0 then
         ln_dias:=1 ;
      end if ;
      ld_fecha := rc_opes.fec_inicio;
      ln_cant  := rc_opes.cant_proyect / ln_dias;
      ln_cant_tot := 0;
      for i in 1..ln_dias
      loop
         ln_cant_tot := ln_cant_tot + ln_cant ;
         if i = ln_dias then
            ln_cant := ln_cant + ( rc_opes.cant_proyect - ln_cant_tot );
         end if ;
         if ld_fecha >= ad_fecini and ld_fecha <=ad_fecfin Then
            insert into tt_tareaje ( 
               cod_zona, cod_campo, desc_campo, 
               corr_corte, nro_operacion, cod_labor, desc_labor, 
               fecha, cantidad) values ( 
               rc_opes.cod_zona, rc_opes.cod_campo, 
               rc_opes.desc_campo,
               rc_opes.corr_corte, rc_opes.nro_operacion,
               rc_opes.cod_labor, rc_opes.desc_labor, 
               ld_fecha, ln_cant ) ;
         end if;
         ld_fecha := ld_fecha + 1;
      end loop;            
      
    End Loop;
    
end usp_tareaje;
/
