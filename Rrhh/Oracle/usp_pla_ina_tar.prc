create or replace procedure usp_pla_ina_tar(
   as_cod_trabajador in char, -- trabajador
   as_tiptra         in char, -- tipo de trabajador
   an_dpla  in int,           -- días de la planilla
   ad_desde in date,          -- inicio de la planilla
   ad_hasta in date,          -- fin de la planilla
   as_ina_des in char) is     -- inasistencia a descontar 

   cursor c_ina_tar is 
      select i.cod_trabajador, i.concep, 
             i.dias_inasist, i.fec_desde, i.fec_hasta
         from inasistencia i
         where i.cod_trabajador = as_cod_trabajador
           and substr(i.concep,1,2) = as_ina_des;
           
   ld_fer1     date;
   ld_fer2     date;
   ld_fer3     date;
   ld_fer4     date;
   ld_fer5     date;
   ln_temp     integer; -- temporal numerico
   ln_tardanza number;
   ln_inasis   integer; -- inasistencias
   ld_fecha    date;    -- fecha de proceso
   ln_dias     integer; -- dias de falta
   ln_dtrb     integer; -- días trabajados
   ln_htrb     number;  -- horas trabajados
           
begin

   select c.dia_feriado1, c.dia_feriado2, c.dia_feriado3, 
          c.dia_feriado4, c.dia_feriado5
   Into   ld_fer1, ld_fer2, ld_fer3, ld_fer4, ld_fer5
   from   control c
   where  c.fec_desde = ad_desde and c.fec_hasta = ad_hasta;
     
   ln_inasis   := 0;  -- días de inasistencias
   ln_tardanza := 0;  -- horas de tardanza
   For rc_ina_tar in c_ina_tar  
   Loop
      If rc_ina_tar.dias_inasist < 8 Then 
         ln_temp := usf_pla_ina_tar_ins ( rc_ina_tar.cod_trabajador, 
            rc_ina_tar.concep, rc_ina_tar.dias_inasist,
            rc_ina_tar.dias_inasist ) ;
         ln_tardanza := ln_tardanza + rc_ina_tar.dias_inasist ;
      Else
         ld_fecha := rc_ina_tar.fec_desde;
         For x in 1 .. (rc_ina_tar.fec_hasta - 
                        rc_ina_tar.fec_desde + 1)
         Loop
            ln_dias  := 1;
            IF as_tiptra = 'O' Then 
               ln_dias := usf_pla_ina_tar_fer ( ld_fecha, ld_fer1,
                 ld_fer2, ld_fer3, ld_fer4, ld_fer5, as_tiptra );
            End If ;
            ln_temp := usf_pla_ina_tar_ins ( rc_ina_tar.cod_trabajador, 
            rc_ina_tar.concep, ln_dias*8, ln_dias) ;
            ln_inasis := ln_inasis + ln_dias;
            ld_fecha := ld_fecha + 1;
         End Loop; 
      End If;
   End Loop;
   
   ln_dtrb := an_dpla-ln_inasis;
   ln_htrb := ((an_dpla-ln_inasis)*8)-ln_tardanza;
   Insert into tt_pla_concep (concep, formula, debe_haber,  
      valor, dtra, htra, hpag ) values ( 'DPLA', '', '+1', 
      an_dpla, ln_dtrb, ln_htrb, ln_htrb );
   Insert into tt_pla_concep (concep, formula, debe_haber,  
      valor, dtra, htra, hpag ) values ( 'DTRB', '', '+1', 
      ln_dtrb, ln_dtrb, ln_htrb, ln_htrb );
   Insert into tt_pla_concep (concep, formula, debe_haber,  
      valor, dtra, htra, hpag ) values ( 'HTRB', '', '+1', 
      ln_htrb, ln_dtrb, ln_htrb, ln_htrb );
end usp_pla_ina_tar;
/
