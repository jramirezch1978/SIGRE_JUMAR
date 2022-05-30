create or replace procedure prueba_centros_costo is

cursor c_c is 
select c.cencos        , c.cod_origen , c.cod_n1       , 
       c.cod_n2        , c.cod_n3     , c.desc_cencos  ,
       c.flag_estado   , c.flag_tipo  , c.flag_mod_pres, 
       c.flag_proyecto , c.email
from aipsa.centros_costo c;

begin
For cr_c in c_c Loop
 Insert Into work1.centros_costo
     ( cencos              , cod_n1           , cod_n2        ,
       cod_n3              , origen           , desc_cencos   ,
       email               , flag_estado      , flag_tipo     ,
       flag_mod_pres       , flag_proyecto)
 Values
     ( cr_c.cencos         , nvl(cr_c.cod_n1,'')     , nvl(cr_c.cod_n2,'') ,
       nvl(cr_c.cod_n3,'') , nvl(cr_c.cod_origen,'') , cr_c.desc_cencos    ,
       cr_c.email          , cr_c.flag_estado        , cr_c.flag_tipo      ,
       cr_c.flag_mod_pres  , cr_C.flag_proyecto);
End Loop;       
end prueba_centros_costo;
/
