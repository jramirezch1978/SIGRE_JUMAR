create or replace procedure usp_rh_cal_pago_devengados (
  asi_codtra      in maestro.cod_trabajador%TYPE, 
  asi_codusr      in usuario.cod_usr%TYPE, 
  adi_fec_proceso in date,
  asi_doc_autom   in doc_tipo.tipo_doc%TYPE, 
  adi_fec_anterior in date 
) is

ls_grc_gratif     grupo_calculo.grupo_calculo%TYPE ;
ls_grc_remune     grupo_calculo.grupo_calculo%TYPE ;
ls_grc_racion     grupo_calculo.grupo_calculo%TYPE ;

ln_count          number ;
ls_grc_nivel      grupo_calculo.grupo_calculo%TYPE ;
ls_concepto       concepto.concep%TYPE ;
ln_gratif         number(13,2) ;
ln_remune         number(13,2) ;
ln_racion         number(13,2) ;
ln_deuda          number(13,2) ;
ln_tope           number(13,2) ;
ln_a_pagar        number(13,2) ;
ln_a_difere       number(13,2) ;
ln_a_pagar_acu    number(13,2) ;

--  Lectura por adelantos variables a cuenta de devengados
cursor c_devengados is
  select d.concep, d.fec_pago, d.importe
  from mov_devengado d
  where d.cod_trabajador = asi_codtra 
    and to_char(d.fec_pago,'mm/yyyy') = to_char(adi_fec_proceso,'mm/yyyy') ;

begin

--  ******************************************************
--  ***   REALIZA PAGO POR REMUNERACIONES DEVENGADAS   ***
--  ******************************************************

select c.gratific_deveng, c.remun_deveng, c.rac_azucar_deveng
  into ls_grc_gratif, ls_grc_remune, ls_grc_racion
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

select count(*) 
  into ln_count 
  from sldo_deveng sd
 where sd.cod_trabajador = asi_codtra 
   and sd.fec_proceso    = adi_fec_anterior ;

if ln_count > 0 then

   select nvl(sd.sldo_gratif_dev,0), nvl(sd.sldo_rem_dev,0), nvl(sd.sldo_racion,0)
     into ln_gratif, ln_remune, ln_racion
     from sldo_deveng sd
    where sd.cod_trabajador = asi_codtra 
      and sd.fec_proceso    = adi_fec_anterior ;

   ln_a_pagar_acu := 0 ;
   for x in 1 .. 3 loop
       if x = 1 then
          ln_deuda     := ln_remune ; 
          ls_grc_nivel := ls_grc_remune ;
       elsif x = 2 then
          ln_deuda     := ln_gratif ; 
          ls_grc_nivel := ls_grc_gratif ;
       elsif x = 3 then
          ln_deuda     := ln_racion ; 
          ls_grc_nivel := ls_grc_racion ;
       end if ;
       if ln_deuda > 0 then
          select g.concepto_gen, nvl(c.imp_tope_max,0)
            into ls_concepto, ln_tope 
            from grupo_calculo g, concepto c
           where g.grupo_calculo = ls_grc_nivel 
             and g.concepto_gen  = c.concep ;
          
          if ln_deuda >= ln_tope then
             ln_a_pagar := ln_tope ;
             if ln_a_pagar_acu < ln_tope then
                ln_a_pagar     := ln_tope - ln_a_pagar_acu ;
                ln_a_pagar_acu := ln_a_pagar_acu + ln_a_pagar ;
             else
                ln_a_pagar_acu := ln_a_pagar_acu + ln_a_pagar ;
             end if ;
          else
             ln_a_pagar := ln_deuda ;
             ln_a_pagar_acu := ln_a_pagar_acu + ln_a_pagar ;
             if ln_a_pagar_acu > ln_tope then
                ln_a_difere := ln_a_pagar_acu - ln_tope ;
                ln_a_pagar := ln_a_pagar - ln_a_difere ;
                if ln_a_pagar > 0 then
                   insert into gan_desct_variable (
                          cod_trabajador, fec_movim, concep, imp_var,
                          cod_usr, tipo_doc, flag_replicacion )
                   values (
                          asi_codtra, adi_fec_proceso, ls_concepto, ln_a_pagar,
                          asi_codusr, asi_doc_autom, '1' ) ;
                end if ;
             end if ;
          end if ;
          if ln_a_pagar_acu <= ln_tope then
             insert into gan_desct_variable (
                    cod_trabajador, fec_movim, concep, imp_var,
                    cod_usr, tipo_doc, flag_replicacion )
             values (
                    asi_codtra, adi_fec_proceso, ls_concepto, ln_a_pagar,
                    asi_codusr, asi_doc_autom, '1' ) ;
          end if ;
       end if ;
   end loop ;

   for rc_dev in c_devengados loop
       select count(*) 
         into ln_count 
         from gan_desct_variable v
        where v.cod_trabajador = asi_codtra 
          and v.concep         = rc_dev.concep 
          and trunc(v.fec_movim) = trunc(rc_dev.fec_pago) ;
       
       if ln_count > 0 then
          update gan_desct_variable
             set imp_var = imp_var + nvl(rc_dev.importe,0),
                 flag_replicacion = '1'
           where cod_trabajador = asi_codtra 
             and concep         = rc_dev.concep 
             and trunc(fec_movim) = trunc(rc_dev.fec_pago) ;
       else
          insert into gan_desct_variable (
                 cod_trabajador, fec_movim, concep, imp_var,
                 cod_usr, tipo_doc, flag_replicacion )
          values (
                 asi_codtra , trunc(rc_dev.fec_pago), rc_dev.concep, nvl(rc_dev.importe,0),
                 asi_codusr, asi_doc_autom, '1' ) ;
       end if ;
   end loop ;

end if ;

end usp_rh_cal_pago_devengados ;
/
