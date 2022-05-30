create or replace procedure usp_edad_jubilacion
 ( an_aservf in number, --a?o de servicio femenino
   an_aservm in number, --a?o de servicio masculino
   an_edadf_desde in number ,
   an_edadf_hasta in number,
   an_edadm_desde in number,
   an_edadm_hasta in number,
   ad_fec_proy in date
   ) is  --Fec de Proyeccion 
   --de Jubilacion

ln_meses_serv number(6,2);   
ln_anios_serv number(6,2);
ln_meses_jub number(6,2);   
ln_anios_jub number(6,2);
ls_area area.cod_area%type;
ls_desc_area area.desc_area%type;
ls_seccion seccion.cod_seccion%type;
ls_desc_seccion seccion.desc_seccion%type;
ls_cencos centros_costo.cencos%type;
ls_desc_cencos centros_costo.desc_cencos%type;
ls_flag_sexo maestro.flag_sexo%type;   
ls_nombre varchar2(100);
ld_fec_ingreso date;
ld_fec_nacimiento date;

--Cursor por Trabajador de la Tabla Maestro
Cursor c_trabaj is 
 Select m.cod_trabajador, 
        m.cod_area, a.desc_area, 
        m.cod_seccion, s.desc_seccion,
        m.cencos, cc.desc_cencos,
        m.flag_sexo, m.fec_nacimiento, 
        m.fec_ingreso 
  From  maestro m, area a, seccion s,
        centros_costo cc 
 where  m.cod_area = a.cod_area (+) and 
        m.cod_seccion = s.cod_seccion (+) and 
        m.cencos = cc.cencos (+) ;
        --and 
        --m.cod_trabajador = 'R5550'; 
 
begin

For c_t in c_trabaj Loop
  ls_nombre := usf_nombre_trabajador(c_t.cod_trabajador);
    
  --Definimos los argumentos para que no sean nulos
  ls_area := nvl(c_t.cod_area, '0'); 
  ls_desc_area := nvl(c_t.desc_area,' '); 
  ls_seccion := nvl(c_t.cod_seccion,'0');
  ls_desc_seccion := nvl(c_t.desc_seccion,' '); 
  ls_cencos := nvl(c_t.cencos,'0');
  ls_desc_cencos := nvl(c_t.desc_cencos,' ');
  ls_flag_sexo := nvl(c_t.flag_sexo,'N');
  ld_fec_ingreso := nvl(c_t.fec_ingreso,SYSDATE );
  ld_fec_nacimiento := nvl(c_t.fec_nacimiento, SYSDATE );
  
  --Verificamos los a?os de servicios
  ln_meses_serv := MONTHS_BETWEEN(ad_fec_proy,c_t.fec_ingreso);
  ln_anios_serv := ln_meses_serv/12;
  ln_anios_serv := nvl(ln_anios_serv,0);
  
  --Verificamos la edad de jubilacion
  ln_meses_jub := MONTHS_BETWEEN(ad_fec_proy,c_t.fec_nacimiento);
  ln_anios_jub := ln_meses_jub/12;
  ln_anios_jub := nvl(ln_anios_jub,0);
  
  If ls_flag_sexo = 'F' Then 
     --sexo
     IF ln_anios_serv >= an_aservf and 
        ln_anios_jub >= an_edadf_desde and
        ln_anios_jub <= an_edadf_hasta  Then  
           --Insertamos datos dentro de la Tabla 
          insert into tt_edad_jubilacion 
          ( cod_area        ,    desc_area     , 
            cod_seccion     ,    desc_seccion  ,
            cencos          ,    desc_cencos   ,
            cod_trabajador  ,    nombre_trabaj ,
            flag_sexo       ,    fec_ingreso   ,
            fec_nacimiento )
         
          values
          ( ls_area            ,  ls_desc_area    ,
            ls_seccion         ,  ls_desc_seccion ,  
            ls_cencos          ,  ls_desc_cencos  ,
            c_t.cod_trabajador ,  ls_nombre       ,
            ls_flag_sexo       ,  ld_fec_ingreso  ,
            ld_fec_nacimiento );
       --End if;    
     End if;
  ENd if; 
  
  IF  ls_flag_sexo = 'M' Then
     IF ln_anios_serv >= an_aservm and 
        ln_anios_jub >= an_edadm_desde and
        ln_anios_jub <= an_edadm_hasta  Then  
          --Insertamos datos dentro de la Tabla 
          --ls_area := ls_area ;
          
          insert into tt_edad_jubilacion 
          ( cod_area        ,    desc_area     , 
            cod_seccion     ,    desc_seccion  ,
            cencos          ,    desc_cencos   ,
            cod_trabajador  ,    nombre_trabaj ,
            flag_sexo       ,    fec_ingreso   ,
            fec_nacimiento )
         
          values
          ( ls_area            ,  ls_desc_area    ,
            ls_seccion         ,  ls_desc_seccion ,  
            ls_cencos          ,  ls_desc_cencos  ,
            c_t.cod_trabajador ,  ls_nombre       ,
            ls_flag_sexo       ,  ld_fec_ingreso  ,
            ld_fec_nacimiento );
            
          --ls_seccion := ls_seccion ;  
     End if; 
  End if;  
     
End Loop;      

end usp_edad_jubilacion;
/
