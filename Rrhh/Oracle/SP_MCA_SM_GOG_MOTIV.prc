create or replace procedure SP_MCA_SM_GOG_MOTIV(
       pi_company           varchar2,
       po_cursor            out Types.cursor_type, 
       po_msg_error         out varchar2, 
       po_cod_error         out integer
) is
    v_msg_error    varchar2(200);
    v_cod_error    integer;
begin
   begin
     v_cod_error:=0;

     open po_cursor for
     select GOG_CODE, GOG_NAME
     from GOG_MOTIV 
     where COM_CODE = pi_company 
       AND rownum <= 30;

     exception 
        when no_data_found then
           v_cod_error:=100;
        when others then
            v_cod_error:=1;
            v_msg_error:='Err Fun:' || sqlcode || ' | ' || sqlerrm;
     end;   
 po_msg_error:=v_msg_error;
 po_cod_error:=v_cod_error;
end;
/
