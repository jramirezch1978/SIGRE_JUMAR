create or replace procedure usp_fin_cpd_articulo_mov(
       asi_nada  in varchar2
) is

  ln_count       number;
  ls_org_am      articulo_mov.cod_origen%TYPE;
  ln_nro_am      articulo_mov.nro_mov%TYPE;

cursor c_Datos is
  select cp.cod_relacion, cpd.tipo_doc, cpd.nro_doc, cpd.item,
         cpd.org_amp_ref, cpd.nro_amp_ref, cpd.cantidad
    from cntas_pagar_det cpd,
         cntas_pagar     cp
   where cp.cod_relacion = cpd.cod_relacion
     and cp.tipo_doc     = cpd.tipo_doc
     and cp.nro_doc      = cpd.nro_doc
     and cpd.org_amp_ref is not null
     and cpd.nro_amp_ref is not null
     and cpd.org_am is null and cpd.nro_am is null
     and cp.flag_estado <> '0';   
  
begin
     
  for lc_reg in c_datos loop
      select count(*)
        into ln_count
        from articulo_mov am,
             vale_mov     vm,
             (select cod_origen as org_am, nro_mov as nro_am from articulo_mov where flag_estado <> '0'
               minus
              select org_am, nro_am from cntas_pagar_det cpd where cpd.org_am is not null and cpd.nro_am is not null) amd
      where am.nro_vale = vm.nro_vale
        and vm.flag_estado <> '0'
        and am.flag_estado <> '0'
        and am.origen_mov_proy = lc_reg.org_amp_ref
        and am.nro_mov_proy    = lc_reg.nro_amp_ref
        and am.cod_origen      = amd.org_am
        and am.nro_mov         = amd.nro_am
        and am.cant_procesada  = lc_reg.cantidad
        and vm.tipo_refer = (select doc_oc from logparam where reckey = '1');

      
      if ln_count = 1 then
        
          select am.cod_origen, am.nro_mov
            into ls_org_am, ln_nro_am
            from articulo_mov am,
                 vale_mov     vm,
                 (select cod_origen as org_am, nro_mov as nro_am from articulo_mov where flag_estado <> '0'
                   minus
                  select org_am, nro_am from cntas_pagar_det cpd where cpd.org_am is not null and cpd.nro_am is not null) amd
          where am.nro_vale = vm.nro_vale
            and vm.flag_estado <> '0'
            and am.flag_estado <> '0'
            and am.origen_mov_proy = lc_reg.org_amp_ref
            and am.nro_mov_proy    = lc_reg.nro_amp_ref
            and am.cod_origen      = amd.org_am
            and am.nro_mov         = amd.nro_am
            and am.cant_procesada  = lc_reg.cantidad
            and vm.tipo_refer = (select doc_oc from logparam where reckey = '1');
            
      elsif ln_count > 1 then
      
          select am.cod_origen, am.nro_mov
            into ls_org_am, ln_nro_am
            from articulo_mov am,
                 vale_mov     vm,
                 (select cod_origen as org_am, nro_mov as nro_am from articulo_mov where flag_estado <> '0'
                   minus
                  select org_am, nro_am from cntas_pagar_det cpd where cpd.org_am is not null and cpd.nro_am is not null) amd
          where am.nro_vale = vm.nro_vale
            and vm.flag_estado <> '0'
            and am.flag_estado <> '0'
            and am.origen_mov_proy = lc_reg.org_amp_ref
            and am.nro_mov_proy    = lc_reg.nro_amp_ref
            and am.cod_origen      = amd.org_am
            and am.nro_mov         = amd.nro_am
            and am.cant_procesada  = lc_reg.cantidad
            and rownum = 1
            and vm.tipo_refer = (select doc_oc from logparam where reckey = '1');

      else
         ls_org_am := null; 
         ln_nro_am := null;
      end if;
      
      if ls_org_am is not null and ln_nro_am is not null then
         update cntas_pagar_det cpd
            set cpd.org_am = ls_org_am,
                cpd.nro_am = ln_nro_am
          where cpd.cod_relacion = lc_reg.cod_relacion
            and cpd.tipo_doc     = lc_reg.tipo_doc
            and cpd.nro_doc      = lc_reg.nro_doc
            and cpd.item         = lc_reg.item;
            
      end if;
      
  end loop;

end usp_fin_cpd_articulo_mov;
/
