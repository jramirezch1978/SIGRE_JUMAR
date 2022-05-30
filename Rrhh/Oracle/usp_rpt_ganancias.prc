create or replace procedure usp_rpt_ganancias
 ( ln_estable          in integer ,
   ln_contratado       in integer ,
   as_tipo_trabajador  in maestro.tipo_trabajador%type
 ) is

--  Variables locales
ls_cod_trabajador       maestro.cod_trabajador%type ;
ls_concepto             char(4) ;
ls_desc_concepto        varchar2(25) ;
ls_bonif                char(1) ;
ls_situacion            char(1) ;
ln_importe              number(13,2) ;
ln_importe_30           number(13,2) ;
ln_importe_25           number(13,2) ;
ln_nro_trabajadores     number(4) ;
ln_nro_trabajadores_25  number(4) ;
ln_nro_trabajadores_30  number(4) ;
ln_contador             number(15) ;

--  Cursor para la tabla de conceptos
cursor c_concepto is 
  Select c.concep, c.desc_breve
  from concepto c
  where c.flag_estado = '1' and
        substr(c.concep,1,2) = '10' and
        c.concep <> '1025' and
        c.concep <> '1030'
  order by c.concep ;

--  Cursor para la tabla de ganancias fijas
cursor c_ganancias is 
  Select gdf.cod_trabajador, gdf.concep, gdf.flag_trabaj,
         gdf.flag_estado, gdf.imp_gan_desc
  from gan_desct_fijo gdf
  where gdf.concep = ls_concepto and 
        gdf.flag_estado = '1' and
        gdf.flag_trabaj = '1'
  order by gdf.concep ;

begin

--  Borra la informacion cada vez que se ejecuta
delete from tt_rpt_ganancias ;

--  Graba informacion a la tabla temporal
ln_importe_30          := 0 ; 
ln_importe_25          := 0 ; 
ln_nro_trabajadores_25 := 0 ; 
ln_nro_trabajadores_30 := 0 ; 

For rc_con in c_concepto Loop

  ls_concepto         := rc_con.concep ;
  ls_desc_concepto    := rc_con.desc_breve ;
  ln_importe          := 0 ;
  ln_nro_trabajadores := 0 ; 
  
  For rc_gan in c_ganancias Loop  

    ln_contador := 0 ;
    Select count(*)
      into ln_contador
      from maestro m
      where m.cod_trabajador = rc_gan.cod_trabajador and
            m.tipo_trabajador = as_tipo_trabajador and
            m.flag_estado = '1' ;
            
    If ln_contador > 0 then
    
    Select m.bonif_fija_30_25, m.situa_trabaj
      into ls_bonif, ls_situacion
      from maestro m
      where m.cod_trabajador = rc_gan.cod_trabajador and
            m.tipo_trabajador = as_tipo_trabajador and
            m.flag_estado = '1' ;
    ls_bonif     := nvl(ls_bonif,'0') ;
    ls_situacion := nvl(ls_situacion,' ') ;

    --  Proceso solo para estables
    If ln_estable <> 0 then
      If ls_situacion = 'E' or ls_situacion = 'S' then
        rc_gan.imp_gan_desc := nvl(rc_gan.imp_gan_desc,0) ;
        ln_importe          := ln_importe + rc_gan.imp_gan_desc ;
        ln_nro_trabajadores := ln_nro_trabajadores + 1 ;

        If ls_bonif = '1' then
          ln_importe_30 := ln_importe_30 + (rc_gan.imp_gan_desc * 0.30) ;
          If rc_gan.concep = '1001' then
            ln_nro_trabajadores_30 := ln_nro_trabajadores_30 + 1 ;
          End if ;
        End if ;
        If ls_bonif = '2' then
          ln_importe_25 := ln_importe_25 + (rc_gan.imp_gan_desc * 0.25) ;
          If rc_gan.concep = '1001' then
            ln_nro_trabajadores_25 := ln_nro_trabajadores_25 + 1 ;
          End if ;
        End if ;
      End if ;
    End if ;
       
    --  Proceso solo para contratados
    If ln_contratado <> 0 then
      If ls_situacion = 'C' then
        rc_gan.imp_gan_desc := nvl(rc_gan.imp_gan_desc,0) ;
        ln_importe          := ln_importe + rc_gan.imp_gan_desc ;
        ln_nro_trabajadores := ln_nro_trabajadores + 1 ;

        If ls_bonif = '1' then
          ln_importe_30 := ln_importe_30 + (rc_gan.imp_gan_desc * 0.30) ;
          If rc_gan.concep = '1001' then
            ln_nro_trabajadores_30 := ln_nro_trabajadores_30 + 1 ;
          End if ;
        End if ;
        If ls_bonif = '2' then
          ln_importe_25 := ln_importe_25 + (rc_gan.imp_gan_desc * 0.25) ;
          If rc_gan.concep = '1001' then
            ln_nro_trabajadores_25 := ln_nro_trabajadores_25 + 1 ;
          End if ;
        End if ;
      End if ;
    End if ;

    End if ;
    
  End Loop ;
     
  --  Insertar los Registro en la tabla tt_rpt_ganancias
  If ln_importe > 0 then
    Insert into tt_rpt_ganancias
      (concep, desc_concep, nro_trabajadores,
       importe)
    Values
      (ls_concepto, ls_desc_concepto, ln_nro_trabajadores,
       ln_importe ) ;
  End if ;
  
End loop ;

--  Insertar los Registro en la tabla tt_rpt_ganancias para 30%
If ln_importe_30 > 0 then
  Insert into tt_rpt_ganancias
    (concep, desc_concep, nro_trabajadores,
     importe)
  Values
    ('1030', 'BONIFICACION 30%         ', ln_nro_trabajadores_30,
     ln_importe_30 ) ;
End if ;

--  Insertar los Registro en la tabla tt_rpt_ganancias para 25%
If ln_importe_25 > 0 then
  Insert into tt_rpt_ganancias
    (concep, desc_concep, nro_trabajadores,
     importe)
  Values
    ('1025', 'BONIFICACION 25%         ', ln_nro_trabajadores_25,
     ln_importe_25 ) ;
End if ;

end usp_rpt_ganancias ;
/
