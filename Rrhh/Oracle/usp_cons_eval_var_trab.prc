create or replace procedure usp_cons_eval_var_trab
 is
 
ls_nombre varchar2(100); 
ld_fec_nac date;
ls_f_est_civ char(1);
ls_f_sexo char(1);
ls_cod_seccion seccion.cod_seccion%type;
ls_desc_seccion seccion.desc_seccion%type; 
ls_cencos centros_costo.cencos%type;
ls_desc_cencos centros_costo.desc_cencos%type;
ln_edad number(4,2);  
   
--Cursor para la Tabla Habilidad
Cursor c_habil is 
 select th.cod_trabajador, th.cod_habilidad, 
        th.fec_proceso , th.puntaje
 from trabajador_habilidad th  ;

--Cursor para la tabla Personalidad
Cursor c_pers is 
 select tp.cod_trabajador, tp.cod_personalid,
        tp.fec_proceso, tp.puntaje
 from trabajador_personalidad tp ;
 
begin
--Llamada al 1er store procedure
For rc_h in c_habil Loop
 ls_nombre:=usf_nombre_trabajador(rc_h.cod_trabajador); 
        
 select m.fec_nacimiento, m.flag_estado_civil, m.flag_sexo,
        m.cod_seccion, s.desc_seccion, m.cencos, cc.desc_cencos
 into ld_fec_nac, ls_f_est_civ, ls_f_sexo,
      ls_cod_seccion, ls_desc_seccion, ls_cencos, ls_desc_cencos  
 from maestro m, seccion s, centros_costo cc
 where  m.cod_trabajador = rc_h.cod_trabajador and 
        m.cod_seccion = s.cod_seccion (+) and 
        m.cencos = cc.cencos (+);
 
 ln_edad:= MONTHS_BETWEEN(SYSDATE,ld_fec_nac)/12;
 --Insertamos los registros dentro de la Tabla
 Insert into tt_cons_cyd_eval_variables
   ( cod_trabajador     , flag_h_p       ,cod_evaluacion ,
     fec_proceso        , nombre         , edad          ,
     flag_civil         , flag_sexo      , cod_seccion   ,
     desc_seccion       , cencos         , desc_cencos   ) 
 Values 
   ( rc_h.cod_trabajador , 'H'            ,rc_h.cod_habilidad ,
     rc_h.fec_proceso    , ls_nombre      , ln_edad           ,
     ls_f_est_civ        , ls_f_sexo      , ls_cod_seccion    ,
     ls_desc_seccion     , ls_cencos      , ls_desc_cencos  );
    
End loop;

--Llamada al 2do store procedure
For rc_p in c_pers Loop
   ls_nombre:=usf_nombre_trabajador(rc_p.cod_trabajador);
   
   select m.fec_nacimiento, m.flag_estado_civil, m.flag_sexo,
          m.cod_seccion, s.desc_seccion, m.cencos, cc.desc_cencos
    into ld_fec_nac, ls_f_est_civ, ls_f_sexo,
         ls_cod_seccion, ls_desc_seccion, ls_cencos, ls_desc_cencos  
    from maestro m, seccion s, centros_costo cc
   where  m.cod_trabajador = rc_p.cod_trabajador and 
          m.cod_seccion = s.cod_seccion (+) and 
          m.cencos = cc.cencos (+);
   
   ln_edad:= MONTHS_BETWEEN(SYSDATE,ld_fec_nac)/12;
   --Insertamos los registros dentro de la Tabla
   Insert into tt_cons_cyd_eval_variables
   ( cod_trabajador     , flag_h_p       ,cod_evaluacion ,
     fec_proceso        , nombre         , edad          ,
     flag_civil         , flag_sexo      , cod_seccion   ,
     desc_seccion       , cencos         , desc_cencos   ) 
   Values 
   ( rc_p.cod_trabajador , 'P'           , rc_p.cod_personalid ,
     rc_p.fec_proceso    , ls_nombre     , ln_edad             ,
     ls_f_est_civ        , ls_f_sexo     , ls_cod_seccion      ,
     ls_desc_seccion     , ls_cencos     , ls_desc_cencos  );
    
End loop;
 
    
     
   
end usp_cons_eval_var_trab;
/
