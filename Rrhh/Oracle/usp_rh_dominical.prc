create or replace procedure usp_rh_dominical(
   asi_tipo_trabajador      in maestro.tipo_trabajador%TYPE,
   asi_usr                  in usuario.cod_usr%TYPE,
   asi_cod_origen           in origen.cod_origen%TYPE,
   ani_jornal               in number,
   adi_proceso              in date
) is
   ls_test1                 varchar2(100);

   ld_ini                   date;
   ld_fin                   date;

   ls_concep_dominical      concepto.concep%type;
   ls_concep_feriado        concepto.concep%TYPE;
   ls_tipo_doc              doc_tipo.tipo_doc%type;

   ln_valida                number;
   ln_asis_nor              number;
   ln_ganancia_fija         number;
   ln_ganancia_variable     number;
   ln_jornal                number;
   ln_dominical             number;
   ln_count                 number;
   
   ln_feriado               number;
   ln_dias_feriado          number;
   ln_dias_normales         number;
   ln_dias_domingo          number;
   ln_dias_pago_dominical   number;
   ln_pago                  number;

   cursor lc_trabajador is
      select distinct m.cod_trabajador, m.turno
        from maestro m
       where m.tipo_trabajador  = asi_tipo_trabajador
         and m.flag_cal_plnlla  = '1'
         and m.flag_estado      = '1'
         AND m.turno_asist IS NOT NULL
         --and m.turno is not null
         and m.cod_origen   = asi_cod_origen
       order by m.cod_trabajador;

BEGIN

     -- Verifica si tenemos fechas para procesar
    select count(*)
      into ln_valida
      from tt_rh_dominical trd;

   if ln_valida < 1 then
      RAISE_APPLICATION_ERROR(-20000, 'ORACLE: No se pudieron capturar las fechas del periodo a calcular');
      RETURN;    
   end if;

   -- inicio y fin del perdiodo
   select min(trd.dia), max(trd.dia)
     into ld_ini, ld_fin
     from tt_rh_dominical trd;

   if trunc(ld_fin) < trunc(ld_ini) then
      RAISE_APPLICATION_ERROR(-20000, 'ORACLE: La fecha final del rango debe ser mayor a la fecha inicial de ese rango');
      return;
   end if;
   
   if trunc(ld_fin) - trunc(ld_fin) + 1 > 7 then
      RAISE_APPLICATION_ERROR(-20000, 'ORACLE: El Rango de Fechas no puede ser mayor a 7 dias, Verificar por favor');
      return;
   end if;
   
   -- Numero de dias Feriados
   select count(*)
     into ln_dias_feriado
     from tt_rh_dominical t
    where NVL(t.flag_feriado, '0') = '1'
      and NVL(t.flag_domingo, '0') = '0';
   
   -- Numero de dias normales
   select count(*)
     into ln_dias_normales
     from tt_rh_dominical t
    where NVL(t.flag_feriado, '0') = '0'
      and NVL(t.flag_domingo, '0') = '0';

   -- Numero de dias dominicales 
   select count(*)
     into ln_dias_domingo
     from tt_rh_dominical t
    where NVL(t.flag_domingo, '0') = '1';    
      
   -- Numero de dias considerados para pago dominicales 
   select count(*)
     into ln_dias_pago_dominical 
     from tt_rh_dominical t
    where NVL(t.flag_calc_dominical, '0') = '1';    
      
   -- tipo de documento para dominical
   select rhp.doc_cmps
      into ls_tipo_doc
      from rrhhparam rhp
      where rhp.reckey = '1';

   if ls_tipo_doc is null then
      RAISE_APPLICATION_ERROR(-20000, 'ORACLE :  No existe el tipo de documento en los parámetros');
      return;
   end if;

   --concepto de dominical
   select gc.concepto_gen
     into ls_concep_dominical
     from grupo_calculo     gc,
          rrhhparam_cconcep rhc 
    where gc.grupo_calculo = rhc.concep_dominical
      and rhc.reckey = '1';

   if ls_concep_dominical is null then
      RAISE_APPLICATION_ERROR(-20000, 'ORACLE :  No existe concepto para generar el pago de dominical');
      return;
   end if;

   --concepto Feriado
   select gc.concepto_gen
     into ls_concep_feriado
     from grupo_calculo     gc,
          rrhhparam_cconcep rhc 
    where gc.grupo_calculo = rhc.hr_no_laborable
      and rhc.reckey = '1';

   if ls_concep_feriado is null then
      RAISE_APPLICATION_ERROR(-20000, 'ORACLE :  No existe concepto para generar el pago de Feriado');
      return;
   end if;
   
   --verificando que no existan registro de dominical para la fecha determianda
   select count(*)
     into ln_count
     from gan_desct_variable gdv,
          maestro            m 
    where gdv.cod_trabajador   = m.cod_trabajador
      and trunc(gdv.fec_movim) = trunc(adi_proceso)
      and m.tipo_trabajador    = asi_tipo_trabajador
      and m.flag_estado        = '1'
      and m.flag_cal_plnlla    = '1'
      and gdv.tipo_doc         = ls_tipo_doc
      and gdv.concep           = ls_concep_dominical
      and m.cod_origen         = asi_cod_origen      ;

   if ln_count > 0 then
      RAISE_APPLICATION_ERROR(-20000, 'ORACLE: Ya existen registros de D.S.O. reviértalos');
      return;
   end if;
   
   --verificando que no existan registro de Feriado para la fecha determianda
   select count(*)
     into ln_count
     from gan_desct_variable gdv,
          maestro            m 
    where gdv.cod_trabajador   = m.cod_trabajador
      and trunc(gdv.fec_movim) = trunc(adi_proceso)
      and m.tipo_trabajador    = asi_tipo_trabajador
      and m.flag_estado        = '1'
      and m.flag_cal_plnlla    = '1'
      and gdv.tipo_doc         = ls_tipo_doc
      and gdv.concep           = ls_concep_feriado;

   if ln_count > 0 then
      RAISE_APPLICATION_ERROR(-20000, 'ORACLE: Ya existen registros de feriado reviértalos');
      return;
   end if;

   -- barrido de trabajadores para un tipo de trabajador determinado
   for rs_ct in lc_trabajador loop

       if rs_ct.cod_trabajador = '10000122' or rs_ct.cod_trabajador = '10000184' then
          ls_test1 := 'Pendejos con 40 horas laboradas';
       end if;

       --importe fijo por concepto de dominical
       select NVL(sum(gdf.imp_gan_desc), 0)
         into ln_ganancia_fija
         from gan_desct_fijo gdf
        where gdf.cod_trabajador = rs_ct.cod_trabajador
          and gdf.flag_estado    = '1'
          and gdf.concep in ( select gcd.concepto_calc
                                from grupo_calculo_det gcd,
                                     rrhhparam_cconcep rhc 
                               where gcd.grupo_calculo = rhc.concep_dominical
                                 and rhc.reckey = '1');
       
       --importe variable por concepto de dominical
       select nvl(sum(gdv.imp_var), 0)
         into ln_ganancia_variable
         from gan_desct_variable gdv
        where gdv.cod_trabajador = rs_ct.cod_trabajador
          and trunc(gdv.fec_movim) between trunc(ld_ini) and trunc(ld_fin)
          and gdv.concep in ( select gcd.concepto_calc
                                from grupo_calculo_det gcd,
                                     rrhhparam_cconcep rhc 
                               where gcd.grupo_calculo = rhc.concep_dominical
                                 and rhc.reckey = '1');
      
      ln_ganancia_fija     := NVL(ln_ganancia_fija, 0);
      ln_ganancia_variable := NVL(ln_ganancia_variable,0);
      
      ln_pago := ln_ganancia_fija + ln_ganancia_variable;
                                
      if ani_jornal = 1 then
         -- Obtengo el Jornal de Pago
         ln_jornal := ln_pago /30;

         -- Calculo de dias asistidos en período seleccionado 
         select (a.fec_hasta - a.fec_desde) + 1 
           into ln_asis_nor
           from asistencia a
          where a.cod_trabajador = rs_ct.cod_trabajador
            and trunc(a.fec_desde) between trunc(ld_ini) and trunc(ld_fin);
         
          -- Calculo del dominical (se considera 1/6 del jornal por día).
         IF ln_asis_nor < ln_dias_pago_dominical THEN
            ln_dominical := ROUND( ln_asis_nor * ln_jornal / 6, 2 ) ;
         ELSE         
            ln_dominical := ROUND( ln_dias_pago_dominical * ln_jornal / 6, 2 ) ;
         END IF ;
         
      else
         --cálculo en base a dias de producción y cantidad producida
         if ln_ganancia_variable > 0 then
            ln_pago := ln_ganancia_fija/ 30 + ln_ganancia_variable;
            ln_dominical := ln_pago / ln_dias_normales;
         else
            ln_dominical := 0;
         end if;
      end if;
      
      --grabar importe de dominical (jornal o destajo)
      if ln_dominical > 0 then
         insert into gan_desct_variable (
                cod_trabajador, fec_movim, concep, imp_var, cod_usr, 
                tipo_doc, flag_replicacion)
         values(
                rs_ct.cod_trabajador, adi_proceso, ls_concep_dominical, ln_dominical, 
                asi_usr, ls_tipo_doc, '1');
      end if;
      
      -- Importe de feriado total, depende del numero de dias feriado
      ln_feriado   := ln_jornal * ln_dias_feriado;
      
      if ln_feriado > 0 then
         insert into gan_desct_variable (
                cod_trabajador, fec_movim, concep, imp_var, cod_usr, 
                tipo_doc, flag_replicacion)
         values(
                rs_ct.cod_trabajador, adi_proceso, ls_concep_feriado, ln_feriado, 
                asi_usr, ls_tipo_doc, '1');
      end if;

   end loop;
   
   commit;

end usp_rh_dominical;
/
