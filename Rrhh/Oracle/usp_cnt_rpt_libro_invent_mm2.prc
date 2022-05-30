CREATE OR REPLACE PROCEDURE usp_cnt_rpt_libro_invent_mm2 (
  an_ano in cntbl_asiento.ano%type,
  an_mes in cntbl_asiento.mes%type) IS

ln_ano_ant              number(4)     ;
ln_mes_ant              number(2)     ;
ld_fecha_ini            date          ;
ld_fecha_fin            date          ;
ln_flag_existe          integer       ;
ln_existe_ini           integer       ;
ln_contador             integer       ;
ln_cant_fin             number(15,3)  ;
ln_cant_ini             number(15,3)  ;
lc_articulo             char(12)      ;
lc_desc_articulo        VARCHAR2(400) ;
lc_unidad               char(3)   ;
lc_categoria            char(6)   ;
lc_desc_categoria       char(60)  ;
lc_subcategoria         char(6)   ;
lc_desc_subcategoria    char(60)  ;
lc_cencos               char(10)  ;
lc_nro_vale             char(10)  ;
ld_registro             date      ;
lc_tipo_mov             char(6)   ;
ln_ingresos             number(13,2) ;
ln_egresos              number(13,2) ;
ln_precio_uni           number(13,2) ;
ln_precio_promedio      number(13,3) ;
ln_sldo_inicial         number(13,2) ;
ln_sldo_final           number(13,2) ;
ln_valor_inicial        number(13,2) ;
ln_valor_final          number(13,2) ;
lc_almacen              char(6)      ;
lc_desc_almacen         char(60)     ;
  

CURSOR c_almacen is 
SELECT distinct(almacen) as cod_almacen
  FROM tt_cntbl_almacen ;

CURSOR c_articulo is 
select distinct(cod_art) as cod_artic
FROM tt_cntbl_articulo
order by cod_art ;



CURSOR c_calculo is 
SELECT registro as registro,
       articulo as articulo, 
       almacen as almacen,
       nro_vale as vale,
       ingreso  as ingreso,
       salida as salida
  FROM tt_cntbl_inventario_calculo
order by registro ;

begin

DELETE FROM tt_cntbl_almacen ;
DELETE FROM tt_cntbl_articulo ;
DELETE FROM tt_cntbl_libro_inventario ;

INSERT INTO tt_cntbl_almacen (ALMACEN)
SELECT distinct(almacen)
  FROM articulo_saldo_mensual
  where ano= an_ano and mes = an_mes ;
  
  
For c_al in c_almacen loop
  
INSERT INTO tt_cntbl_articulo
SELECT distinct(cod_art)
  FROM articulo_saldo_mensual
 where ano= an_ano and mes = an_mes and
       almacen = c_al.cod_almacen;
  

ld_fecha_ini := trunc(to_date( '01/'|| to_char(an_mes,'99') ||'/'|| to_char(an_ano,'9999') ,'dd/mm/yyyy'));
ld_fecha_fin := trunc( last_day(ld_fecha_ini) ) + 0.999 ;

ln_ano_ant := an_ano ;
ln_mes_ant := an_mes - 1;

            
    For c_a in c_articulo loop

          SELECT count(am.cod_art) into ln_existe_ini
            FROM vale_mov vm, articulo_mov am, almacen a, articulo_mov_tipo amv, 
                 articulo ar , articulo_sub_categ asct, articulo_categ ac
           WHERE vm.cod_origen = am.cod_origen and
                 vm.nro_vale = am.nro_vale and
                 vm.almacen = a.almacen and
                 vm.tipo_mov = amv.tipo_mov and
                 am.cod_art= ar.cod_art AND
                 ar.sub_cat_art = asct.cod_sub_cat AND
                 asct.cat_art = ac.cat_art and
                (vm.fec_registro BETWEEN ld_fecha_ini and ld_fecha_fin) and
                 vm.flag_estado <> '0' and
                 am.cod_art = c_a.cod_artic and
                 vm.almacen = c_al.cod_almacen and
                 am.flag_estado <> '0' AND
                 a.flag_tipo_almacen = 'M'
        ORDER BY vm.fec_registro, vm.tipo_mov ;

     if ln_existe_ini > 0 then

     
          INSERT INTO tt_cntbl_inventario_calculo (articulo,desc_articulo, unidad, almacen, desc_almacen, subcategoria,
                                                   desc_subcategoria ,categoria,desc_categoria,
                                                   cencos,nro_vale,registro, tipo_mov,salida,ingreso, precio_uni)
          SELECT am.cod_art,ar.desc_art, ar.und, vm.almacen,a.desc_almacen,
                 ar.sub_cat_art, asct.desc_sub_cat, asct.cat_art, ac.desc_categoria,
                 am.cencos, vm.nro_vale, vm.fec_registro, vm.tipo_mov, 
                 decode(amv.factor_sldo_total,-1, nvl(am.cant_procesada,0),0) as Cantidad_Egreso, 
                 decode(amv.factor_sldo_total,1, nvl(am.cant_procesada,0),0) as Cantidad_Ingreso, 
                 am.precio_unit 
            FROM vale_mov vm, articulo_mov am, almacen a, articulo_mov_tipo amv, 
                 articulo ar , articulo_sub_categ asct, articulo_categ ac
           WHERE vm.cod_origen = am.cod_origen and
                 vm.nro_vale = am.nro_vale and
                 vm.almacen = a.almacen and
                 vm.tipo_mov = amv.tipo_mov and
                 am.cod_art= ar.cod_art AND
                 ar.sub_cat_art = asct.cod_sub_cat AND
                 asct.cat_art = ac.cat_art and
                (vm.fec_registro BETWEEN ld_fecha_ini and ld_fecha_fin) and
                 vm.flag_estado <> '0' and
                 am.cod_art = c_a.cod_artic and
                 vm.almacen = c_al.cod_almacen and
                 am.flag_estado <> '0' AND
                 a.flag_tipo_almacen = 'M'
        ORDER BY vm.fec_registro, vm.tipo_mov ;
        
------ Calcula saldo iniciales y finales por movimiento
          
        For c_inv in c_calculo  loop
          
      --**************** CAPTURA LOS SALDO INICIALES************--


          SELECT count(*) into ln_flag_existe
            FROM articulo_saldo_mensual 
           WHERE ano= ln_ano_ant and
                 mes= ln_mes_ant and
                 cod_art = c_a.cod_artic and
                 almacen = c_al.cod_almacen ;

         if ln_flag_existe > 0 then
          
          SELECT sldo_total, valor_saldo_total
            into ln_sldo_inicial, ln_valor_inicial
            FROM articulo_saldo_mensual 
           WHERE ano= ln_ano_ant and
                 mes= ln_mes_ant and
                 cod_art = c_a.cod_artic and
                 almacen = c_al.cod_almacen ;
                 
          SELECT precio_prom_sol
            into ln_precio_promedio
            FROM articulo_saldo_mensual 
           WHERE ano= an_ano and
                 mes= an_mes and
                 cod_art = c_a.cod_artic and
                 almacen = c_al.cod_almacen ;
          else
           ln_sldo_inicial := 0 ;
           ln_valor_inicial :=0 ;
          end if ;

                  
             if ln_contador < 1 then
               ln_contador := 0 ;
               ln_cant_fin := ((ln_sldo_inicial + c_inv.ingreso) - c_inv.salida) ;
               ln_cant_ini := (ln_cant_fin - c_inv.ingreso) + c_inv.salida ;
          
               update tt_cntbl_inventario_calculo
                  Set SLDO_FINAL = ln_cant_fin,
                      VALOR_FINAL = ln_cant_fin * ln_precio_promedio ,
                      SLDO_INICIAL = ln_cant_ini , 
                      VALOR_INICIAL = ln_cant_ini * ln_precio_promedio
                WHERE almacen = c_inv.almacen and 
                      articulo = c_inv.articulo and
                      registro = c_inv.registro and
                      nro_vale = c_inv.vale and
                      ingreso = c_inv.ingreso and
                      salida = c_inv.salida;
             end if;
                ln_contador :=  ln_contador + 1  ;      
          
          if ln_contador > 1 then

               ln_cant_fin := ((ln_cant_fin + c_inv.ingreso) - c_inv.salida) ;
               ln_cant_ini := (ln_cant_fin - c_inv.ingreso) + c_inv.salida ;

               update tt_cntbl_inventario_calculo
                  Set SLDO_FINAL = ln_cant_fin,
                      VALOR_FINAL = ln_cant_fin * ln_precio_promedio ,
                      SLDO_INICIAL = ln_cant_ini , 
                      VALOR_INICIAL = ln_cant_ini * ln_precio_promedio
                where almacen = c_inv.almacen and 
                      articulo = c_inv.articulo and
                      registro = c_inv.registro and
                      nro_vale = c_inv.vale and
                      ingreso = c_inv.ingreso and
                      salida = c_inv.salida ;
           end if ;
        end loop ;

       Insert Into tt_cntbl_libro_inventario (
                   ALMACEN, DESC_ALMACEN, ARTICULO, DESC_ARTICULO, UNIDAD, CATEGORIA, DESC_CATEGORIA,     
                   SUB_CATEGORIA, DESC_SUB_CATEGORIA, NRO_VALE, FEC_DOCUMENTO, TIPO_MOV,           
                   SALDO_INICIAL, VALORIZ_INICIAL, CANTIDAD_INGRESO, CANTIDAD_SALIDA, VALOR_UNITARIO,  
                   SALDO_ACTUAL, VALORIZ_ACTUAL , CENCOS, PRECIO_PROM_SOL )
            SELECT almacen, desc_almacen, articulo, desc_articulo, unidad, categoria, desc_categoria, 
                   subcategoria, desc_subcategoria , nro_vale, registro, tipo_mov,
                   sldo_inicial, sldo_inicial, ingreso, salida, precio_uni, sldo_final, sldo_final, cencos, ln_precio_promedio
              FROM tt_cntbl_inventario_calculo
          order by registro ;
        
---        VALORIZ_INICIAL,VALOR_UNITARIO, VALORIZ_ACTUAL     
        else
          ---- Captura los saldos de los articulos que no tiene movimiento -----
                 
          SELECT asm.cod_art, ar.desc_art, ar.und, asm.almacen,a.desc_almacen ,
                 ar.sub_cat_art,  asct.desc_sub_cat, asct.cat_art, ac.desc_categoria,
                 asm.total_mes_ingr, asm.total_mes_egr, asm.precio_prom_sol, asm.sldo_total, asm.valor_saldo_total
            into lc_articulo, lc_desc_articulo, lc_unidad, lc_almacen, lc_desc_almacen ,
                 lc_subcategoria, lc_desc_subcategoria, lc_categoria, lc_desc_categoria,
                 ln_ingresos, ln_egresos, ln_precio_uni, ln_sldo_final, ln_valor_final
            FROM articulo_saldo_mensual asm, almacen a, 
                 articulo ar , articulo_sub_categ asct, articulo_categ ac
           WHERE asm.cod_art= ar.cod_art AND
                 asm.almacen = a.almacen and
                 ar.sub_cat_art = asct.cod_sub_cat AND
                 asct.cat_art = ac.cat_art and
                 asm.ano = an_ano and
                 asm.mes = an_mes and
                 asm.cod_art = c_a.cod_artic and
                 asm.almacen = c_al.cod_almacen ;
                 
                  
      /**************** CAPTURA LOS SALDO INICIALES************/
          SELECT sldo_total, valor_saldo_total
            into ln_sldo_inicial, ln_valor_inicial
            FROM articulo_saldo_mensual 
           WHERE ano= ln_ano_ant and
                 mes= ln_mes_ant and
                 cod_art = c_a.cod_artic and
                 almacen = c_al.cod_almacen ;
     
     
       Insert Into tt_cntbl_libro_inventario (
                   articulo, desc_articulo, unidad, 
                   almacen, desc_almacen, sub_categoria ,
                   desc_sub_categoria, categoria, desc_categoria, 
                   cantidad_ingreso, cantidad_salida, valor_unitario, saldo_inicial, valoriz_inicial,
                   saldo_actual, valoriz_actual )
          values ( lc_articulo, lc_desc_articulo, lc_unidad, lc_almacen, lc_desc_almacen, 
                   lc_subcategoria, lc_desc_subcategoria, lc_categoria, lc_desc_categoria, 
                   ln_ingresos, ln_egresos, ln_precio_uni, ln_sldo_inicial, ln_valor_inicial,
                   ln_sldo_final, ln_valor_final );

                   
/*                        Insert Into tt_cntbl_libro_inventario (
                 articulo, desc_articulo, unidad, 
                 almacen, desc_almacen, sub_categoria ,
                 desc_sub_categoria, categoria, desc_categoria, cencos,
                 nro_vale, fec_documento, tipo_mov,
                 cantidad_salida, cantidad_ingreso,  valor_unitario, SALDO_INICIAL, VALORIZ_INICIAL,
                 SALDO_ACTUAL , VALORIZ_ACTUAL )
          values ( lc_articulo, lc_desc_articulo, lc_unidad, lc_almacen, lc_desc_almacen, 
                   lc_subcategoria, lc_desc_subcategoria, lc_categoria, lc_desc_categoria, 
                   ln_ingresos, ln_egresos, ln_precio_uni, ln_sldo_inicial, ln_valor_inicial,
                   ln_sldo_final, ln_valor_final );*/

   end if ;
    DELETE FROM tt_cntbl_inventario_calculo ;
   end loop;
  DELETE FROM tt_cntbl_articulo;
end loop;

END usp_cnt_rpt_libro_invent_mm2 ;
/
