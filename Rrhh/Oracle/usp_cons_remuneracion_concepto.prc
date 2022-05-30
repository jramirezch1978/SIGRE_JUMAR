create or replace procedure usp_cons_remuneracion_concepto
  ( ad_fec_hasta         in date,
    as_tipo_trabajador   in maestro.tipo_trabajador% type ) is

--  Variables locales
ls_cod_trabajador       char(8) ;
ls_nombre               varchar2(100) ;
ls_cod_area             char(1) ;
ls_desc_area            varchar2(30) ;
ls_cod_seccion          char(3) ;
ls_desc_seccion         varchar2(30) ;
ls_cencos               char(10) ;
ls_desc_cencos          varchar2(40) ;
ls_concep               char(4) ;
ls_desc_concep          varchar2(30) ;
ld_fec_hasta            date ;
ln_importe              number(13,2) ;
ls_tipo_trabajador      maestro.tipo_trabajador%type ;

--  Cursor para la tabla de remuneraciones por conceptos
cursor c_remuneracion is 
  Select c.cod_trabajador, c.fec_proceso, c.concep,
         c.imp_soles
  from calculo c
  where c.fec_proceso = ad_fec_hasta ;

begin

--  Borra la informacion cada vez que se ejecuta
delete from tt_rem_concepto ;

--  Graba informacion a la tabla temporal
For rc_rem in c_remuneracion Loop  

  ls_cod_trabajador := rc_rem.cod_trabajador ;
  ld_fec_hasta      := rc_rem.fec_proceso ;
  ls_concep         := rc_rem.concep ;
  ln_importe        := rc_rem.imp_soles ;

  ls_nombre := usf_nombre_trabajador (ls_cod_trabajador) ;

  Select m.cencos, m.tipo_trabajador, m.cod_seccion
    into ls_cencos, ls_tipo_trabajador, ls_cod_seccion
    from maestro m
    where m.cod_trabajador = ls_cod_trabajador ;

  If ls_tipo_trabajador = as_tipo_trabajador then
    
    ls_cod_area := substr(ls_cod_seccion,1,1) ;
    
    If ls_cod_area is not null then
      Select a.desc_area
        into ls_desc_area 
        from area a  
        where a.cod_area = ls_cod_area;
      If ls_cod_seccion  is not null Then
        Select s.desc_seccion
          into ls_desc_seccion
          from seccion s
          where s.cod_seccion = ls_cod_seccion ;
      Else 
        ls_cod_seccion := '0' ;
      End if ;
    Else
      ls_cod_area    := '0' ;
      ls_cod_seccion := '0' ;
    End if ;
       
    If ls_cencos is not null then
      Select cc.desc_cencos
        into ls_desc_cencos
        from centros_costo cc
        where cc.cencos = ls_cencos ;
    Else
      ls_cencos := '0' ;
    End if ;
     
    If ls_concep is not null then
      Select c.desc_breve
        into ls_desc_concep
        from concepto c
        where c.concep = ls_concep ;
    Else
      ls_concep := '0' ;
    End if ;
     
    If ls_concep = '1450' then
      ls_concep := '0001' ;
    Elsif ls_concep = '2351' then
      ls_concep := '0002' ;
    Elsif ls_concep = '2354' then
      ls_concep := '0003' ;
    Elsif ls_concep = '3050' then
      ls_concep := '0004' ;
    End if ;
  
    --  Insertar los Registro en la tabla tt_rem_concepto
    Insert into tt_rem_concepto
      (cod_trabajador, nombre, cod_area,
       desc_area, cod_seccion, desc_seccion,
       cencos, desc_cencos, concep, desc_concep,
       fec_hasta, importe)
    Values
      (ls_cod_trabajador, ls_nombre, ls_cod_area,
       ls_desc_area, ls_cod_seccion, ls_desc_seccion,
       ls_cencos, ls_desc_cencos, ls_concep, ls_desc_concep,
       ld_fec_hasta, ln_importe) ;

  End if ;
       
End loop ;

end usp_cons_remuneracion_concepto ;
/
