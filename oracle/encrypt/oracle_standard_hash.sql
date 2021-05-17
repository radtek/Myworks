/**************************************************
the function script of STANDARD_HASH ENCRYPT
**************************************************/
CREATE OR REPLACE FUNCTION FN_SEC_SH256
( 
     input_string  IN      VARCHAR2 
) 
RETURN VARCHAR2 
IS 
/****************************************************************************** 
*                                                                             * 
* Program ID   : FN_SEC_STHASH                                                * 
* Program Name : Secure one-direction Hash function                           * 
* Create Date  : 2018.01.29                                                   * 
* Creator      :  yskim                                                       * 
*                                                                             * 
*******************************************************************************/
output_string       VARCHAR2(4000); 

BEGIN 
    SELECT STANDARD_HASH (input_string, 'SHA256')
          INTO output_string 
          FROM dual;

      RETURN UTL_RAW.cast_to_varchar2 (UTL_ENCODE.base64_encode (output_string));

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

END FN_SEC_SH256;
/

/*****************************************************************************
grant execute on DBMS_CRYPTO to system;
grant execute on UTL_I18N to system;	
grant execute on UTL_ENCODE to system;		
	
wrap iname=fn_hash.sql oname=fn_hash.plb

sqlplus system
@fn_hash.plb

create public synonym fn_sec_sh256 for system.fn_sec_sh256;
grant execute on system.fn_sec_sh256 to WMSADM;
grant execute on system.fn_sec_sh256 to WMSAPP;

-- TEST SCRIPT

select fn_sec_sh256('raw_string')
from dual;

******************************************************************************/