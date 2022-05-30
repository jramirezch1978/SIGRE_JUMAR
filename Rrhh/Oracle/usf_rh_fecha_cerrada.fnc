create or replace function usf_rh_fecha_cerrada ( 
       pi_fec in date,
       pi_codtra in MAESTRO.COD_TRABAJADOR%type 
       
) RETURN varchar2 IS

v_feccal       date;
v_fec          date;
v_tiptra       rrhh_param_org.tipo_trabajador%type;
v_codori       maestro.cod_origen%type;
v_cont         pls_integer;

BEGIN

    /* 
     3 = trabajador no existe
     2 = fecha solicitada no esta parametrizada
     1 = fecha cerrada
     0 = fecha abierta
    */
    
    if pi_codtra is null then
        RAISE_APPLICATION_ERROR(-20000, 'Debe especificar un codigo de trabajador, por favor verifique!');
    end if;
    
    begin
        select tipo_trabajador
          into v_tiptra
          from maestro
         where cod_trabajador = pi_codtra;
         
    exception
      when NO_DATA_FOUND then
          RAISE_APPLICATION_ERROR(-20000, 'Código de Trabajador ' || pi_codtra || ', por favor verifique!');
    end;
    
    v_fec := trunc(pi_fec);
    
    if v_fec is null then
        v_fec := trunc(sysdate);
    end if;

    begin    
        select fec_proceso
          into v_feccal
          from rrhh_param_org
         where origen = v_codori
           and trunc(fec_inicio) <= v_fec
           and trunc(fec_final) >= v_fec 
           and tipo_trabajador = v_tiptra
           and rownum = 1;
    exception
      when NO_DATA_FOUND then
        RAISE_APPLICATION_ERROR(-20000, 'No existe fecha de calculo en tabla de parametros de fecha, por favor verifique!'
                                  || chr(13) || 'Fecha: ' || to_char(v_fec, 'dd/mm/yyyy')
                                  || chr(13) || 'Tipo de Trabajador: ' || v_tiptra);
    end;
    
    select count(1)
      into v_cont
      from historico_calculo
     where cod_trabajador = pi_codtra
       and fec_calc_plan  = v_feccal;
    
    if v_cont = 0 then
        return '0';
    else
        return '1';
    end if;

END;
/
