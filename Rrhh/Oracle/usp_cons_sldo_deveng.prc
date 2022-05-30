create or replace procedure usp_cons_sldo_deveng
 ( ad_fec_proceso     in sldo_deveng.fec_proceso%type,
   as_tipo_trabajador in maestro.tipo_trabajador%type ) is
  
ls_nombre            varchar2(100);
ls_flag_estado       maestro.flag_estado%type;
ls_area              area.cod_area%type;
ls_desc_area         area.desc_area%type;
ls_seccion           seccion.cod_seccion%type;
ls_desc_seccion      seccion.desc_seccion%type;
ls_cencos            centros_costo.cencos%type;
ls_desc_cencos       centros_costo.desc_cencos%type;
ls_suma              number(13,2); 
ls_tipo_trabajador   maestro.tipo_trabajador%type ;

 
--Cursor para la Tabla Saldo Devengados
Cursor c_sldo is 
  Select sd.cod_trabajador, sd.fec_proceso, sd.sldo_gratif_dev,
         sd.sldo_rem_dev, sd.sldo_racion
  from  sldo_deveng sd
  where sd.fec_proceso = ad_fec_proceso;  
 
begin

delete from tt_cons_sldo_deveng; 

For rc_s in c_sldo Loop

  Select m.tipo_trabajador, m.cod_area, m.cod_seccion, m.cencos, 
         m.flag_estado
    into ls_tipo_trabajador, ls_area, ls_seccion, ls_cencos, 
         ls_flag_estado  
    from maestro m
    where m.cod_trabajador = rc_s.cod_trabajador; 
 
  If ls_tipo_trabajador = as_tipo_trabajador then

    If ls_flag_estado = '1'  then 

      ls_nombre  := usf_nombre_trabajador(rc_s.cod_trabajador);   
      ls_area    := nvl(ls_area,'3');
      ls_seccion := nvl(ls_seccion, '340');
      ls_cencos  := nvl(ls_cencos, ' ');
    
      Select a.desc_area
        into ls_desc_area 
        from area a  
        where a.cod_area = ls_area;
     
      Select s.desc_seccion
        into ls_desc_seccion
        from seccion s
        where s.cod_area = ls_area and 
              s.cod_seccion = ls_seccion;
      
      If ls_cencos <> ' ' Then 
        Select cc.desc_cencos
          into ls_desc_cencos
          from centros_costo cc
          where cc.cencos = ls_cencos;
      Else 
        ls_desc_cencos := ' ';
      End if;  

      ls_suma := rc_s.sldo_gratif_dev + rc_s.sldo_rem_dev + 
                 rc_s.sldo_racion;
    
      If ls_suma <> 0 then
       --Insertamos Datos a tt_cons_sldo_deveng
        Insert into tt_cons_sldo_deveng
          ( cod_trabajador      ,   nombre           ,   
            cod_area            ,   desc_area        ,
            cod_seccion         ,   desc_seccion     ,
            cencos              ,   desc_cencos      ,
            fec_proceso         ,   sldo_gratif_dev  ,
            sldo_rem_dev        ,   sldo_racion  )
        
        Values 
          ( rc_s.cod_trabajador ,   ls_nombre             ,
            ls_area             ,   ls_desc_area          ,
            ls_seccion          ,   ls_desc_seccion       ,
            ls_cencos           ,   ls_desc_cencos        ,
            ad_fec_proceso      ,   rc_s.sldo_gratif_dev  ,    
            rc_s.sldo_rem_dev   ,   rc_s.sldo_racion  );
      End if;
      
    End if;
    
  End if ;
  
End Loop;

End usp_cons_sldo_deveng;
/
