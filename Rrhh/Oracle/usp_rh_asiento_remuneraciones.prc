create or replace procedure usp_rh_asiento_remuneraciones(
       asi_ttrab       in maestro.tipo_trabajador%TYPE ,
       asi_origen      in origen.cod_origen%TYPE,
       asi_usuario     in usuario.cod_usr%TYPE         ,
       ani_year        in number,
       ani_mes         in number,
       asi_veda        in varchar2
) is

ls_cnta_debe       cntbl_cnta.cnta_ctbl%type    ;
ls_cnta_haber      cntbl_cnta.cnta_ctbl%type    ;
ls_tipo_doc        doc_tipo.tipo_doc%type       ;
ls_nro_doc         calculo.nro_doc_cc%type      ;
ls_cod_relacion    maestro.cod_trabajador%type  ;
ls_cencos          maestro.cencos%type          ;
ls_centro_benef    maestro.centro_benef%type    ;
ls_flag_ctrl_deb   Char(1)                      ;
ls_flag_dh         Char(1)                      ;
ln_count           Number                       ;
ln_count_doc       Number                       ;
ln_nro_libro       cntbl_libro.nro_libro%type   ;
ls_concepto_ing    concepto.concep%type         ;
ls_cnc_gan_fija    rrhhparam_cconcep.concep_gan_fij%TYPE;
ls_concepto_des    concepto.concep%type         ;
ls_concepto_apo    concepto.concep%type         ;
ln_tcambio         calendario.cmp_dol_libre%type;
ls_des_libro       cntbl_libro.desc_libro%type  ;
ln_num_provisional cntbl_libro.num_provisional%type ;
ln_item            cntbl_asiento_det.item%TYPE      ;
ls_grp_afp_jub     rrhhparam_cconcep.afp_jubilacion%type ;
ls_grp_afp_inv     rrhhparam_cconcep.afp_jubilacion%type ;
ls_grp_afp_com     rrhhparam_cconcep.afp_jubilacion%type ;
ls_concep_com      concepto.concep%Type                  ;
ls_concep_jub      concepto.concep%Type                  ;
ls_concep_inv      concepto.concep%Type                  ;
ls_concep_def      rrhhparam_cconcep.afect_ccosto_def%type ;
ln_count_gc        Number                                  ;
ln_tot_sum_soldeb  cntbl_asiento.tot_soldeb%TYPE;
ln_tot_sum_doldeb  cntbl_asiento.tot_solhab%TYPE;
ln_tot_sum_solhab  cntbl_asiento.tot_doldeb%TYPE;
ln_tot_sum_dolhab  cntbl_asiento.tot_dolhab%TYPE;

--hallar diferencias
ln_tot_dif_soldeb  Number(13,2);
ln_tot_dif_doldeb  Number(13,2);
ln_tot_dif_solhab  Number(13,2);
ln_tot_dif_dolhab  Number(13,2);

ln_saldo_soles     Number(13,2);
ln_saldo_dolares   Number(13,2);


--  Lectura del calculo de la planilla por trabajador
cursor c_detalle(adi_fec_proceso date) is
  select m.cod_trabajador   ,m.cencos            ,c.concep , c.imp_soles, c.imp_dolar,c.tipo_doc_cc, c.nro_doc_cc,
         ct.cnta_cntbl_debe ,ct.cnta_cntbl_haber ,ct.cnta_cntbl_debe_veda, m.cod_origen ,m.cod_afp,m.centro_benef,
         tt.flag_tabla_origen,
         c.fec_proceso,
         co.desc_concep,
         c.tipo_planilla,
         'C' as fuente
   from calculo                c,
        maestro                m,
        tipo_trabajador        tt,
        concepto_tip_trab_cnta ct,
        concepto               co
  where c.cod_trabajador     = m.cod_trabajador
    and c.concep             = ct.concep
    and co.concep            = c.concep
    and tt.tipo_trabajador   = m.tipo_trabajador
    and m.tipo_trabajador    = ct.tipo_trabajador
    and m.cod_origen         = ct.origen
    and m.tipo_trabajador    = asi_ttrab
    and m.cod_origen         = asi_origen
    and trunc(c.fec_proceso) = trunc(adi_fec_proceso)
    and nvl(c.imp_soles,0)   <> 0
    and c.concep             not in (ls_concepto_ing, ls_concepto_des, ls_concepto_apo)
  union
  select m.cod_trabajador   ,
         DECODE(hc.cencos, null, m.cencos, hc.cencos) as cencos,
         hc.concep , hc.imp_soles, hc.imp_dolar,
         hc.tipo_doc_cc, hc.nro_doc_cc,
         ct.cnta_cntbl_debe ,ct.cnta_cntbl_haber ,ct.cnta_cntbl_debe_veda, 
         m.cod_origen,
         hc.cod_afp,
         m.centro_benef,
         tt.flag_tabla_origen,
         hc.fec_calc_plan as fec_proceso,
         co.desc_concep,
         hc.tipo_planilla,
         'H' as fuente
   from historico_calculo      hc,
        maestro                m,
        tipo_trabajador        tt,
        concepto_tip_trab_cnta ct,
        concepto               co
  where hc.cod_trabajador       = m.cod_trabajador
    and hc.concep               = ct.concep
    and co.concep              = hc.concep
    and tt.tipo_trabajador     = hc.tipo_trabajador
    and hc.tipo_trabajador     = ct.tipo_trabajador
    and hc.cod_origen          = ct.origen    
    and hc.tipo_trabajador     = asi_ttrab
    and hc.cod_origen           = asi_origen
    and trunc(hc.fec_calc_plan) = trunc(adi_fec_proceso)
    and nvl(hc.imp_soles,0)    <> 0
    and hc.concep              not in (ls_concepto_ing,ls_concepto_des,ls_concepto_apo)
 order by concep, cod_trabajador;

-- cursor con las fechas de proceso
Cursor c_fechas is
  select distinct c.fec_proceso
   from calculo c,
        maestro m
  where c.cod_trabajador     = m.cod_trabajador
    and m.tipo_trabajador    = asi_ttrab
    and m.cod_origen         = asi_origen
    and to_number(to_char(c.fec_proceso, 'yyyy')) = ani_year
    and to_number(to_char(c.fec_proceso, 'mm'))   = ani_mes
    and nvl(c.imp_soles,0)   <> 0
union
  select distinct hc.fec_calc_plan
   from historico_calculo hc,
        maestro           m
  where hc.cod_trabajador       = m.cod_trabajador
    and hc.tipo_trabajador       = asi_ttrab
    and m.cod_origen            = asi_origen
    and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
    and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ani_mes
    and nvl(hc.imp_soles,0)     <> 0
order by fec_proceso;    


Cursor c_trabajadores is
  select distinct m.cod_trabajador
   from calculo c,
        maestro m
  where c.cod_trabajador     = m.cod_trabajador
    and m.tipo_trabajador    = asi_ttrab
    and m.cod_origen         = asi_origen
    and to_number(to_char(c.fec_proceso, 'yyyy')) = ani_year
    and to_number(to_char(c.fec_proceso, 'mm'))   = ani_mes
    and nvl(c.imp_soles,0)   <> 0
group by m.cod_trabajador
union
  select distinct m.cod_trabajador
   from historico_calculo hc,
        maestro           m
  where hc.cod_trabajador       = m.cod_trabajador
    and m.tipo_trabajador       = asi_ttrab
    and m.cod_origen            = asi_origen
    and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
    and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ani_mes
    and nvl(hc.imp_soles,0)     <> 0
group by m.cod_trabajador  ;

--Tabla temporal
Cursor c_ttemp (asi_cod_trab maestro.cod_trabajador%type) is
  select tt.flag_debhab,Sum(tt.imp_movsol) as imp_soles,Sum(tt.imp_movdol) as imp_dolares
    from tt_asiento_det tt
   where (tt.cod_trabajador = asi_cod_trab)
  group by tt.flag_debhab ;



begin

  --inicializacion
  ln_tot_sum_soldeb := 0.00 ;
  ln_tot_sum_doldeb := 0.00 ;
  ln_tot_sum_solhab := 0.00 ;
  ln_tot_sum_dolhab := 0.00 ;


  --vacaciones o dias feriados
  select rc.afect_ccosto_def, rc.concep_gan_fij
    into ls_concep_def, ls_cnc_gan_fija
    from rrhhparam_cconcep rc
   where reckey = '1' ;

  --conceptos de parametros
  select p.cnc_total_ing, p.cnc_total_dsct, p.cnc_total_aport
    into ls_concepto_ing, ls_concepto_des,  ls_concepto_apo
    from rrhhparam p
   where p.reckey = '1' ;

  --recupero de parametros grupos deconceptos de afp
  select rhc.afp_jubilacion,rhc.afp_invalidez,rhc.afp_comision
    into ls_grp_afp_jub,ls_grp_afp_inv,ls_grp_afp_com
    from rrhhparam_cconcep rhc
   where rhc.reckey = '1' ;

  --recupero conceptos de acuerdo a grupos de afp
  --jubilacion / invalidez / comision
  select gc.concepto_gen
    into ls_concep_jub
    from grupo_calculo gc
   where (gc.grupo_calculo = ls_grp_afp_jub)  ;

  select gc.concepto_gen
    into ls_concep_inv
    from grupo_calculo gc
   where (gc.grupo_calculo = ls_grp_afp_inv)  ;

  select gc.concepto_gen
    into ls_concep_com
    from grupo_calculo gc
   where (gc.grupo_calculo = ls_grp_afp_com)  ;


  --Recupero nro de libro por tipo de trbajador
  select t.libro_planilla ,cl.desc_libro 
    into ln_nro_libro ,ls_des_libro
    from tipo_trabajador t,
         cntbl_libro cl
   where t.libro_planilla  = cl.nro_libro (+)
     and t.tipo_trabajador = asi_ttrab ;

  if ln_nro_libro is null or ln_nro_libro = 0 then
     ROLLBACK;
     Raise_Application_Error(-20000,'Nro de Libro no esta Asignado al tipo de trabajador ,Comuniquese con RRHH!') ;
  end if ;

  if ls_des_libro is null then
     ROLLBACK;
     Raise_Application_Error(-20000,'Descripcion de Libro no existe ,Comuniquese con Contabilidad!') ;
  end if ;

  --  Elimino todos los preasientos de RRHH del periodo indicado
  USP_SIGRE_CNTBL.sp_delete_pre_asiento(asi_origen, ln_nro_libro, ani_year, ani_mes);


  for lc_reg in c_fechas loop
      
      --inserta asiento unico de cabecera, cada asiento tendra como fecha contable a la fecha de proceso
      select count(*)
        into ln_count
        from cntbl_pre_asiento p
       where p.origen           = asi_origen
         and p.nro_libro        = ln_nro_libro
         and trunc(p.fec_cntbl) = lc_reg.fec_proceso;
          
      if ln_count = 0 then
         -- Obtengo el siguiente numero provisional
         select num_provisional
           into ln_num_provisional
           from cntbl_libro cl
          where cl.nro_libro = ln_nro_libro for update;
          
         --RECUPERO TIPO DE CAMBIO DE ACUERDO A FECHA DE PROCESO
         ln_tcambio := usf_fin_tasa_cambio(lc_reg.fec_proceso) ;
         
         if ln_tcambio = 0 then
            Raise_Application_Error(-20000,'Fecha de Proceso ' || to_char(lc_reg.fec_proceso, 'dd/mm/yyyy') || ' no tiene tipo de Cambio ,Comuniquese con Contabilidad para que lo ingrese!') ;
         end if ;
         
         -- Evaluo si el numerador existe o no
         select count(*)
           into ln_count
           from cntbl_pre_asiento p
          where p.origen           = asi_origen
            and p.nro_libro        = ln_nro_libro
            and p.nro_provisional  = ln_num_provisional;
       
         while ln_count > 0 loop
           ln_num_provisional := ln_num_provisional + 1;
           -- Evaluo si el numerador existe o no
           select count(*)
             into ln_count
             from cntbl_pre_asiento p
            where p.origen           = asi_origen
              and p.nro_libro        = ln_nro_libro
              and p.nro_provisional  = ln_num_provisional;
           
         end loop;
             
         -- Inserto la cabecera del pre asiento contable
         Insert Into cntbl_pre_asiento(
                 origen     ,nro_libro  ,nro_provisional ,cod_moneda ,tasa_cambio ,
                 desc_glosa ,fec_cntbl  ,fec_registro    ,cod_usr    ,flag_estado ,
                 tot_soldeb ,tot_solhab ,tot_doldeb      ,tot_dolhab)
         Values(
                 asi_origen   ,ln_nro_libro       ,ln_num_provisional ,PKG_LOGISTICA.is_soles ,ln_tcambio,
                 ls_des_libro ,lc_reg.fec_proceso , sysdate           ,asi_usuario ,'1'       ,
                 0.00         ,0.00               ,0.00               ,0.00);
         
         -- actualizo el numerador
         update cntbl_libro cl
            set cl.num_provisional = ln_num_provisional + 1
          where cl.nro_libro       = ln_nro_libro;
              
         -- Reseteo el item
         ln_item := 0;
         
         -- Borro las tablas temmporales
         delete from tt_asiento_det ;
         delete from  TT_RH_INC_ASIENTOS ;
          
      else
        
         -- Obtengo el tipo de cambio y el numero provisional
         select p.nro_provisional, p.tasa_cambio
          into ln_num_provisional, ln_tcambio
          from cntbl_pre_asiento p
         where p.origen           = asi_origen
           and p.nro_libro        = ln_nro_libro
           and trunc(p.fec_cntbl) = lc_reg.fec_proceso for update;
         
         select nvl(max(p.item),0) 
           into ln_item
           from cntbl_pre_asiento_det p
          where p.origen          = asi_origen
            and p.nro_libro       = ln_nro_libro 
            and p.nro_provisional = ln_num_provisional;
      end if;
    
      For lc_data in c_detalle(lc_reg.fec_proceso) Loop

          ln_count_gc  := 0 ;
          ls_tipo_doc      := lc_data.tipo_doc_cc    ;
          ls_nro_doc       := lc_data.nro_doc_cc     ;
          ls_cod_relacion  := lc_data.cod_trabajador ;
          ls_cencos        := lc_data.cencos         ;
          ls_centro_benef  := lc_data.centro_benef   ;
          ls_flag_ctrl_deb := '1'                    ; --controlador en caso sean importes negativos 1 = positivo
                                                       --                                            0 = negativo
          ls_flag_dh := 'D' ;

          if lc_data.imp_soles < 0 and lc_data.imp_dolar < 0 then
             ls_flag_ctrl_deb := '0' ; --invertir  flag debhab
          end if ;

          if asi_veda = '1' then --trabajo con cntas contable de veda en caso seleccion sea (VEDA)
             ls_cnta_debe  := lc_data.cnta_cntbl_debe_veda ;
             ls_cnta_haber := lc_data.cnta_cntbl_haber ;
          else
             ls_cnta_debe  := lc_data.cnta_cntbl_debe  ;
             ls_cnta_haber := lc_data.cnta_cntbl_haber ;
          end if ;

          --verificar que sea concepto de afp para cambiar codigo de relacion
          if lc_data.concep in (ls_concep_jub, ls_concep_inv, ls_concep_com)    then
             --considerar codigo de relacion de afp
             --buscar codigo de relacion de afp
             select afp.cod_relacion
               into ls_cod_relacion
               from admin_afp afp
              where afp.cod_afp = lc_data.cod_afp ;

             if ((ls_cod_relacion Is Null) ) then
                Insert Into TT_RH_INC_ASIENTOS(
                       cod_trabajador ,obs)
                Values(
                       lc_data.cod_trabajador,'AFP ' || lc_data.cod_afp || ' no tiene codigo de relacion ,Revise Maestro ' ) ;
                Return ;
             end if ;


             select count(*) 
               into ln_count_doc
               from calc_doc_pagar_plla cdpp
              where cdpp.cod_origen         = asi_origen            
                and cdpp.tipo_trabajador    = asi_ttrab            
                and cdpp.cod_relacion       = ls_cod_relacion  
                and cdpp.tipo_planilla      = lc_data.tipo_planilla
                and cdpp.flag_estado        = '1'                  
                and trunc(cdpp.fec_proceso) = trunc(lc_reg.fec_proceso) ;

             if ln_count_doc > 0 then
                select cdpp.tipo_doc, cdpp.nro_doc 
                  into ls_tipo_doc,ls_nro_doc
                  from calc_doc_pagar_plla cdpp
                 where cdpp.cod_origen         = asi_origen            
                   and cdpp.tipo_trabajador    = asi_ttrab            
                   and cdpp.cod_relacion       = ls_cod_relacion   
                   and cdpp.tipo_planilla      = lc_data.tipo_planilla                      
                   and cdpp.flag_estado        = '1'              
                   and rownum                  = 1    
                   and trunc(cdpp.fec_proceso) = trunc(lc_reg.fec_proceso) ;
             end if;

          end if ;
          
          if lc_data.fuente = 'C' then
             select count(*)
               into ln_count
               from distribucion_cntble dc
              where dc.cod_trabajador     = lc_data.cod_trabajador 
                and trunc(dc.fec_calculo) = trunc(lc_reg.fec_proceso) ;
          else
             select count(*)
               into ln_count
               from historico_distrib_cntble dc
              where dc.cod_trabajador     = lc_data.cod_trabajador 
                and trunc(dc.fec_calculo) = trunc(lc_reg.fec_proceso) ;
          end if;
          
          --verificar concepto de pago vacaciones y feriados no hay distribucion
          select Count(*) 
            into ln_count_gc
            from grupo_calculo_det gcd
           where gcd.grupo_calculo = ls_concep_def 
             and gcd.concepto_calc = lc_data.concep ;

          /*if ln_count_gc > 0 then  --si es vacaciones no existe distribucion
             ln_count := 0 ;
          end if ;
          */
          
          if ls_nro_doc is null then
             ls_nro_doc := to_char(lc_reg.fec_proceso, 'yyyymmdd');
          end if;
          
          if ls_tipo_doc is null then
             ls_tipo_doc := 'PLLA';
          end if;


          if (ls_cnta_debe is not null ) then
             --PROCESO PARA CUENTA debe
             --verificar si cuenta contable es de gasto (verificar si tiene grupo contable y verifico si tiene distribucion)
             if ls_cnta_debe like '9%' then
                if ln_count > 0 then --realizo distribucion contable
                    /*
                    create or replace procedure USP_RH_DISTRIBUCION_ASIENTOS(
                           adi_fec_proceso     in     date                                   ,
                           asi_cod_trabajador  in     maestro.cod_trabajador%type            ,
                           asi_origen          in     origen.cod_origen%TYPE                 ,
                           asi_cnta_ctbl       in     cntbl_cnta.cnta_ctbl%type              ,
                           asi_flag_debhab     in     cntbl_asiento_det.flag_debhab%TYPE     ,
                           asi_flag_ctrl_debh  in     cntbl_asiento_det.flag_debhab%TYPE     ,
                           ani_imp_movsol      in     calculo.imp_soles%type                 ,
                           ani_imp_movdol      in     calculo.imp_soles%type                 ,
                           asi_tipo_doc        in     doc_tipo.tipo_doc%type                 ,
                           asi_nro_doc         in     calculo.nro_doc_cc%type                ,
                           ani_nro_libro       in     cntbl_libro.nro_libro%type             ,
                           asi_det_glosa       in     cntbl_pre_asiento_det.det_glosa%TYPE   ,
                           ani_nro_provisional in     cntbl_libro.num_provisional%type       ,
                           asi_cencos          in     centros_costo.cencos%type              ,
                           ani_item            in out cntbl_pre_asiento_det.item%type        ,
                           asi_tipo_inf        in     tipo_trabajador.flag_tabla_origen%TYPE ,
                           asi_concep          in     concepto.concep%type                   ,
                           asi_centro_benef    in     maestro.centro_benef%type              
                    ) is
                    */
                   USP_RH_DISTRIBUCION_ASIENTOS(lc_reg.fec_proceso     ,
                                                ls_cod_relacion        ,
                                                asi_origen             ,
                                                ls_cnta_debe           ,
                                                ls_flag_dh             ,
                                                ls_flag_ctrl_deb       ,
                                                Abs(lc_data.imp_soles) ,
                                                Abs(lc_data.imp_dolar) ,
                                                ls_tipo_doc            ,
                                                ls_nro_doc             ,
                                                ln_nro_libro           ,
                                                lc_data.concep || '-' || lc_data.desc_concep    ,
                                                ln_num_provisional     ,
                                                ls_cencos              ,
                                                ln_item                ,
                                                lc_data.fuente         ,
                                                lc_data.concep         ,
                                                ls_centro_benef        ) ;
                end if ;
             end if ;

             --no realizar este proceso si existe distribucion contable
             if ln_count = 0 or Substr(ls_cnta_debe,1,1) <> '9' then
                --INSERTA ASIENTO
                /*
                create or replace procedure USP_RH_INSERT_ASIENTO(
                       adi_fec_proceso    in date                                   ,
                       asi_origen         in origen.cod_origen%type                 ,
                       asi_cencos         in centros_costo.cencos%type              ,
                       asi_cnta_ctbl      in cntbl_cnta.cnta_ctbl%type              ,
                       asi_tipo_doc       in doc_tipo.tipo_doc%type                 ,
                       asi_nro_doc        in calculo.nro_doc_cc%type                ,
                       asi_cod_relacion   in cntbl_asiento_det.cod_relacion%TYPE   ,
                       asi_flag_ctrl_debh in cntbl_asiento_det.flag_debhab%TYPE     ,
                       asi_flag_debhab    in cntbl_asiento_det.flag_debhab%TYPE     ,
                       ani_nro_libro      in cntbl_libro.nro_libro%type             ,
                       asi_glosa_det      in cntbl_pre_asiento_det.det_glosa%TYPE   ,
                       ani_item           in out cntbl_pre_asiento_det.item%type    ,
                       ani_num_prov       in cntbl_libro.num_provisional%type       ,
                       ani_imp_soles      in cntbl_pre_asiento_det.imp_movsol%type  ,
                       ani_imp_dolares    in cntbl_pre_asiento_det.imp_movsol%type  ,
                       asi_concep         in concepto.concep%type                   ,
                       asi_cbenef         in maestro.centro_benef%type              ,
                       asi_cod_trabajador in maestro.cod_trabajador%TYPE
                ) is
                */
                USP_RH_INSERT_ASIENTO(lc_reg.fec_proceso     ,
                                      asi_origen             ,
                                      ls_cencos              ,
                                      ls_cnta_debe           ,
                                      ls_tipo_doc            ,
                                      ls_nro_doc             ,
                                      ls_cod_relacion        ,
                                      ls_flag_ctrl_deb       ,
                                      ls_flag_dh             ,
                                      ln_nro_libro           ,
                                      lc_data.concep || '-' || lc_data.desc_concep    ,
                                      ln_item                ,
                                      ln_num_provisional     ,
                                      Abs(lc_data.imp_soles) ,
                                      Abs(lc_data.imp_dolar) ,
                                      lc_data.concep         ,
                                      ls_centro_benef        , 
                                      lc_data.cod_trabajador );
              end if ;
          end if ;

           if (ls_cnta_haber is not null) then
              --PROCESO PARA CUENTA HABER
              --verificar si cuenta contable es de gasto (verificar si tiene grupo contable y verifico si tiene distribucion)
              ls_flag_dh := 'H' ;

              if Substr(ls_cnta_haber,1,1) = '9' then
                 if ln_count > 0 then --realizo distribucion contable
                    USP_RH_DISTRIBUCION_ASIENTOS(lc_reg.fec_proceso      ,
                                                 ls_cod_relacion         ,
                                                 asi_origen              ,
                                                 ls_cnta_haber           ,
                                                 ls_flag_dh              ,
                                                 ls_flag_ctrl_deb        ,
                                                 Abs(lc_data.imp_soles)  ,
                                                 Abs(lc_data.imp_dolar)  ,
                                                 ls_tipo_doc             ,
                                                 ls_nro_doc              ,
                                                 ln_nro_libro            ,
                                                 lc_data.concep || '-' || lc_data.desc_concep     ,
                                                 ln_num_provisional      ,
                                                 ls_cencos               ,
                                                 ln_item                 ,
                                                 lc_data.fuente         ,
                                                 lc_data.concep         ,
                                                 ls_centro_benef        ) ;

                 end if ;
              end if ;

              --no realizar este proceso si existe distribucion contable
              if ln_count = 0 or Substr(ls_cnta_haber,1,1) <> '9' then
                 --INSERTA ASIENTO
                 USP_RH_INSERT_ASIENTO(lc_reg.fec_proceso      ,
                                       asi_origen              ,
                                       ls_cencos               ,
                                       ls_cnta_haber           ,
                                       ls_tipo_doc             ,
                                       ls_nro_doc              ,
                                       ls_cod_relacion         ,
                                       ls_flag_ctrl_deb        ,
                                       ls_flag_dh              ,
                                       ln_nro_libro            ,
                                       lc_data.concep || '-' || lc_data.desc_concep     ,
                                       ln_item                 ,
                                       ln_num_provisional      ,
                                       Abs(lc_data.imp_soles)  ,
                                       Abs(lc_data.imp_dolar)  ,
                                       lc_data.concep         ,
                                       ls_centro_benef         , 
                                       lc_data.cod_trabajador);
              end if ;
           end if ;


      end loop;
      
      -- Valido el asiento
      For rc_trabajador in c_trabajadores Loop
          --cuadrar asientos descuadrados en el haber
          ln_tot_dif_soldeb := 0.00 ;
          ln_tot_dif_doldeb := 0.00 ;
          ln_tot_dif_solhab := 0.00 ;
          ln_tot_dif_dolhab := 0.00 ;

          For rc_ttemp in c_ttemp (rc_trabajador.cod_trabajador) Loop
              if rc_ttemp.flag_debhab = 'D' then
                 ln_tot_dif_soldeb := Nvl(rc_ttemp.imp_soles,0.00)   ;
                 ln_tot_dif_doldeb := Nvl(rc_ttemp.imp_dolares,0.00) ;
              elsif rc_ttemp.flag_debhab = 'H' then
                 ln_tot_dif_solhab := Nvl(rc_ttemp.imp_soles,0.00)   ;
                 ln_tot_dif_dolhab := Nvl(rc_ttemp.imp_dolares,0.00) ;
              end if ;
          End Loop ;

          ln_saldo_soles   := ln_tot_dif_solhab - ln_tot_dif_soldeb ;
          ln_saldo_dolares := ln_tot_dif_dolhab - ln_tot_dif_doldeb ;


          if abs(ln_saldo_soles) > 0.50 then  --enviar aviso
             raise_application_error(-20000,'Por Favor Revisar Conceptos de Pago no tienen Vinculacion de Cuentas Contables y Paartida Presupuestal - Trabajador '||rc_trabajador.cod_trabajador||' Diferencia : '||to_char(abs(ln_saldo_soles))  ) ;
          end if ;



          if ln_saldo_soles <> 0 then


             --incrementar diferencia en item de menor valor que se encuentre en el debe
             update cntbl_pre_asiento_det cad
                set cad.imp_movsol       = Nvl(cad.imp_movsol,0) + ln_saldo_soles
              where (cad.origen          = asi_origen          ) and
                    (cad.nro_libro       = ln_nro_libro       ) and
                    (cad.nro_provisional = ln_num_provisional ) and
                    (cad.flag_debhab     = 'D'                ) and
                    (cad.item            = (select Min(item) from cntbl_pre_asiento_det
                                             where (cad.origen          = asi_origen          ) and
                                                   (cad.nro_libro       = ln_nro_libro       ) and
                                                   (cad.nro_provisional = ln_num_provisional ) and
                                                   (cad.flag_debhab     = 'D'                ) )) ;

          end if ;

          if ln_saldo_dolares <> 0 then


             --incrementar diferencia en item de menor valor que se encuentre en el debe
             update cntbl_pre_asiento_det cad
                set cad.imp_movdol       = Nvl(cad.imp_movdol,0) + ln_saldo_dolares
              where (cad.origen          = asi_origen          ) and
                    (cad.nro_libro       = ln_nro_libro       ) and
                    (cad.nro_provisional = ln_num_provisional ) and
                    (cad.flag_debhab     = 'D'                ) and
                    (cad.item            = (select Min(item) from cntbl_pre_asiento_det
                                             where (cad.origen          = asi_origen          ) and
                                                   (cad.nro_libro       = ln_nro_libro       ) and
                                                   (cad.nro_provisional = ln_num_provisional ) and
                                                   (cad.flag_debhab     = 'D'                ) )) ;

          end if ;


      End Loop ;

      --INSERTA TOTALES DE ASIENTO
      --suma total de detalle del debe
      select Sum(cpad.imp_movsol),Sum(cpad.imp_movdol) 
        into ln_tot_sum_soldeb,ln_tot_sum_doldeb 
        from cntbl_pre_asiento_det cpad
       where (cpad.origen          = asi_origen         ) and
             (cpad.nro_libro       = ln_nro_libro      ) and
             (cpad.flag_debhab     = 'D'               ) and
             (cpad.nro_provisional = ln_num_provisional) ;



      --suma total de detalle del haber
      select Sum(cpad.imp_movsol),Sum(cpad.imp_movdol) 
        into ln_tot_sum_solhab,ln_tot_sum_dolhab 
        from cntbl_pre_asiento_det cpad
       where (cpad.origen          = asi_origen         ) and
             (cpad.nro_libro       = ln_nro_libro      ) and
             (cpad.flag_debhab     = 'H'               ) and
             (cpad.nro_provisional = ln_num_provisional) ;


      --Actualiza totales de asiento
      Update cntbl_pre_asiento cpa
        set cpa.tot_soldeb = ln_tot_sum_soldeb,
            cpa.tot_solhab = ln_tot_sum_solhab ,
            cpa.tot_doldeb = ln_tot_sum_doldeb,
            cpa.tot_dolhab = ln_tot_sum_dolhab
       where cpa.origen          = asi_origen         
         and cpa.nro_libro       = ln_nro_libro      
         and cpa.nro_provisional = ln_num_provisional;



  End Loop;

  commit;

end usp_rh_asiento_remuneraciones;
/
