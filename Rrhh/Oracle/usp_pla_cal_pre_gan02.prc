create or replace procedure usp_pla_cal_pre_gan02(
   as_codtra      in maestro.cod_trabajador%type, 
   as_codusr      in usuario.cod_usr%type,
   ad_fec_proceso in rrhhparam.fec_proceso%type
) is
    
   lk_quinquenio  constant char(3) := '020' ;
   
   --  Conceptos calculos de quinquenio (fijos)
   Cursor c_gan_fijas  is 
     Select rd.concep
       from rrhh_nivel_detalle rd
       where rd.cod_nivel = lk_quinquenio ;
   
   ld_fec_ingreso    date;         
   ln_anios          number(4,2); 
   ln_jornal         number(4,2); 
   ln_quinquenio     integer;     
   ln_valor          gan_desct_fijo.imp_gan_desc%type; 
   ln_tot_valor      gan_desct_fijo.imp_gan_desc%type; 
   ln_count_fijo     number(4);
   ln_count_jornal   number(4); 
   ls_concep         concepto.concep%type;
   ls_cencos         maestro.cencos%type;
   
begin
   
   --  Determina fecha de ingreso y anos de servicios
   Select m.fec_ingreso, m.cencos
     into ld_fec_ingreso, ls_cencos
     from maestro m
     where m.cod_trabajador = as_codtra ;

   ld_fec_ingreso := nvl ( ld_fec_ingreso, ad_fec_proceso) ;
   ln_anios := months_between(ad_fec_proceso,ld_fec_ingreso) / 12;
   
   If ln_anios > 5 Then 

     ln_quinquenio := Trunc ( ln_anios );
     Select count(q.jornal)
       into ln_count_jornal
       from quinquenio q
       where q.quinquenio = ln_quinquenio and
             to_char(ld_fec_ingreso,'MM') = to_char(ad_fec_proceso,'MM') ;

       --  Verifica prueba del contador
       If ln_count_jornal > 0 Then
         Select q.jornal 
           into ln_jornal
           from quinquenio q
           where q.quinquenio = ln_quinquenio;
         ln_jornal := nvl ( ln_jornal, 0 ) ;
       End if;

       ln_tot_valor := 0;
       If ln_jornal > 0 Then 

         For rc_gan_fijas in c_gan_fijas Loop

           Select count(gdf.imp_gan_desc)
             into ln_count_fijo
             from gan_desct_fijo gdf
             where gdf.cod_trabajador = as_codtra 
                   and gdf.flag_estado = '1'
                   and gdf.concep = rc_gan_fijas.concep ;
              
           If ln_count_fijo > 0 then
             Select gdf.imp_gan_desc
               into ln_valor
               from gan_desct_fijo gdf
               where gdf.cod_trabajador = as_codtra 
                     and gdf.flag_estado = '1'
                     and gdf.flag_trabaj = '1'
                     and gdf.concep = rc_gan_fijas.concep ;

             ln_valor := nvl( ln_valor, 0 ) ;
             ln_tot_valor := ln_tot_valor + ln_valor ;
           End if;
                     
         End Loop ;

         ln_tot_valor := nvl(ln_tot_valor,0);
         ln_tot_valor := ln_tot_valor / 30 * ln_jornal ;

         If ln_tot_valor > 0 Then
           Select pn.concep
             into ls_concep
             from rrhh_nivel pn
             where pn.cod_nivel = lk_quinquenio ;

           Insert into gan_desct_variable 
             ( cod_trabajador, fec_movim  , concep, 
               nro_doc       , imp_var    , cencos, 
               cod_labor     , cod_usr    , proveedor,
               tipo_doc ) 
           Values ( as_codtra , ad_fec_proceso, ls_concep,
               'autom'       , ln_tot_valor  , ls_cencos ,
               ''  , ''      , ''              , 
               'auto' );
         End If;

       End if ;
   End If ;
     
End usp_pla_cal_pre_gan02;
/
