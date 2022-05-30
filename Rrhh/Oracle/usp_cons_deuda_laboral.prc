create or replace procedure usp_cons_deuda_laboral
  ( ad_fec_hasta         in date,
    as_tipo_trabajador   in maestro.tipo_trabajador%type ) is

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
ls_desc_concep          varchar2(25) ;
ld_fec_hasta            date ;
ln_importe              number(13,2) ;
ls_tipo_trabajador      maestro.tipo_trabajador%type ;

--  Cursor para la tabla de deudas laborales
cursor c_deuda is 
  select d.cod_trabajador, d.fec_proceso, d.cencos, d.concep,
         d.cod_seccion, d.flag_estado, d.importe
  from deuda d
  where d.fec_proceso = ad_fec_hasta and
        d.flag_estado = '1' ;

begin

--  Borra la informacion cada vez que se ejecuta
delete from tt_deuda ;

--  Graba informacion a la tabla temporal
For rc_deuda in c_deuda Loop  

  ls_cod_trabajador := rc_deuda.cod_trabajador ;
  ld_fec_hasta      := rc_deuda.fec_proceso ;
  ls_cencos         := rc_deuda.cencos ;
  ls_concep         := rc_deuda.concep ;
  ls_cod_seccion    := rc_deuda.cod_seccion ;
  ls_cod_area       := substr(rc_deuda.cod_seccion,1,1) ;
  ln_importe        := rc_deuda.importe ;

  Select m.tipo_trabajador
    into ls_tipo_trabajador
    from maestro m
    where m.cod_trabajador = ls_cod_trabajador ;

  If ls_tipo_trabajador = as_tipo_trabajador then

    ls_nombre := usf_nombre_trabajador (ls_cod_trabajador) ;

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
     
    --  Insertar los Registro en la tabla tt_deuda
    Insert into tt_deuda
      (cod_trabajador, nombre, cod_area,
       desc_area, cod_seccion, desc_seccion,
       cencos, desc_cencos, concep, fec_hasta,
       importe, desc_concep)
    Values
      (ls_cod_trabajador, ls_nombre, ls_cod_area,
       ls_desc_area, ls_cod_seccion, ls_desc_seccion,
       ls_cencos, ls_desc_cencos, ls_concep, ld_fec_hasta,
       ln_importe, ls_desc_concep) ;
     
  End if ;

End loop ;

end usp_cons_deuda_laboral ;
/
