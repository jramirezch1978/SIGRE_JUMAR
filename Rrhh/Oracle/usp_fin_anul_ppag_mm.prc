create or replace procedure usp_fin_anul_ppag
(ac_cod_usr      in usuario.cod_usr%type           ) is


Cursor c_prog_pago is
select ppd.nro_prog_pago, ppd.item, ppd.origen_caja, ppd.nro_reg_caja, cb.origen, cb.ano,
       cb.mes, cb.nro_libro, cb.nro_asiento, cb.reg_cheque
  from programacion_pagos_det ppd,caja_bancos cb,cheque_emitir ce,tt_fin_ppdd tt
 where (ppd.origen_caja   = cb.origen          ) and
       (ppd.nro_reg_caja  = cb.nro_registro    ) and
       (cb.reg_cheque     = ce.nro_registro (+)) and
       (ppd.flag_estado   = '2'                ) and
       (ppd.nro_prog_pago = tt.nro_prog_pago   ) and
       (ppd.item          = tt.item            ) ;

       
lc_nro_programa programacion_pagos.nro_prog_pago%Type ;       
       
begin


For rc_ppag in c_prog_pago Loop

    update retencion_igv_crt
       set flag_estado = '0',saldo_sol = 0.00,saldo_dol = 0.00
     where ((origen           = rc_ppag.origen_caja  ) and
            (nro_reg_caja_ban = rc_ppag.nro_reg_caja )) ;



    update cheque_emitir ce
       set ce.flag_estado = '0'
     where (ce.nro_registro = rc_ppag.reg_cheque );

    update caja_bancos cb
       set cb.imp_total   =  0.00  ,cb.flag_estado = '0'
     where (cb.origen       = rc_ppag.origen_caja  ) and
           (cb.nro_registro = rc_ppag.nro_reg_caja ) ;

    delete from caja_bancos_det cbd
     where (cbd.origen       = rc_ppag.origen_caja  ) and
           (cbd.nro_registro = rc_ppag.nro_reg_caja ) ;


    update cntbl_asiento_det cad
       set cad.imp_movsol = 0.00,cad.imp_movdol = 0.00
     where (cad.origen      = rc_ppag.origen      ) and
           (cad.ano         = rc_ppag.ano         ) and
           (cad.mes         = rc_ppag.mes         ) and
           (cad.nro_libro   = rc_ppag.nro_libro   ) and
           (cad.nro_asiento = rc_ppag.nro_asiento ) ;


    update cntbl_asiento ca
       set ca.tot_soldeb  = 0.00 ,ca.tot_solhab = 0.00,
           ca.tot_doldeb  = 0.00 ,ca.tot_dolhab = 0.00,
           ca.flag_estado = '0'
     where (ca.origen      = rc_ppag.origen      ) and
           (ca.ano         = rc_ppag.ano         ) and
           (ca.mes         = rc_ppag.mes         ) and
           (ca.nro_libro   = rc_ppag.nro_libro   ) and
           (ca.nro_asiento = rc_ppag.nro_asiento ) ;





     Insert into prog_pagos_desaprob
     (nro_prog_pago,fecha,org_caja_bancos,nro_caja_bancos,cod_usr)
     Values
     (rc_ppag.nro_prog_pago,sysdate,rc_ppag.origen_caja,rc_ppag.nro_reg_caja,ac_cod_usr );

     update programacion_pagos_det ppd
        set ppd.origen_caja = null ,ppd.nro_reg_caja = null,ppd.usr_aprueba = null,ppd.flag_estado ='1'
      where (ppd.nro_prog_pago = rc_ppag.nro_prog_pago ) and
            (ppd.item          = rc_ppag.item          ) ;
     
End Loop ;


select tt.nro_prog_pago into lc_nro_programa
  from tt_fin_ppdd tt
 group by tt.nro_prog_pago ;

--actualizacion  de programa de pagos cabecera
update programacion_pagos pp
   set pp.flag_estado = '1'
 where (pp.nro_prog_pago = lc_nro_programa) ;






end ;
/
