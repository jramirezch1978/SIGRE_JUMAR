create or replace procedure x is
total     number(15,2);
begin
  Select sum(gdf.imp_gan_desc)
  into total
  from gan_desct_fijo gdf
  where gdf.flag_estado = '1' and
        gdf.flag_trabaj = '1' and
        gdf.concep = '1001' ;
end x;
/
