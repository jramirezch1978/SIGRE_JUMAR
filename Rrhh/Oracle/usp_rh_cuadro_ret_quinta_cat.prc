create or replace procedure usp_rh_cuadro_ret_quinta_cat(
       asi_codtra in maestro.cod_trabajador%type,
       ani_year   in number
) is

ln_cont          Number := 0 ;
ls_grc_quinta    grupo_calculo.grupo_calculo%TYPE := '805';

Cursor c_ing_ret_quinta is
  SELECT hc.cod_trabajador,   
         hc.concep,   
         c.desc_concep,   
         hc.imp_soles,   
         c.flag_rep_quinta,
         TO_CHAR(hc.fec_calc_plan,'YYYY') as ano,
         Decode(to_char(hc.fec_calc_plan,'MM'),'01','Enero',
                                               '02','Feberero',
                                               '03','Marzo',
                                               '04','Abril',
                                               '05','Mayo',
                                               '06','Junio',
                                               '07','Julio',
                                               '08','Agosto',
                                               '09','Setiembre',
                                               '10','Octubre',
                                               '11','Noviembre',
                                               '12','Diciembre') as mes
    FROM historico_calculo hc,   
         concepto          c  
   WHERE hc.concep = c.concep 
     and hc.cod_trabajador = asi_codtra 
     AND to_number(TO_CHAR(hc.fec_calc_plan,'yyyy')) = ani_year 
     AND Substr(hc.concep,1,1) = '1' 
     AND hc.concep not in (select r.cnc_total_ing 
                             from rrhhparam r 
                            where r.reckey = '1' )     
order by TO_CHAR(hc.fec_calc_plan,'yyyymm')         ;
         
Cursor c_egr_ret_quinta is
  SELECT hc.cod_trabajador,   
         hc.concep,   
         c.desc_concep,   
         hc.imp_soles,   
         c.flag_rep_quinta,
         TO_CHAR(hc.fec_calc_plan,'YYYY') as ano,
         Decode(to_char(hc.fec_calc_plan,'MM'),'01','Enero',
                                               '02','Feberero',
                                               '03','Marzo',
                                               '04','Abril',
                                               '05','Mayo',
                                               '06','Junio',
                                               '07','Julio',
                                               '08','Agosto',
                                               '09','Setiembre',
                                               '10','Octubre',
                                               '11','Noviembre',
                                               '12','Diciembre') as mes
    FROM historico_calculo hc,   
         concepto          c,
         grupo_calculo_det gcd  
   WHERE hc.concep         = c.concep 
     and hc.concep         = gcd.concepto_calc
     and hc.cod_trabajador = asi_codtra 
     and gcd.grupo_calculo = ls_grc_quinta
     AND to_number(TO_CHAR(hc.fec_calc_plan,'yyyy')) = ani_year 
order by TO_CHAR(hc.fec_calc_plan,'yyyymm')  ;         

begin

delete from rrhh_formato_quinta_cat dr
 where cod_trabajador = asi_codtra 
   and ano            = ani_year;

For rc_rq in c_ing_ret_quinta Loop

    if Nvl(rc_rq.flag_rep_quinta,'0') = '1' then
       ln_cont := ln_cont + 1 ;
       
       Insert Into rrhh_formato_quinta_cat(
              cod_trabajador       ,item       ,ano       ,columnas          ,
              valor                ,flag_grupo ,factor    ,tipo_concepto     )
       Values(
              rc_rq.cod_trabajador   ,ln_cont ,rc_rq.ano ,rc_rq.desc_concep ,
              Nvl(rc_rq.imp_soles,0) ,1       ,1         ,'1');
    else
       Update rrhh_formato_quinta_cat
          set valor = Nvl(valor,0) + Nvl(rc_rq.imp_soles,0)
        where cod_trabajador = rc_rq.cod_trabajador 
          and ano            = rc_rq.ano            
          and columnas       = rc_rq.mes            
          and flag_grupo     = 1;
   
       if sql%notfound then
          ln_cont := ln_cont + 1 ;
          
          Insert Into rrhh_formato_quinta_cat(
                 cod_trabajador         ,item       ,ano       ,columnas          ,
                 valor                  ,flag_grupo ,factor    ,tipo_concepto     )
          Values(
                 rc_rq.cod_trabajador   ,ln_cont    ,rc_rq.ano ,rc_rq.mes         ,
                 Nvl(rc_rq.imp_soles,0) ,1          ,1         ,'0');
          
       end if;
    end if;
End Loop ;
  
ln_cont := 0 ;

For rc_rqe in c_egr_ret_quinta Loop
    if Nvl(rc_rqe.flag_rep_quinta,'0') = '1' then
       ln_cont := ln_cont + 1 ;
       
       Insert Into rrhh_formato_quinta_cat(
              cod_trabajador         ,item       ,ano        ,columnas          ,
              valor                  ,flag_grupo ,factor     ,tipo_concepto     )
       Values(
              rc_rqe.cod_trabajador  ,ln_cont    ,rc_rqe.ano ,rc_rqe.desc_concep,
              Nvl(rc_rqe.imp_soles,0),3          ,-1         ,'1');
    else
       Update rrhh_formato_quinta_cat
          set valor = Nvl(valor,0) + Nvl(rc_rqe.imp_soles,0)
        where cod_trabajador = rc_rqe.cod_trabajador 
          and ano            = rc_rqe.ano            
          and columnas       = rc_rqe.mes            
          and flag_grupo     = 3;
   
       if sql%notfound then
          ln_cont := ln_cont + 1 ;
       
          Insert Into rrhh_formato_quinta_cat(
                 cod_trabajador         ,item       ,ano        ,columnas          ,
                 valor                  ,flag_grupo ,factor     ,tipo_concepto     )
          Values(
                 rc_rqe.cod_trabajador  ,ln_cont    ,rc_rqe.ano ,rc_rqe.mes        ,
                 Nvl(rc_rqe.imp_soles,0),3          ,-1         ,'0');
          
       end if;
    end if;
End Loop ;  

end usp_rh_cuadro_ret_quinta_cat;
/
