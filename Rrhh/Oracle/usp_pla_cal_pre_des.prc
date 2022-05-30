create or replace procedure usp_pla_cal_pre_des(
   as_codtra      in maestro.cod_trabajador%type, 
   as_codusr      in usuario.cod_usr%type,
   ad_fec_proceso in date
   ) is
   
   ld_fec_diferido  date ;
   ld_fec_quincena  date ;
   ls_cencos        maestro.cencos%type;
   ln_contador      number(15);
   ld_fecha         date  ;
   ln_horas         number(4,2) ;
   ls_horas         char(6) ;
   ln_min           number(15) ;
   ln_hrs           number(15) ;
   ln_importe       number(13,2) ;
   ln_ganancias     number(13,2) ;
   
   Cursor c_diferidos is
   Select d.cod_trabajador, d.concep, d.importe
     from diferido d
     where d.cod_trabajador = as_codtra and 
           d.fec_proceso = add_months(ad_fec_proceso,-1)
     order by d.fec_proceso, d.concep ;

   Cursor c_quincena is
   Select aq.cod_trabajador, aq.concep, aq.imp_adelanto
     from adelanto_quincena aq
     where aq.cod_trabajador = as_codtra ;

begin

   ld_fecha := ad_fec_proceso - 1 ;
   ld_fec_quincena := ad_fec_proceso;
   
   For rc_dif in c_diferidos
   Loop
      Select m.cencos
        into ls_cencos
        from maestro m
        where m.cod_trabajador = rc_dif.cod_trabajador;
             
      Insert into gan_desct_variable 
         ( cod_trabajador, fec_movim  , concep, 
           nro_doc       , imp_var    , cencos, 
           cod_labor     , cod_usr    , proveedor,
           tipo_doc ) 
      Values ( as_codtra , ld_fecha          , rc_dif.concep,
           'autom'         , rc_dif.importe  , ls_cencos ,
           ''  , ''         , ''             , 
           'auto' );
   End Loop ;
      
   For rc_qui in c_quincena
   Loop
      Select m.cencos
        into ls_cencos
        from maestro m
        where m.cod_trabajador = rc_qui.cod_trabajador;

      ln_contador := 0 ;
      Select count(*)
        into ln_contador
        from gan_desct_variable gdv
        where gdv.cod_trabajador = as_codtra and
              gdv.concep = rc_qui.concep ;
      ln_contador := nvl(ln_contador,0) ;
      If ln_contador > 0 then
        Update gan_desct_variable
        Set imp_var = imp_var + rc_qui.imp_adelanto
        where cod_trabajador = as_codtra and
              concep = rc_qui.concep ;
      Else
        Insert into gan_desct_variable 
           ( cod_trabajador, fec_movim  , concep, 
             nro_doc       , imp_var    , cencos, 
             cod_labor     , cod_usr    , proveedor,
             tipo_doc ) 
        Values ( as_codtra , ld_fec_quincena, rc_qui.concep,
             'autom'         , rc_qui.imp_adelanto  , ls_cencos ,
             ''  , ''        , ''              , 
             'auto' );
      End if ;
   End Loop ;

   --  Realiza descuento por horas por permiso particular
   ln_contador := 0 ; ln_importe := 0 ;
   select count(*)
     into ln_contador
     from inasistencia i
     where i.cod_trabajador = as_codtra and i.concep = '2406' ;
   if ln_contador > 0 then
     select sum(nvl(i.dias_inasist,0))
       into ln_horas
       from inasistencia i
       where i.cod_trabajador = as_codtra and i.concep = '2406' ;
     if ln_horas <> 0 then
       select m.cencos
        into ls_cencos from maestro m
        where m.cod_trabajador = as_codtra ;
       select sum(g.imp_gan_desc)
         into ln_ganancias
         from gan_desct_fijo g
         where g.cod_trabajador = as_codtra and g.flag_estado = '1' and
               g.flag_trabaj = '1' and substr(g.concep,1,1) = '1' ;
       ls_horas := to_char(ln_horas,'99.99') ;
       ls_horas := replace(ls_horas,'.','') ;
       ls_horas := lpad(ltrim(rtrim(ls_horas)),6,'0') ;
       ln_min := to_number(substr(ls_horas,5,2)) ;
       ln_hrs := to_number(substr(ls_horas,1,4)) ;
       if ln_min <> 0 then
         ln_importe := ln_ganancias / 240 / 60 * ln_min ;
       end if ;
       if ln_hrs <> 0 then
         ln_importe := ln_importe + (ln_ganancias / 240 * ln_hrs) ;
       end if ;
       if ln_importe <> 0 then
         insert into gan_desct_variable (
           cod_trabajador, fec_movim, concep, nro_doc,
           imp_var, cencos, cod_labor, cod_usr, proveedor, tipo_doc ) 
         values (
           as_codtra, ad_fec_proceso, '2314', 'autom',
           ln_importe, ls_cencos, '', '', '', 'auto' ) ;
       end if ;
     end if ;
   end if ;

end usp_pla_cal_pre_des;
/
