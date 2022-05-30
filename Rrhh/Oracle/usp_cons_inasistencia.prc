create or replace procedure usp_cons_inasistencia(

    ad_fec_desde in date, 
    ad_fec_hasta in date) 
is

--Variables Locales del Store Procedure
ls_nombre varchar2(100);
ls_cod_trabajador char(8);
ls_cod_area char(1);
ls_desc_area varchar2(30);
ls_cod_seccion char(3);
ls_desc_seccion varchar2(30);
ls_cencos char(10);
ls_desc_cencos varchar2(40);
ls_concep char(4);
ld_fec_desde date;
ln_dias_inasist number(4,2);

--Cursor de la Tabla Inasistencia
cursor c_cons_inasistencia is 
  select i.cod_trabajador, i.concep, i.dias_inasist,
         i.fec_desde
  from inasistencia i
  where i.fec_movim >= ad_fec_desde and
        i.fec_movim <= ad_fec_hasta;

begin
--Borramos la data cada vez que se ejecuta
delete from tt_cons_inasistencia ;

--captura de datos dentro de la tabla temporal tt_cons_inasistencia

For rc_cons_inasistencia in c_cons_inasistencia  
   Loop 
     --Obtengo los valores de los campos de tt_cons_inasistencia
     ls_cod_trabajador:=rc_cons_inasistencia.cod_trabajador;
     ls_concep:=rc_cons_inasistencia.concep;
     ld_fec_desde:=rc_cons_inasistencia.fec_desde ;
     ln_dias_inasist:=rc_cons_inasistencia.dias_inasist;

     --El Nombre Completo del Trabajador    
     ls_nombre:=usf_nombre_trabajador(ls_cod_trabajador);
    
     --Capturo area del trabajador 
     select m.cod_area, m.cod_seccion, m.cencos
     into ls_cod_area, ls_cod_seccion, ls_cencos
     from maestro m
     where m.cod_trabajador=ls_cod_trabajador;
    
     If ls_cod_area is not null then
        
        --Capturo de las Descripciones del Area    
        Select a.desc_area
        into ls_desc_area 
        from area a  
        where a.cod_area=ls_cod_area;
        
        If ls_cod_seccion  is not null Then
        
           --Capture de la Descripcion de Seccion
           Select s.desc_seccion
           into ls_desc_seccion
           from seccion s
           where s.cod_area = ls_cod_area and
                 s.cod_seccion = ls_cod_seccion ;
        else 
           ls_cod_seccion:='0';
        end if;
        
     else
        ls_cod_area:='0';
        ls_cod_seccion:='0';
     end if;
       
     If ls_cencos is not null then
        --Captura de la Dewcripcion del Cencos
        select cc.desc_cencos
        into ls_desc_cencos
        from centros_costo cc
        where cc.cencos = ls_cencos;
     else
        ls_cencos:='0';
     end if;
     
    --Insertar los Registro en la tabla tt_cons_inasistencia
     Insert into tt_cons_inasistencia
        (cod_trabajador, nombre, cod_area,
         desc_area, cod_seccion, desc_seccion,
         cencos, desc_cencos, concep, fec_desde,
         dias_inasist)
           
     values
        ( ls_cod_trabajador, ls_nombre, ls_cod_area,
          ls_desc_area, ls_cod_seccion, ls_desc_seccion,
          ls_cencos, ls_desc_cencos, ls_concep,
          ld_fec_desde, ln_dias_inasist);
          
     --Inicializa las variables de la Tabla Temporal     
     ln_dias_inasist:=0;
   end loop;

end usp_cons_inasistencia;
/
