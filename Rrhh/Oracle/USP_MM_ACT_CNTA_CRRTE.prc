create or replace procedure USP_MM_ACT_CNTA_CRRTE (
   as_nada in usuario.cod_usr%type) is 

CURSOR c_cnta_crte IS
select c.cod_trabajador, c.tipo_doc, c.nro_doc, c.cod_moneda, c.mont_original, c.sldo_prestamo, 
       c.flag_estado, sum(NVL(cd.imp_dscto,0)) as dcto
  from cnta_crrte c, cnta_crrte_detalle cd, proveedor p  
 where c.cod_trabajador = cd.cod_trabajador(+) and 
       c.tipo_doc = cd.tipo_doc(+) and 
       c.nro_doc = cd.nro_doc(+) and 
       --c.flag_estado = '1' and 
       c.cod_trabajador = p.proveedor --and 
      -- c.cod_trabajador = '30000002'
group by c.cod_trabajador, c.tipo_doc, c.nro_doc, c.cod_moneda, c.mont_original, c.sldo_prestamo, c.flag_estado  ;

ln_monto                   calculo.imp_soles%type ;
ln_count                   number ;

BEGIN

  -- Movimientos  
  FOR rc_cta in c_cnta_crte LOOP 
      
      -- Verifica si lo ha aplicado en el historico
      SELECT count(*) 
        INTO ln_count 
        FROM calculo c 
       WHERE c.cod_trabajador = rc_cta.cod_trabajador 
         AND c.tipo_doc_cc = rc_cta.tipo_doc 
         AND c.nro_doc_cc = rc_cta.nro_doc ; 
      
      IF ln_count > 0 THEN 
        SELECT DECODE(rc_cta.cod_moneda, 'S/.', NVL(c.imp_soles,0), NVL(c.imp_dolar,0) ) 
          INTO ln_monto 
          FROM calculo c 
         WHERE c.cod_trabajador = rc_cta.cod_trabajador 
           AND c.tipo_doc_cc = rc_cta.tipo_doc 
           AND c.nro_doc_cc = rc_cta.nro_doc ; 
      ELSE
         ln_monto := 0 ;
      END IF ;

      -- Actualiza saldo de cuenta corriente si saldo esta errado      
      IF rc_cta.sldo_prestamo <> (rc_cta.mont_original - NVL(rc_cta.dcto,0) + ln_monto) THEN
         UPDATE cnta_crrte c
           SET c.sldo_prestamo = rc_cta.mont_original - NVL(rc_cta.dcto,0) + ln_monto
         WHERE c.cod_trabajador = rc_cta.cod_trabajador and 
               c.tipo_doc = rc_cta.tipo_doc and 
               c.nro_doc = rc_cta.nro_doc ;
      END IF ;


  END LOOP;
  
  commit;  
  
END USP_MM_ACT_CNTA_CRRTE;
/
