create or replace procedure SP_MCA_UP_GOG_MOTIV_DETAIL(
       pi_useradm_id        varchar2, 
       pi_company           varchar2,
       pi_movement_number    integer, 
       pi_store_code_origen  varchar2,
       pi_movement_date      varchar2,    
       pi_line_number        integer, 
       pi_bar_code           varchar2,
       pi_GOG_CODE           integer,
       pi_GOG_DATE           varchar2,
       po_msg_error          out varchar2, 
       po_cod_error          out integer
) is

 v_msg_error    varchar2(200);
 v_cod_error    integer;
 v_gog_date     date;
begin
   begin

     v_cod_error:=0;
     v_gog_date:=to_date (pi_gog_date, 'YYYY/MM/DD');

       UPDATE TMP_STOCK_MOVEMENT_DETAIL
       SET GOG_CODE     = pi_gog_code,    
           GOG_USER_ID  = pi_useradm_id,
           GOG_DATE     = v_gog_date   

       WHERE COM_CODE = pi_company
             AND MOVEMENT_NUMBER    = pi_movement_number 
             AND STORE_CODE_ORIGEN  = pi_store_code_origen
             AND MOVEMENT_DATE      = to_date (pi_movement_date , 'YYYY/MM/DD')
             AND LINE_NUMBER        = pi_line_number
             AND BAR_CODE           = pi_bar_code;

     exception 
        when no_data_found then
           v_cod_error:=202;
        when others then
            v_cod_error:=1;
            v_msg_error:='Err Fun:' || sqlcode || ' | ' || sqlerrm;
     end;   

 po_msg_error:=v_msg_error;
 po_cod_error:=v_cod_error;
end;
/
