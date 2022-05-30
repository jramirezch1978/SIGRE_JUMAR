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

ln_total_dist           distribucion_cntble.nro_horas%type    ;

ln_imp_sol              cntbl_Asiento_det.Imp_Movsol%TYPE;
ln_imp_dol              cntbl_asiento_det.imp_movdol%TYPE;
ln_tot_imp_sol          cntbl_asiento_det.imp_movsol%TYPE;
ln_tot_imp_dol          cntbl_asiento_det.imp_movdol%TYPE;


Cursor c_distribucion is
  select dc.cod_trabajador ,dc.cencos  ,dc.centro_benef, sum(dc.nro_horas) as nro_horas
    from distribucion_cntble dc ,
         maestro             m
   where dc.cod_trabajador     = m.cod_trabajador
     and dc.cod_trabajador     = asi_cod_trabajador
     and trunc(dc.fec_calculo) = trunc(adi_fec_proceso)
  group by dc.cod_trabajador ,dc.cencos  ,dc.centro_benef  
order by cencos, centro_benef;


Cursor c_hist_distribucion is
  select hc.cod_trabajador, hc.cencos, hc.centro_benef, sum(hc.nro_horas) as nro_horas
    from historico_distrib_cntble hc ,
         maestro                  m
   where hc.cod_trabajador     = m.cod_trabajador
     and hc.cod_trabajador     = asi_cod_trabajador
     and trunc(hc.fec_calculo) = trunc(adi_fec_proceso)
  group by hc.cod_trabajador, hc.cencos, hc.centro_benef  
order by cencos, centro_benef  ;


begin

  if asi_tipo_inf = 'C' then --calculo

     select Sum(dc.nro_horas)
       into ln_total_dist
       from distribucion_cntble dc
      where dc.cod_trabajador     = asi_cod_trabajador
        and trunc(dc.fec_calculo) = adi_fec_proceso
     group by dc.cod_trabajador ;


  elsif asi_tipo_inf = 'H' then --informacion historica

     select Sum(dc.nro_horas)
       into ln_total_dist
       from historico_distrib_cntble dc
      where dc.cod_trabajador     = asi_cod_trabajador
        and trunc(dc.fec_calculo) = adi_fec_proceso
     group by dc.cod_trabajador ;

  end if;

  --inicializar
  ln_tot_imp_sol := 0; ln_tot_imp_dol := 0;
  if ln_total_dist > 0 then
     if asi_tipo_inf = 'C' then

          For rc_dist in c_distribucion Loop --calculo

              ln_imp_sol := Round(ani_imp_movsol * rc_dist.nro_horas / ln_total_dist ,2) ;
              ln_imp_dol := Round(ani_imp_movdol * rc_dist.nro_horas / ln_total_dist ,2) ;

              if ln_tot_imp_sol + ln_imp_sol > ani_imp_movsol then
                 ln_imp_sol := ani_imp_movsol - ln_tot_imp_sol;
              end if;

              if ln_tot_imp_dol + ln_imp_dol > ani_imp_movdol then
                 ln_imp_dol := ani_imp_movdol - ln_tot_imp_dol;
              end if;

              --acumula porcentaje de participacion
              ln_tot_imp_sol := Nvl(ln_tot_imp_sol,0) + ln_imp_sol ;
              ln_tot_imp_dol := Nvl(ln_tot_imp_dol,0) + ln_imp_dol ;

              --INSERT ASIENTOS DETALLE
              USP_RH_INSERT_ASIENTO(adi_fec_proceso     ,asi_origen       ,rc_dist.cencos    ,asi_cnta_ctbl      ,
                                    asi_tipo_doc        ,asi_nro_doc      ,asi_cod_trabajador,asi_flag_ctrl_debh ,
                                    asi_flag_debhab     ,ani_nro_libro    ,asi_det_glosa     ,ani_item           ,
                                    ani_nro_provisional ,ln_imp_sol       ,ln_imp_dol        ,asi_concep         ,
                                    rc_dist.centro_benef, rc_dist.cod_trabajador);


          End Loop ;
     else
          For rc_hist_dist in c_hist_distribucion Loop --informacion historica
              
              /*Porcentaje de horas*/
              ln_imp_sol := Round(ani_imp_movsol * rc_hist_dist.nro_horas / ln_total_dist ,2) ;
              ln_imp_dol := Round(ani_imp_movdol * rc_hist_dist.nro_horas / ln_total_dist ,2) ;

              if ln_tot_imp_sol + ln_imp_sol > ani_imp_movsol then
                 ln_imp_sol := ani_imp_movsol - ln_tot_imp_sol;
              end if;

              if ln_tot_imp_dol + ln_imp_dol > ani_imp_movdol then
                 ln_imp_dol := ani_imp_movdol - ln_tot_imp_dol;
              end if;

              --acumula porcentaje de participacion
              ln_tot_imp_sol := Nvl(ln_tot_imp_sol,0) + ln_imp_sol ;
              ln_tot_imp_dol := Nvl(ln_tot_imp_dol,0) + ln_imp_dol ;

              --INSERT ASIENTOS DETALLE
              USP_RH_INSERT_ASIENTO(adi_fec_proceso     ,asi_origen    ,rc_hist_dist.cencos ,asi_cnta_ctbl      ,
                                    asi_tipo_doc        ,asi_nro_doc   ,asi_cod_trabajador   ,asi_flag_ctrl_debh ,
                                    asi_flag_debhab     ,ani_nro_libro ,asi_det_glosa       ,ani_item           ,
                                    ani_nro_provisional ,ln_imp_sol    ,ln_imp_dol           ,asi_concep         ,
                                    rc_hist_dist.centro_benef, rc_hist_dist.cod_trabajador);


          End Loop ;

     end if;
    
  end if;
  



  IF ln_tot_imp_sol <> ani_imp_movsol or ln_tot_imp_dol <> ani_imp_movdol THEN
    --HALLAR COSTO RESTANTE A CENTRO DE COSTO POR DEFECTO DE TRABAJADOR
    ln_imp_sol := Round(ani_imp_movsol - ln_tot_imp_sol,2) ;
    ln_imp_dol := Round(ani_imp_movdol - ln_tot_imp_dol,2) ;


    --INSERT ASIENTOS DETALLE
    USP_RH_INSERT_ASIENTO(adi_fec_proceso     ,asi_origen       ,asi_cencos         ,asi_cnta_ctbl      ,
                          asi_tipo_doc        ,asi_nro_doc      ,asi_cod_trabajador ,asi_flag_ctrl_debh ,
                          asi_flag_debhab     ,ani_nro_libro    ,asi_det_glosa     ,ani_item           ,
                          ani_nro_provisional ,ln_imp_sol       ,ln_imp_dol   ,asi_concep         ,
                          asi_centro_benef    , asi_cod_trabajador);

  END IF ;


end USP_RH_DISTRIBUCION_ASIENTOS;
/
