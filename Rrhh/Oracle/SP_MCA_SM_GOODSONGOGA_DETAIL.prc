create or replace procedure SP_MCA_SM_GOODSONGOGA_DETAIL(
       pi_company varchar2,
       pi_movement_number integer, 
       po_cursor out Types.cursor_type, 
       po_msg_error out varchar2, 
       po_cod_error out integer
) is

    v_msg_error    varchar2(200);
    v_cod_error    integer;
begin
   begin
     v_cod_error:=0;

     open po_cursor for

     SELECT MD.MOVEMENT_NUMBER, MD.BAR_CODE, MD.LINE_NUMBER,       
            AZ.ARTICLE_CODE, AZ.POSITION, AZ.ART_SIZE,
            A.ARTICLE_NAME, MD.MOVEMENT_PRICE,
     MD.MOVEMENT_QTY DOCUMENT_QTY,
     MD.DOCUMENT_QTY RECEPTION_QTY,
            (MD.MOVEMENT_QTY   - MD.DOCUMENT_QTY) DIFFERENCE_QTY,
     (MD.MOVEMENT_PRICE - MD.DOCUMENT_PRICE) VALUE_DIFFERENCE,
     MD.GOG_CODE, MD.GOG_USER_ID, MD.GOG_DATE

     FROM TMP_STOCK_MOVEMENT_DETAIL MD, ARTICLE_SIZE AZ, ARTICLE A

     WHERE MD.COM_CODE = pi_company 
       AND AZ.COM_CODE = MD.COM_CODE
       AND A.COM_CODE  = MD.COM_CODE
       AND MD.MOVEMENT_NUMBER = pi_movement_number
       AND MD.BAR_CODE        = AZ.BAR_CODE
       AND A.ARTICLE_CODE     = AZ.ARTICLE_CODE;

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
