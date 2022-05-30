create or replace procedure usp_fin_actualiza_saldo_cp(
       asi_nada in varchar2
) is

  cursor c_datos is
    select cp.cod_relacion, cp.tipo_doc, cp.nro_doc, cp.tasa_cambio, cp.importe_doc, cp.cod_moneda,
           cp.flag_control_reg, cp.flag_provisionado, 
           'CP' as referencia
      from cntas_pagar cp
     where cp.flag_estado <> '0'
       and ((cp.flag_provisionado = 'D' and cp.flag_control_reg = '0') or (cp.flag_provisionado = 'R') )
    union
    select cri.proveedor as cod_relacion,
           'CRI' as tipo_doc,
           cri.nro_certificado as nro_doc,
           cri.tasa_cambio,
           cri.importe_doc,
           (select cod_soles from logparam where reckey = '1') as cod_moneda,
           '0' as flag_control_reg,
           'D' as flag_provisionado,
           'CRI' as referencia
      from retencion_igv_crt cri
     where cri.flag_estado <> '0'
  order by referencia, tipo_doc, nro_doc;
     
  cursor c_dpd_cxc is
    select cp.cod_relacion, cp.tipo_doc, cp.nro_doc, cp.tasa_cambio, cp.importe_doc, cp.cod_moneda,
           cp.flag_control_reg, cp.flag_provisionado, cp.flag_caja_bancos
      from cntas_pagar cp
     where cp.flag_estado <> '0'
       and ((cp.flag_provisionado = 'D' and cp.flag_control_reg = '1'))
  order by tipo_doc, nro_doc;

  cursor c_og_det (as_proveedor cntas_pagar.cod_relacion%TYPE, 
                   as_tipo_doc  cntas_pagar.tipo_doc%TYPE, 
                   as_nro_doc   cntas_pagar.nro_doc%TYPE) is  
    select s.tasa_cambio, s.cod_moneda, s.importe
      from solicitud_giro_liq_det s
     where s.proveedor = as_proveedor
       and s.tipo_doc  = as_tipo_doc
       and s.nro_doc   = as_nro_doc;
  
  cursor c_caja_bancos_det (as_proveedor cntas_pagar.cod_relacion%TYPE, 
                            as_tipo_doc  cntas_pagar.tipo_doc%TYPE, 
                            as_nro_doc   cntas_pagar.nro_doc%TYPE) is  
    select cb.fecha_emision, cb.nro_registro, cbd.cod_moneda, cb.flag_tiptran, cb.tasa_cambio,
           cbd.importe
    from caja_bancos_det cbd,
         caja_bancos     cb
    where cb.origen    = cbd.origen
      and cb.nro_registro  = cbd.nro_registro
      and cbd.cod_relacion = as_proveedor 
      and cbd.tipo_doc     = as_tipo_doc
      and cbd.nro_doc      = as_nro_doc
      and cb.flag_estado   <> '0'
      and ((cb.flag_tiptran= '3' and cbd.factor           = -1) 
        or (cb.flag_tiptran in ('2', '4') and cbd.factor  = 1) 
        or (cbd.tipo_doc in ('NCP', 'CNC') and cbd.factor = -1));

  cursor c_canje_documentos(as_proveedor cntas_pagar.cod_relacion%TYPE, 
                            as_tipo_doc  cntas_pagar.tipo_doc%TYPE, 
                            as_nro_doc   cntas_pagar.nro_doc%TYPE) is
    select cp.cod_moneda, dr.importe, cp.tasa_cambio
    from cntas_pagar cp,
         doc_referencias dr
    where cp.cod_relacion  = dr.proveedor_ref
      and cp.tipo_doc      = dr.tipo_ref
      and cp.nro_doc       = dr.nro_ref
      and dr.proveedor_ref = as_proveedor
      and dr.tipo_ref      = as_tipo_doc
      and dr.nro_ref       = as_nro_doc
      and cp.flag_estado   <> '0'
      and dr.tipo_mov      = 'P'
      and dr.flag_provisionado is not null;
        
  
  ln_saldo_sol            cntas_pagar.saldo_sol%TYPE;
  ln_saldo_dol            cntas_pagar.saldo_dol%TYPE;
  ln_imp_sol              cntas_pagar.saldo_sol%TYPE;
  ln_imp_dol              cntas_pagar.saldo_dol%TYPE;
  ls_soles                logparam.cod_soles%TYPE;
  ls_dolares              logparam.cod_dolares%TYPE;
  ls_flag_estado          cntas_pagar.flag_estado%TYPE;
  ls_flag_caja_bancos     cntas_pagar.flag_caja_bancos%TYPE;
  ls_flag_dh              doc_pendientes_cta_cte.flag_debhab%TYPE;
  ls_cnta_cntbl           doc_pendientes_cta_cte.cnta_ctbl%TYPE;
  ln_count                number;
  
begin
  
  select cod_soles, cod_dolares
    into ls_soles, ls_dolares 
    from logparam l
   where l.reckey = '1'; 

  for lc_reg in c_datos loop
      if lc_reg.cod_moneda = ls_soles then
         ln_saldo_sol := lc_reg.importe_doc;
         ln_saldo_dol := lc_reg.importe_doc / lc_reg.tasa_cambio;
      else
         ln_saldo_sol := lc_reg.importe_doc * lc_reg.tasa_cambio;
         ln_saldo_dol := lc_reg.importe_doc;
      end if;
      
      -- Detalle en Cartera de Pagos
      for lc_reg2 in c_caja_bancos_det(lc_reg.cod_relacion, lc_reg.tipo_doc, lc_reg.nro_doc) loop
          if lc_reg2.cod_moneda = ls_soles then
             ln_imp_sol := lc_reg2.importe;
             ln_imp_dol := lc_reg2.importe / lc_reg2.tasa_cambio;
          else
             ln_imp_sol := lc_reg2.importe * lc_reg2.tasa_cambio;
             ln_imp_dol := lc_reg2.importe;
          end if;
             
          ln_saldo_sol := ln_saldo_sol - ln_imp_sol;
          ln_saldo_dol := ln_saldo_dol - ln_imp_dol;
      end loop;
      
      if ln_saldo_sol < 0 then ln_saldo_sol := 0; end if;
      if ln_saldo_dol < 0 then ln_saldo_dol := 0; end if;
      
      -- detalle en Orden de Giro
      if ln_saldo_sol > 0 or ln_saldo_dol > 0 then
         for lc_reg2 in c_og_det(lc_reg.cod_relacion, lc_reg.tipo_doc, lc_reg.nro_doc) loop
             if lc_reg2.cod_moneda = ls_soles then
                ln_imp_sol := lc_reg2.importe;
                ln_imp_dol := lc_reg2.importe / lc_reg2.tasa_cambio;
             else
                ln_imp_sol := lc_reg2.importe * lc_reg2.tasa_cambio;
                ln_imp_dol := lc_reg2.importe;
             end if;
                 
             ln_saldo_sol := ln_saldo_sol - ln_imp_sol;
             ln_saldo_dol := ln_saldo_dol - ln_imp_dol;
         end loop;
         
         if ln_saldo_sol < 0 then ln_saldo_sol := 0; end if;
         if ln_saldo_dol < 0 then ln_saldo_dol := 0; end if;
      end if;
      
      -- detalle en Canje de Documentos
      if ln_saldo_sol > 0 or ln_saldo_dol > 0 then
         for lc_reg2 in c_canje_documentos(lc_reg.cod_relacion, lc_reg.tipo_doc, lc_reg.nro_doc) loop
             if lc_reg2.cod_moneda = ls_soles then
                ln_imp_sol := lc_reg2.importe;
                ln_imp_dol := lc_reg2.importe / lc_reg2.tasa_cambio;
             else
                ln_imp_sol := lc_reg2.importe * lc_reg2.tasa_cambio;
                ln_imp_dol := lc_reg2.importe;
             end if;
                 
             ln_saldo_sol := ln_saldo_sol - ln_imp_sol;
             ln_saldo_dol := ln_saldo_dol - ln_imp_dol;
         end loop;
         
         if ln_saldo_sol < 0 then ln_saldo_sol := 0; end if;
         if ln_saldo_dol < 0 then ln_saldo_dol := 0; end if;
      end if;
      
      -- Actualizo los datos en cntas_pagar
      if lc_reg.cod_moneda = ls_soles then
         if ln_saldo_sol = 0 then --pagado totalmente
            ls_flag_estado := '3' ;
         elsif lc_reg.importe_doc = ln_saldo_sol then --generado
            ls_flag_estado := '1';
         elsif ln_saldo_sol > 0 then    --pagado parcialmente
            ls_flag_estado := '2';
         end if ;
      end if;
          
      if lc_reg.cod_moneda = ls_dolares then
        if ln_saldo_dol = 0 then --pagado totalmente
           ls_flag_estado := '3' ;
        elsif lc_reg.importe_doc = ln_saldo_dol then --generado
           ls_flag_estado := '1';
        elsif ln_saldo_dol > 0 then    --pagado parcialmente
           ls_flag_estado := '2';
        end if ;
      end if;
      
      if lc_reg.referencia = 'CP' then 
         UPDATE cntas_pagar
            SET flag_estado = ls_flag_estado , 
                saldo_sol   = ln_saldo_sol,
                saldo_dol   = ln_saldo_dol,
                flag_replicacion = '0'
          WHERE cod_relacion = lc_reg.cod_relacion 
            AND tipo_doc     = lc_reg.tipo_doc  
            AND nro_doc      = lc_reg.nro_doc;
          
      elsif lc_reg.referencia = 'CRI' then
      
         UPDATE retencion_igv_crt cri
            SET flag_estado = ls_flag_estado , 
                saldo_sol   = ln_saldo_sol,
                saldo_dol   = ln_saldo_dol,
                flag_replicacion = '0'
          WHERE cri.nro_certificado = lc_reg.nro_doc;
      end if; 

      if (lc_reg.cod_moneda = ls_soles and ln_saldo_sol = 0) or (lc_reg.cod_moneda = ls_dolares and ln_saldo_dol = 0) then
         delete doc_pendientes_cta_cte d
          where d.cod_relacion = lc_reg.cod_relacion
            and d.tipo_doc     = lc_reg.tipo_doc
            and d.nro_doc      = lc_reg.nro_doc; 
      end if;
      
  end loop;
  

  -- ahora los documentos tipo DPD tipo cuenta corriente
  for lc_reg in c_dpd_cxc loop
      -- Saco lo que se ha pagado
      select nvl(sum(case when cb.cod_moneda = ls_soles then cbd.importe else cbd.importe / cb.tasa_cambio end),0),
             nvl(sum(case when cb.cod_moneda = ls_soles then cbd.importe * cb.tasa_cambio else cbd.importe end),0)
        into ln_saldo_sol, ln_saldo_dol
        from caja_bancos cb,
             caja_bancos_det cbd
       where cb.origen       = cbd.origen
         and cb.nro_registro = cbd.nro_registro
         and cb.flag_estado  <> '0'
         and cbd.cod_relacion = lc_Reg.Cod_Relacion
         and cbd.tipo_doc     = lc_reg.tipo_doc
         and cbd.nro_doc      = lc_reg.nro_doc
         and ((cb.flag_tiptran= '3' and cbd.factor           = -1) 
           or (cb.flag_tiptran in ('2', '4') and cbd.factor  = 1));
      
      -- Saco lo que se ha cobrado
      select nvl(sum(case when cb.cod_moneda = ls_soles then cbd.importe else cbd.importe / cb.tasa_cambio end),0),
             nvl(sum(case when cb.cod_moneda = ls_soles then cbd.importe * cb.tasa_cambio else cbd.importe end),0)
        into ln_imp_sol, ln_imp_dol
        from caja_bancos cb,
             caja_bancos_det cbd
       where cb.origen       = cbd.origen
         and cb.nro_registro = cbd.nro_registro
         and cb.flag_estado  <> '0'
         and cbd.cod_relacion = lc_Reg.Cod_Relacion
         and cbd.tipo_doc     = lc_reg.tipo_doc
         and cbd.nro_doc      = lc_reg.nro_doc
         and ((cb.flag_tiptran= '3' and cbd.factor           = 1) 
           or (cb.flag_tiptran in ('2', '4') and cbd.factor  = -1));
      
      --Actualizo ahora la cuenta contable
      if ln_saldo_sol > 0 or ln_saldo_dol > 0 then
         select count(*)
           into ln_count
           from cntbl_Asiento ca,
                cntbl_Asiento_det cad
          where ca.origen = cad.origen
            and ca.ano    = cad.ano
            and ca.mes    = cad.mes
            and ca.nro_libro = cad.nro_libro
            and ca.nro_asiento = cad.nro_asiento
            and ca.flag_estado <> '0'
            and cad.cod_relacion = lc_reg.cod_relacion
            and cad.tipo_docref1 = lc_reg.tipo_doc
            and cad.nro_docref1  = lc_reg.nro_doc
            and cad.flag_debhab  = 'D';             
         
         if ln_count > 0 then
            select min(cad.cnta_ctbl)
              into ls_cnta_cntbl
              from cntbl_Asiento ca,
                   cntbl_Asiento_det cad
             where ca.origen = cad.origen
               and ca.ano    = cad.ano
               and ca.mes    = cad.mes
               and ca.nro_libro = cad.nro_libro
               and ca.nro_asiento = cad.nro_asiento
               and ca.flag_estado <> '0'
               and cad.cod_relacion = lc_reg.cod_relacion
               and cad.tipo_docref1 = lc_reg.tipo_doc
               and cad.nro_docref1  = lc_reg.nro_doc;
              
         else
            ls_cnta_cntbl := null;
            
         end if;
         ls_flag_dh    := 'D';
         
      else
         ls_cnta_cntbl := null;
         ls_flag_dh    := 'H'; 
      end if;  
      
      if lc_reg.cod_moneda = ls_soles and ln_imp_sol > 0 or lc_reg.cod_moneda = ls_dolares and ln_imp_dol > 0 then
         ln_saldo_sol := ln_saldo_sol - ln_imp_sol;
         ln_saldo_dol := ln_saldo_dol - ln_imp_dol;
         
         if ln_saldo_sol < 0 then ln_saldo_sol := 0; end if;
         if ln_saldo_dol < 0 then ln_saldo_dol := 0; end if;
         
         ls_flag_caja_bancos := '1';
         
      elsif lc_reg.cod_moneda = ls_soles and ln_saldo_sol > 0 or lc_reg.cod_moneda = ls_dolares and ln_saldo_dol > 0 then

         ls_flag_caja_bancos := '1';
         
      else
        
         if lc_reg.cod_moneda = ls_soles then
            ln_saldo_sol := lc_reg.importe_doc;
            ln_saldo_dol := lc_reg.importe_doc / lc_reg.tasa_cambio;
         else
            ln_saldo_sol := lc_reg.importe_doc * lc_reg.tasa_cambio;
            ln_saldo_dol := lc_reg.importe_doc;
         end if;
      
         ls_flag_caja_bancos := '0';
         
      end if;   
      
      update cntas_pagar cp
         set cp.flag_caja_bancos = ls_flag_caja_bancos,
             cp.saldo_sol        = ln_saldo_sol,
             cp.saldo_dol        = ln_saldo_dol
       where cp.cod_relacion     = lc_reg.cod_relacion
         and cp.tipo_doc         = lc_reg.tipo_doc
         and cp.nro_doc          = lc_reg.nro_doc;
      
      update doc_pendientes_cta_cte t
         set t.cnta_ctbl = ls_cnta_cntbl,
             t.flag_debhab = ls_flag_dh
       where t.cod_relacion     = lc_reg.cod_relacion
         and t.tipo_doc         = lc_reg.tipo_doc
         and t.nro_doc          = lc_reg.nro_doc;
      
         
  end loop;
  
  commit;
  
end usp_fin_actualiza_saldo_cp;
/
