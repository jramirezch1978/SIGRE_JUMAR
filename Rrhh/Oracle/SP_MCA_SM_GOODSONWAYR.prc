create or replace procedure SP_MCA_SM_GOODSONWAYR(
       pi_company                varchar2,
       pi_store_code_origen      varchar2, 
       pi_store_code_destination varchar2, 
       pi_start_date             varchar2,
       pi_end_date               varchar2,
       pi_document_number        integer,
       po_cursor                 out Types.cursor_type, 
       po_msg_error              out varchar2, 
       po_cod_error              out integer
) is
    v_msg_error    varchar2(200);
    v_cod_error    integer;
    sum_qty stock_movement_detail.qty_movement%type;  

begin
   begin
     v_cod_error:=0;

     open po_cursor for

     SELECT S.MOVEMENT_NUMBER,S.STORE_CODE_ORIGEN, S.STORE_CODE_DESTINATION, 
            to_char(S.DOCUMENT_DATE, 'yyyy/mm/dd') CREATION_DATE,
            to_char(S.DOCUMENT_DATE, 'hh24:mi:ss') CREATION_HOUR,
            S.DOCUMENT_NUMBER,
            S.DOCUMENT_QTY_PAIRS, S.DOCUMENT_QTY_UNITS, 
     S.DOCUMENT_PAIRS_VALUE, S.DOCUMENT_UNITS_VALUE,
            S.DOCUMENT_PAIRS_COST, S.DOCUMENT_UNITS_COST,
            to_char(S.DOCUMENT_DATE, 'yyyy/mm/dd') RECEPTION_DATE

     FROM TMP_STOCK_MOVEMENT S
     WHERE S.COM_CODE = pi_company
     AND (S.STORE_CODE_ORIGEN = pi_store_code_origen
          OR pi_store_code_origen = '-1')
     AND (S.STORE_CODE_DESTINATION = pi_store_code_destination
          OR pi_store_code_destination = '-1')
     AND S.DOCUMENT_DATE between to_date(pi_start_date, 'yyyy/mm/dd') and f_grl_date_final_day(pi_end_date)
     AND (S.DOCUMENT_NUMBER = pi_document_number OR pi_document_number = -1)
     AND S.TYPE_MOVEMENT_CODE in (100, 400, 900)
     AND S.MOVEMENT_STATUS = 'Y'
     ORDER BY S.DOCUMENT_NUMBER;
  
     exception 
        when no_data_found then
           v_cod_error:=100;
        when others then
            v_cod_error:=1;
            v_msg_error:='Err Fun:' || sqlcode || ' | ' || sqlerrm;
     end;   
     if v_cod_error != 1
     then
        v_msg_error:=f_msg_su_error(pi_company, v_cod_error);
     end if;

 po_msg_error:=v_msg_error;
 po_cod_error:=v_cod_error;
end;
/
