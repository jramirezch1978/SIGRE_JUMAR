CREATE OR REPLACE TRIGGER "TEST1".tia_fin_cntas_cobrar
  after insert on cntas_cobrar
  for each row

declare
  -- local variables here
  lc_cnta_ctbl   cntbl_cnta.cnta_ctbl%type          ;
  lc_flag_debhab cntbl_asiento_det.flag_debhab%type ;
  ln_factor      doc_tipo.factor%type               ;
  ln_existe                                 integer ;
  lc_forma_pago       cntas_cobrar.forma_pago%type ; --- variable Forma de Pago
  ln_monto_cuota      rrhh_credito_solicitud.importe%type ; --- variable tasa de interes
  lc_concep           rrhh_credito_solicitud.concep%type ; --- variable concepto
  ln_nro_cuotas       rrhh_credito_solicitud.nro_cuotas%type ; --- variable nro de cuotas
  ln_tasa_interes     rrhh_credito_solicitud.tasa_interes%type ; --- variable tasa de interes
  ln_importe          rrhh_credito_solicitud.importe%type ; --- variable tasa de interes
  lc_nro_doc          rrhh_credito_solicitud.nro_solicitud%type ; --- variable numero doc


begin
  If (dbms_reputil.from_remote=true or dbms_snapshot.i_am_a_refresh=true) then
     return;
  end if;

select Nvl(factor,0) into ln_factor from doc_tipo where (tipo_doc = :new.tipo_doc) ;

if ln_factor = 0 then
   RAISE_APPLICATION_ERROR(-20000,'Factor de Documento '||:new.tipo_doc||' es igual a 0 debera Colocar Algun Valor 1 o -1');
end if ;

  --documento provisionado
IF :new.flag_provisionado = 'R' THEN
   --recupero cuenta contable de documento provisionado


  usp_fin_cntbl_asiento_det(:new.origen,:new.ano,:new.mes,:new.nro_libro,:new.nro_asiento,:new.tipo_doc,:new.nro_doc,:new.cod_relacion,lc_cnta_ctbl ,lc_flag_debhab);
   /*****************************************************************
        REPLICACION
   ****************************************************************/

   Insert into doc_pendientes_cta_cte
   (cod_relacion ,tipo_doc ,nro_doc  ,flag_tabla ,cnta_ctbl ,cod_moneda ,
    flag_debhab  ,sldo_sol ,saldo_dol,fecha_doc  ,factor    ,flag_replicacion,
    fecha_vencimiento)
   Values
   (:new.cod_relacion, :new.tipo_doc  ,:new.nro_doc  ,'1',lc_cnta_ctbl  ,:new.cod_moneda,
    lc_flag_debhab   , :new.saldo_sol ,:new.saldo_dol,:new.fecha_documento,ln_factor,'0',
    :new.fecha_vencimiento) ;

ELSIF :new.flag_provisionado = 'D' THEN -- DIRECTO NO PROVISIONADO

   if ln_factor = 1 then
      lc_flag_debhab := 'D' ;
   elsif ln_factor = -1 then
      lc_flag_debhab := 'H' ;
   end if ;

   /*****************************************************************
        REPLICACION
   ****************************************************************/
   Insert Into doc_pendientes_cta_cte
   (cod_relacion ,tipo_doc  ,nro_doc   ,flag_tabla ,cod_moneda ,flag_debhab ,
    sldo_sol     ,saldo_dol ,fecha_doc ,factor     , flag_replicacion,
    fecha_vencimiento)
   Values
   (:new.cod_relacion, :new.tipo_doc  ,:new.nro_doc  ,'1',:new.cod_moneda,
    lc_flag_debhab   , :new.saldo_sol ,:new.saldo_dol,:new.fecha_documento,ln_factor,'0',
    :new.fecha_vencimiento) ;

END IF;

--  Inicio de modificacion realizada por J. Farfán
-- ***************************************************************
-- ***  Genera cuenta corriente de las Factura & Boletas       ***
-- ***************************************************************

ln_existe:=0;

select count(*) into  ln_existe  from rrhh_credito_solicitud
 where (nro_solicitud = :new.nro_sol_cred_rrhh) and (flag_estado = '2')  and ( flag_tipo_solic_cred = 'C');

if ln_existe > 0 then
   --- Captura informacion de rrhh_credito_solicitud     
   select nro_solicitud, concep, nro_cuotas, tasa_interes, importe 
     into lc_nro_doc, lc_concep, ln_nro_cuotas, ln_tasa_interes, ln_importe 
     from rrhh_credito_solicitud
    where (nro_solicitud = :new.nro_sol_cred_rrhh) and (flag_estado = '2') and ( flag_tipo_solic_cred = 'C');

    ln_monto_cuota := Round(ln_importe / ln_nro_cuotas,2) ; -- variable donde se alla el monto de la cuota

    select f_pago_cnta_crte into lc_forma_pago from rrhhparam where reckey='1';
  if :new.importe_doc <= ln_importe then
      --- Inserta Cuenta Corriente del Trabajador
      insert into cnta_crrte 
                 (cod_trabajador, tipo_doc, nro_doc, fec_prestamo, concep, flag_estado,
                  nro_cuotas, mont_original, mont_cuota, sldo_prestamo, cod_sit_prest, cod_moneda, cod_usr, 
                  tasa_interes, forma_pago )
           values
                 (:new.cod_relacion, :new.tipo_doc, :new.nro_doc,  sysdate, lc_concep, '1', ln_nro_cuotas,
                  ln_importe, ln_monto_cuota, ln_importe, 'A', :new.cod_moneda, :new.cod_usr, ln_tasa_interes, lc_forma_pago ); 

           update rrhh_credito_solicitud  set flag_estado = '5' WHERE (nro_solicitud = lc_nro_doc);
   else
           Raise_application_error(-20001,' El importe de la Factura y/o Boleta  es Mayor al importe de la Solicitud de Credito' );  
   end if;
end if;

--  Fin de modificacion realizada por J. Farfán
end tia_fin_cntas_cobrar;
/
