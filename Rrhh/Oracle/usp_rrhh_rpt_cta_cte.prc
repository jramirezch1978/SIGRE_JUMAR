create or replace procedure usp_rrhh_rpt_cta_cte
(ac_user     in usuario.cod_usr%type         ,
 ac_tipo_tra in maestro.tipo_trabajador%type ,
 ac_origen   in origen.cod_origen%type       ) is

Cursor c_cta_maestro is
  select m.cod_trabajador ,Nvl(m.apel_paterno,' ')||' '||Nvl(m.apel_paterno,'')||' '||Nvl(m.nombre1,'') as nombres,
         cc.cod_sit_prest ,cc.tipo_doc     ,cc.nro_doc      ,cc.fec_prestamo ,ccd.fec_dscto   ,
         cc.nro_cuotas    ,cc.mont_original ,cc.sldo_prestamo ,ccd.imp_dscto   ,cc.cod_moneda   ,
         cc.concep        ,m.cod_origen ,m.tipo_trabajador
  from maestro m ,cnta_crrte cc,cnta_crrte_detalle ccd
 where  (m.cod_trabajador  = cc.cod_trabajador  )  and
       ((cc.cod_trabajador = ccd.cod_trabajador )  and
        (cc.tipo_doc       = ccd.tipo_doc       )  and
        (cc.nro_doc        = ccd.nro_doc        )) and
        (m.tipo_trabajador like ac_tipo_tra     )  and
        (cc.cod_sit_prest  in ('A', 'S')        )  and
        (cc.flag_estado    = '1'                )  and
        (m.cod_origen      Like ac_origen       )    
order by m.cod_trabajador ,cc.fec_prestamo ,ccd.fec_dscto      ; 

ln_count Number ;

begin
  
       
For rc_cta in c_cta_maestro Loop      
    
    select count (*) into ln_count from tt_rrhh_cta_cte 
      where (cod_trabajador = rc_cta.cod_trabajador) and
            (tipo_doc       = rc_cta.tipo_doc      ) and
            (nro_doc        = rc_cta.nro_doc       ) ;  
    
    
    if ln_count = 0 then        
       --inserta registro maestro
       Insert Into tt_rrhh_cta_cte       
       (cod_trabajador ,nombres    ,cod_sit_prest  ,
        tipo_doc       ,nro_doc    ,fec_prestamo   ,
        fec_descto     ,nro_cuotas ,monto_original ,
        saldo_prestamo ,imp_dscto  ,moneda         ,
        concepto       ,cod_origen ,tipo_trabajador )
       Values
       (rc_cta.cod_trabajador  ,rc_cta.nombres       ,rc_cta.cod_sit_prest ,rc_cta.tipo_doc   ,
        rc_cta.nro_doc         ,rc_cta.fec_prestamo  ,rc_cta.fec_dscto     ,rc_cta.nro_cuotas ,
        rc_cta.mont_original   ,rc_cta.sldo_prestamo ,rc_cta.imp_dscto     ,rc_cta.cod_moneda ,
        rc_cta.concep          ,rc_cta.cod_origen    ,rc_cta.tipo_trabajador) ;
    else
    
       Update tt_rrhh_cta_cte
          set nro_cuotas = rc_cta.nro_cuotas,fec_descto = rc_cta.fec_dscto, saldo_prestamo = rc_cta.sldo_prestamo ,
              imp_dscto  = rc_cta.imp_dscto
        where (cod_trabajador = rc_cta.cod_trabajador) and
              (tipo_doc       = rc_cta.tipo_doc      ) and
              (nro_doc        = rc_cta.nro_doc       ) ;  
              
    End if ;

End Loop ;
       


                              

  
end usp_rrhh_rpt_cta_cte;
/
