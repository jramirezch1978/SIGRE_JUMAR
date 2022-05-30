create or replace procedure usp_cons_cnta_crrte
  ( ad_fec_desde        in date, 
    ad_fec_hasta        in date,
    as_tipo_trabajador  in maestro.tipo_trabajador%type ) is

--  Variables 
ls_cod_trabajador   maestro.cod_trabajador%type;
ls_concep           concepto.concep%type;
ld_fec_prestamo     cnta_crrte.fec_prestamo%type;
ls_nombre           tt_cons_cnta_crrte.nombre%type;
ls_cod_area         area.cod_area%type;
ls_cod_seccion      seccion.cod_seccion%type;
ls_cencos           centros_costo.cencos%type;
ls_desc_area        area.desc_area%type;
ls_desc_seccion     seccion.desc_seccion%type;
ls_desc_cencos      centros_costo.desc_cencos%type;
ls_desc_concep      concepto.desc_breve%type;
ls_tipo_trabajador  maestro.tipo_trabajador%type;
ln_monto            number(13,2);
ln_cuota            number(13,2);
ln_saldo            number(13,2);
 
--  Cursor para la tabla de cuenta corriente
Cursor c_cons_cnta_crrte is 
  Select cc.cod_trabajador, cc.concep, cc.fec_prestamo,
         cc.mont_original, cc.mont_cuota, cc.sldo_prestamo,
         cc.tipo_doc , cc.nro_doc
  from cnta_crrte cc
  where cc.fec_prestamo >= ad_fec_desde and
        cc.fec_prestamo <= ad_fec_hasta;
  
begin

delete from tt_cons_cnta_crrte; 

For rc_cc in c_cons_cnta_crrte Loop 
     
  ls_cod_trabajador := rc_cc.cod_trabajador;
  ls_concep         := rc_cc.concep;
  ld_fec_prestamo   := rc_cc.fec_prestamo;
  ln_monto          := rc_cc.mont_original;
  ln_cuota          := rc_cc.mont_cuota;
  ln_saldo          := rc_cc.sldo_prestamo;
  
  ln_monto := nvl(ln_monto,0);
  ln_cuota := nvl(ln_cuota,0);
  ln_saldo := nvl(ln_saldo,0);

  ls_nombre         := usf_nombre_trabajador(ls_cod_trabajador);
    
  Select m.tipo_trabajador, m.cod_area, m.cod_seccion, m.cencos
    into ls_tipo_trabajador, ls_cod_area, ls_cod_seccion, ls_cencos
    from maestro m
    where m.cod_trabajador=ls_cod_trabajador;
   
  If ls_tipo_trabajador = as_tipo_trabajador then

    If ls_cod_area is not null then
       
      Select a.desc_area
        into ls_desc_area 
        from area a  
        where a.cod_area=ls_cod_area;
       
      If ls_cod_seccion  is not null Then
        Select s.desc_seccion
          into ls_desc_seccion
          from seccion s
          where s.cod_area = ls_cod_area and
                s.cod_seccion = ls_cod_seccion ;
      Else 
        ls_cod_seccion:='0';
        ls_desc_seccion := ' ';
      End if;
       
      If ls_cencos is not null then
        Select cc.desc_cencos
          into ls_desc_cencos
          from centros_costo cc
          where cc.cencos = ls_cencos;
      Else
        ls_cencos:='0';
        ls_desc_cencos:=' '; 
      End if;
        
      If ls_concep is not null then
        Select c.desc_breve 
          into ls_desc_concep
          from concepto c
          where c.concep = ls_concep;
      Else 
        ls_concep:= '0 ';
        ls_desc_concep := ' ';
      End if ;
    
      --Insertar los Registro en la tabla tt_cons_cnta_crrte
      If ln_monto <> 0 or ln_cuota <> 0 or ln_saldo <> 0 then
      Insert into tt_cons_cnta_crrte 
        ( cod_trabajador   , nombre        ,
          cod_area        , desc_area     ,
          cod_seccion     , desc_seccion  ,
          cencos          , desc_cencos   ,
          concep          , desc_concep   ,
          tipo_doc        , nro_doc       , 
          fec_prestamo    , mont_original ,
          mont_cuota      , sldo_prestamo)
          
      Values
         ( ls_cod_trabajador , ls_nombre          , 
           ls_cod_area       , ls_desc_area       ,
           ls_cod_seccion    , ls_desc_seccion    ,
           ls_cencos         , ls_desc_cencos     ,
           ls_concep         , ls_desc_concep     ,
           rc_cc.tipo_doc    , rc_cc.nro_doc      , 
           ld_fec_prestamo   , rc_cc.mont_original,
           rc_cc.mont_cuota  , rc_cc.sldo_prestamo);
      End if ;
       
    End If;

  End If;

End loop;  
  
End usp_cons_cnta_crrte;
/
