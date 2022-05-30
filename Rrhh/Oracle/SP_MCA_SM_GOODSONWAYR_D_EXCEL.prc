create or replace procedure SP_MCA_SM_GOODSONWAYR_D_EXCEL(
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
begin
   begin
     v_cod_error:=0;

     open po_cursor for

     SELECT MD.MOVEMENT_NUMBER, MD.BAR_CODE, MD.LINE_NUMBER,       
            AZ.ARTICLE_CODE, AZ.POSITION, AZ.ART_SIZE,
            A.ARTICLE_NAME, A.PURCHASE_PRICE, A.SALE_PRICE,
     MD.QTY_PHISICAL QUANTITY,
     MD.MOVEMENT_COST TOTAL_COST,
     MD.MOVEMENT_PRICE TOTAL_VALUE,
            SM.STORE_CODE_ORIGEN, SM.STORE_CODE_DESTINATION, SM.DOCUMENT_NUMBER,      
            to_char(SM.DOCUMENT_DATE, 'yyyy/mm/dd') CREATION_DATE,
            to_char(SM.DOCUMENT_DATE, 'yyyy/mm/dd') RECEPCTION_DATE

     FROM TMP_STOCK_MOVEMENT_DETAIL MD, ARTICLE_SIZE AZ, ARTICLE A, TMP_STOCK_MOVEMENT SM

     WHERE MD.COM_CODE = pi_company 
       AND AZ.COM_CODE = MD.COM_CODE
       AND A.COM_CODE  = MD.COM_CODE
       AND A.COM_CODE  = SM.COM_CODE
       AND MD.BAR_CODE    = AZ.BAR_CODE
       AND A.ARTICLE_CODE = AZ.ARTICLE_CODE
       AND MD.MOVEMENT_NUMBER = SM.MOVEMENT_NUMBER 
       AND MD.MOVEMENT_NUMBER IN (SELECT S.MOVEMENT_NUMBER FROM TMP_STOCK_MOVEMENT S
                                  WHERE S.COM_CODE = pi_company
                                  AND (S.STORE_CODE_ORIGEN = pi_store_code_origen
                                       OR pi_store_code_origen = '-1')
                                  AND (S.STORE_CODE_DESTINATION = pi_store_code_destination
                                       OR pi_store_code_destination = '-1')
                                  AND S.DOCUMENT_DATE between to_date(pi_start_date, 'yyyy/mm/dd') 
                                                              and f_grl_date_final_day(pi_end_date)
                                  AND (S.DOCUMENT_NUMBER = pi_document_number OR pi_document_number = -1)
                                  AND S.TYPE_MOVEMENT_CODE in (100, 400, 900)
                                  AND S.MOVEMENT_STATUS = 'Y'
                                  );
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
