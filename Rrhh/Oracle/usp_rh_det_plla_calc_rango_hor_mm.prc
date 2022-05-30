CREATE OR REPLACE PROCEDURE usp_rh_det_plla_calc_rango_hor (
  as_origen in origen.cod_origen%type, 
  as_tipo_trabaj in tipo_trabajador.tipo_trabajador%type, 
  as_proceso     in char, 
  ad_fec_proceso_ini in date, 
  ad_fec_proceso_fin in date) is

ls_codigo                maestro.cod_trabajador%type ;
ls_nave                  tg_naves.nave%type ;
ls_embarcacion           tg_naves.nave%type ;
ln_count                 number ;
ln_1001                  calculo.imp_soles%type ;
ln_1002                  calculo.imp_soles%type ;
ln_1003                  calculo.imp_soles%type ;
ln_1004                  calculo.imp_soles%type ;
ln_1005                  calculo.imp_soles%type ;
ln_1006                  calculo.imp_soles%type ;
ln_1007                  calculo.imp_soles%type ;
ln_1101                  calculo.imp_soles%type ;
ln_1102                  calculo.imp_soles%type ;
ln_1103                  calculo.imp_soles%type ;
ln_1104                  calculo.imp_soles%type ;
ln_1105                  calculo.imp_soles%type ;
ln_1201                  calculo.imp_soles%type ;
ln_1202                  calculo.imp_soles%type ;
ln_1203                  calculo.imp_soles%type ;
ln_1204                  calculo.imp_soles%type ;
ln_1205                  calculo.imp_soles%type ;
ln_1301                  calculo.imp_soles%type ;
ln_1302                  calculo.imp_soles%type ;
ln_1401                  calculo.imp_soles%type ;
ln_1402                  calculo.imp_soles%type ;
ln_1403                  calculo.imp_soles%type ;
ln_1405                  calculo.imp_soles%type ;
ln_1406                  calculo.imp_soles%type ;
ln_1407                  calculo.imp_soles%type ;
ln_1408                  calculo.imp_soles%type ;
ln_1409                  calculo.imp_soles%type ;
ln_1419                  calculo.imp_soles%type ;
ln_1420                  calculo.imp_soles%type ;
ln_1421                  calculo.imp_soles%type ;
ln_1422                  calculo.imp_soles%type ;
ln_1423                  calculo.imp_soles%type ;
ln_1424                  calculo.imp_soles%type ;
ln_1425                  calculo.imp_soles%type ;
ln_1426                  calculo.imp_soles%type ;
ln_1427                  calculo.imp_soles%type ;
ln_1428                  calculo.imp_soles%type ;
ln_1429                  calculo.imp_soles%type ;
ln_1430                  calculo.imp_soles%type ;
ln_1431                  calculo.imp_soles%type ;
ln_1460                  calculo.imp_soles%type ;
ln_1461                  calculo.imp_soles%type ;
ln_1462                  calculo.imp_soles%type ;
ln_1463                  calculo.imp_soles%type ;
ln_1464                  calculo.imp_soles%type ;
ln_1466                  calculo.imp_soles%type ;
ln_1467                  calculo.imp_soles%type ;
ln_1468                  calculo.imp_soles%type ;
ln_1469                  calculo.imp_soles%type ;
ln_1470                  calculo.imp_soles%type ;
ln_1471                  calculo.imp_soles%type ;
ln_1499                  calculo.imp_soles%type ;
ln_2001                  calculo.imp_soles%type ;
ln_2003                  calculo.imp_soles%type ;
ln_2004                  calculo.imp_soles%type ;
ln_2005                  calculo.imp_soles%type ;
ln_2007                  calculo.imp_soles%type ;
ln_2008                  calculo.imp_soles%type ;
ln_2009                  calculo.imp_soles%type ;
ln_2010                  calculo.imp_soles%type ;
ln_2101                  calculo.imp_soles%type ;
ln_2102                  calculo.imp_soles%type ;
ln_2103                  calculo.imp_soles%type ;
ln_2104                  calculo.imp_soles%type ;
ln_2105                  calculo.imp_soles%type ;
ln_2106                  calculo.imp_soles%type ;
ln_2107                  calculo.imp_soles%type ;
ln_2108                  calculo.imp_soles%type ;
ln_2109                  calculo.imp_soles%type ;
ln_2110                  calculo.imp_soles%type ;
ln_2111                  calculo.imp_soles%type ;
ln_2112                  calculo.imp_soles%type ;
ln_2113                  calculo.imp_soles%type ;
ln_2114                  calculo.imp_soles%type ;
ln_2115                  calculo.imp_soles%type ;
ln_2116                  calculo.imp_soles%type ;
ln_2199                  calculo.imp_soles%type ;
ln_2201                  calculo.imp_soles%type ;
ln_2202                  calculo.imp_soles%type ;
ln_2203                  calculo.imp_soles%type ;
ln_2204                  calculo.imp_soles%type ;
ln_2301                  calculo.imp_soles%type ;
ln_2302                  calculo.imp_soles%type ;
ln_2306                  calculo.imp_soles%type ;
ln_2307                  calculo.imp_soles%type ;
ln_2308                  calculo.imp_soles%type ;
ln_2309                  calculo.imp_soles%type ;
ln_2310                  calculo.imp_soles%type ;
ln_2311                  calculo.imp_soles%type ;
ln_2312                  calculo.imp_soles%type ;
ln_2313                  calculo.imp_soles%type ;
ln_2314                  calculo.imp_soles%type ;
ln_2397                  calculo.imp_soles%type ;
ln_2398                  calculo.imp_soles%type ;
ln_2399                  calculo.imp_soles%type ;
ln_2401                  calculo.imp_soles%type ;
ln_2402                  calculo.imp_soles%type ;
ln_2403                  calculo.imp_soles%type ;
ln_2404                  calculo.imp_soles%type ;
ln_2405                  calculo.imp_soles%type ;
ln_2406                  calculo.imp_soles%type ;
ln_2407                  calculo.imp_soles%type ;
ln_2408                  calculo.imp_soles%type ;
ln_2409                  calculo.imp_soles%type ;
ln_2410                  calculo.imp_soles%type ;
ln_2411                  calculo.imp_soles%type ;
ln_2412                  calculo.imp_soles%type ;
ln_2413                  calculo.imp_soles%type ;
ln_2414                  calculo.imp_soles%type ;
ln_2415                  calculo.imp_soles%type ;
ln_3001                  calculo.imp_soles%type ;
ln_3002                  calculo.imp_soles%type ;
ln_3003                  calculo.imp_soles%type ;
ln_3004                  calculo.imp_soles%type ;
ln_3005                  calculo.imp_soles%type ;
ln_3006                  calculo.imp_soles%type ;
ln_3007                  calculo.imp_soles%type ;
ln_3008                  calculo.imp_soles%type ;
ln_3099                  calculo.imp_soles%type ;
ln_7001                  calculo.imp_soles%type ;
ln_7002                  calculo.imp_soles%type ;
ln_7003                  calculo.imp_soles%type ;
ln_7004                  calculo.imp_soles%type ;
ln_7005                  calculo.imp_soles%type ;
ln_7006                  calculo.imp_soles%type ;
ln_7007                  calculo.imp_soles%type ;
ln_7008                  calculo.imp_soles%type ;
ln_7009                  calculo.imp_soles%type ;
ln_7010                  calculo.imp_soles%type ;
ln_7011                  calculo.imp_soles%type ;
ln_7012                  calculo.imp_soles%type ;
ln_7013                  calculo.imp_soles%type ;


--  Maestro de trabajadores segun origen y tipo de trabajador
CURSOR c_maestro is
  select m.cod_trabajador, m.dni, m.cod_origen, 
         m.tipo_trabajador, aos.cod_sede, ats.tipo_plla 
    from maestro m, aux_origen_sede aos, aux_tipo_trab_sede ats  
   where m.cod_origen = aos.cod_origen and
         m.tipo_trabajador = ats.tipo_trabajador and  
         m.cod_origen = as_origen and 
         m.tipo_trabajador like as_tipo_trabaj ;

--  Detalle de la planilla calculada actual
CURSOR c_calculo(as_codigo in maestro.cod_trabajador%type) is
  select c.concep, c.imp_soles, c.dias_trabaj, c.horas_trabaj, to_number(to_char(c.fec_proceso,'mm')) as mes
    from calculo c 
   where (c.cod_trabajador = as_codigo) and 
         (trunc(c.fec_proceso) between ad_fec_proceso_ini and ad_fec_proceso_fin) ;

--  Detalle de la planilla calcula historica
CURSOR c_historico(as_codigo  in maestro.cod_trabajador%type) is
  select h.concep, h.imp_soles, h.dias_trabaj, h.horas_trabaj, to_number(to_char(h.fec_calc_plan,'mm')) as mes
    from historico_calculo h
   where (h.cod_trabajador = as_codigo) and 
         (trunc(h.fec_calc_plan) between ad_fec_proceso_ini and ad_fec_proceso_fin) ;

BEGIN 

--  ********************************************************
--  ***   REPORTE DEL DETALLE DE LA PLANILLA CALCULADA   ***
--  ********************************************************

delete from tt_rpt_plla_calculada_cgsa ;

FOR rc_m in c_maestro loop
    
    FOR rc_c in c_calculo(rc_m.cod_trabajador) LOOP 
        -- Inicializa variables
        ln_1001:=0;            ln_1002:=0;          ln_1003:=0;                     ln_1004:=0;
        ln_1005:=0;            ln_1006:=0;          ln_1007:=0;                     ln_1101:=0;
        ln_1102:=0;            ln_1103:=0;          ln_1104:=0;                     ln_1105:=0;
        ln_1201:=0;            ln_1202:=0;          ln_1203:=0;                     ln_1204:=0;
        ln_1205:=0;            ln_1301:=0;          ln_1302:=0;                     ln_1401:=0;
        ln_1402:=0;            ln_1403:=0;          ln_1405:=0;                     ln_1406:=0;
        ln_1407:=0;            ln_1408:=0;          ln_1409:=0;                     ln_1419:=0;
        ln_1420:=0;            ln_1421:=0;          ln_1422:=0;                     ln_1423:=0;
        ln_1424:=0;            ln_1425:=0;          ln_1426:=0;                     ln_1427:=0;
        ln_1428:=0;            ln_1429:=0;          ln_1430:=0;                     ln_1431:=0;
        ln_1460:=0;            ln_1461:=0;          ln_1462:=0;                     ln_1463:=0;
        ln_1464:=0;            ln_1466:=0;          ln_1467:=0;                     ln_1468:=0;
        ln_1469:=0;            ln_1470:=0;          ln_1471:=0;                     ln_1499:=0;

        ln_2001:=0;
        ln_2003:=0;            ln_2004:=0;          ln_2005:=0;                     ln_2007:=0;
        ln_2008:=0;            ln_2009:=0;          ln_2010:=0;                     ln_2101:=0;
        ln_2102:=0;            ln_2103:=0;          ln_2104:=0;                     ln_2105:=0;
        ln_2106:=0;            ln_2107:=0;          ln_2108:=0;                     ln_2109:=0;
        ln_2110:=0;            ln_2111:=0;          ln_2112:=0;                     ln_2113:=0;
        ln_2114:=0;            ln_2115:=0;          ln_2116:=0;                     ln_2199:=0;
        ln_2201:=0;            ln_2202:=0;          ln_2203:=0;                     ln_2204:=0;
        ln_2301:=0;            ln_2302:=0;          ln_2306:=0;                     ln_2307:=0;
        ln_2308:=0;            ln_2309:=0;          ln_2310:=0;                     ln_2311:=0;
        ln_2312:=0;            ln_2313:=0;          ln_2314:=0;                     ln_2397:=0;
        ln_2398:=0;            ln_2399:=0;          ln_2401:=0;                     ln_2402:=0;
        ln_2403:=0;            ln_2404:=0;          ln_2405:=0;                     ln_2406:=0;
        ln_2407:=0;            ln_2408:=0;          ln_2409:=0;                     ln_2410:=0;
        ln_2411:=0;            ln_2412:=0;          ln_2413:=0;                     ln_2414:=0;
        ln_2415:=0;            
        
        ln_3001:=0;            ln_3002:=0;          ln_3003:=0;                     ln_3004:=0;
        ln_3005:=0;            ln_3006:=0;          ln_3007:=0;                     ln_3008:=0;
        ln_3099:=0;          

        ln_7001:=0;            ln_7002:=0;          ln_7003:=0;                     ln_7004:=0;
        ln_7005:=0;            ln_7006:=0;          ln_7007:=0;                     ln_7008:=0;
        ln_7009:=0;            ln_7010:=0;          ln_7011:=0;                     ln_7012:=0;
        ln_7013:=0;
        
        -- Actualiza variables por cada concepto
        IF    rc_c.concep = '1001' THEN 
           ln_1001 := NVL(rc_c.imp_soles,0) ;
           ln_7001 := NVL(rc_c.dias_trabaj,0);
           ln_7002 := NVL(rc_c.horas_trabaj,0);
        ELSIF rc_c.concep = '1002' THEN 
           ln_1002 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1003' THEN 
           ln_1003 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1004' THEN
           ln_1004 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1005' THEN
           ln_1005 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1006' THEN
           ln_1006 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1007' THEN
           ln_1007 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1101' THEN
           ln_1101 := NVL(rc_c.imp_soles,0) ;
           ln_7003 := NVL(rc_c.horas_trabaj,0) ;
        ELSIF rc_c.concep = '1102' THEN
           ln_1102 := NVL(rc_c.imp_soles,0) ;
           ln_7004 := NVL(rc_c.horas_trabaj,0) ;
        ELSIF rc_c.concep = '1103' THEN
           ln_1103 := NVL(rc_c.imp_soles,0) ;
           ln_7005 := NVL(rc_c.horas_trabaj,0) ;
        ELSIF rc_c.concep = '1104' THEN
           ln_1104 := NVL(rc_c.imp_soles,0) ;
           ln_7006 := NVL(rc_c.horas_trabaj,0) ;
        ELSIF rc_c.concep = '1105' THEN
           ln_1105 := NVL(rc_c.imp_soles,0) ;
           ln_7007 := NVL(rc_c.horas_trabaj,0) ;
        ELSIF rc_c.concep = '1201' THEN
           ln_1201 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1202' THEN
           ln_1202 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1203' THEN
           ln_1203 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1204' THEN
           ln_1204 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1205' THEN
           ln_1205 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1301' THEN
           ln_1301 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1302' THEN
           ln_1302 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1401' THEN
           ln_1401 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1402' THEN
           ln_1402 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1403' THEN
           ln_1403 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1405' THEN
           ln_1405 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1406' THEN
           ln_1406 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1407' THEN
           ln_1407 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1408' THEN
           ln_1408 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1409' THEN
           ln_1409 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1419' THEN
           ln_1419 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1420' THEN
           ln_1420 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1421' THEN
           ln_1421 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1422' THEN
           ln_1422 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1423' THEN
           ln_1423 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1424' THEN
           ln_1424 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1425' THEN
           ln_1425 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1426' THEN
           ln_1426 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1427' THEN
           ln_1427 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1428' THEN
           ln_1428 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1429' THEN
           ln_1429 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1430' THEN
           ln_1430 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1431' THEN
           ln_1431 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1460' THEN
           ln_1460 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1461' THEN
           ln_1461 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1462' THEN
           ln_1462 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1463' THEN
           ln_1463 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1464' THEN
           ln_1464 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1466' THEN
           ln_1466 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1467' THEN
           ln_1467 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1468' THEN
           ln_1468 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1469' THEN
           ln_1469 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1470' THEN
           ln_1470 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1471' THEN
           ln_1471 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '1499' THEN
           ln_1499 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2001' THEN
           ln_2001 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2003' THEN
           ln_2003 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2004' THEN
           ln_2004 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2005' THEN
           ln_2005 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2007' THEN
           ln_2007 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2008' THEN
           ln_2008 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2009' THEN
           ln_2009 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2010' THEN
           ln_2010 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2101' THEN
           ln_2101 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2102' THEN
           ln_2102 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2103' THEN
           ln_2103 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2104' THEN
           ln_2104 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2105' THEN
           ln_2105 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2106' THEN
           ln_2106 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2107' THEN
           ln_2107 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2108' THEN
           ln_2108 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2109' THEN
           ln_2109 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2110' THEN
           ln_2110 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2111' THEN
           ln_2111 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2112' THEN
           ln_2112 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2113' THEN
           ln_2113 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2114' THEN
           ln_2114 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2115' THEN
           ln_2115 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2116' THEN
           ln_2116 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2199' THEN
           ln_2199 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2201' THEN
           ln_2201 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2202' THEN
           ln_2202 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2203' THEN
           ln_2203 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2204' THEN
           ln_2204 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2301' THEN
           ln_2301 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2302' THEN
           ln_2302 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2306' THEN
           ln_2306 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2307' THEN
           ln_2307 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2308' THEN
           ln_2308 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2309' THEN
           ln_2309 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2310' THEN
           ln_2310 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2311' THEN
           ln_2311 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2312' THEN
           ln_2312 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2313' THEN
           ln_2313 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2314' THEN
           ln_2314 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2397' THEN
           ln_2397 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2398' THEN
           ln_2398 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2399' THEN
           ln_2399 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2401' THEN
           ln_2401 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2402' THEN
           ln_2402 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2403' THEN
           ln_2403 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2404' THEN
           ln_2404 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2405' THEN
           ln_2405 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2406' THEN
           ln_2406 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2407' THEN
           ln_2407 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2408' THEN
           ln_2408 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2409' THEN
           ln_2409 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2410' THEN
           ln_2410 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2411' THEN
           ln_2411 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2412' THEN
           ln_2412 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2413' THEN
           ln_2413 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2414' THEN
           ln_2414 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '2415' THEN
           ln_2415 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '3001' THEN
           ln_3001 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '3002' THEN
           ln_3002 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '3003' THEN
           ln_3003 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '3004' THEN
           ln_3004 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '3005' THEN
           ln_3005 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '3006' THEN
           ln_3006 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '3007' THEN
           ln_3007 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '3008' THEN
           ln_3008 := NVL(rc_c.imp_soles,0) ;
        ELSIF rc_c.concep = '3099' THEN
           ln_3099 := NVL(rc_c.imp_soles,0) ;
        END IF ;

        -- Actualiza en caso ya exista el registro     
        UPDATE tt_rpt_plla_calculada_cgsa tt 
           SET tt.c1001 = NVL(tt.c1001,0) + NVL(ln_1001,0), 
               tt.c1002 = NVL(tt.c1002,0) + NVL(ln_1002,0),
               tt.c1003 = NVL(tt.c1003,0) + NVL(ln_1003,0), 
               tt.c1004 = NVL(tt.c1004,0) + NVL(ln_1004,0), 
               tt.c1005 = NVL(tt.c1005,0) + NVL(ln_1005,0), 
               tt.c1006 = NVL(tt.c1006,0) + NVL(ln_1006,0), 
               tt.c1007 = NVL(tt.c1007,0) + NVL(ln_1007,0), 
               tt.c1101 = NVL(tt.c1101,0) + NVL(ln_1101,0), 
               tt.c1102 = NVL(tt.c1102,0) + NVL(ln_1102,0), 
               tt.c1103 = NVL(tt.c1103,0) + NVL(ln_1103,0), 
               tt.c1104 = NVL(tt.c1104,0) + NVL(ln_1104,0), 
               tt.c1105 = NVL(tt.c1105,0) + NVL(ln_1105,0), 
               tt.c1201 = NVL(tt.c1201,0) + NVL(ln_1201,0), 
               tt.c1202 = NVL(tt.c1202,0) + NVL(ln_1202,0), 
               tt.c1203 = NVL(tt.c1203,0) + NVL(ln_1203,0), 
               tt.c1204 = NVL(tt.c1204,0) + NVL(ln_1204,0), 
               tt.c1205 = NVL(tt.c1205,0) + NVL(ln_1205,0), 
               tt.c1301 = NVL(tt.c1301,0) + NVL(ln_1301,0), 
               tt.c1302 = NVL(tt.c1302,0) + NVL(ln_1302,0), 
               tt.c1401 = NVL(tt.c1401,0) + NVL(ln_1401,0), 
               tt.c1402 = NVL(tt.c1402,0) + NVL(ln_1402,0), 
               tt.c1403 = NVL(tt.c1403,0) + NVL(ln_1403,0), 
               tt.c1405 = NVL(tt.c1405,0) + NVL(ln_1405,0), 
               tt.c1406 = NVL(tt.c1406,0) + NVL(ln_1406,0), 
               tt.c1407 = NVL(tt.c1407,0) + NVL(ln_1407,0), 
               tt.c1408 = NVL(tt.c1408,0) + NVL(ln_1408,0), 
               tt.c1409 = NVL(tt.c1409,0) + NVL(ln_1409,0), 
               tt.c1419 = NVL(tt.c1419,0) + NVL(ln_1419,0), 
               tt.c1420 = NVL(tt.c1420,0) + NVL(ln_1420,0), 
               tt.c1421 = NVL(tt.c1421,0) + NVL(ln_1421,0), 
               tt.c1422 = NVL(tt.c1422,0) + NVL(ln_1422,0), 
               tt.c1423 = NVL(tt.c1423,0) + NVL(ln_1423,0), 
               tt.c1424 = NVL(tt.c1424,0) + NVL(ln_1424,0), 
               tt.c1425 = NVL(tt.c1425,0) + NVL(ln_1425,0), 
               tt.c1426 = NVL(tt.c1426,0) + NVL(ln_1426,0), 
               tt.c1427 = NVL(tt.c1427,0) + NVL(ln_1427,0), 
               tt.c1428 = NVL(tt.c1428,0) + NVL(ln_1428,0), 
               tt.c1429 = NVL(tt.c1429,0) + NVL(ln_1429,0), 
               tt.c1430 = NVL(tt.c1430,0) + NVL(ln_1430,0),
               tt.c1431 = NVL(tt.c1431,0) + NVL(ln_1431,0), 
               tt.c1460 = NVL(tt.c1460,0) + NVL(ln_1460,0), 
               tt.c1461 = NVL(tt.c1461,0) + NVL(ln_1461,0),   
               tt.c1462 = NVL(tt.c1462,0) + NVL(ln_1462,0),   
               tt.c1463 = NVL(tt.c1463,0) + NVL(ln_1463,0),
               tt.c1464 = NVL(tt.c1464,0) + NVL(ln_1464,0),   
               tt.c1466 = NVL(tt.c1466,0) + NVL(ln_1466,0),   
               tt.c1467 = NVL(tt.c1467,0) + NVL(ln_1467,0),   
               tt.c1468 = NVL(tt.c1468,0) + NVL(ln_1468,0),   
               tt.c1469 = NVL(tt.c1469,0) + NVL(ln_1469,0),   
               tt.c1470 = NVL(tt.c1470,0) + NVL(ln_1470,0),
               tt.c1499 = NVL(tt.c1499,0) + NVL(ln_1499,0),
               tt.c2001 = NVL(tt.c2001,0) + NVL(ln_2001,0),
               tt.c2003 = NVL(tt.c2003,0) + NVL(ln_2003,0),
               tt.c2004 = NVL(tt.c2004,0) + NVL(ln_2004,0),
               tt.c2005 = NVL(tt.c2005,0) + NVL(ln_2005,0),
               tt.c2007 = NVL(tt.c2007,0) + NVL(ln_2007,0),
               tt.c2008 = NVL(tt.c2008,0) + NVL(ln_2008,0),
               tt.c2009 = NVL(tt.c2009,0) + NVL(ln_2009,0),
               tt.c2010 = NVL(tt.c2010,0) + NVL(ln_2010,0),
               tt.c2101 = NVL(tt.c2101,0) + NVL(ln_2101,0),
               tt.c2102 = NVL(tt.c2102,0) + NVL(ln_2102,0),
               tt.c2103 = NVL(tt.c2103,0) + NVL(ln_2103,0),
               tt.c2104 = NVL(tt.c2104,0) + NVL(ln_2104,0),
               tt.c2105 = NVL(tt.c2105,0) + NVL(ln_2105,0),
               tt.c2106 = NVL(tt.c2106,0) + NVL(ln_2106,0),
               tt.c2107 = NVL(tt.c2107,0) + NVL(ln_2107,0),
               tt.c2108 = NVL(tt.c2108,0) + NVL(ln_2108,0),
               tt.c2109 = NVL(tt.c2109,0) + NVL(ln_2109,0),
               tt.c2110 = NVL(tt.c2110,0) + NVL(ln_2110,0),
               tt.c2111 = NVL(tt.c2111,0) + NVL(ln_2111,0),
               tt.c2112 = NVL(tt.c2112,0) + NVL(ln_2112,0),
               tt.c2113 = NVL(tt.c2113,0) + NVL(ln_2113,0),
               tt.c2114 = NVL(tt.c2114,0) + NVL(ln_2114,0),
               tt.c2115 = NVL(tt.c2115,0) + NVL(ln_2115,0),
               tt.c2116 = NVL(tt.c2116,0) + NVL(ln_2116,0),
               tt.c2199 = NVL(tt.c2199,0) + NVL(ln_2199,0),
               tt.c2201 = NVL(tt.c2201,0) + NVL(ln_2201,0),
               tt.c2202 = NVL(tt.c2202,0) + NVL(ln_2202,0),
               tt.c2203 = NVL(tt.c2203,0) + NVL(ln_2203,0),
               tt.c2204 = NVL(tt.c2204,0) + NVL(ln_2204,0),
               tt.c2301 = NVL(tt.c2301,0) + NVL(ln_2301,0),
               tt.c2302 = NVL(tt.c2302,0) + NVL(ln_2302,0),
               tt.c2306 = NVL(tt.c2306,0) + NVL(ln_2306,0),
               tt.c2307 = NVL(tt.c2307,0) + NVL(ln_2307,0),
               tt.c2308 = NVL(tt.c2308,0) + NVL(ln_2308,0),
               tt.c2309 = NVL(tt.c2309,0) + NVL(ln_2309,0),
               tt.c2310 = NVL(tt.c2310,0) + NVL(ln_2310,0),
               tt.c2311 = NVL(tt.c2311,0) + NVL(ln_2311,0),
               tt.c2312 = NVL(tt.c2312,0) + NVL(ln_2312,0),
               tt.c2313 = NVL(tt.c2313,0) + NVL(ln_2313,0),
               tt.c2314 = NVL(tt.c2314,0) + NVL(ln_2314,0),
               tt.c2397 = NVL(tt.c2397,0) + NVL(ln_2397,0),
               tt.c2398 = NVL(tt.c2398,0) + NVL(ln_2398,0),
               tt.c2399 = NVL(tt.c2399,0) + NVL(ln_2399,0),
               tt.c2401 = NVL(tt.c2401,0) + NVL(ln_2401,0),
               tt.c2402 = NVL(tt.c2402,0) + NVL(ln_2402,0),
               tt.c2403 = NVL(tt.c2403,0) + NVL(ln_2403,0),
               tt.c2404 = NVL(tt.c2404,0) + NVL(ln_2404,0),
               tt.c2405 = NVL(tt.c2405,0) + NVL(ln_2405,0),
               tt.c2406 = NVL(tt.c2406,0) + NVL(ln_2406,0),
               tt.c2407 = NVL(tt.c2407,0) + NVL(ln_2407,0),
               tt.c2408 = NVL(tt.c2408,0) + NVL(ln_2408,0),
               tt.c2409 = NVL(tt.c2409,0) + NVL(ln_2409,0),
               tt.c2410 = NVL(tt.c2410,0) + NVL(ln_2410,0),
               tt.c2411 = NVL(tt.c2411,0) + NVL(ln_2411,0),
               tt.c2412 = NVL(tt.c2412,0) + NVL(ln_2412,0),
               tt.c2413 = NVL(tt.c2413,0) + NVL(ln_2413,0),
               tt.c2414 = NVL(tt.c2414,0) + NVL(ln_2414,0),
               tt.c2415 = NVL(tt.c2415,0) + NVL(ln_2415,0),
               tt.c3001 = NVL(tt.c3001,0) + NVL(ln_3001,0),
               tt.c3002 = NVL(tt.c3002,0) + NVL(ln_3002,0),
               tt.c3003 = NVL(tt.c3003,0) + NVL(ln_3003,0),
               tt.c3004 = NVL(tt.c3004,0) + NVL(ln_3004,0),
               tt.c3005 = NVL(tt.c3005,0) + NVL(ln_3005,0),
               tt.c3006 = NVL(tt.c3006,0) + NVL(ln_3006,0),
               tt.c3007 = NVL(tt.c3007,0) + NVL(ln_3007,0),
               tt.c3008 = NVL(tt.c3008,0) + NVL(ln_3008,0),
               tt.c3099 = NVL(tt.c3099,0) + NVL(ln_3099,0) 
         WHERE tt.cod_trabajador = rc_m.cod_trabajador and
               tt.mes            = rc_c.mes ; 
               
        -- Actualiza dias trabajados
        IF ln_7001 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7001 = NVL(tt.c7001,0) + ln_7001
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_c.mes;
        END IF ;

        -- Actualiza horas trabajados
        IF ln_7002 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7002 = NVL(tt.c7002,0) + ln_7002
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_c.mes;
        END IF ;
        
        -- Actualiza horas extras 25%
        IF ln_7003 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7003 = NVL(tt.c7003,0) + ln_7003
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_c.mes;
        END IF ;
        
        -- Actualiza horas extras al 35%
        IF ln_7004 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7004 = NVL(tt.c7004,0) + ln_7004
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_c.mes;
        END IF ;
        
        -- Actualiza horas extras al 50%
        IF ln_7005 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7005 = NVL(tt.c7005,0) + ln_7005
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_c.mes;
        END IF ;
        
        -- Actualiza horas extras dominicales 
        IF ln_7006 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7006 = NVL(tt.c7006,0) + ln_7006
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_c.mes;
        END IF ;
        
        -- Actualiza horas extras feriados
        IF ln_7007 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7007 = NVL(tt.c7007,0) + ln_7007
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_c.mes;
        END IF ;

        -- Adiciona en caso no exista el registro
        IF SQL%NOTFOUND THEN 
            insert into tt_rpt_plla_calculada_cgsa(
              origen, tipo_trabajador, fecha_ini, fecha_fin, cod_trabajador,
              nave, sede, tipo_plla, proceso, mes,
              id_embarcacion, dni, c1001, c1002, c1003,
              c1004, c1005, c1006, c1007, c1101,
              c1102, c1103, c1104, c1105, c1201,
              c1202, c1203, c1204, c1205, c1301,
              c1302, c1401, c1402, c1403, c1405,
              c1406, c1407, c1408, c1409, c1419, 
              c1420, c1421, c1422, c1423, c1424, 
              c1425, c1426, c1427, c1428, c1429, 
              c1430, c1431, c1460, c1461, c1462, 
              c1463, c1464, c1466, c1467, c1468, 
              c1469, c1470, c1471, c1499, 
              c2001, 
              c2003, c2004, c2005, c2007, c2008, 
              c2009, c2010, c2101, c2102, c2103, 
              c2104, c2105, c2106, c2107, c2108, 
              c2109, c2110, c2111, c2112, c2113, 
              c2114, c2115, c2116, c2199, c2201, 
              c2202, c2203, c2204, c2301, c2302, 
              c2306, c2307, c2308, c2309, c2310, 
              c2311, c2312, c2313, c2314, c2397, 
              c2398, c2399, c2401, c2402, c2403, 
              c2404, c2405, c2406, c2407, c2408, 
              c2409, c2410, c2411, c2412, c2413, 
              c2414, c2415, 
              c3001, c3002, c3003, 
              c3004, c3005, c3006, c3007, c3008, 
              c3099, 
              c7001, c7002, c7003, c7004, 
              c7005, c7006, c7007, c7008, c7009, 
              c7010, c7011, c7012, c7013) 
            values (
              rc_m.cod_origen, rc_m.tipo_trabajador, ad_fec_proceso_ini, ad_fec_proceso_fin, rc_m.cod_trabajador, 
              ls_nave, rc_m.cod_sede, rc_m.tipo_plla, as_proceso, rc_c.mes, 
              ls_embarcacion, rc_m.dni, ln_1001, ln_1002, ln_1003, 
              ln_1004, ln_1005, ln_1006, ln_1007, ln_1101, 
              ln_1102, ln_1103, ln_1104, ln_1105, ln_1201, 
              ln_1202, ln_1203, ln_1204, ln_1205, ln_1301, 
              ln_1302, ln_1401, ln_1402, ln_1403, ln_1405, 
              ln_1406, ln_1407, ln_1408, ln_1409, ln_1419, 
              ln_1420, ln_1421, ln_1422, ln_1423, ln_1424, 
              ln_1425, ln_1426, ln_1427, ln_1428, ln_1429, 
              ln_1430, ln_1431, ln_1460, ln_1461, ln_1462, 
              ln_1463, ln_1464, ln_1466, ln_1467, ln_1468, 
              ln_1469, ln_1470, ln_1471, ln_1499, 
              ln_2001, 
              ln_2003, ln_2004, ln_2005, ln_2007, ln_2008, 
              ln_2009, ln_2010, ln_2101, ln_2102, ln_2103, 
              ln_2104, ln_2105, ln_2106, ln_2107, ln_2108, 
              ln_2109, ln_2110, ln_2111, ln_2112, ln_2113, 
              ln_2114, ln_2115, ln_2116, ln_2199, ln_2201, 
              ln_2202, ln_2203, ln_2204, ln_2301, ln_2302, 
              ln_2306, ln_2307, ln_2308, ln_2309, ln_2310, 
              ln_2311, ln_2312, ln_2313, ln_2314, ln_2397, 
              ln_2398, ln_2399, ln_2401, ln_2402, ln_2403,
              ln_2404, ln_2405, ln_2406, ln_2407, ln_2408,
              ln_2409, ln_2410, ln_2411, ln_2412, ln_2413, 
              ln_2414, ln_2415, 
              ln_3001, ln_3002, ln_3003, 
              ln_3004, ln_3005, ln_3006, ln_3007, ln_3008, 
              ln_3099, 
              ln_7001, ln_7002, ln_7003, ln_7004, 
              ln_7005, ln_7006, ln_7007, ln_7008, ln_7009, 
              ln_7010, ln_7011, ln_7012, ln_7013) ;
        END IF ;  
    END LOOP ;
  

  FOR rc_h in c_historico(rc_m.cod_trabajador) LOOP
        -- Inicializa variables
        ln_1001:=0;            ln_1002:=0;          ln_1003:=0;                     ln_1004:=0;
        ln_1005:=0;            ln_1006:=0;          ln_1007:=0;                     ln_1101:=0;
        ln_1102:=0;            ln_1103:=0;          ln_1104:=0;                     ln_1105:=0;
        ln_1201:=0;            ln_1202:=0;          ln_1203:=0;                     ln_1204:=0;
        ln_1205:=0;            ln_1301:=0;          ln_1302:=0;                     ln_1401:=0;
        ln_1402:=0;            ln_1403:=0;          ln_1405:=0;                     ln_1406:=0;
        ln_1407:=0;            ln_1408:=0;          ln_1409:=0;                     ln_1419:=0;
        ln_1420:=0;            ln_1421:=0;          ln_1422:=0;                     ln_1423:=0;
        ln_1424:=0;            ln_1425:=0;          ln_1426:=0;                     ln_1427:=0;
        ln_1428:=0;            ln_1429:=0;          ln_1430:=0;                     ln_1431:=0;
        ln_1460:=0;            ln_1461:=0;          ln_1462:=0;                     ln_1463:=0;
        ln_1464:=0;            ln_1466:=0;          ln_1467:=0;                     ln_1468:=0;
        ln_1469:=0;            ln_1470:=0;          ln_1471:=0;                     ln_1499:=0;
        ln_2001:=0;
        ln_2003:=0;            ln_2004:=0;          ln_2005:=0;                     ln_2007:=0;
        ln_2008:=0;            ln_2009:=0;          ln_2010:=0;                     ln_2101:=0;
        ln_2102:=0;            ln_2103:=0;          ln_2104:=0;                     ln_2105:=0;
        ln_2106:=0;            ln_2107:=0;          ln_2108:=0;                     ln_2109:=0;
        ln_2110:=0;            ln_2111:=0;          ln_2112:=0;                     ln_2113:=0;
        ln_2114:=0;            ln_2115:=0;          ln_2116:=0;                     ln_2199:=0;
        ln_2201:=0;            ln_2202:=0;          ln_2203:=0;                     ln_2204:=0;
        ln_2301:=0;            ln_2302:=0;          ln_2306:=0;                     ln_2307:=0;
        ln_2308:=0;            ln_2309:=0;          ln_2310:=0;                     ln_2311:=0;
        ln_2312:=0;            ln_2313:=0;          ln_2314:=0;                     ln_2397:=0;
        ln_2398:=0;            ln_2399:=0;          ln_2401:=0;                     ln_2402:=0;
        ln_2403:=0;            ln_2404:=0;          ln_2405:=0;                     ln_2406:=0;
        ln_2407:=0;            ln_2408:=0;          ln_2409:=0;                     ln_2410:=0;
        ln_2411:=0;            ln_2412:=0;          ln_2413:=0;                     ln_2414:=0;
        ln_2415:=0;            
        ln_3001:=0;            ln_3002:=0;          ln_3003:=0;
        ln_3004:=0;            ln_3005:=0;          ln_3006:=0;                     ln_3007:=0;
        ln_3008:=0;            ln_3099:=0;
        ln_7001:=0;            ln_7002:=0;          ln_7003:=0;                     ln_7004:=0;
        ln_7005:=0;            ln_7006:=0;          ln_7007:=0;                     ln_7008:=0;
        ln_7009:=0;            ln_7010:=0;          ln_7011:=0;                     ln_7012:=0;
        ln_7013:=0;
   
        
        -- Actualiza variables por cada concepto
        IF    rc_h.concep = '1001' THEN 
           ln_1001 := NVL(rc_h.imp_soles,0) ;
           ln_7001 := NVL(rc_h.dias_trabaj,0) ;
           ln_7002 := NVL(rc_h.horas_trabaj,0) ;
        ELSIF rc_h.concep = '1002' THEN 
           ln_1002 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1003' THEN 
           ln_1003 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1004' THEN
           ln_1004 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1005' THEN
           ln_1005 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1006' THEN
           ln_1006 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1007' THEN
           ln_1007 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1101' THEN
           ln_1101 := NVL(rc_h.imp_soles,0) ;
           ln_7003 := NVL(rc_h.horas_trabaj,0) ;
        ELSIF rc_h.concep = '1102' THEN
           ln_1102 := NVL(rc_h.imp_soles,0) ;
           ln_7004 := NVL(rc_h.horas_trabaj,0) ;           
        ELSIF rc_h.concep = '1103' THEN
           ln_1103 := NVL(rc_h.imp_soles,0) ;
           ln_7005 := NVL(rc_h.horas_trabaj,0) ;                      
        ELSIF rc_h.concep = '1104' THEN
           ln_1104 := NVL(rc_h.imp_soles,0) ;
           ln_7006 := NVL(rc_h.horas_trabaj,0) ;                      
        ELSIF rc_h.concep = '1105' THEN
           ln_1105 := NVL(rc_h.imp_soles,0) ;
           ln_7007 := NVL(rc_h.horas_trabaj,0) ;                                 
        ELSIF rc_h.concep = '1201' THEN
           ln_1201 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1202' THEN
           ln_1202 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1203' THEN
           ln_1203 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1204' THEN
           ln_1204 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1205' THEN
           ln_1205 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1301' THEN
           ln_1301 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1302' THEN
           ln_1302 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1401' THEN
           ln_1401 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1402' THEN
           ln_1402 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1403' THEN
           ln_1403 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1405' THEN
           ln_1405 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1406' THEN
           ln_1406 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1407' THEN
           ln_1407 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1408' THEN
           ln_1408 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1409' THEN
           ln_1409 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1419' THEN
           ln_1419 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1420' THEN
           ln_1420 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1421' THEN
           ln_1421 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1422' THEN
           ln_1422 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1423' THEN
           ln_1423 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1424' THEN
           ln_1424 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1425' THEN
           ln_1425 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1426' THEN
           ln_1426 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1427' THEN
           ln_1427 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1428' THEN
           ln_1428 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1429' THEN
           ln_1429 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1430' THEN
           ln_1430 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1431' THEN
           ln_1431 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1460' THEN
           ln_1460 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1461' THEN
           ln_1461 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1462' THEN
           ln_1462 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1463' THEN
           ln_1463 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1464' THEN
           ln_1464 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1466' THEN
           ln_1466 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1467' THEN
           ln_1467 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1468' THEN
           ln_1468 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1469' THEN
           ln_1469 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1470' THEN
           ln_1470 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1471' THEN
           ln_1471 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '1499' THEN
           ln_1499 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2001' THEN
           ln_2001 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2003' THEN
           ln_2003 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2004' THEN
           ln_2004 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2005' THEN
           ln_2005 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2007' THEN
           ln_2007 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2008' THEN
           ln_2008 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2009' THEN
           ln_2009 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2010' THEN
           ln_2010 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2101' THEN
           ln_2101 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2102' THEN
           ln_2102 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2103' THEN
           ln_2103 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2104' THEN
           ln_2104 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2105' THEN
           ln_2105 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2106' THEN
           ln_2106 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2107' THEN
           ln_2107 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2108' THEN
           ln_2108 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2109' THEN
           ln_2109 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2110' THEN
           ln_2110 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2111' THEN
           ln_2111 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2112' THEN
           ln_2112 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2113' THEN
           ln_2113 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2114' THEN
           ln_2114 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2115' THEN
           ln_2115 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2116' THEN
           ln_2116 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2199' THEN
           ln_2199 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2201' THEN
           ln_2201 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2202' THEN
           ln_2202 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2203' THEN
           ln_2203 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2204' THEN
           ln_2204 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2301' THEN
           ln_2301 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2302' THEN
           ln_2302 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2306' THEN
           ln_2306 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2307' THEN
           ln_2307 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2308' THEN
           ln_2308 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2309' THEN
           ln_2309 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2310' THEN
           ln_2310 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2311' THEN
           ln_2311 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2312' THEN
           ln_2312 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2313' THEN
           ln_2313 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2314' THEN
           ln_2314 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2397' THEN
           ln_2397 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2398' THEN
           ln_2398 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2399' THEN
           ln_2399 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2401' THEN
           ln_2401 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2402' THEN
           ln_2402 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2403' THEN
           ln_2403 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2404' THEN
           ln_2404 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2405' THEN
           ln_2405 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2406' THEN
           ln_2406 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2407' THEN
           ln_2407 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2408' THEN
           ln_2408 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2409' THEN
           ln_2409 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2410' THEN
           ln_2410 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2411' THEN
           ln_2411 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2412' THEN
           ln_2412 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2413' THEN
           ln_2413 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2414' THEN
           ln_2414 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '2415' THEN
           ln_2415 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '3001' THEN
           ln_3001 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '3002' THEN
           ln_3002 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '3003' THEN
           ln_3003 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '3004' THEN
           ln_3004 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '3005' THEN
           ln_3005 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '3006' THEN
           ln_3006 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '3007' THEN
           ln_3007 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '3008' THEN
           ln_3008 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '3099' THEN
           ln_3099 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '7001' THEN
           ln_7001 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '7002' THEN
           ln_7002 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '7003' THEN
           ln_7003 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '7004' THEN
           ln_7004 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '7005' THEN
           ln_7005 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '7006' THEN
           ln_7006 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '7007' THEN
           ln_7007 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '7008' THEN
           ln_7008 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '7009' THEN
           ln_7009 := NVL(rc_h.dias_trabaj,0) ;
           -- Verifica si monto es mayor que 0 y si ya existe el dato
           IF ln_7009 > 0 THEN
              SELECT count(*) 
                INTO ln_count 
                FROM tt_rpt_plla_calculada_cgsa tt 
               WHERE tt.cod_trabajador=rc_m.cod_trabajador and tt.c7009>0 ;
              IF ln_count>0 THEN
                 ln_7009 := 0 ;
              END IF ;
           END IF ;
        ELSIF rc_h.concep = '7010' THEN
           ln_7010 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '7011' THEN
           ln_7011 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '7012' THEN
           ln_7012 := NVL(rc_h.imp_soles,0) ;
        ELSIF rc_h.concep = '7013' THEN
           ln_7013 := NVL(rc_h.imp_soles,0) ;
        END IF ;
        
        -- Actualiza en caso ya exista el registro     
        UPDATE tt_rpt_plla_calculada_cgsa tt 
           SET tt.c1001 = NVL(tt.c1001,0) + NVL(ln_1001,0), 
               tt.c1002 = NVL(tt.c1002,0) + NVL(ln_1002,0),
               tt.c1003 = NVL(tt.c1003,0) + NVL(ln_1003,0), 
               tt.c1004 = NVL(tt.c1004,0) + NVL(ln_1004,0), 
               tt.c1005 = NVL(tt.c1005,0) + NVL(ln_1005,0), 
               tt.c1006 = NVL(tt.c1006,0) + NVL(ln_1006,0), 
               tt.c1007 = NVL(tt.c1007,0) + NVL(ln_1007,0), 
               tt.c1101 = NVL(tt.c1101,0) + NVL(ln_1101,0), 
               tt.c1102 = NVL(tt.c1102,0) + NVL(ln_1102,0), 
               tt.c1103 = NVL(tt.c1103,0) + NVL(ln_1103,0), 
               tt.c1104 = NVL(tt.c1104,0) + NVL(ln_1104,0), 
               tt.c1105 = NVL(tt.c1105,0) + NVL(ln_1105,0), 
               tt.c1201 = NVL(tt.c1201,0) + NVL(ln_1201,0), 
               tt.c1202 = NVL(tt.c1202,0) + NVL(ln_1202,0), 
               tt.c1203 = NVL(tt.c1203,0) + NVL(ln_1203,0), 
               tt.c1204 = NVL(tt.c1204,0) + NVL(ln_1204,0), 
               tt.c1205 = NVL(tt.c1205,0) + NVL(ln_1205,0), 
               tt.c1301 = NVL(tt.c1301,0) + NVL(ln_1301,0), 
               tt.c1302 = NVL(tt.c1302,0) + NVL(ln_1302,0), 
               tt.c1401 = NVL(tt.c1401,0) + NVL(ln_1401,0), 
               tt.c1402 = NVL(tt.c1402,0) + NVL(ln_1402,0), 
               tt.c1403 = NVL(tt.c1403,0) + NVL(ln_1403,0), 
               tt.c1405 = NVL(tt.c1405,0) + NVL(ln_1405,0), 
               tt.c1406 = NVL(tt.c1406,0) + NVL(ln_1406,0), 
               tt.c1407 = NVL(tt.c1407,0) + NVL(ln_1407,0), 
               tt.c1408 = NVL(tt.c1408,0) + NVL(ln_1408,0), 
               tt.c1409 = NVL(tt.c1409,0) + NVL(ln_1409,0), 
               tt.c1419 = NVL(tt.c1419,0) + NVL(ln_1419,0), 
               tt.c1420 = NVL(tt.c1420,0) + NVL(ln_1420,0), 
               tt.c1421 = NVL(tt.c1421,0) + NVL(ln_1421,0), 
               tt.c1422 = NVL(tt.c1422,0) + NVL(ln_1422,0), 
               tt.c1423 = NVL(tt.c1423,0) + NVL(ln_1423,0), 
               tt.c1424 = NVL(tt.c1424,0) + NVL(ln_1424,0), 
               tt.c1425 = NVL(tt.c1425,0) + NVL(ln_1425,0), 
               tt.c1426 = NVL(tt.c1426,0) + NVL(ln_1426,0), 
               tt.c1427 = NVL(tt.c1427,0) + NVL(ln_1427,0), 
               tt.c1428 = NVL(tt.c1428,0) + NVL(ln_1428,0), 
               tt.c1429 = NVL(tt.c1429,0) + NVL(ln_1429,0), 
               tt.c1430 = NVL(tt.c1430,0) + NVL(ln_1430,0),
               tt.c1431 = NVL(tt.c1431,0) + NVL(ln_1431,0), 
               tt.c1460 = NVL(tt.c1460,0) + NVL(ln_1460,0), 
               tt.c1461 = NVL(tt.c1461,0) + NVL(ln_1461,0),   
               tt.c1462 = NVL(tt.c1462,0) + NVL(ln_1462,0),   
               tt.c1463 = NVL(tt.c1463,0) + NVL(ln_1463,0),
               tt.c1464 = NVL(tt.c1464,0) + NVL(ln_1464,0),   
               tt.c1466 = NVL(tt.c1466,0) + NVL(ln_1466,0),   
               tt.c1467 = NVL(tt.c1467,0) + NVL(ln_1467,0),   
               tt.c1468 = NVL(tt.c1468,0) + NVL(ln_1468,0),   
               tt.c1469 = NVL(tt.c1469,0) + NVL(ln_1469,0),   
               tt.c1470 = NVL(tt.c1470,0) + NVL(ln_1470,0),
               tt.c1499 = NVL(tt.c1499,0) + NVL(ln_1499,0),
               tt.c2001 = NVL(tt.c2001,0) + NVL(ln_2001,0),
               tt.c2003 = NVL(tt.c2003,0) + NVL(ln_2003,0),
               tt.c2004 = NVL(tt.c2004,0) + NVL(ln_2004,0),
               tt.c2005 = NVL(tt.c2005,0) + NVL(ln_2005,0),
               tt.c2007 = NVL(tt.c2007,0) + NVL(ln_2007,0),
               tt.c2008 = NVL(tt.c2008,0) + NVL(ln_2008,0),
               tt.c2009 = NVL(tt.c2009,0) + NVL(ln_2009,0),
               tt.c2010 = NVL(tt.c2010,0) + NVL(ln_2010,0),
               tt.c2101 = NVL(tt.c2101,0) + NVL(ln_2101,0),
               tt.c2102 = NVL(tt.c2102,0) + NVL(ln_2102,0),
               tt.c2103 = NVL(tt.c2103,0) + NVL(ln_2103,0),
               tt.c2104 = NVL(tt.c2104,0) + NVL(ln_2104,0),
               tt.c2105 = NVL(tt.c2105,0) + NVL(ln_2105,0),
               tt.c2106 = NVL(tt.c2106,0) + NVL(ln_2106,0),
               tt.c2107 = NVL(tt.c2107,0) + NVL(ln_2107,0),
               tt.c2108 = NVL(tt.c2108,0) + NVL(ln_2108,0),
               tt.c2109 = NVL(tt.c2109,0) + NVL(ln_2109,0),
               tt.c2110 = NVL(tt.c2110,0) + NVL(ln_2110,0),
               tt.c2111 = NVL(tt.c2111,0) + NVL(ln_2111,0),
               tt.c2112 = NVL(tt.c2112,0) + NVL(ln_2112,0),
               tt.c2113 = NVL(tt.c2113,0) + NVL(ln_2113,0),
               tt.c2114 = NVL(tt.c2114,0) + NVL(ln_2114,0),
               tt.c2115 = NVL(tt.c2115,0) + NVL(ln_2115,0),
               tt.c2116 = NVL(tt.c2116,0) + NVL(ln_2116,0),
               tt.c2199 = NVL(tt.c2199,0) + NVL(ln_2199,0),
               tt.c2201 = NVL(tt.c2201,0) + NVL(ln_2201,0),
               tt.c2202 = NVL(tt.c2202,0) + NVL(ln_2202,0),
               tt.c2203 = NVL(tt.c2203,0) + NVL(ln_2203,0),
               tt.c2204 = NVL(tt.c2204,0) + NVL(ln_2204,0),
               tt.c2301 = NVL(tt.c2301,0) + NVL(ln_2301,0),
               tt.c2302 = NVL(tt.c2302,0) + NVL(ln_2302,0),
               tt.c2306 = NVL(tt.c2306,0) + NVL(ln_2306,0),
               tt.c2307 = NVL(tt.c2307,0) + NVL(ln_2307,0),
               tt.c2308 = NVL(tt.c2308,0) + NVL(ln_2308,0),
               tt.c2309 = NVL(tt.c2309,0) + NVL(ln_2309,0),
               tt.c2310 = NVL(tt.c2310,0) + NVL(ln_2310,0),
               tt.c2311 = NVL(tt.c2311,0) + NVL(ln_2311,0),
               tt.c2312 = NVL(tt.c2312,0) + NVL(ln_2312,0),
               tt.c2313 = NVL(tt.c2313,0) + NVL(ln_2313,0),
               tt.c2314 = NVL(tt.c2314,0) + NVL(ln_2314,0),
               tt.c2397 = NVL(tt.c2397,0) + NVL(ln_2397,0),
               tt.c2398 = NVL(tt.c2398,0) + NVL(ln_2398,0),
               tt.c2399 = NVL(tt.c2399,0) + NVL(ln_2399,0),
               tt.c2401 = NVL(tt.c2401,0) + NVL(ln_2401,0),
               tt.c2402 = NVL(tt.c2402,0) + NVL(ln_2402,0),
               tt.c2403 = NVL(tt.c2403,0) + NVL(ln_2403,0),
               tt.c2404 = NVL(tt.c2404,0) + NVL(ln_2404,0),
               tt.c2405 = NVL(tt.c2405,0) + NVL(ln_2405,0),
               tt.c2406 = NVL(tt.c2406,0) + NVL(ln_2406,0),
               tt.c2407 = NVL(tt.c2407,0) + NVL(ln_2407,0),
               tt.c2408 = NVL(tt.c2408,0) + NVL(ln_2408,0),
               tt.c2409 = NVL(tt.c2409,0) + NVL(ln_2409,0),
               tt.c2410 = NVL(tt.c2410,0) + NVL(ln_2410,0),
               tt.c2411 = NVL(tt.c2411,0) + NVL(ln_2411,0),
               tt.c2412 = NVL(tt.c2412,0) + NVL(ln_2412,0),
               tt.c2413 = NVL(tt.c2413,0) + NVL(ln_2413,0),
               tt.c2414 = NVL(tt.c2414,0) + NVL(ln_2414,0),
               tt.c2415 = NVL(tt.c2415,0) + NVL(ln_2415,0),
               tt.c3001 = NVL(tt.c3001,0) + NVL(ln_3001,0),
               tt.c3002 = NVL(tt.c3002,0) + NVL(ln_3002,0),
               tt.c3003 = NVL(tt.c3003,0) + NVL(ln_3003,0),
               tt.c3004 = NVL(tt.c3004,0) + NVL(ln_3004,0),
               tt.c3005 = NVL(tt.c3005,0) + NVL(ln_3005,0),
               tt.c3006 = NVL(tt.c3006,0) + NVL(ln_3006,0),
               tt.c3007 = NVL(tt.c3007,0) + NVL(ln_3007,0),
               tt.c3008 = NVL(tt.c3008,0) + NVL(ln_3008,0),
               tt.c3099 = NVL(tt.c3099,0) + NVL(ln_3099,0)
         WHERE tt.cod_trabajador = rc_m.cod_trabajador and
               tt.mes            = rc_h.mes ;
               
        -- Actualiza dias trabajados
        IF ln_7001 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7001 = NVL(tt.c7001,0) + ln_7001
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_h.mes;
        END IF ;

        -- Actualiza horas trabajados
        IF ln_7002 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7002 = NVL(tt.c7002,0) + ln_7002
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_h.mes;
        END IF ;
        
        -- Actualiza horas extras 25%
        IF ln_7003 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7003 = NVL(tt.c7003,0) + ln_7003
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_h.mes;
        END IF ;
        
        -- Actualiza horas extras al 35%
        IF ln_7004 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7004 = NVL(tt.c7004,0) + ln_7004
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_h.mes;
        END IF ;
        
        -- Actualiza horas extras al 50%
        IF ln_7005 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7005 = NVL(tt.c7005,0) + ln_7005
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_h.mes;
        END IF ;
        
        -- Actualiza horas extras dominicales 
        IF ln_7006 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7006 = NVL(tt.c7006,0) + ln_7006
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_h.mes;
        END IF ;
        
        -- Actualiza horas extras feriados
        IF ln_7007 > 0 THEN 
            UPDATE tt_rpt_plla_calculada_cgsa tt 
               SET tt.c7007 = NVL(tt.c7007,0) + ln_7007
             WHERE tt.cod_trabajador = rc_m.cod_trabajador and
                   tt.mes            = rc_h.mes;
        END IF ;
               
      
        -- Adiciona en caso no exista el registro
        IF SQL%NOTFOUND THEN
            insert into tt_rpt_plla_calculada_cgsa(
              origen, tipo_trabajador, fecha_ini, fecha_fin, cod_trabajador,
              nave, sede, tipo_plla, proceso, mes,
              id_embarcacion, dni, c1001, c1002, c1003,
              c1004, c1005, c1006, c1007, c1101,
              c1102, c1103, c1104, c1105, c1201,
              c1202, c1203, c1204, c1205, c1301,
              c1302, c1401, c1402, c1403, c1405,
              c1406, c1407, c1408, c1409, c1419, 
              c1420, c1421, c1422, c1423, c1424, 
              c1425, c1426, c1427, c1428, c1429, 
              c1430, c1431, c1460, c1461, c1462, 
              c1463, c1464, c1466, c1467, c1468, 
              c1469, c1470, c1471, c1499, 
              c2001, 
              c2003, c2004, c2005, c2007, c2008, 
              c2009, c2010, c2101, c2102, c2103, 
              c2104, c2105, c2106, c2107, c2108, 
              c2109, c2110, c2111, c2112, c2113, 
              c2114, c2115, c2116, c2199, c2201, 
              c2202, c2203, c2204, c2301, c2302, 
              c2306, c2307, c2308, c2309, c2310, 
              c2311, c2312, c2313, c2314, c2397, 
              c2398, c2399, c2401, c2402, c2403, 
              c2404, c2405, c2406, c2407, c2408, 
              c2409, c2410, c2411, c2412, c2413, 
              c2414, c2415, c3001, c3002, c3003, 
              c3004, c3005, c3006, c3007, c3008, 
              c3099, c7001, c7002, c7003, c7004, 
              c7005, c7006, c7007, c7008, c7009, 
              c7010, c7011, c7012, c7013) 
            values (
              rc_m.cod_origen, rc_m.tipo_trabajador, ad_fec_proceso_ini, ad_fec_proceso_fin, rc_m.cod_trabajador, 
              ls_nave, rc_m.cod_sede, rc_m.tipo_plla, as_proceso, rc_h.mes, 
              ls_embarcacion, rc_m.dni, ln_1001, ln_1002, ln_1003, 
              ln_1004, ln_1005, ln_1006, ln_1007, ln_1101, 
              ln_1102, ln_1103, ln_1104, ln_1105, ln_1201, 
              ln_1202, ln_1203, ln_1204, ln_1205, ln_1301, 
              ln_1302, ln_1401, ln_1402, ln_1403, ln_1405, 
              ln_1406, ln_1407, ln_1408, ln_1409, ln_1419, 
              ln_1420, ln_1421, ln_1422, ln_1423, ln_1424, 
              ln_1425, ln_1426, ln_1427, ln_1428, ln_1429, 
              ln_1430, ln_1431, ln_1460, ln_1461, ln_1462, 
              ln_1463, ln_1464, ln_1466, ln_1467, ln_1468, 
              ln_1469, ln_1470, ln_1471, ln_1499, 
              ln_2001, 
              ln_2003, ln_2004, ln_2005, ln_2007, ln_2008, 
              ln_2009, ln_2010, ln_2101, ln_2102, ln_2103, 
              ln_2104, ln_2105, ln_2106, ln_2107, ln_2108, 
              ln_2109, ln_2110, ln_2111, ln_2112, ln_2113, 
              ln_2114, ln_2115, ln_2116, ln_2199, ln_2201, 
              ln_2202, ln_2203, ln_2204, ln_2301, ln_2302, 
              ln_2306, ln_2307, ln_2308, ln_2309, ln_2310, 
              ln_2311, ln_2312, ln_2313, ln_2314, ln_2397, 
              ln_2398, ln_2399, ln_2401, ln_2402, ln_2403,
              ln_2404, ln_2405, ln_2406, ln_2407, ln_2408,
              ln_2409, ln_2410, ln_2411, ln_2412, ln_2413, 
              ln_2414, ln_2415, ln_3001, ln_3002, ln_3003, 
              ln_3004, ln_3005, ln_3006, ln_3007, ln_3008, 
              ln_3099, ln_7001, ln_7002, ln_7003, ln_7004, 
              ln_7005, ln_7006, ln_7007, ln_7008, ln_7009, 
              ln_7010, ln_7011, ln_7012, ln_7013) ;
        END IF ;  
   END LOOP ;
   ls_codigo := rc_m.cod_trabajador; 
END LOOP ;


END usp_rh_det_plla_calc_rango_hor ;
/
