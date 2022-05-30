create or replace procedure usp_copia_tabla is

ls_cod_usr usuario.cod_usr%type;
ls_tip_doc doc_tipo.tipo_doc%type;
ls_nro_doc inasistencia.nro_doc%type;
ln_dias_inasist inasistencia.dias_inasist%type;
ld_fec_desde inasistencia.fec_desde%type;
ld_fec_hasta inasistencia.fec_hasta%type;

cursor c_copia is 
 select i.cod_trabajador, i.concep, i.fec_desde,
        i.fec_hasta, i.fec_movim, i.dias_inasist,
        i.tipo_doc , i.nro_doc, i.cod_usr
 from inasistencia i ;
 
begin
For rc_i in c_copia Loop
 ls_cod_usr := nvl(rc_i.cod_usr, ' ');
 ls_tip_doc := nvl(rc_i.tipo_doc, ' ');
 ls_nro_doc := nvl(rc_i.nro_doc, ' ');
 ln_dias_inasist := nvl(rc_i.dias_inasist, 0 );
 ld_fec_desde := nvl(rc_i.fec_desde , to_date('20/09/2000','DD/MM/YYYY') );
 ld_fec_hasta := nvl(rc_i.fec_hasta , to_date('20/09/2000','DD/MM/YYYY') );
  
   Insert into historico_inasistencia
    ( cod_trabajador     ,   concep      , fec_desde ,
      fec_hasta          ,   fec_movim   , dias_inasist ,
      tipo_doc           ,   nro_doc     , cod_usr )
   
   values 
   ( rc_i.cod_trabajador ,   rc_i.concep    , ld_fec_desde,
     ld_fec_hasta        ,   rc_i.fec_movim , ln_dias_inasist,
     ls_tip_doc          ,   ls_nro_doc     , ls_cod_usr );
   
End loop;
end usp_copia_tabla;
/
