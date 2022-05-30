create or replace procedure usp_liquidacion
 ( as_codtra in maestro.cod_trabajador%type
  ) is
ls_nombre varchar2(100);
lk_rem_bas constant char(4):='1001';--Concep de REMUN BASICA
lk_niv_inas constant char(3):='051';--Nivel de Inasist
lk_gratif_dev constant char(4):='1301';--concep de Gratif Dev 
lk_remun_dev constant char(4):='1302';--Concep de Remun Dev
lk_snp constant char(4):= '3001';--Concep de SNP

ld_fec_fr_ini date; 
ld_fec_fr_fin date; 
ld_fec_ing date;
ld_fec_cese date; 
ld_fec_ing_vt date; 
ls_desc_cese motivo_cese.desc_motiv_cese%type;
ls_desc_cargo cargo.desc_cargo%type;
ls_tipo_trabaj maestro.tipo_trabajador%type;--Tipo de Trabaj 
ls_cod_liquid_imp_cts char(3);  --Viene de una Tabla TT
ls_anio char(4);
ls_mes char(2);
ls_dia char(2);
ls_cod_afp admin_afp.cod_afp%type; --Cod de AFP 

ln_imp_bas number(13,2); --Importe de Remun Basica
ln_imp_gf number(13,2); --Importe de Ganan Fijas  
ln_imp_fon_ret number(13,2); --Imp del Fond Retiro 
ln_imp_cts_ant number(13,2); --Ant importe CTS   
ln_imp_cts_tot number(13,2); --Tot imp de CTs 
ln_imp_cts_ult number(13,2); --Imp del Ult CTS   
ln_imp_int_cts number(13,2); --Imp de Int de CTS           
ln_imp_remun_dev  number(13,2);
ln_imp_gratif_dev  number(13,2);
ln_imp_mes number(13,2);
ln_imp_dia number(13,2); 
ln_imp_rac number(13,2); 
ln_por_jub admin_afp.porc_jubilac%type;
ln_por_inv admin_afp.porc_invalidez%type;
ln_por_com admin_afp.porc_comision%type;
ln_factor concepto.fact_pago%type;--Factor de SNP  
ln_imp_tot number(13,2);
ln_imp_cts_fin  number(13,2);
ln_imp_adeudo_fin number(13,2);
ln_imp_cnta_crrte number(13,2);  
ln_imp_snp number(13,2);
ln_imp_adeudo number(13,2);
ln_imp_jub number(13,2);
ln_imp_inv number(13,2);
ln_imp_com number(13,2);

ln_mes number(2);
ln_dia number(2);
ln_dias_trabaj number(5,2);
ln_anios number(4,2);
ln_meses number(4,2);
ln_dias number(4,2);
ln_dias_inas number(4,2);
ln_anios_fr number(2);
ln_meses_fr number(2);
ln_dias_fr number(2); 
ln_anios_cts  number(2);
ln_meses_cts number(2);
ln_dias_cts number(2);
ln_anios_tot number(2);
ln_meses_tot number(2);
ln_dias_tot number(2);
ln_dif number(6,2);
ls_resul char(8);
ln_pos number(3);    

begin
--Eliminamos los Registros de cnta cntbl liquidacion
delete cnta_cntbl_liquidacion cc
 where cc.cod_trabajador = as_codtra;

--Asignacion de valores previos 
ld_fec_fr_ini := to_date('31/12/1994','DD/MM/YYYY');
ld_fec_fr_fin := to_date('01/01/1995','DD/MM/YYYY');
 
--Obtenemos el Nombre del Trabajador
ls_nombre := usf_nombre_trabajador(as_codtra);

--Buscamos los Datos del Trabajador
select m.fec_ingreso, m.fec_cese, m.tipo_trabajador,
       m.cod_afp, mc.desc_motiv_cese, c.desc_cargo
 into ld_fec_ing, ld_fec_cese, ls_tipo_trabaj,
      ls_cod_afp, ls_desc_cese, ls_desc_cargo  
from maestro m, motivo_cese mc, cargo c 
where m.cod_trabajador = as_codtra and 
      m.cod_motiv_cese = mc.cod_motiv_cese (+) and 
      m.cod_cargo = c.cod_cargo (+);
ls_desc_cese  := nvl(ls_desc_cese,' ');
ls_desc_cargo := nvl(ls_desc_cargo,' ');
ls_tipo_trabaj:= nvl(ls_tipo_trabaj,'N');
--ls_cod_afp := nvl(ls_cod_afp,'0');  

--Identif del Cod liquidacion EMP u OBR
if UPPER(ls_tipo_trabaj) = 'EMP' Then
   ls_cod_liquid_imp_cts:='003';
ELSIF UPPER(ls_tipo_trabaj) = 'OBR' Then
   ls_cod_liquid_imp_cts:='002';
END IF;                     
      
IF ld_fec_cese IS NOT NULL THEN 
   --Buscamos la REMUN BASICA del Trabaj
   select gdf.imp_gan_desc 
   into ln_imp_bas
   from gan_desct_fijo gdf
   where gdf.cod_trabajador = as_codtra and 
         gdf.concep = lk_rem_bas ;
      
   --Importe Total por las Gananc Fijas
   select sum(gdf.imp_gan_desc)
   into  ln_imp_gf
   from  gan_desct_fijo gdf  
   where gdf.cod_trabajador = as_codtra and 
         substr(gdf.concep,1,1) = '1' and 
         gdf.flag_estado = '1' ;

   --Diferencia de Fechas Totales
   ls_resul := usf_dif_fechas(ld_fec_cese, ld_fec_ing); 
   ln_pos:= INSTR(ls_resul,'?');
   ln_anios_tot := TO_NUMBER(SUBSTR(ls_resul,1,ln_pos - 1));
   ls_resul := SUBSTR(ls_resul,ln_pos + 1 );
   
   --El Numero de Meses y Dias Totales
   ln_pos := INSTR(ls_resul,'?');
   ln_meses_tot :=TO_NUMBER(SUBSTR(ls_resul,1,ln_pos - 1));
   ln_dias_tot := TO_NUMBER(SUBSTR(ls_resul,ln_pos + 1 ));
     
   --Diferencia de Fechas del Fondo de Retiro
   If ld_fec_fr_ini > ld_fec_ing Then 
     ls_resul := usf_dif_fechas(ld_fec_fr_ini,ld_fec_ing);
     ln_pos := INSTR(ls_resul,'?');
     ln_anios_fr := TO_NUMBER(SUBSTR(ls_resul,1,ln_pos - 1)); 
     ls_resul := SUBSTR(ls_resul,ln_pos + 1);
     
     --El Nro de Meses y Dias DEl Fondo Retiro    
     ln_pos := INSTR(ls_resul,'?');
     ln_meses_fr := TO_NUMBER(SUBSTR(ls_resul,1,ln_pos -1));
     ln_dias_fr := TO_NUMBER(SUBSTR(ls_resul,ln_pos + 1));
   Else 
     ln_anios_fr := 0;
     ln_meses_fr := 0;
     ln_dias_fr := 0;
   End if ;
   
   If ld_fec_ing >= ld_fec_fr_fin Then 
      ls_resul := usf_dif_fechas(ld_fec_cese,ld_fec_ing );
   Else 
      ls_resul := usf_dif_fechas(ld_fec_cese ,ld_fec_fr_fin);
   End if;
       
   --Dif de Fechas hasta la FECHA de CESE
   ln_pos := INSTR(ls_resul,'?');
   ln_anios_cts := TO_NUMBER(SUBSTR(ls_resul,1,ln_pos - 1));   
   ls_resul := SUBSTR(ls_resul,ln_pos + 1);
   
   --El Nro de Meses y Dias de la CTS 
   ln_pos := INSTR(ls_resul,'?');
   ln_meses_cts := TO_NUMBER(SUBSTR(ls_resul,1,ln_pos - 1));
   ln_dias_cts := TO_NUMBER(SUBSTR(ls_resul,ln_pos + 1));      

   --Obtenemos los dias para el calculo de la CTS
   select sum(p.dias_trabaj)
   into ln_dias_trabaj
   from prov_cts_gratif p 
   where p.cod_trabajador = as_codtra and 
         p.flag_estado = '1'; 
      
   ln_dias_trabaj := NVL(ln_dias_trabaj,0);   
   ln_dias_trabaj := ln_dias_trabaj + ln_dias_cts;

   --Restamos los dias de Inasistencias
   select sum(i.dias_inasist)
   into ln_dias_inas 
   from inasistencia i, rrhh_nivel_detalle rhd 
   where i.cod_trabajador = as_codtra and 
         i.concep = rhd.concep and 
         rhd.cod_nivel = lk_niv_inas ;
   ln_dias_inas :=nvl(ln_dias_inas,0);
       
   --Nro de dias Trabajados 
   ln_dias_trabaj := ln_dias_trabaj - ln_dias_inas;
   --Importe de la Ultima CTS 
   ln_imp_cts_ult := ln_imp_gf*ln_dias_trabaj/360;
      
   select sum(ccc.imp_prdo_dpsto), 
          sum(ccc.int_legales)
   into ln_imp_cts_ant,
        ln_imp_int_cts  
   from cnta_crrte_cts ccc
   where ccc.cod_trabajador = as_codtra ;
 
   --Insertar la cnta cntble del Fondo de Retiro
   ln_imp_fon_ret := ln_imp_gf*(ln_anios_fr + ln_meses_fr/12+
                                   ln_dias_fr/360); 
                                                      
   If ln_imp_fon_ret > 0 then 
     INSERT INTO cnta_cntbl_liquidacion 
      ( cod_trabajador , cod_liquid   ,  imp_liquid  ,
        fec_movim      , flag_gen_aut ,  cod_moneda  )
     values 
      ( as_codtra      , '001'        , ln_imp_fon_ret ,
        ld_fec_cese    , '1'          ,   'Sol'       );
   End if; 
      
   --Insertar la cnta cntbl de Imp de CTS 
   ln_imp_cts_tot := ln_imp_cts_ant + ln_imp_cts_ult;
   If ln_imp_cts_tot > 0 Then
     INSERT INTO cnta_cntbl_liquidacion 
      ( cod_trabajador , cod_liquid   , imp_liquid ,
        fec_movim      , flag_gen_aut , cod_moneda )
     values 
      ( as_codtra      , ls_cod_liquid_imp_cts , ln_imp_cts_tot , 
        ld_fec_cese    , '1'                   ,   'Sol'       );
   End if;       
   
   --Insertar los Int Legales de la CTS 
   If ln_imp_int_cts > 0 Then   
     INSERT INTO cnta_cntbl_liquidacion
      ( cod_trabajador , cod_liquid   , imp_liquid  ,
        fec_movim      , flag_gen_aut , cod_moneda  )
     values 
      ( as_codtra      , '004'        , ln_imp_int_cts ,
        ld_fec_cese    , '1'          ,   'Sol'       );
   End if; 

   --Descuentos de para la CTs de la Cnta Crrte 
   select sum(cc.sldo_prestamo) 
   into ln_imp_cnta_crrte 
   from cnta_crrte cc
   where cc.cod_trabajador = as_codtra  ;
   ln_imp_cnta_crrte := nvl(ln_imp_cnta_crrte,0);
   
   --/////////////////////////////
   --Importe Final de la CTS 
   ln_imp_cts_fin := ln_imp_fon_ret + ln_imp_cts_tot+ 
                     ln_imp_int_cts - (ln_imp_cnta_crrte);  
   --/////////////////////////////                  
   
   --Obtencion del importe de los devengados 
   --Remuneracion Devengada  
   select sum(mr.nvo_capital + mr.nvo_interes) 
   into ln_imp_remun_dev  
   from maestro_remun_gratif_dev mr 
   where mr.cod_trabajador = as_codtra and 
         mr.concep = lk_remun_dev and 
         mr.fec_pago in ( select max(mr.fec_pago)
                          from maestro_remun_gratif_dev m1
                          where m1.cod_trabajador = as_codtra and 
                                m1.concep = lk_remun_dev );
   ln_imp_remun_dev := nvl(ln_imp_remun_dev,0);
    
   --Gratificacion Devengada  
   select sum(mr.nvo_capital + mr.nvo_interes) 
   into ln_imp_gratif_dev 
   from maestro_remun_gratif_dev mr  
   where mr.cod_trabajador = as_codtra and 
         mr.concep = lk_gratif_dev and 
         mr.fec_pago in ( select max(mr.fec_pago)
                          from maestro_remun_gratif_dev m1
                          where m1.cod_trabajador = as_codtra and 
                                m1.concep = lk_gratif_dev ); 
   ln_imp_gratif_dev := nvl(ln_imp_gratif_dev, 0);
   
   --Vacaciones Truncas 
   If TO_CHAR(ld_fec_ing,'MM')>TO_CHAR(ld_fec_cese,'MM') Then
      ls_anio := TO_CHAR(TO_NUMBER(TO_CHAR(ld_fec_cese,'YYYY')) - 1);
      ls_mes := TO_CHAR(ld_fec_ing,'MM');
      ls_dia := TO_CHAR(ld_fec_ing,'DD');
      --Asignamos la fec de ingreso nueva
      ld_fec_ing_vt := TO_DATE(ls_dia||'/'||ls_mes||'/'||ls_anio,'DD/MM/YYYY');
   Else    
      ls_anio := TO_CHAR(ld_fec_cese,'YYYY');
      ls_mes := TO_CHAR(ld_fec_ing,'MM');
      ls_dia := TO_CHAR(ld_fec_ing,'DD');
      --Asignamos la fec de ingrso nueva
      ld_fec_ing_vt := TO_DATE(ls_dia||'/'||ls_mes||'/'||ls_anio,'DD/MM/YYYY');
   End If;
   --Diferencia de Meses
   ln_mes := TRUNC(MONTHS_BETWEEN(ld_fec_cese,ld_fec_ing_vt));
   ln_dia := (MONTHS_BETWEEN(ld_fec_cese,ld_fec_ing_vt) - ln_mes)* 30 ;
   ln_imp_mes := ln_imp_gf*ln_mes/12;
   ln_imp_dia := ln_imp_gf*ln_dia/360;      
      
   --Importe de Racion de Azucar
   select sum(r.sldo_racion)
   into ln_imp_rac 
   from racion_azucar_deveng r 
   where r.cod_trabajador = as_codtra and 
         r.fec_proceso in ( select max(r1.fec_proceso)
                             from racion_azucar_deveng r1
                             where r1.cod_trabajador = as_codtra );
   ln_imp_rac := nvl(ln_imp_rac,0);
   --Importe de Adeudo Laboral 
   ln_imp_adeudo := ln_imp_remun_dev + ln_imp_gratif_dev +
                    ln_imp_mes + ln_imp_dia + ln_imp_rac; 
    
   --Descuento de Aportaciones por AFP
   If ls_cod_afp is not null then
      select aa.porc_jubilac, aa.porc_invalidez, 
             aa.porc_comision
      into ln_por_jub, ln_por_inv, ln_por_com 
      from admin_afp aa 
      where aa.cod_afp = ls_cod_afp;
      
      --Importes de las Aportaciones
      ln_imp_jub := ln_imp_adeudo*ln_por_jub/100 ;
      ln_imp_inv := ln_imp_adeudo*ln_por_inv/100;
      ln_imp_com := ln_imp_adeudo*ln_por_com/100;         
      --otro caso
      ln_imp_snp := 0;
   Else    
      select c.fact_pago 
      into ln_factor 
      from concepto c
      where c.concep = lk_snp ;
   
      --Importe de SNP 
      ln_imp_snp := ln_imp_adeudo*ln_factor;
      --Otro Caso 
      ln_imp_jub := 0;
      ln_imp_inv := 0;
      ln_imp_com := 0;
   END IF;     
      
   --Ingreso del Aporte de Jubilacion
   If ln_imp_jub > 0 Then   
     INSERT INTO cnta_cntbl_liquidacion
      ( cod_trabajador   ,   cod_liquid   , imp_liquid ,
        fec_movim        ,   flag_gen_aut , cod_moneda  )
     values 
      ( as_codtra        ,   '015'        , ln_imp_jub , 
        ld_fec_cese      ,   '1'          , 'Sol'      );
   End if; 
   
   --Ingreso del Aporte de Invalidez 
   If ln_imp_inv > 0 Then   
     INSERT INTO cnta_cntbl_liquidacion
      ( cod_trabajador   ,   cod_liquid   , imp_liquid  ,
        fec_movim        ,   flag_gen_aut , cod_moneda  )
     values 
      ( as_codtra        ,   '016'        , ln_imp_inv  ,
        ld_fec_cese      ,   '1'          ,   'Sol'       );
   End if; 
   
   --Ingreso del Aporte de Comision 
   If ln_imp_com > 0 Then   
     INSERT INTO cnta_cntbl_liquidacion
      ( cod_trabajador   ,   cod_liquid   ,  imp_liquid ,
        fec_movim        ,   flag_gen_aut ,  cod_moneda  )
     values 
      ( as_codtra        ,   '017'        ,  ln_imp_com ,
        ld_fec_cese      ,   '1'          ,   'Sol'       );
   End if; 
    
   --Ingreso del Aporte del SNP 
   If ln_imp_snp > 0 Then   
     INSERT INTO cnta_cntbl_liquidacion
      ( cod_trabajador   ,   cod_liquid   , imp_liquid ,
        fec_movim        ,   flag_gen_aut , cod_moneda  )
      values 
      ( as_codtra        ,   '018'        , ln_imp_snp ,
        ld_fec_cese      ,   '1'          , 'Sol'      );
   End if; 

   --//////////////////////////////////
   --Importe de la Liquidacion de Adeudos Laborales   
   ln_imp_adeudo_fin := ln_imp_adeudo - (ln_imp_jub + ln_imp_inv +
                                         ln_imp_com + ln_imp_snp );   
   --//////////////////////////////////                                      
   
   --Ingreso de la Cnta Cntbl de la Liquid de Adeudo Lab
   If ln_imp_adeudo_fin > 0 Then 
     Insert Into cnta_cntbl_liquidacion
      ( cod_trabajador , cod_liquid    ,  imp_liquid   ,
        fec_movim      , flag_gen_aut  ,  cod_moneda   )
     values 
      ( as_codtra      , '020'         , ln_imp_adeudo_fin ,
        ld_fec_cese    , '1'           , 'Sol'             );
   End if;
      
   --********************************
   --Monto Total de la lIQUIDACION del Trabajador 
   ln_imp_tot := ln_imp_cts_fin + ln_imp_adeudo_fin;
   --*********************************
   
   --FIn de la obtencion de los Imp DEVENG
   --Insertar en tt_liquidacion 
   insert into tt_liquidacion 
      ( cod_trabajador  ,  nombre          ,   fec_ingreso     ,
        fec_cese        ,  anios_tot       ,   meses_tot       ,
        dias_tot        ,  desc_cese       ,   desc_cargo      ,
        imp_basico      ,  imp_gan_fij     ,   anios_fr        ,
        meses_fr        ,  dias_fr         ,   anios_cts       ,
        meses_cts       ,  dias_cts        ,   dias_trabaj     ,
        imp_cts_ant     ,  imp_int_cts     ,   imp_cts_ult     ,
        imp_remun_dev   ,  imp_gratif_dev  ,   imp_vac_tru_mes ,
        imp_vac_tru_dia ,  imp_rac_azuc    ,   imp_cts_fin     ,
        imp_adeudo_fin  ,  imp_total       )
      values 
      ( as_codtra         ,  ls_nombre         , ld_fec_ing     ,
        ld_fec_cese       ,  ln_anios_tot      , ln_meses_tot   ,
        ln_dias_tot       ,  ls_desc_cese      , ls_desc_cargo  ,
        ln_imp_bas        ,  ln_imp_gf         , ln_anios_fr    ,
        ln_meses_fr       ,  ln_dias_fr        , ln_anios_cts   , 
        ln_meses_cts      ,  ln_dias_cts       , ln_dias_trabaj ,   
        ln_imp_cts_ant    ,  ln_imp_int_cts    , ln_imp_cts_ult ,
        ln_imp_remun_dev  ,  ln_imp_gratif_dev , ln_imp_mes     ,
        ln_imp_dia        ,  ln_imp_rac        , ln_imp_cts_fin ,
        ln_imp_adeudo_fin ,  ln_imp_tot        );  

END IF; --FIN DE FECHA DE CESE  
end usp_liquidacion;
/
