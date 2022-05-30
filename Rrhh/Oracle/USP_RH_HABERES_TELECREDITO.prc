create or replace procedure USP_RH_HABERES_TELECREDITO (
  asi_origen       in origen.cod_origen%TYPE,
  adi_fec_proceso  in date,
  asi_tipo_trabaj  in tipo_trabajador.tipo_trabajador%TYPE,
  asi_cta_banco    IN banco_cnta.cod_ctabco%TYPE,
  asi_quincena     in varchar2
) is

ln_neto_trab          calculo.imp_soles%type ;
lc_neto_trab          char(15) ;
lc_cuenta_ahorro      char(16) ;
lc_neto_bif           varchar2(20);
lc_cod_bco            char(3)  ;
lc_nombres            varchar2(100) ;

lc_telecredito        tt_telecredito.col_telecredito%TYPE;
ln_neto_emp           calculo.imp_soles%type ;
ln_trabajadores       number(15) ;
lc_nom_empresa        empresa.nombre%type ;
ls_concepto           concepto.concep%TYPE;
ln_suma_ctas          NUMBER;
ln_val_cta_emp        NUMBER;
ls_nro_cta_emp        varchar(20);
ls_doc                varchar(1);
ls_cod_banco          banco.cod_banco%TYPE;
ls_moneda             banco_cnta.cod_moneda%TYPE;
ln_nro_item           tt_telecredito.nro_item%TYPE;
ls_nro_cuenta         banco_cnta.nro_cuenta%TYPE;


-- Lectura de trabajadores para pago de remuneraciones
cursor c_boleta is
  SELECT c.imp_soles AS pagos,
         m.nro_cnta_ahorro AS cuenta,
         m.cod_banco AS cod_banco,
         m.email,
         upper(m.apel_paterno || ' ' || m.apel_materno || ' ' || m.nombre1 || ' ' || m.nombre2) AS nombre,
         upper(m.apel_paterno) AS apel_paterno, upper(m.apel_materno) AS apel_materno, upper(m.nombre1 || ' ' || m.nombre2) AS nombres,
         m.tipo_doc_ident_rtps AS tipo_doc,
         m.nro_doc_ident_rtps AS dni,
         t.flag_doc_bbva
  from calculo c,
       maestro m,
       RRHH_DOCUMENTO_IDENTIDAD_RTPS t
  where m.cod_trabajador = c.cod_trabajador
    and m.tipo_doc_ident_rtps = t.cod_doc_identidad
--    and m.flag_cal_plnlla = '1'
--    AND m.flag_estado = '1'
    and (m.nro_cnta_ahorro <> ' ' AND m.nro_cnta_ahorro IS NOT NULL)
    AND c.concep        = ls_concepto
    and m.cod_moneda    = ls_moneda
    and m.cod_banco     = ls_cod_banco 
    and nvl(c.imp_soles,0) <> 0
    AND m.tipo_trabajador like asi_tipo_trabaj
    and m.cod_origen    = asi_origen
    and c.fec_proceso   = trunc(adi_fec_proceso)
 order by nombre;

cursor c_quincena is
  SELECT aq.imp_adelanto AS pagos,
         m.nro_cnta_ahorro AS cuenta,
         m.cod_banco AS cod_banco,
         upper(m.apel_paterno || ' ' || m.apel_materno || ' ' || m.nombre1 || ' ' || m.nombre2) AS nombre,
         upper(m.apel_paterno) AS apel_paterno, upper(m.apel_materno) AS apel_materno, upper(m.nombre1 || ' ' || m.nombre2) AS nombres,
         m.tipo_doc_ident_rtps,
         m.nro_doc_ident_rtps AS dni,
         t.flag_doc_bbva,
         m.email
  from adelanto_quincena aq,
       maestro m,
       RRHH_DOCUMENTO_IDENTIDAD_RTPS t
  where m.cod_trabajador      = aq.cod_trabajador
    and m.tipo_doc_ident_rtps = t.cod_doc_identidad
--    and m.flag_cal_plnlla     = '1'
--    AND m.flag_estado         = '1'
    and (m.nro_cnta_ahorro <> ' ' AND m.nro_cnta_ahorro IS NOT NULL)
    and m.cod_banco        = ls_cod_banco
    and nvl(aq.imp_adelanto,0) <> 0
    AND m.tipo_trabajador like asi_tipo_trabaj
    and m.cod_origen      = asi_origen
    and aq.fec_proceso    = trunc(adi_fec_proceso)
 order by nombre;

cursor c_GRATIFICACION is
  SELECT g.imp_adelanto AS pagos,
         m.nro_cnta_ahorro AS cuenta,
         m.cod_banco AS cod_banco,
         upper(m.apel_paterno || ' ' || m.apel_materno || ' ' || m.nombre1 || ' ' || m.nombre2) AS nombre,
         upper(m.apel_paterno) AS apel_paterno, upper(m.apel_materno) AS apel_materno, upper(m.nombre1 || ' ' || m.nombre2) AS nombres,
         m.nro_doc_ident_rtps AS dni,
         t.flag_doc_bbva,
         m.email
  from gratificacion g,
       maestro m,
       RRHH_DOCUMENTO_IDENTIDAD_RTPS t
  where g.cod_trabajador = m.cod_trabajador
    and m.tipo_doc_ident_rtps = t.cod_doc_identidad
    and trunc(g.fec_proceso) = trunc(adi_fec_proceso)
--    and m.flag_estado = '1'
    and m.cod_origen = asi_origen
    and m.tipo_trabajador like asi_tipo_trabaj
    and m.nro_cnta_ahorro is not null
    and m.cod_banco = ls_cod_banco
  order by nombre;


begin

--  *************************************************************
--  ***   REALIZA PAGO DE REMUNERACIONES A LOS TRABAJADORES   ***
--  *************************************************************

delete from tt_telecredito ;

-- Determino el concepto de pago de remuneraciones
select p.cnc_total_pgd
  into ls_concepto
  from rrhhparam p
 where p.reckey = '1';

select bc.cod_banco, bc.cod_moneda, bc.nro_cuenta
  into ls_cod_banco, ls_moneda, ls_nro_cuenta
  from banco_cnta bc
 where bc.cod_ctabco = asi_cta_banco;

-- Determina nombre de la empresa
select e.nombre
  into lc_nom_empresa
  from empresa e,
       genparam g
  where g.cod_empresa = e.cod_empresa
    AND g.reckey = '1';

--  Determina monto total a pagar por la empresa
if asi_quincena = '0' then
   select sum(nvl(c.imp_soles,0)), COUNT(*)
     into ln_neto_emp, ln_trabajadores
     from calculo c,
          maestro m
     where c.cod_trabajador = m.cod_trabajador
--       and m.flag_cal_plnlla = '1'
--       AND m.flag_estado = '1'
       and m.cod_origen = asi_origen
       AND m.tipo_trabajador like asi_tipo_trabaj
       and c.fec_proceso = trunc(adi_fec_proceso)
       AND (m.nro_cnta_ahorro <> ' ' AND m.nro_cnta_ahorro IS NOT NULL)
       and c.concep = ls_concepto
       and m.cod_banco = ls_cod_banco
       AND nvl(c.imp_soles,0) <> 0 ;

    -- cuentas de baco
    SELECT sum(substr(replace(m.nro_cnta_ahorro,'-',''),4))
      into ln_suma_ctas
      from calculo c, maestro m
      where c.cod_trabajador = m.cod_trabajador
--        and m.flag_cal_plnlla = '1'
--        AND m.flag_estado = '1'
        and m.cod_origen = asi_origen
        AND m.tipo_trabajador like asi_tipo_trabaj
        AND (m.nro_cnta_ahorro <> ' ' AND m.nro_cnta_ahorro IS NOT NULL)
        and c.concep = ls_concepto
        and m.cod_banco = ls_cod_banco
        AND nvl(c.imp_soles,0) <> 0 ;

elsif asi_quincena = '1' then  -- Pago de Quincena
   select sum(nvl(aq.imp_adelanto,0)), COUNT(*)
     into ln_neto_emp, ln_trabajadores
     from adelanto_quincena aq,
          maestro m
     where aq.cod_trabajador = m.cod_trabajador
--       and m.flag_cal_plnlla = '1'
--       AND m.flag_estado = '1'
       and m.cod_origen = asi_origen
       AND m.tipo_trabajador like asi_tipo_trabaj
       and aq.fec_proceso = trunc(adi_fec_proceso)
       AND (m.nro_cnta_ahorro <> ' ' AND m.nro_cnta_ahorro IS NOT NULL)
       and m.cod_banco = ls_cod_banco
       AND nvl(aq.imp_adelanto,0) <> 0 ;

    -- cuentas de baco
    SELECT sum(substr(replace(m.nro_cnta_ahorro,'-',''),4))
      into ln_suma_ctas
      from adelanto_quincena aq, maestro m
      where aq.cod_trabajador = m.cod_trabajador
--        and m.flag_cal_plnlla = '1'
--        AND m.flag_estado = '1'
        and m.cod_origen = asi_origen
        AND m.tipo_trabajador like asi_tipo_trabaj
        AND (m.nro_cnta_ahorro <> ' ' AND m.nro_cnta_ahorro IS NOT NULL)
        and m.cod_banco = ls_cod_banco
        AND nvl(aq.imp_adelanto,0) <> 0 ;

elsif asi_quincena = '3' then  -- Pago de GRATIFICACION

   select sum(nvl(g.imp_adelanto,0)), COUNT(*)
     into ln_neto_emp, ln_trabajadores
     from gratificacion g,
          maestro m
     where g.cod_trabajador = m.cod_trabajador
       and nvl(g.imp_adelanto,0) <> 0
       and trunc(g.fec_proceso) = trunc(adi_fec_proceso)
--       and m.flag_estado = '1'
       and m.cod_origen = asi_origen
       and m.tipo_trabajador like asi_tipo_trabaj
       and m.nro_cnta_ahorro is not null
       and m.cod_banco = ls_cod_banco;

   -- cuentas de baco
   SELECT sum(substr(replace(m.nro_cnta_ahorro,'-',''),4))
     into ln_suma_ctas
     from gratificacion g,
          maestro m
     where g.cod_trabajador = m.cod_trabajador
       and nvl(g.imp_adelanto,0) <> 0
       and trunc(g.fec_proceso) = trunc(adi_fec_proceso)
--       and m.flag_estado = '1'
       and m.cod_origen = asi_origen
       and m.tipo_trabajador like asi_tipo_trabaj
       and m.nro_cnta_ahorro is not null
       and m.cod_banco = ls_cod_banco ;

end if;

if ls_cod_banco = '010' then
   -- Si el codigo de banco es del BCP
    -- Obtengo los ultimos digistos de la cuenta de la empresa
    ls_nro_cta_emp := ltrim(rtrim(asi_cta_banco));
    ls_nro_cta_emp := substr(ls_nro_cta_emp, 1, 3) || '0' || substr(ls_nro_cta_emp, 4);
    ln_val_cta_emp := to_number(substr(ltrim(rtrim(replace(asi_cta_banco, '-', ''))),4));
    ln_suma_ctas := ln_suma_ctas + ln_val_cta_emp;

    -- Datos de la cabecera
    -- Planilla nueva: Constante #
    lc_telecredito := '#';

    -- Tipo de Registro: Constante 1
    lc_telecredito := lc_telecredito || '1';

    -- Tipo de Pago Masivo
    -- H: Haberes
    -- P:Proveedores
    -- D:Dividendos
    lc_telecredito := lc_telecredito || 'H';

    -- Tipo de Producto
    -- C = Cuenta Corriente
    -- M = Cuenta Maestra
    lc_telecredito := lc_telecredito || 'C';

    -- Nro de Cuenta Corriente
    lc_telecredito := lc_telecredito || ltrim(rtrim(ls_nro_cta_emp));

    -- Espacios en blanco (6)
    lc_telecredito := lc_telecredito || lpad(' ', 6, ' ');

    -- Moneda: Soles S/
    lc_telecredito := lc_telecredito || 'S/';

    -- Importe a pagar, 13 enteros y 2 decimales, rellenar con ceros a la izquierda, no poner punto ni coma
    lc_telecredito := lc_telecredito || ltrim(replace(to_char(ln_neto_emp,'0000000000000.00'), '.',''));


    -- Fecha, formato ddmmyyyy
    lc_telecredito := lc_telecredito || to_char(adi_fec_proceso, 'ddmmyyyy');

    -- Rerencia, 20 caracteres
    if asi_quincena = '0' then
       lc_telecredito := lc_telecredito || rpad('PAGO HABERES', 20);
    elsif asi_quincena = '1' then
       lc_telecredito := lc_telecredito || rpad('ADELANTO QUINCENA', 20);
    elsif asi_quincena = '2' then
       lc_telecredito := lc_telecredito || rpad('PAGO CTS', 20);
    elsif asi_quincena = '3' then
       lc_telecredito := lc_telecredito || rpad('GRATIFICACIONES', 20);
    end if;

    -- Total de Control (Checksum)
    lc_telecredito := lc_telecredito || lpad(trim(to_char(ln_suma_ctas)), 15, '0');

    -- Nro de Trabajadore
    lc_telecredito := lc_telecredito || lpad(rtrim(to_char(ln_trabajadores)),6,'0');

    -- Sub Tipo de Pago Masivo
    lc_telecredito := lc_telecredito || '1';

    -- Identificador de Dividendos, poner 15 espacios en blanco si no aplica
    lc_telecredito := lc_telecredito || lpad('', 15, ' ');

    -- Indicador de Nota de Cargo,
    -- 1: Si desea nota de cargo
    -- 0: No desea nota de cargo
    lc_telecredito := lc_telecredito || '1';

    insert into tt_telecredito (col_telecredito, nro_item)
    values (lc_telecredito, 0) ;

    --  Lectura por trabajador para pago de remuneraciones
    ln_nro_item := 0;
    if asi_quincena = '0' then
       for rc_t in c_boleta loop
           lc_nombres       := Substr(rc_t.nombre,1,36)  ;
           lc_cuenta_ahorro := REPLACE(rc_t.cuenta,'-','') ;

           ln_neto_trab := nvl(rc_t.pagos,0) ;
           lc_neto_trab := to_char(ln_neto_trab,'99999999999.99') ;
           lc_neto_trab := replace(lc_neto_trab,'.','') ;
           lc_neto_trab := lpad(ltrim(rtrim(lc_neto_trab)),15,'0') ;

           ln_nro_item := ln_nro_item + 1;
           lc_telecredito := ' 2A'||rPAD(lc_cuenta_ahorro,20,' ')||rpad(substr(lc_nombres,1,36),40,' ')||'S/'||
                          lc_neto_trab||rpad('PAGO HABERES', 40, ' ')||'0'||'DNI'||rpad(substr(rc_t.dni,1,8),12,' ')||'1' ;

         insert into tt_telecredito(col_telecredito, nro_item)
         values (lc_telecredito, ln_nro_item) ;

       end loop ;
    elsif asi_quincena = '1' then -- Pago de Adelanto de Quincena
       for rc_t in c_quincena loop

           lc_nombres       := Substr(rc_t.nombre,1,36)  ;
           lc_cuenta_ahorro := REPLACE(rc_t.cuenta,'-','') ;

           ln_neto_trab := nvl(rc_t.pagos,0) ;
           lc_neto_trab := to_char(ln_neto_trab,'99999999999.99') ;
           lc_neto_trab := replace(lc_neto_trab,'.','') ;
           lc_neto_trab := lpad(ltrim(rtrim(lc_neto_trab)),15,'0') ;

           ln_nro_item := ln_nro_item + 1;
           lc_telecredito := ' 2A'||rPAD(lc_cuenta_ahorro,20,' ')||rpad(substr(lc_nombres,1,36),40,' ')||'S/'||
                          lc_neto_trab||rpad('ADELANTO QUINCENA', 40, ' ')||'0'||'DNI'||rpad(substr(rc_t.dni,1,8),12,' ')||'1' ;

           insert into tt_telecredito(col_telecredito, nro_item)
           values (lc_telecredito, ln_nro_item) ;

       end loop ;

    elsif asi_quincena = '3' then    -- Pago de gratificaCiones
       for rc_t in c_GRATIFICACION loop

           lc_nombres       := Substr(rc_t.nombre,1,36)  ;
           lc_cuenta_ahorro := REPLACE(rc_t.cuenta,'-','') ;

           ln_neto_trab := nvl(rc_t.pagos,0) ;
           lc_neto_trab := to_char(ln_neto_trab,'99999999999.99') ;
           lc_neto_trab := replace(lc_neto_trab,'.','') ;
           lc_neto_trab := lpad(ltrim(rtrim(lc_neto_trab)),15,'0') ;

           ln_nro_item := ln_nro_item + 1;

           lc_telecredito := ' 2A'||rPAD(lc_cuenta_ahorro,20,' ')||rpad(substr(lc_nombres,1,36),40,' ')||'S/'||
                          lc_neto_trab||rpad('PAGO GRATIFICACION', 40, ' ')||'0'||'DNI'||rpad(substr(rc_t.dni,1,8),12,' ')||'1' ;

           insert into tt_telecredito(col_telecredito, nro_item)
           values (lc_telecredito, ln_nro_item) ;

       end loop ;

    end if;
elsif ls_cod_banco = '028' then -- Banco Continental

    -- Datos de la cabecera
    -- Planilla nueva: Constante #
    lc_telecredito := '700';

    -- NRO CUENTA
    lc_telecredito := lc_telecredito || substr(ltrim(rtrim(ls_nro_cuenta)),1,20);

    -- Moneda: Soles S/
    lc_telecredito := lc_telecredito || 'PEN';

    -- Importe a pagar, 13 enteros y 2 decimales, rellenar con ceros a la izquierda, no poner punto ni coma
    lc_telecredito := lc_telecredito || ltrim(replace(to_char(ln_neto_emp,'0000000000000.00'), '.',''));

    -- Tipo de Proceso
    -- A = Inmediato
    -- H = Hora de Proceso
    -- F = Fecha Futura
    lc_telecredito := lc_telecredito || 'A';

    -- Fecha, formato yyyymmdd
    lc_telecredito := lc_telecredito || lpad(' ', 8, ' ');--to_char(adi_fec_proceso, 'yyyymmdd');

    -- Hora de proceso
    -- B = 11:00 a.m.
    -- C = 03:00 p.m.
    -- D = 07:00 p.m.
    lc_telecredito := lc_telecredito || 'D';

    -- Rerencia, 25 caracteres
    if asi_quincena = '0' then
       lc_telecredito := lc_telecredito || rpad('PAGO HABERES', 25);
    elsif asi_quincena = '1' then
       lc_telecredito := lc_telecredito || rpad('ADELANTO QUINCENA', 25);
    elsif asi_quincena = '2' then
       lc_telecredito := lc_telecredito || rpad('PAGO CTS', 25);
    elsif asi_quincena = '3' then
       lc_telecredito := lc_telecredito || rpad('GRATIFICACIONES', 25);
    end if;

    -- Nro de Trabajadore
    lc_telecredito := lc_telecredito || lpad(rtrim(to_char(ln_trabajadores)),6,'0');

    -- Validacion de Pertenencia
    lc_telecredito := lc_telecredito || 'S';

    -- Valor de Control (uso Futuro)
    lc_telecredito := lc_telecredito || lpad('0',18,'0');

    -- Indicador de Proceso
    lc_telecredito := lc_telecredito || lpad('',3,'0');

    -- Descripcion
    lc_telecredito := lc_telecredito || lpad(' ',30,' ');

    -- Filler
    lc_telecredito := lc_telecredito || lpad(' ',20,' ');

    insert into tt_telecredito (col_telecredito, nro_item)
    values (lc_telecredito, 0) ;

    --  Lectura por trabajador para pago de remuneraciones
    ln_nro_item := 0;
    if asi_quincena = '0' then
       for rc_t in c_boleta loop
           ln_neto_trab := nvl(rc_t.pagos,0) ;
           lc_neto_trab := to_char(ln_neto_trab,'99999999999.00') ;
           lc_neto_trab := replace(lc_neto_trab,'.','') ;
           lc_neto_trab := lpad(ltrim(rtrim(lc_neto_trab)),15,'0') ;

           ln_nro_item := ln_nro_item + 1;
           lc_telecredito := '002'|| rc_t.flag_doc_bbva || rpad(rc_t.dni, 12, ' ') || 'P'
                          || lpad(rtrim(ltrim(substr(replace(rc_t.cuenta, '-', ''),1,20))),20, ' ')
                          || rpad(rtrim(ltrim(substr(REPLACE(rc_t.nombre, 'Ñ', 'N'),1,40))),40, ' ')
                          || lc_neto_trab
                          || rpad(' ',40, ' ')
                          || LPAD(rc_t.email || ' ' , 50, ' ')
                          || lpad(' ', 2, ' ')
                          || lpad(' ', 30, ' ')
                          || lpad(' ', 19, ' ');

           insert into tt_telecredito(col_telecredito, nro_item)
           values (lc_telecredito, ln_nro_item) ;

       end loop ;
    elsif asi_quincena = '1' then -- Pago de Adelanto de Quincena
       for rc_t in c_quincena loop

           ln_neto_trab := nvl(rc_t.pagos,0) ;
           lc_neto_trab := to_char(ln_neto_trab,'99999999999.00') ;
           lc_neto_trab := replace(lc_neto_trab,'.','') ;
           lc_neto_trab := lpad(ltrim(rtrim(lc_neto_trab)),15,'0') ;

           ln_nro_item := ln_nro_item + 1;
           lc_telecredito := '002'|| rc_t.flag_doc_bbva || rpad(rc_t.dni, 12, ' ') || 'P'
                          || lpad(rtrim(ltrim(substr(replace(rc_t.cuenta, '-', ''),1,20))),20, ' ')
                          || rpad(rtrim(ltrim(substr(REPLACE(rc_t.nombre, 'Ñ', 'N'),1,40))),40, ' ')
                          || lc_neto_trab
                          || rpad(' ',40, ' ')
                          || LPAD(rc_t.email || ' ' , 50, ' ')
                          || lpad(' ', 2, ' ')
                          || lpad(' ', 30, ' ')
                          || lpad(' ', 19, ' ');

           insert into tt_telecredito(col_telecredito, nro_item)
           values (lc_telecredito, ln_nro_item) ;

       end loop ;

    elsif asi_quincena = '3' then    -- Pago de gratificaCiones
       for rc_t in c_GRATIFICACION loop

           ln_neto_trab := nvl(rc_t.pagos,0) ;
           lc_neto_trab := to_char(ln_neto_trab,'99999999999.00') ;
           lc_neto_trab := replace(lc_neto_trab,'.','') ;
           lc_neto_trab := lpad(ltrim(rtrim(lc_neto_trab)),15,'0') ;

           ln_nro_item := ln_nro_item + 1;
           lc_telecredito := '002'|| rc_t.flag_doc_bbva || rpad(rc_t.dni, 12, ' ') || 'P'
                          || lpad(rtrim(ltrim(substr(replace(rc_t.cuenta, '-', ''),1,20))),20, ' ')
                          || rpad(rtrim(ltrim(substr(REPLACE(rc_t.nombre, 'Ñ', 'N'),1,40))),40, ' ')
                          || lc_neto_trab
                          || rpad(' ',40, ' ')
                          || LPAD(rc_t.email || ' ' , 50, ' ')
                          || lpad(' ', 2, ' ')
                          || lpad(' ', 30, ' ')
                          || lpad(' ', 19, ' ');

           insert into tt_telecredito(col_telecredito, nro_item)
           values (lc_telecredito, ln_nro_item) ;

       end loop ;

    end if;
elsif ls_cod_banco = '020' then -- Banco BIF

    --  Lectura por trabajador para pago de remuneraciones
    ln_nro_item := 0;
    if asi_quincena = '0' then
       for rc_t in c_boleta loop
           lc_cuenta_ahorro := REPLACE(trim(rc_t.cuenta),'-','')||'1' ;

           ln_neto_trab := nvl(rc_t.pagos,0) ;
           lc_neto_bif := to_char(ln_neto_trab,'99999999999.99') ;
           lc_neto_bif := replace(lc_neto_bif,'.','')||'5' ;
           lc_neto_bif := lpad(ltrim(rtrim(lc_neto_bif)),10,' ') ;
           
           if rc_t.cod_banco = '010' then
             lc_cod_bco := '002';
           elsif rc_t.cod_banco = '020' then
             lc_cod_bco := '038';
           elsif rc_t.cod_banco = '029' then
             lc_cod_bco := '018';
           end if;
           
           ln_nro_item := ln_nro_item + 1;
           if rc_t.tipo_doc = '01' then
             ls_doc := '1';
           elsif rc_t.tipo_doc = '04' then
             ls_doc := '3';
           end if;
           lc_telecredito := lpad(ln_nro_item,7,' ')||ls_doc||rpad(trim(rc_t.dni),11,' ')||rpad(rc_t.apel_paterno,20,' ')||rpad(rc_t.apel_materno,20,' ')||rpad(rc_t.nombres,114,' ')||
                          'H'||lc_cod_bco||LPAD(lc_cuenta_ahorro,26,' ')||lc_neto_bif;

         insert into tt_telecredito(col_telecredito, nro_item)
         values (lc_telecredito, ln_nro_item) ;

       end loop ;
    elsif asi_quincena = '1' then -- Pago de Adelanto de Quincena
       for rc_t in c_quincena loop
           lc_cuenta_ahorro := REPLACE(trim(rc_t.cuenta),'-','')||'1' ;

           ln_neto_trab := nvl(rc_t.pagos,0) ;
           lc_neto_bif := to_char(ln_neto_trab,'99999999999.99') ;
           lc_neto_bif := replace(lc_neto_bif,'.','')||'5' ;
           lc_neto_bif := lpad(ltrim(rtrim(lc_neto_bif)),10,' ') ;
           
           if rc_t.cod_banco = '010' then
             lc_cod_bco := '002';
           elsif rc_t.cod_banco = '020' then
             lc_cod_bco := '038';
           elsif rc_t.cod_banco = '029' then
             lc_cod_bco := '018';
           end if;
           
           ln_nro_item := ln_nro_item + 1;
           
           lc_telecredito := lpad(ln_nro_item,7,' ')||'1'||rpad(substr(rc_t.dni,1,8),11,' ')||rpad(rc_t.apel_paterno,20,' ')||rpad(rc_t.apel_materno,20,' ')||rpad(rc_t.nombres,114,' ')||
                          'H'||lc_cod_bco||LPAD(lc_cuenta_ahorro,26,' ')||lc_neto_bif;

         insert into tt_telecredito(col_telecredito, nro_item)
         values (lc_telecredito, ln_nro_item) ;

       end loop ;

    elsif asi_quincena = '3' then    -- Pago de gratificaCiones
       for rc_t in c_GRATIFICACION loop
           lc_cuenta_ahorro := REPLACE(trim(rc_t.cuenta),'-','')||'1' ;

           ln_neto_trab := nvl(rc_t.pagos,0) ;
           lc_neto_bif := to_char(ln_neto_trab,'99999999999.99') ;
           lc_neto_bif := replace(lc_neto_bif,'.','')||'5' ;
           lc_neto_bif := lpad(ltrim(rtrim(lc_neto_bif)),10,' ') ;
           
           if rc_t.cod_banco = '010' then
             lc_cod_bco := '002';
           elsif rc_t.cod_banco = '020' then
             lc_cod_bco := '038';
           elsif rc_t.cod_banco = '029' then
             lc_cod_bco := '018';
           end if;
           
           ln_nro_item := ln_nro_item + 1;
           
           lc_telecredito := lpad(ln_nro_item,7,' ')||'1'||rpad(substr(rc_t.dni,1,8),11,' ')||rpad(rc_t.apel_paterno,20,' ')||rpad(rc_t.apel_materno,20,' ')||rpad(rc_t.nombres,114,' ')||
                          'H'||lc_cod_bco||LPAD(lc_cuenta_ahorro,26,' ')||lc_neto_bif;

         insert into tt_telecredito(col_telecredito, nro_item)
         values (lc_telecredito, ln_nro_item) ;
         
       end loop ;

    end if;

end if;

commit;
end  USP_RH_HABERES_TELECREDITO ;
/
