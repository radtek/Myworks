
/*****************************************************************************************************
grant execute on DBMS_CRYPTO to system;
grant execute on UTL_I18N to system;	
grant execute on UTL_ENCODE to system;		
	
wrap iname=pkg_crypt1.sql oname=pkg_crypt1.plb
wrap iname=pkg_crypt2.sql oname=pkg_crypt2.plb

sqlplus system
@pkg_crypto.plb
--   select * from SYS.USER_ERRORS    -- Verify when compile Error

create public synonym pkg_crypt for system.pkg_crypt;
grant execute on system.pkg_crypt to WMSADM;
grant execute on system.pkg_crypt to WMSAPP;
******************************************************************************************************/

-- WARN : ONLY USING DETERMINISTIC FOR FUCTION BASED INDEX
-- Package HEAD (DBMS_CRYPTO - pkg_crypt1.sql)
/******************************************************************************************************
 * PACKAGE DECLARE OF DBMS_CRYPTO ENCRYPTED ***********************************************************
 ******************************************************************************************************/

CREATE OR REPLACE PACKAGE pkg_crypt 
AS
   FUNCTION fn_encrypt_aes (raw_str IN VARCHAR2)
      RETURN VARCHAR2 DETERMINISTIC;
 
   FUNCTION fn_decrypt_aes (raw_str IN VARCHAR2)
      RETURN VARCHAR2 DETERMINISTIC;
END pkg_crypt;
/


-- Package BODY (DBMS_CRYPTO - pkg_crypt2.sql)
/******************************************************************************************************
 * PACKAGE BODY OF DBMS_CRYPTO ENCRYPTED **************************************************************
 ******************************************************************************************************/

CREATE OR REPLACE PACKAGE BODY pkg_crypt 
AS
   pv_key               VARCHAR2 (32) := 'abcd1234efgh5678ijkl9012mnop3456';
 
/******************************************************************************************************
 * ENCRYPT FUNCTION BODY ******************************************************************************
 ******************************************************************************************************/

   FUNCTION fn_encrypt_aes (raw_str IN VARCHAR2)
      RETURN VARCHAR2 DETERMINISTIC
   IS
      fv_encrypt_raw    RAW (2000);
      fv_key_bytes      RAW (32);
      fv_iv             RAW (16);
      fv_cipher_type    PLS_INTEGER := DBMS_CRYPTO.encrypt_aes256
                                     + DBMS_CRYPTO.chain_cbc
                                     + DBMS_CRYPTO.pad_pkcs5;


   BEGIN
      fv_key_bytes := UTL_I18N.string_to_raw (SUBSTR (pv_key, 0, 32), 'AL32UTF8');
      fv_iv := UTL_I18N.string_to_raw (SUBSTR (pv_key, 0, 16), 'AL32UTF8');
      fv_encrypt_raw := DBMS_CRYPTO.encrypt (src => UTL_I18N.string_to_raw (raw_str, 'AL32UTF8'),
                                             typ => fv_cipher_type, 
                                             key => fv_key_bytes, 
                                             iv => fv_iv);
 
      RETURN UTL_RAW.cast_to_varchar2 (UTL_ENCODE.base64_encode (fv_encrypt_raw));

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END fn_encrypt_aes;
 


/******************************************************************************************************
 * DECRYPT FUNCTION BODY ******************************************************************************
 ******************************************************************************************************/

   FUNCTION fn_decrypt_aes (raw_str IN VARCHAR2)
      RETURN VARCHAR2 DETERMINISTIC
   IS
      fv_decrypt_raw    RAW (2000);
      fv_key_bytes      RAW (32);
      fv_iv             RAW (16);
      fv_cipher_type    PLS_INTEGER := DBMS_CRYPTO.encrypt_aes256
                                     + DBMS_CRYPTO.chain_cbc
                                     + DBMS_CRYPTO.pad_pkcs5;
   

   BEGIN
      fv_key_bytes := UTL_I18N.string_to_raw (SUBSTR (pv_key, 0, 32), 'AL32UTF8');
      fv_iv := UTL_I18N.string_to_raw (SUBSTR (pv_key, 0, 16), 'AL32UTF8');
      fv_decrypt_raw := DBMS_CRYPTO.decrypt (src => UTL_ENCODE.base64_decode (UTL_RAW.cast_to_raw (raw_str)), 
                                             typ => fv_cipher_type, 
                                             key => fv_key_bytes,
                                             iv => fv_iv);
 
      RETURN UTL_I18N.raw_to_char (fv_decrypt_raw, 'AL32UTF8');

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END fn_decrypt_aes;
END pkg_crypt;
/

/******************************************************************************************************
-- TEST SCRIPT

SELECT PKG_CRYPT.FN_ENCRYPT_AES('RAW_STRING') FROM DUAL;

SELECT PKG_CRYPT.FN_DECRYPT_AES('x2G3b2OJ3tnGdcX7QJa3mg==') FROM DUAL;	

******************************************************************************************************/