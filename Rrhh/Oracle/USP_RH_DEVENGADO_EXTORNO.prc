create or replace procedure USP_RH_DEVENGADO_EXTORNO (
       asi_origen       in origen.cod_origen%TYPE,
       ani_year         in number,
       ani_mes          in number,
       ani_nro_libro    in cntbl_libro.nro_libro%TYPE,
       asi_usuario      in usuario.cod_usr%TYPE
) is

--  Concepto de devengados, y extornos
cursor c_devengados is
  select a.reckey, a.descripcion, a.concep, a.grp_fijo, a.grp_variable, a.flag_tipo
    from devengado a
   order by a.reckey;

cursor c_detalle(ani_reckey devengado.reckey%TYPE) is
  select dc.tipo_trabajador, dc.cnta_cntbl, tt.libro_planilla, dc.trabajadores, tt.desc_tipo_tra,
         DC.CNTA_CNTBL_DEB
    from devengado_cnta dc,
         tipo_trabajador     tt
   where dc.reckey      = ani_reckey
     and dc.tipo_trabajador = tt.tipo_trabajador
  order by dc.tipo_trabajador;

/*
cursor c_asiento_det(ani_reckey      devengado.reckey%TYPE, 
                     an_nro_libro    cntbl_libro.nro_libro%TYPE, 
                     ani_mes         number, 
                     as_trabajadores devengado_cnta.trabajadores%TYPE) is
  select cad.cnta_ctbl, cad.cencos, cad.cod_relacion, cad.tipo_docref1, cad.nro_docref1, cad.centro_benef, cad.concep,
         nvl(sum(decode(cad.flag_debhab, 'D', cad.imp_movsol, 0)),0) as debe_sol,
         nvl(sum(decode(cad.flag_debhab, 'H', cad.imp_movsol, 0)),0) as haber_sol,
         nvl(sum(decode(cad.flag_debhab, 'D', cad.imp_movdol, 0)),0) as debe_dol,
         nvl(sum(decode(cad.flag_debhab, 'H', cad.imp_movdol, 0)),0) as haber_dol
    from cntbl_asiento_det cad,
         cntbl_Asiento     ca,
         devengado_extorno de
   where ca.origen         = cad.origen
     and ca.ano            = cad.ano
     and ca.mes            = cad.mes
     and ca.nro_libro      = cad.nro_libro
     and ca.nro_asiento    = cad.nro_asiento
     and ca.flag_estado    <> '0'
     and cad.concep        = de.concep
     and de.reckey         = ani_reckey
     and cad.origen        = asi_origen
     and cad.ano           = ani_year
     and cad.mes           = ani_mes
     and cad.nro_libro     = an_nro_libro
     and (as_trabajadores is null or (cad.cod_relacion = as_trabajadores and as_trabajadores is not null))
  group by cad.cnta_ctbl, cad.cencos, cad.cod_relacion, cad.tipo_docref1, cad.nro_docref1, cad.centro_benef,cad.concep
  order by cad.cnta_ctbl, cad.cencos, cad.cod_relacion, cad.tipo_docref1, cad.nro_docref1, cad.centro_benef; 
*/
  
cursor c_trabajadores(as_tipo_trabajador   tipo_trabajador.tipo_trabajador%TYPE,
                      an_mes               number,
                      as_trabajadores      devengado_cnta.trabajadores%TYPE) is
  select distinct hc.cod_trabajador,
         DECODE(hc.cencos, null, m.cencos, hc.cencos) as cencos,
         decode(hc.centro_benef, null, m.centro_benef, hc.centro_benef) as centro_benef,
         hc.tipo_trabajador
    from historico_calculo hc,
         maestro           m
   where hc.cod_trabajador = m.cod_trabajador
     and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
     and to_number(to_char(hc.fec_calc_plan, 'mm'))   = an_mes
     and hc.tipo_trabajador                           = as_tipo_trabajador
     and (as_trabajadores is null or (hc.cod_trabajador = as_trabajadores and as_trabajadores is not null))
order by cod_trabajador;
 

ln_imp_soles        historico_calculo.imp_soles%TYPE;
ln_imp_dolar        historico_calculo.imp_dolar%TYPE;  
ln_nro_provisional  cntbl_libro.num_provisional%TYPE;
ln_mes              number;
ld_fec_proceso      date;
ln_imp_fijo         number;
ln_imp_variable     number;
ls_cnta_cntbl_deb   cntbl_pre_asiento_det.cnta_ctbl%TYPE;
ln_count            number;
ln_gratificacion    historico_calculo.imp_soles%TYPE;


--Cntbl_pre_asiento
ls_glosa            cntbl_pre_asiento.desc_glosa%TYPE;
ln_tasa_cambio      cntbl_pre_asiento.tasa_cambio%TYPE;

-- cntbl_pre_asiento_det
ln_item             cntbl_pre_asiento_det.item%TYPE;
ln_tot_debe_sol     cntbl_pre_asiento_Det.imp_movsol%TYPE;
ln_tot_haber_sol    cntbl_pre_asiento_Det.imp_movsol%TYPE;
ln_tot_debe_dol     cntbl_pre_asiento_Det.imp_movdol%TYPE;
ln_tot_haber_dol    cntbl_pre_asiento_Det.imp_movdol%TYPE;
ls_flag_debhab      cntbl_pre_asiento_det.flag_debhab%TYPE;


begin

--  **************************************************************
--  ***   PROCESO PARA CALCULAS DEVENGADOS Y EXTORNOS   ***
--  **************************************************************

-- Obtengo el numerador del pre asiento
select NVL(cl.num_provisional,1)
  into ln_nro_provisional
  from cntbl_libro cl
 where cl.nro_libro = ani_nro_libro for update;

--Verifico si el nro de provsional ya existe
select count(*)
  into ln_count
  from cntbl_pre_asiento ca
 where ca.origen          = asi_origen
   and ca.nro_libro       = ani_nro_libro
   and ca.nro_provisional = ln_nro_provisional;

if ln_count > 0 then
   --En caso ya exista el provisional, entonces obtengo el ultimo y lo incremento en uno
   select max(ca.nro_provisional) + 1
     into ln_nro_provisional
     from cntbl_pre_asiento ca
    where ca.origen    = asi_origen
      and ca.nro_libro = ani_nro_libro;
end if;

FOR ln_mes IN 1..12 LOOP
  
    if to_Char(sysdate, 'yyyymm') < trim(to_char(ani_year, '0000')) || trim(to_char(ani_year, '00')) then
      exit;
    end if;
    
    if (ln_mes = ani_mes or ani_mes = -1) then
      
        -- Primero elimino todos los preasientos
        usp_sigre_cntbl.sp_delete_pre_asiento(asi_origen, ani_nro_libro, ani_year, ln_mes);

        -- Obtengo la fecha de proceso
        ld_fec_proceso := last_day(to_date('01/' || trim(to_char(ln_mes, '00')) || '/' || trim(to_char(ani_year, '0000')), 'dd/mm/yyyy'));
        
        if ld_fec_proceso > trunc(sysdate) then
           ld_Fec_proceso := trunc(sysdate);
        end if;
        
        -- Elimino el detalle del devengado por mes
        delete rh_devengados_mes t
         where t.ano = ani_year
           and t.mes = ln_mes;
        
        
        --RECUPERO TIPO DE CAMBIO DE ACUERDO A FECHA DE PROCESO
        ln_tasa_cambio := usf_fin_tasa_cambio(ld_fec_proceso) ;
             
        if ln_tasa_cambio = 0 then
           Raise_Application_Error(-20000,'Fecha de Proceso ' || to_char(ld_fec_proceso, 'dd/mm/yyyy') || ' no tiene tipo de Cambio ,Comuniquese con Contabilidad para que lo ingrese!') ;
        end if ;


        for lc_reg in c_devengados loop
            --  **************************************************************
            --  Calculo los importes de los extornos
            --  **************************************************************
            /*
            for lc_detalle in c_detalle(lc_reg.reckey) loop
                select count(*)
                  into ln_count
                  from devengado_cnta dc
                 where dc.reckey          = lc_reg.reckey
                   and dc.tipo_trabajador = lc_detalle.tipo_trabajador
                   and dc.trabajadores  is not null;
                
                if ln_count = 0 then
                   select NVL(sum(hc.imp_soles),0)
                     into ln_imp_soles
                     from historico_calculo hc,
                          devengado_extorno de
                    where hc.concep           = de.concep
                      and de.reckey           = lc_reg.reckey
                      and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
                      and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ln_mes;
                else
                   select NVL(sum(hc.imp_soles),0)
                     into ln_imp_soles
                     from historico_calculo hc,
                          devengado_extorno de
                    where hc.concep           = de.concep
                      and de.reckey           = lc_reg.reckey
                      and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
                      and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ln_mes
                      and hc.cod_trabajador                            = lc_detalle.trabajadores;
                end if;
                
                if ln_imp_soles > 0 then
                   -- Si hay importe entonces tengo que extornar
                   ls_glosa := substr('EXTORNO ' || lc_reg.descripcion || ' ' || lc_detalle.desc_tipo_tra || '. PERIODO: ' || trim(to_char(ani_year, '0000')) || '-' || trim(to_char(ln_mes, '00')) ,1,100);
                   -- Inserto la cabecera del pre asiento contable
                   Insert Into cntbl_pre_asiento(
                         origen     ,nro_libro  ,nro_provisional ,cod_moneda ,tasa_cambio ,
                         desc_glosa ,fec_cntbl  ,fec_registro    ,cod_usr    ,flag_estado ,
                         tot_soldeb ,tot_solhab ,tot_doldeb      ,tot_dolhab)
                   Values(
                         asi_origen   ,ani_nro_libro   ,ln_nro_provisional ,ls_soles    ,ln_tasa_cambio,
                         ls_glosa     ,ld_fec_proceso  , sysdate           ,asi_usuario ,'1'       ,
                         0.00         ,0.00            ,0.00               ,0.00);
                   
                   ln_item := 1;        
                   
                   ln_tot_haber_sol := 0; ln_tot_haber_dol := 0;
                   for lc_data in c_asiento_det(lc_reg.reckey, lc_detalle.libro_planilla, ln_mes, lc_detalle.trabajadores) loop         
                       ls_flag_debhab := 'H';
                           
                       if lc_data.debe_sol > lc_data.haber_sol then
                          ln_imp_soles   := lc_data.debe_sol - lc_data.haber_sol;
                          ln_imp_dolar   := lc_data.debe_dol - lc_data.haber_dol;
                       else
                          ln_imp_soles   := lc_data.haber_sol - lc_data.debe_sol;
                          ln_imp_dolar   := lc_data.haber_dol - lc_data.debe_dol;
                       end if;
                           
                       if ln_imp_soles > 0 or ln_imp_dolar > 0 then
                          ln_tot_haber_sol := ln_tot_haber_sol + ln_imp_soles;
                          ln_tot_haber_dol := ln_tot_haber_sol + ln_imp_dolar;
                              
                          Insert Into cntbl_pre_asiento_det   (
                                  origen      ,nro_libro ,nro_provisional   ,item        ,det_glosa ,flag_debhab ,
                                  cnta_ctbl   ,fec_cntbl   ,tipo_docref     ,nro_docref1 ,cencos    ,imp_movsol  ,
                                  imp_movdol  ,cod_relacion, centro_benef   ,concep )
                          Values(
                                  asi_origen        ,ani_nro_libro        ,ln_nro_provisional   ,ln_item              ,
                                  substr(ls_glosa || lc_detalle.desc_tipo_tra, 1, 60)          , 
                                  ls_flag_debhab ,
                                  lc_data.cnta_ctbl ,ld_fec_proceso       ,lc_data.tipo_docref1 ,lc_data.nro_docref1  ,lc_data.cencos ,ln_imp_soles   ,
                                  ln_imp_dolar      ,lc_data.cod_relacion ,lc_data.centro_benef , lc_data.concep );
                               
                           ln_item := ln_item + 1;
                       end if;
                   end loop;
                       
                   if ln_tot_haber_sol > 0 or ln_tot_haber_dol > 0 then
                       ls_flag_debhab := 'D';
                           
                       Insert Into cntbl_pre_asiento_det   (
                              origen      ,nro_libro ,nro_provisional   ,item        ,det_glosa ,flag_debhab ,
                              cnta_ctbl   ,fec_cntbl   ,tipo_docref     ,nro_docref1 ,cencos    ,imp_movsol  ,
                              imp_movdol  ,cod_relacion, centro_benef   ,concep )
                       Values(
                              asi_origen            ,ani_nro_libro        ,ln_nro_provisional   ,ln_item              ,
                              substr(ls_glosa || lc_detalle.desc_tipo_tra, 1, 60)       ,
                              ls_flag_debhab ,
                              lc_detalle.cnta_cntbl ,ld_fec_proceso       ,null                 ,null                 ,null           ,ln_tot_haber_sol   ,
                              ln_tot_haber_dol      ,null                 ,null                 ,lc_reg.concep );

                               
                       ln_item := ln_item + 1;
                   end if;
                       
                   -- Sumo el total del asiento
                   select nvl(sum(decode(cad.flag_debhab, 'D', cad.imp_movsol, 0)),0),
                          nvl(sum(decode(cad.flag_debhab, 'H', cad.imp_movsol, 0)),0),
                          nvl(sum(decode(cad.flag_debhab, 'D', cad.imp_movdol, 0)),0),
                          nvl(sum(decode(cad.flag_debhab, 'H', cad.imp_movdol, 0)),0)
                     into ln_tot_debe_sol, ln_tot_debe_dol, ln_tot_haber_sol, ln_tot_haber_dol
                     from cntbl_pre_asiento_det cad
                    where cad.origen            = asi_origen
                      and cad.nro_libro         = ani_nro_libro
                      and cad.nro_provisional   = ln_nro_provisional;
                      
                   update cntbl_pre_asiento ca
                      set ca.tot_soldeb     = ln_tot_debe_sol,
                          ca.tot_solhab     = ln_tot_haber_sol,
                          ca.tot_doldeb     = ln_tot_debe_dol,
                          ca.tot_dolhab     = ln_tot_haber_dol
                    where ca.origen            = asi_origen
                      and ca.nro_libro         = ani_nro_libro
                      and ca.nro_provisional   = ln_nro_provisional;
                          

                   -- Incremento el nro provisional
                   ln_nro_provisional := ln_nro_provisional + 1;

                end if;
            end loop;
            
            */
            
            --  **************************************************************
            --  Calculo de los devengados
            --  **************************************************************
            for lc_detalle in c_detalle(lc_reg.reckey) loop
                select count(*)
                  into ln_count
                  from devengado_cnta dc
                 where dc.reckey          = lc_reg.reckey
                   and dc.tipo_trabajador = lc_detalle.tipo_trabajador
                   and dc.trabajadores  is not null;
                   
                -- Sumo los fijos
                if lc_reg.grp_fijo is not null then
                   if ln_count = 0 then
                      select nvl(sum(hc.imp_soles), 0)
                        into ln_imp_fijo
                        from historico_calculo hc,
                             grupo_calculo_det gcd
                       where hc.concep           = gcd.concepto_calc
                         and gcd.grupo_calculo   = lc_reg.grp_fijo
                         and hc.tipo_trabajador  = lc_detalle.tipo_trabajador
                         and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
                         and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ln_mes;
                   else
                      select nvl(sum(hc.imp_soles), 0)
                       into ln_imp_fijo
                        from historico_calculo hc,
                             grupo_calculo_det gcd
                       where hc.concep           = gcd.concepto_calc
                         and gcd.grupo_calculo   = lc_reg.grp_fijo
                         and hc.tipo_trabajador  = lc_detalle.tipo_trabajador
                         and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
                         and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ln_mes
                         and hc.cod_trabajador   = lc_detalle.trabajadores;
                   end if;
                else
                   ln_imp_fijo := 0;
                end if;
                    
                -- Sumo los variables
                if lc_reg.grp_variable is not null then
                   if ln_count = 0 then
                      select nvl(sum(hc.imp_soles), 0)
                        into ln_imp_variable
                        from historico_calculo hc,
                             grupo_calculo_det gcd
                       where hc.concep           = gcd.concepto_calc
                         and gcd.grupo_calculo   = lc_reg.grp_variable
                         and hc.tipo_trabajador  = lc_detalle.tipo_trabajador
                         and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
                         and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ln_mes;
                   else
                     select nvl(sum(hc.imp_soles), 0)
                        into ln_imp_variable
                       from historico_calculo hc,
                             grupo_calculo_det gcd
                       where hc.concep           = gcd.concepto_calc
                         and gcd.grupo_calculo   = lc_reg.grp_variable
                         and hc.tipo_trabajador  = lc_detalle.tipo_trabajador
                         and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
                         and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ln_mes
                         and hc.cod_trabajador   = lc_detalle.trabajadores;
                   end if;
                else
                   ln_imp_variable := 0;
                end if;
                    
                if ln_imp_fijo + ln_imp_variable > 0 then
                   -- Si hay importe entonces tengo que extornar
                   ls_glosa := substr('DEVENGADO ' || lc_reg.descripcion || ' ' || lc_detalle.desc_tipo_tra || '. PERIODO: ' || trim(to_char(ani_year, '0000')) || '-' || trim(to_char(ln_mes, '00')) ,1,100);
                   -- Inserto la cabecera del pre asiento contable
                   Insert Into cntbl_pre_asiento(
                         origen     ,nro_libro  ,nro_provisional ,cod_moneda ,tasa_cambio ,
                         desc_glosa ,fec_cntbl  ,fec_registro    ,cod_usr    ,flag_estado ,
                         tot_soldeb ,tot_solhab ,tot_doldeb      ,tot_dolhab)
                   Values(
                         asi_origen   ,ani_nro_libro   ,ln_nro_provisional ,PKG_LOGISTICA.is_soles    ,ln_tasa_cambio,
                         ls_glosa     ,ld_fec_proceso  , sysdate           ,asi_usuario ,'1'       ,
                         0.00         ,0.00            ,0.00               ,0.00);
                   
                   -- Inicializo el item del detalle
                   ln_item := 1;        
                   
                   -- Encuentro la cuenta contable
                   if lc_reg.concep is not null then
                       -- Saco el concepto del amarre
                       select count(*)
                         into ln_count
                         from concepto_tip_trab_cnta t
                        where t.concep               = lc_reg.concep
                          and t.tipo_trabajador      = lc_detalle.tipo_trabajador;
                             
                       if ln_count > 0 then
                          select decode(t.cnta_cntbl_devengado, null, t.cnta_cntbl_haber, t.cnta_cntbl_devengado)
                            into ls_cnta_cntbl_deb
                            from concepto_tip_trab_cnta t
                           where t.concep               = lc_reg.concep
                             and t.tipo_trabajador      = lc_detalle.tipo_trabajador;
                       else
                          ls_cnta_cntbl_deb := lc_detalle.cnta_cntbl_deb;
                       end if;
                             
                   else
                      ls_cnta_cntbl_deb := lc_detalle.cnta_cntbl_deb;
                   end if;
                    
                   -- Inicializo los totales
                   ln_tot_debe_dol := 0; ln_tot_debe_sol := 0;
                    
                   -- Ahora inserto el detalle del asiento
                   for lc_trab in c_trabajadores(lc_detalle.tipo_trabajador, ln_mes, lc_detalle.trabajadores) loop
                       
                       -- Sumo los fijos y variables por cada trabajador
                       if lc_reg.grp_fijo is not null then
                          select nvl(sum(hc.imp_soles), 0)
                            into ln_imp_fijo
                            from historico_calculo hc,
                                 grupo_calculo_det gcd
                           where hc.concep           = gcd.concepto_calc
                             and gcd.grupo_calculo   = lc_reg.grp_fijo
                             and hc.cod_trabajador   = lc_trab.cod_trabajador
                             and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
                             and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ln_mes;
                       else
                          ln_imp_fijo := 0;
                       end if;
                           
                       -- Sumo los variables
                       if lc_reg.grp_variable is not null then
                          select nvl(sum(hc.imp_soles), 0)
                            into ln_imp_variable
                            from historico_calculo hc,
                                 grupo_calculo_det gcd
                           where hc.concep           = gcd.concepto_calc
                             and gcd.grupo_calculo   = lc_reg.grp_variable
                             and hc.cod_trabajador   = lc_trab.cod_trabajador
                             and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
                             and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ln_mes;
                       else
                          ln_imp_variable := 0;
                       end if;


                       if ln_imp_fijo + ln_imp_variable > 0 then
                         -- Formulas para el calculo
                         ------------------------------------------------------------------------------------
                          if lc_reg.flag_tipo = 'G' then
                            
                             ln_imp_soles := (ln_imp_fijo + ln_imp_variable ) / 6 ;
                             ln_gratificacion := 0;
                             --ln_imp_soles   := ln_imp_fijo / 12;
                             
                          elsif lc_reg.flag_tipo = 'V' then
                          
                             ln_imp_soles := (ln_imp_fijo + ln_imp_variable ) / 12 ;
                             ln_gratificacion := 0;
                             --ln_imp_soles := ln_imp_fijo / 12 ;
                             
                          elsif lc_reg.flag_tipo = 'C' then
                          
                             select nvl(sum(r.importe), 0)
                               into ln_gratificacion
                               from rh_devengados_mes r
                              where r.cod_trabajador   = lc_trab.cod_trabajador
                                and r.ano              = ani_year
                                and r.mes              = ln_mes
                                and r.tipo_devengado   = 'G';
                                
                             ln_imp_soles := (ln_imp_fijo + ln_imp_variable  + ln_gratificacion ) / 12 ;
                          else
                             ln_imp_soles := 0;
                          end if;
                          ---------------------------------------------------------------------------------------
                          
                          update rh_devengados_mes t
                             set t.parte_fija      = ln_imp_fijo,
                                 t.parte_variable  = ln_imp_variable,
                                 t.importe         = ln_imp_soles,
                                 t.gratificacion   = ln_gratificacion
                           where t.cod_trabajador  = lc_trab.cod_trabajador
                             and t.ano             = ani_year
                             and t.mes             = ln_mes
                             and t.tipo_devengado  = lc_reg.flag_tipo;
                          
                          if SQL%NOTFOUND then
                             insert into rh_devengados_mes(
                                    cod_trabajador, ano, mes, parte_fija, parte_variable, importe, tipo_devengado, 
                                    gratificacion, tipo_trabajador)
                             values(
                                    lc_trab.cod_trabajador, ani_year, ln_mes, ln_imp_fijo, ln_imp_variable, ln_imp_soles, lc_reg.flag_tipo, 
                                    ln_gratificacion, lc_trab.tipo_trabajador);
                          end if; 

                       end if;
                       
                       if ln_imp_soles > 0 then
                          ln_imp_dolar := ln_imp_soles / ln_tasa_cambio;
                          
                          ln_tot_debe_sol := ln_tot_debe_sol + ln_imp_soles;
                          ln_tot_debe_dol := ln_tot_debe_dol + ln_imp_dolar;
                          
                          
                          ls_flag_debhab := 'D';
                          
                          select count(*)
                            into ln_count
                            from historico_distrib_cntble hc
                           where hc.cod_trabajador = lc_trab.cod_trabajador
                             and to_number(to_char(hc.fec_calculo, 'yyyy')) = to_number(to_char(ld_fec_proceso, 'yyyy'))
                             and to_number(to_char(hc.fec_calculo, 'mm')) = to_number(to_char(ld_fec_proceso, 'mm'));
                          
                          if ln_count > 0 then
                             USP_SIGRE_RRHH.SP_RH_DISTRIBUCION_ASIENTOS(ld_fec_proceso         ,
                                                                        lc_trab.cod_trabajador ,
                                                                        asi_origen             ,
                                                                        ls_cnta_cntbl_deb          ,
                                                                        ls_flag_debhab         ,
                                                                        ln_imp_soles           ,
                                                                        ln_imp_dolar           ,
                                                                        null                   ,
                                                                        null                   ,
                                                                        ani_nro_libro          ,
                                                                        ls_glosa               ,
                                                                        ln_nro_provisional     ,
                                                                        ln_item                ,
                                                                        lc_reg.concep          ) ;
                          else
                             --INSERT ASIENTOS DETALLE
                             USP_SIGRE_RRHH.SP_RH_INSERT_ASIENTO(ld_fec_proceso         ,
                                                                 asi_origen             ,
                                                                 lc_trab.cencos         ,
                                                                 ls_cnta_cntbl_deb          ,
                                                                 null                   ,
                                                                 null                   ,
                                                                 lc_trab.cod_trabajador ,
                                                                 ls_flag_debhab         ,
                                                                 ani_nro_libro          ,
                                                                 ls_glosa               ,
                                                                 ln_item                ,
                                                                 ln_nro_provisional     ,
                                                                 ln_imp_soles           ,
                                                                 ln_imp_dolar           ,
                                                                 lc_reg.concep          ,
                                                                 lc_trab.centro_benef   , 
                                                                 lc_trab.cod_trabajador );
                          end if;
                       end if;
                   end loop;
                
                   -- ahora Inserto el haber
                   if ln_tot_debe_sol > 0 or ln_tot_debe_dol > 0 then
                       ls_flag_debhab := 'H';
                       
                       Insert Into cntbl_pre_asiento_det   (
                              origen      ,nro_libro ,nro_provisional   ,item        ,det_glosa ,flag_debhab ,
                              cnta_ctbl   ,fec_cntbl   ,tipo_docref     ,nro_docref1 ,cencos    ,imp_movsol  ,
                              imp_movdol  ,cod_relacion, centro_benef   ,concep )
                       Values(
                              asi_origen            ,ani_nro_libro        ,ln_nro_provisional   ,ln_item              ,
                              substr(ls_glosa, 1, 60)       ,
                              ls_flag_debhab ,
                              lc_detalle.cnta_cntbl ,ld_fec_proceso       ,null                 ,null                 ,null           ,ln_tot_debe_sol   ,
                              ln_tot_debe_dol      ,null                 ,null                 ,lc_reg.concep );

                           
                       ln_item := ln_item + 1;
                   end if;
                   
                   -- Sumo el total del asiento
                   select nvl(sum(decode(cad.flag_debhab, 'D', cad.imp_movsol, 0)),0),
                          nvl(sum(decode(cad.flag_debhab, 'H', cad.imp_movsol, 0)),0),
                          nvl(sum(decode(cad.flag_debhab, 'D', cad.imp_movdol, 0)),0),
                          nvl(sum(decode(cad.flag_debhab, 'H', cad.imp_movdol, 0)),0)
                     into ln_tot_debe_sol, ln_tot_debe_dol, ln_tot_haber_sol, ln_tot_haber_dol
                     from cntbl_pre_asiento_det cad
                    where cad.origen            = asi_origen
                      and cad.nro_libro         = ani_nro_libro
                      and cad.nro_provisional   = ln_nro_provisional;
                      
                   update cntbl_pre_asiento ca
                      set ca.tot_soldeb     = ln_tot_debe_sol,
                          ca.tot_solhab     = ln_tot_haber_sol,
                          ca.tot_doldeb     = ln_tot_debe_dol,
                          ca.tot_dolhab     = ln_tot_haber_dol
                    where ca.origen            = asi_origen
                      and ca.nro_libro         = ani_nro_libro
                      and ca.nro_provisional   = ln_nro_provisional;
                   
                   -- Incremento el numerador
                   ln_nro_provisional := ln_nro_provisional + 1;
                   
                end if;
            end loop;
        end loop;
    end if;
end loop;

-- Actualizo el numerador
update cntbl_libro cl
   set cl.num_provisional = ln_nro_provisional
 where cl.nro_libro = ani_nro_libro;
  
commit;
end USP_RH_DEVENGADO_EXTORNO ;
/
