create or replace procedure usp_cons_hist_inasist
  ( ad_fec_desde        in date, 
    ad_fec_hasta        in date,
    as_tipo_trabajador  in maestro.tipo_trabajador%type ) is

--Variables Locales del Store Procedure
ls_nombre            varchar2(100) ;
ls_cod_trabajador    char(8) ;
ls_cod_area          char(1) ;
ls_desc_area         varchar2(30) ;
ls_cod_seccion       char(3) ;
ls_desc_seccion      varchar2(30) ;
ls_cencos            char(10) ;
ls_desc_cencos       varchar2(40) ;
ls_concep            char(4) ;
ls_desc_concep       char(25) ; 
ld_fec_desde         date ;
ln_dias_inasist      number(4,2) ;
ls_tipo_trabajador   maestro.tipo_trabajador%type ;

--Cursor de la Tabla Inasistencia
Cursor c_cons_hist_inasist is 
  Select hi.cod_trabajador, hi.concep, hi.dias_inasist,
         hi.fec_desde
  from historico_inasistencia hi
  where hi.fec_movim >= ad_fec_desde and
        hi.fec_movim <= ad_fec_hasta;

begin

delete from tt_cons_hist_inasist;

For rc_hi in c_cons_hist_inasist Loop 
     
  ls_cod_trabajador := rc_hi.cod_trabajador;
  ls_concep         := rc_hi.concep;
  ld_fec_desde      := rc_hi.fec_desde ;
  ln_dias_inasist   := rc_hi.dias_inasist;

  ls_nombre:=usf_nombre_trabajador(ls_cod_trabajador);
    
  Select m.tipo_trabajador, m.cod_area, m.cod_seccion, m.cencos
    into ls_tipo_trabajador, ls_cod_area, ls_cod_seccion, ls_cencos
    from maestro m
    where m.cod_trabajador = ls_cod_trabajador;
    
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
      End if;
        
      If ls_cencos is not null then
        Select cc.desc_cencos
          into ls_desc_cencos
          from centros_costo cc
          where cc.cencos = ls_cencos;
      Else
        ls_cencos:='0';
      End if;
        
      If ls_cencos is not null then
        Select c.desc_breve 
          into ls_desc_concep
          from concepto c
          where c.concep = ls_concep;
      Else 
        ls_desc_concep := ' ';
      End if ;
     
      --Insertar los Registro en la tabla tt_cons_inasistencia
      Insert into tt_cons_hist_inasist 
       ( cod_trabajador, nombre, cod_area,
         desc_area, cod_seccion, desc_seccion,
         cencos, desc_cencos, concep, desc_concep,
         fec_desde, dias_inasist )
           
      Values
       ( ls_cod_trabajador, ls_nombre, ls_cod_area,
         ls_desc_area, ls_cod_seccion, ls_desc_seccion,
         ls_cencos, ls_desc_cencos, ls_concep, ls_desc_concep,
         ld_fec_desde, ln_dias_inasist);
       
    End If ;

  End if ;

End loop ;

End usp_cons_hist_inasist;
/
