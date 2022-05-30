create or replace procedure usp_cons_proy_quinq
 ( ad_fec_proy in date ,
   as_tip_trab in tipo_trabajador.tipo_trabajador%type 
  ) is

--Constantes de nivel de Quinquenio 
lk_nivel_quin constant char(3):='020';
ls_nombre varchar2(100);  
ls_cod_seccion seccion.cod_seccion%type;
ls_desc_mes char(10);
ln_imp_quinq number(13,2);
ln_imp_basico number(13,2);   
ln_anio_ing number(4);
ln_anio_proy number(4);
ln_mes_ing number(2);
ln_quinq number(2);
ln_jornal number(4,2);
ln_resto number(1);
ln_cociente number(5,3); --El Nro de Quiquenio del Trabaj
ln_cociente_round number(5,3); --El Nro de Quinq Redondeado
  
--Cursor de los Trabaj del Tip Trabaj 
Cursor c_m is 
select m.cod_trabajador, m.fec_ingreso,
       m.cod_seccion, s.desc_seccion
from  maestro m, seccion s
where  m.flag_estado = '1' and 
       m.tipo_trabajador = as_tip_trab and 
       m.flag_estado = '1' and 
       m.cod_seccion = s.cod_seccion;

begin
--Deleteo de la Tabla tt_proy_quinquenio
delete from tt_cons_proy_quinq;


--Lectura de los registros del Curso
For rc_m in c_m Loop
 ls_cod_seccion := nvl(rc_m.cod_seccion,'0'); 

 ln_anio_ing := to_char(rc_m.fec_ingreso,'YYYY');
 ln_anio_proy := to_char(ad_fec_proy,'YYYY');
 
 --Diferencia de los Aqos de Servicio 
 ln_quinq := ln_anio_proy - ln_anio_ing;
 ln_resto := mod(ln_quinq,5);
 ln_cociente := ln_quinq/5; --Nro del Cociente sin resondeo 
 ln_cociente_round := round(ln_cociente);--Cociente con Redondeo
  
 If ln_resto = 0 and ls_cod_seccion <> '0' and 
    ln_cociente = ln_cociente_round Then 
    --Nombre del Trabajador
    ls_nombre := usf_nombre_trabajador(rc_m.cod_trabajador);    
 
    --Seleccion del nro de jornal 
    select sum(q.jornal)
    into ln_jornal
    from quinquenio q
    where q.quinquenio = ln_quinq;
    ln_jornal := nvl(ln_jornal,0);
        
    If ln_jornal > 0 Then
       --Obtenemos el Importe Basico
       select nvl(sum(gdf.imp_gan_desc),0)
       into ln_imp_basico
       from  gan_desct_fijo gdf, rrhh_nivel rhn,
             rrhh_nivel_detalle rhd
       where gdf.cod_trabajador = rc_m.cod_trabajador and 
             rhn.cod_nivel = lk_nivel_quin and 
             rhd.cod_nivel = rhn.cod_nivel and 
             gdf.concep = rhd.concep;
        
       If ln_imp_basico > 0 Then
         --Recordar que el jornal es diario 
         ln_imp_quinq := ln_imp_basico/30 * ln_jornal;
    
         --Asignacion del Mes al Trabajador
         --Devuelve el nro del Mes  
         ln_mes_ing := to_char(rc_m.fec_ingreso,'MM');     
         --Devuelve el NOmbre del Mes 
         ls_desc_mes := to_char(rc_m.fec_ingreso,'MONTH');
    
         --Inseramos al Trabajador 
         INSERT INTO tt_cons_proy_quinq 
           ( cod_trabajador      , tipo_trabaj , cod_seccion,
             desc_seccion        , nombre      , cod_mes    ,
             desc_mes            , fec_ingreso , quinquenio ,
             imp_basico          , jornal      , imp_quin )
          VALUES 
           ( rc_m.cod_trabajador , as_tip_trab , rc_m.cod_seccion,                        
             rc_m.desc_seccion   , ls_nombre   , ln_mes_ing ,
             ls_desc_mes         , rc_m.fec_ingreso , ln_quinq ,
             ln_imp_basico       , ln_jornal   , ln_imp_quinq );  
       End if;   
    End If;       
 End if;
End Loop;
end usp_cons_proy_quinq;
/
