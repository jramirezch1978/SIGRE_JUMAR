create or replace function usf_pla_ina_tar_fer(
   ad_fecha in date, -- fecha a ser comparada
   ad_fer1 in date, ad_fer2 in date, ad_fer3 in date,
   ad_fer4 in date, ad_fer5 in date,
   as_tiptra in char -- Obrero pierde dominicales, empleado no 
   ) return number is
  ln_dias number;
begin
   ln_dias := 1;
   If ad_fer1 is not null then
      If ad_fer1 > ad_fecha Then
         ln_dias := ln_dias + 1;
      End If;
   End IF;
   If ad_fer2 is not null then
      If ad_fer2 > ad_fecha Then
         ln_dias := ln_dias + 1;
      End If;
   End IF;
   If ad_fer3 is not null then
      If ad_fer3 > ad_fecha Then
         ln_dias := ln_dias + 1;
      End If;
   End IF;
   If ad_fer4 is not null then
      If ad_fer4 > ad_fecha Then
         ln_dias := ln_dias + 1;
      End If;
   End IF;
   If ad_fer5 is not null then
      If ad_fer5 > ad_fecha Then
         ln_dias := ln_dias + 1;
      End If;
   End IF;
   
  return(ln_dias);
end usf_pla_ina_tar_fer;
/
