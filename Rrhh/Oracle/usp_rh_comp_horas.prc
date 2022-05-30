create or replace procedure usp_rh_comp_horas (

   asi_cod_usr in string,
   asi_concep_ina in string, 
   asi_concep_fer in string, 
   asi_concep_sab in string, 
   asi_concep_dom in string, 
   asi_concep_dominical in string,
   ani_feriado in number, 
   ani_sabado in number, 
   ani_domingo in number,
   ani_dominical in number,
   adi_fecha_proceso in date

)is
   ld_ini date;
   ld_fin date;
   ld_fecha_inasistencia date;
   ld_fecha_sobretiempo date;
   ls_sabado char(1);
   ls_domingo char(1);
   ls_feriado char(1);
   ls_tipo_asist char(1);
   ls_tipo_dia char(1);
   ls_cod_trabajador maestro.cod_trabajador%type;
   ls_fecha_registro char(16);
   ln_horas number (15,5);
   ln_hora_turno number (15,5);
   ln_horas_a_trabajar number(25,10);
   ln_horas_compensadas number(25,10);
   ln_horas_trabajadas number(25,10);
   ln_horas_sobretiempo number(25,10);
   ln_horas_normales number(25,10);
   ln_horas_inasistencia number(25,10);
   ln_hora_a_pagar number(25,10);
   ln_calculo_pagar number(25,10);
   ls_concep concepto.concep%type;
   ls_concep_inasist concepto.concep%type;
   ln_hora_pagada number(25,10);
   ls_tipo_doc doc_tipo.tipo_doc%type;
   ln_dias_periodo number (15,5);
   ln_horas_laborables number (15,5);
   ln_imp_var gan_desct_variable.imp_var%type;
   ln_imp_gan_desc gan_desct_fijo.imp_gan_desc%type;
   
   cursor lc_asistencia is  -- asistencia
      select a.cod_trabajador, a.fec_movim, a.fec_desde, a.fec_hasta, t.hora_inicio_norm, t.hora_inicio_sab, t.hora_inicio_dom, t.hora_final_norm, t.hora_final_sab, t.hora_final_dom
         from asistencia a
         inner join turno t on a.turno = t.turno
         where a.fec_movim between trunc(ld_ini) and trunc(ld_fin)
         order by cod_trabajador, fec_movim;
         
   cursor lc_compensacion is  -- trabajadores a compensar
      select tch.cod_trabajador, count(*)
         from tt_rh_comp_horas_def tch
         where tch.tipo_asist = 'I'
            and tch.tipo_dia not in ('D', 'F')
         group by tch.cod_trabajador
         having count(*) > 0
         order by tch.cod_trabajador;
   
   cursor lc_inasistencia is -- inasistencias
      select tch.fecha, tch.hora_normal, tch.hora_inasistencia, tch.tipo_dia
         from tt_rh_comp_horas_def tch
         where tch.cod_trabajador = ls_cod_trabajador
            and tch.tipo_asist = 'I'
            and tch.tipo_dia not in ('D', 'F')
         order by tch.fecha;
   
   cursor lc_sobretiempo_normal is  -- sobretiempos normales
      select tch.fecha, tch.hora_sobretiempo, tch.tipo_dia
         from tt_rh_comp_horas_def tch
         where tch.cod_trabajador = ls_cod_trabajador
            and tch.tipo_asist = 'S'
            and tch.tipo_dia = 'N'
         order by tch.fecha;
         
   cursor lc_sobretiempo_sabado is  -- sobretiempos sabados
      select tch.fecha, tch.hora_sobretiempo, tch.tipo_dia
         from tt_rh_comp_horas_def tch
         where tch.cod_trabajador = ls_cod_trabajador
            and tch.tipo_asist = 'S'
            and tch.tipo_dia = 'S'
         order by tch.fecha;
   
   cursor lc_sobretiempo_domingo is  -- sobretiempos domingo
      select tch.fecha, tch.hora_sobretiempo, tch.tipo_dia
         from tt_rh_comp_horas_def tch
         where tch.cod_trabajador = ls_cod_trabajador
            and tch.tipo_asist = 'S'
            and tch.tipo_dia = 'D'
         order by tch.fecha;

   cursor lc_sobretiempo_feriado is  -- sobretiempos feriados
      select tch.fecha, tch.hora_sobretiempo, tch.tipo_dia
         from tt_rh_comp_horas_def tch
         where tch.cod_trabajador = ls_cod_trabajador
            and tch.tipo_asist = 'S'
            and tch.tipo_dia = 'F'
         order by tch.fecha;
         
   cursor lc_trab_sobret_normal is  -- trabajadores con sobretiempos normales
      select rchd.cod_trabajador, rchd.fecha, rchd.hora_sobretiempo  
         from tt_rh_comp_horas_def rchd 
         where rchd.tipo_dia  = 'N' 
            and rchd.tipo_asist = 'S';
   
   cursor lc_concep_sobret_norm is -- concepto de sobretiempo
      select gchd.concep, gchd.nro_horas 
         from rh_grp_cmp_hrs_det gchd 
         where gchd.grp_cmps_hrs = (select gcht.grp_cmps_hrs 
               from rh_grp_cmp_hrs_trab gcht 
               where gcht.cod_trabajador = ls_cod_trabajador)
         order by gchd.item;

   cursor lc_trab_inasis_normal is  -- trabajadores con inasistencias normales
      select rchd.cod_trabajador, rchd.fecha, rchd.hora_inasistencia, rchd.hora_normal
         from tt_rh_comp_horas_def rchd 
         where rchd.tipo_dia  = 'N' 
            and rchd.tipo_asist = 'I';
   
   cursor lc_trabajador is -- todos los trbajadores compensados (para calculo de dominical)
      select distinct rchd.cod_trabajador
         from tt_rh_comp_horas_def rchd;

begin
   delete from tt_rh_comp_horas_def;
   ------------------------ solo para pruebas --------------- ini
   /*
   delete from sobretiempo_turno;
   delete from inasistencia;
   delete from gan_desct_variable gdf where gdf.concep = '1035';
   delete from tt_rh_comp_hora;
   insert into tt_rh_comp_hora (fecha, dia, sabado, domingo, feriado)
      values (to_date('29/04/2004', 'dd/mm/yyyy'), 'Domingo', '0', '1', '0');
   insert into tt_rh_comp_hora (fecha, dia, sabado, domingo, feriado)
      values (to_date('30/04/2004', 'dd/mm/yyyy'), 'Lunes', '0', '0', '0');
   insert into tt_rh_comp_hora (fecha, dia, sabado, domingo, feriado)
      values (to_date('01/04/2004', 'dd/mm/yyyy'), 'Martes', '0', '0', '0');
   insert into tt_rh_comp_hora (fecha, dia, sabado, domingo, feriado)
      values (to_date('02/04/2004', 'dd/mm/yyyy'), 'Miércoles', '0', '0', '0');
   insert into tt_rh_comp_hora (fecha, dia, sabado, domingo, feriado)
      values (to_date('03/04/2004', 'dd/mm/yyyy'), 'Jueves', '0', '0', '1');
   insert into tt_rh_comp_hora (fecha, dia, sabado, domingo, feriado)
      values (to_date('04/04/2004', 'dd/mm/yyyy'), 'Viernes', '0', '0', '1');
   insert into tt_rh_comp_hora (fecha, dia, sabado, domingo, feriado)
      values (to_date('05/04/2004', 'dd/mm/yyyy'), 'Sabado', '1', '0', '0');
   commit;
    */
   ------------------------ solo para pruebas --------------- fin
   --documento de compensacion de horas
   select rhp.doc_cmps
      into ls_tipo_doc
      from rrhhparam rhp
      where rhp.reckey = '1';
      
   --limites del periodo a compensar
   select min(trunc(trh.fecha)), max(trunc(trh.fecha)) 
      into ld_ini, ld_fin
      from tt_rh_comp_hora trh;
   
   --busca todas las asistencias por trabajador para el periodo
   for rs_la in lc_asistencia loop

      select nvl(trh.sabado, '0'), nvl(trh.domingo,'0'), nvl(trh.feriado,'0')
         into ls_sabado, ls_domingo, ls_feriado
         from tt_rh_comp_hora trh
         where trunc(trh.fecha) = trunc(rs_la.fec_movim);
      
      if rs_la.hora_final_norm >= rs_la.hora_inicio_norm then
         ln_horas := round( rs_la.hora_final_norm - rs_la.hora_inicio_norm , 10);
      else
         ln_horas := round( rs_la.hora_inicio_norm - rs_la.hora_final_norm , 10);
      end if;
      
      --numero de horas a trabajar en sabado
      if ls_sabado = '1' then
         if rs_la.hora_final_sab >= rs_la.hora_inicio_sab then
            ln_horas := round( rs_la.hora_final_sab - rs_la.hora_inicio_sab , 10);
         else
            ln_horas := round( rs_la.hora_final_sab + 1 - rs_la.hora_inicio_sab , 10);
         end if;
      else  
         --numero de horas a trabajar en domingo
         if ls_domingo = '1' then
            if rs_la.hora_final_dom >= rs_la.hora_inicio_dom then
               ln_horas := round( rs_la.hora_final_dom - rs_la.hora_inicio_dom , 10);
            else
               ln_horas := round( rs_la.hora_final_dom + 1 - rs_la.hora_inicio_dom , 10);
            end if;
         else
            if rs_la.hora_final_norm >= rs_la.hora_inicio_norm then
               ln_horas := round( rs_la.hora_final_norm - rs_la.hora_inicio_norm , 10);
            else
               ln_horas := round( rs_la.hora_final_norm + 1 - rs_la.hora_inicio_norm , 10);
            end if;
         end if;
      end if;

      ln_horas := ln_horas * 24 ;
      
      --tipo de dia
      if ls_sabado = '1' then
         ls_tipo_dia := 'S';
      else
         if ls_domingo = '1' then
            ls_tipo_dia := 'D';
         else
            if ls_feriado = '1' then
               ls_tipo_dia := 'F';
            else
               ls_tipo_dia := 'N';
            end if;
         end if;
      end if;

      --numero de horas trabajadas
      ln_horas_trabajadas := round(rs_la.fec_hasta - rs_la.fec_desde , 10);
      ln_horas_trabajadas := ln_horas_trabajadas * 24;
      
      -- horas trabajadas contra horas que debió trabajar
      if ln_horas_trabajadas < ln_horas then
         ln_horas_sobretiempo := 0;
         ln_horas_normales := ln_horas_trabajadas;
         ln_horas_inasistencia := round(ln_horas - ln_horas_trabajadas , 10);
         ls_tipo_asist := 'I'; --inasistencia o tardanza
      else
         if ln_horas_trabajadas > ln_horas then
            ln_horas_sobretiempo := round(ln_horas_trabajadas - ln_horas , 10);
            ln_horas_normales :=  ln_horas;
            ln_horas_inasistencia := 0;
            ls_tipo_asist := 'S'; -- sobretiempo
         else
            ln_horas_sobretiempo :=  0;
            ln_horas_normales :=  ln_horas_trabajadas;
            ln_horas_inasistencia := 0;
            ls_tipo_asist := 'N'; -- normal
         end if;
      end if;
      insert into tt_rh_comp_horas_def 
         (cod_trabajador, fecha, hora_normal, hora_sobretiempo, hora_inasistencia, tipo_dia, tipo_asist)
         values(rs_la.cod_trabajador, rs_la.fec_movim, ln_horas_normales, ln_horas_sobretiempo, ln_horas_inasistencia, ls_tipo_dia, ls_tipo_asist);
--      commit;
   end loop;

--   commit;
   -- compensación con sobretiempos en dias normales
   for rs_cp in lc_compensacion loop
      ls_cod_trabajador := rs_cp.cod_trabajador;
      ln_horas_inasistencia := 0;
      ln_horas_sobretiempo := 0;
      ln_horas_normales := 0;
   
      for rs_sn in lc_sobretiempo_normal loop
         ln_horas_sobretiempo := rs_sn.hora_sobretiempo;
         ld_fecha_sobretiempo := rs_sn.fecha;
        
         for rs_is in lc_inasistencia loop
            ln_horas_inasistencia := rs_is.hora_inasistencia;
            ln_horas_normales := rs_is.hora_normal;
            ld_fecha_inasistencia := rs_is.fecha;
            
            if ln_horas_sobretiempo >= ln_horas_inasistencia then
               ln_horas_compensadas := ln_horas_sobretiempo - ln_horas_inasistencia;
               ln_horas_normales := ln_horas_normales + ln_horas_inasistencia;
               ln_horas_inasistencia := 0;
               ln_horas_sobretiempo := ln_horas_compensadas;
               ls_tipo_asist := 'N';
            else
               ln_horas_compensadas := ln_horas_inasistencia - ln_horas_sobretiempo;
               ln_horas_normales := ln_horas_normales + ln_horas_sobretiempo;
               ln_horas_inasistencia := ln_horas_compensadas;
               ln_horas_sobretiempo := 0;
               ls_tipo_asist := 'I';
            end if;
            
            update tt_rh_comp_horas_def chd
               set chd.hora_inasistencia = ln_horas_inasistencia,
                  chd.hora_normal = ln_horas_normales,
                  chd.tipo_asist = ls_tipo_asist
               where chd.cod_trabajador = ls_cod_trabajador
                  and chd.fecha = ld_fecha_inasistencia;  
                  
            if ln_horas_sobretiempo = 0 then
               ls_tipo_asist := 'N';
            else
               ls_tipo_asist := 'S';
            end if;
            
            update tt_rh_comp_horas_def chd
               set chd.hora_sobretiempo = ln_horas_sobretiempo,
                  chd.tipo_asist = ls_tipo_asist
               where chd.cod_trabajador = ls_cod_trabajador
                  and chd.fecha = ld_fecha_sobretiempo;

--            commit;
         end loop;
      end loop;
   end loop;
   
      -- compensación con sobretiempos en dias sábado
   for rs_cp in lc_compensacion loop
      ls_cod_trabajador := rs_cp.cod_trabajador;
      ln_horas_inasistencia := 0;
      ln_horas_sobretiempo := 0;
      ln_horas_normales := 0;
   
      for rs_sn in lc_sobretiempo_sabado loop
         ln_horas_sobretiempo := rs_sn.hora_sobretiempo;
         ld_fecha_sobretiempo := rs_sn.fecha;
        
         for rs_is in lc_inasistencia loop
            ln_horas_inasistencia := rs_is.hora_inasistencia;
            ln_horas_normales := rs_is.hora_normal;
            ld_fecha_inasistencia := rs_is.fecha;
            
            if ln_horas_sobretiempo >= ln_horas_inasistencia then
               ln_horas_compensadas := ln_horas_sobretiempo - ln_horas_inasistencia;
               ln_horas_normales := ln_horas_normales + ln_horas_inasistencia;
               ln_horas_inasistencia := 0;
               ln_horas_sobretiempo := ln_horas_compensadas;
               ls_tipo_asist := 'N';
            else
               ln_horas_compensadas := ln_horas_inasistencia - ln_horas_sobretiempo;
               ln_horas_normales := ln_horas_normales + ln_horas_sobretiempo;
               ln_horas_inasistencia := ln_horas_compensadas;
               ln_horas_sobretiempo := 0;
               ls_tipo_asist := 'I';
            end if;
            
            update tt_rh_comp_horas_def chd
               set chd.hora_inasistencia = ln_horas_inasistencia,
                  chd.hora_normal = ln_horas_normales,
                  chd.tipo_asist = ls_tipo_asist
               where chd.cod_trabajador = ls_cod_trabajador
                  and chd.fecha = ld_fecha_inasistencia;  
                  
            if ln_horas_sobretiempo = 0 then
               ls_tipo_asist := 'N';
            else
               ls_tipo_asist := 'S';
            end if;
            
            update tt_rh_comp_horas_def chd
               set chd.hora_sobretiempo = ln_horas_sobretiempo,
                  chd.tipo_asist = ls_tipo_asist
               where chd.cod_trabajador = ls_cod_trabajador
                  and chd.fecha = ld_fecha_sobretiempo;

--            commit;
         end loop;
      end loop;
   end loop;
   
      -- compensación con sobretiempos domingo
   for rs_cp in lc_compensacion loop
      ls_cod_trabajador := rs_cp.cod_trabajador;
      ln_horas_inasistencia := 0;
      ln_horas_sobretiempo := 0;
      ln_horas_normales := 0;
   
      for rs_sn in lc_sobretiempo_domingo loop
         ln_horas_sobretiempo := rs_sn.hora_sobretiempo;
         ld_fecha_sobretiempo := rs_sn.fecha;
        
         for rs_is in lc_inasistencia loop
            ln_horas_inasistencia := rs_is.hora_inasistencia;
            ln_horas_normales := rs_is.hora_normal;
            ld_fecha_inasistencia := rs_is.fecha;
            
            if ln_horas_sobretiempo >= ln_horas_inasistencia then
               ln_horas_compensadas := ln_horas_sobretiempo - ln_horas_inasistencia;
               ln_horas_normales := ln_horas_normales + ln_horas_inasistencia;
               ln_horas_inasistencia := 0;
               ln_horas_sobretiempo := ln_horas_compensadas;
               ls_tipo_asist := 'N';
            else
               ln_horas_compensadas := ln_horas_inasistencia - ln_horas_sobretiempo;
               ln_horas_normales := ln_horas_normales + ln_horas_sobretiempo;
               ln_horas_inasistencia := ln_horas_compensadas;
               ln_horas_sobretiempo := 0;
               ls_tipo_asist := 'I';
            end if;
            
            update tt_rh_comp_horas_def chd
               set chd.hora_inasistencia = ln_horas_inasistencia,
                  chd.hora_normal = ln_horas_normales,
                  chd.tipo_asist = ls_tipo_asist
               where chd.cod_trabajador = ls_cod_trabajador
                  and chd.fecha = ld_fecha_inasistencia;  
                  
            if ln_horas_sobretiempo = 0 then
               ls_tipo_asist := 'N';
            else
               ls_tipo_asist := 'S';
            end if;
            
            update tt_rh_comp_horas_def chd
               set chd.hora_sobretiempo = ln_horas_sobretiempo,
                  chd.tipo_asist = ls_tipo_asist
               where chd.cod_trabajador = ls_cod_trabajador
                  and chd.fecha = ld_fecha_sobretiempo;

--            commit;
         end loop;
      end loop;
   end loop;
   
   -- compensación con sobretiempos en dias feriados
   for rs_cp in lc_compensacion loop
      ls_cod_trabajador := rs_cp.cod_trabajador;
      ln_horas_inasistencia := 0;
      ln_horas_sobretiempo := 0;
      ln_horas_normales := 0;
   
      for rs_sn in lc_sobretiempo_feriado loop
         ln_horas_sobretiempo := rs_sn.hora_sobretiempo;
         ld_fecha_sobretiempo := rs_sn.fecha;
        
         for rs_is in lc_inasistencia loop
            ln_horas_inasistencia := rs_is.hora_inasistencia;
            ln_horas_normales := rs_is.hora_normal;
            ld_fecha_inasistencia := rs_is.fecha;
            
            if ln_horas_sobretiempo >= ln_horas_inasistencia then
               ln_horas_compensadas := ln_horas_sobretiempo - ln_horas_inasistencia;
               ln_horas_normales := ln_horas_normales + ln_horas_inasistencia;
               ln_horas_inasistencia := 0;
               ln_horas_sobretiempo := ln_horas_compensadas;
               ls_tipo_asist := 'N';
            else
               ln_horas_compensadas := ln_horas_inasistencia - ln_horas_sobretiempo;
               ln_horas_normales := ln_horas_normales + ln_horas_sobretiempo;
               ln_horas_inasistencia := ln_horas_compensadas;
               ln_horas_sobretiempo := 0;
               ls_tipo_asist := 'I';
            end if;
            
            update tt_rh_comp_horas_def chd
               set chd.hora_inasistencia = ln_horas_inasistencia,
                  chd.hora_normal = ln_horas_normales,
                  chd.tipo_asist = ls_tipo_asist
               where chd.cod_trabajador = ls_cod_trabajador
                  and chd.fecha = ld_fecha_inasistencia;  
                  
            if ln_horas_sobretiempo = 0 then
               ls_tipo_asist := 'N';
            else
               ls_tipo_asist := 'S';
            end if;
            
            update tt_rh_comp_horas_def chd
               set chd.hora_sobretiempo = ln_horas_sobretiempo,
                  chd.tipo_asist = ls_tipo_asist
               where chd.cod_trabajador = ls_cod_trabajador
                  and chd.fecha = ld_fecha_sobretiempo;
--            commit;
         end loop;
      end loop;
   end loop;
   
   -- sobretirmpos normales
   for rs_tn in lc_trab_sobret_normal loop
      ls_cod_trabajador := rs_tn.cod_trabajador;
      ld_fecha_sobretiempo := rs_tn.fecha;
      ln_horas_sobretiempo := rs_tn.hora_sobretiempo;
      
      for rs_cn in lc_concep_sobret_norm loop
         ls_concep := rs_cn.concep;
         ln_hora_a_pagar := rs_cn.nro_horas;
         
         if ln_horas_sobretiempo > 0 then
            if ln_hora_a_pagar < ln_horas_sobretiempo then
               ln_hora_pagada := ln_hora_a_pagar;
            else
               ln_hora_pagada := ln_horas_sobretiempo;
            end if;
            ln_horas_sobretiempo := ln_horas_sobretiempo - ln_hora_pagada;
            insert into sobretiempo_turno (cod_trabajador, fec_movim, concep, horas_sobret, cod_usr, tipo_doc)
               values(ls_cod_trabajador, ld_fecha_sobretiempo, ls_concep, ln_hora_pagada, asi_cod_usr, ls_tipo_doc);
         end if;
         
      end loop;
   end loop;
--   commit;
   
   -- trabajadores con inasistencias normales
   select c.nro_horas 
   into ln_horas_a_trabajar
   from concepto c 
   where c.concep = ( select gc.concepto_gen 
         from grupo_calculo gc 
         where gc.grupo_calculo = ( select rc.remunerac_basica 
               from rrhhparam_cconcep rc
               where rc.reckey = '1' ) );

   select rp.dias_mes_obrero
      into ln_dias_periodo
      from rrhhparam rp
      where rp.reckey = '1';
   
   ln_horas_a_trabajar := ln_horas_a_trabajar / ln_dias_periodo; --horas trabajadas por dia
   
   for rs_ti in lc_trab_inasis_normal loop

      ls_cod_trabajador := rs_ti.cod_trabajador;
      ld_fecha_inasistencia :=  rs_ti.fecha;
      ln_horas_inasistencia := rs_ti.hora_inasistencia;
      ln_horas_normales := rs_ti.hora_normal;
      
      ln_horas_inasistencia := ln_horas_inasistencia / ln_horas_a_trabajar;  --horas inasistecia
      ln_horas_normales := ln_horas_normales / ln_horas_a_trabajar; --horas normales
      ls_fecha_registro := to_char(ld_fecha_inasistencia, 'dd/mm/yyyy');
      
      select t.hora_inicio_norm
         into ld_ini
         from maestro m 
            inner join turno t on m.turno = t.turno
         where m.cod_trabajador = ls_cod_trabajador;

      ls_fecha_registro := trim(ls_fecha_registro) || ' ' || to_char(ld_ini, 'hh24:mi');
      ld_ini := to_date (ls_fecha_registro, 'dd/mm/yyyy hh24:mi');
      ld_fin := ld_ini + ln_horas_normales;

      insert into inasistencia ( cod_trabajador, concep, fec_desde, fec_hasta, fec_movim, dias_inasist, tipo_doc, cod_usr )
         values (ls_cod_trabajador, asi_concep_ina, ld_ini, ld_fin, ld_fecha_inasistencia, ln_horas_inasistencia, ls_tipo_doc, asi_cod_usr);
--      commit;
      
   end loop;

   --trabajo en domingo
   if ani_domingo = 1 then
      insert into sobretiempo_turno (cod_trabajador, fec_movim, concep, horas_sobret, cod_usr, tipo_doc)
         select hd.cod_trabajador, hd.fecha, asi_concep_dom, hd.hora_normal + hd.hora_sobretiempo + hd.hora_inasistencia, asi_cod_usr, ls_tipo_doc
            from tt_rh_comp_horas_def hd 
            where hd.tipo_dia = 'D';
   end if;

   --trabajo en Sabado
   if ani_sabado = 1 then
      insert into sobretiempo_turno (cod_trabajador, fec_movim, concep, horas_sobret, cod_usr, tipo_doc)
         select hd.cod_trabajador, hd.fecha, asi_concep_sab, hd.hora_normal + hd.hora_sobretiempo + hd.hora_inasistencia, asi_cod_usr, ls_tipo_doc
            from tt_rh_comp_horas_def hd 
            where hd.tipo_dia = 'S';
   end if;

   --trabajo en feriado
   if ani_feriado = 1 then
      insert into sobretiempo_turno (cod_trabajador, fec_movim, concep, horas_sobret, cod_usr, tipo_doc)
         select hd.cod_trabajador, hd.fecha, asi_concep_fer, hd.hora_normal + hd.hora_sobretiempo + hd.hora_inasistencia, asi_cod_usr, ls_tipo_doc
            from tt_rh_comp_horas_def hd 
            where hd.tipo_dia = 'F';
   end if;
         
   --dominical
   if ani_dominical = 1 then
      select count(*) * ln_horas_a_trabajar  --horas a trabajar en el periodo
         into ln_horas_laborables
         from tt_rh_comp_hora t
         where t.domingo = '0'
            and t.feriado = '0'
            and t.sabado = '0';

      for rs_lt in lc_trabajador loop

         ls_cod_trabajador := rs_lt.cod_trabajador;
      
         select nvl(sum(tch.hora_normal), 0)
            into ln_horas_trabajadas
            from tt_rh_comp_horas_def tch
            where tch.tipo_dia not in ('F', 'D');
      
         select (gdf.imp_gan_desc / ln_dias_periodo) / ln_horas_laborables -- pago por hora trabajada
            into ln_imp_gan_desc 
            from gan_desct_fijo gdf
            where gdf.cod_trabajador = ls_cod_trabajador
               and gdf.concep = ( select gc.concepto_gen 
                     from grupo_calculo gc 
                     where gc.grupo_calculo = ( select rc.remunerac_basica 
                           from rrhhparam_cconcep rc
                           where rc.reckey = '1' ) );
      
         if ln_horas_trabajadas >= ln_horas_laborables then
            ln_imp_var := ln_imp_gan_desc * ln_horas_laborables;
         else
            ln_imp_var := (ln_imp_gan_desc / ln_horas_trabajadas) * ln_horas_laborables;
         end if;
      
         if ln_imp_var > 0 then
            insert into gan_desct_variable (cod_trabajador, fec_movim, concep, imp_var, cod_usr, tipo_doc)
               values (ls_cod_trabajador, trunc(adi_fecha_proceso), asi_concep_dominical, ln_imp_var, asi_cod_usr, ls_tipo_doc);
         end if;
--         commit;
      end loop;
   end if;
commit;
end usp_rh_comp_horas;
/
