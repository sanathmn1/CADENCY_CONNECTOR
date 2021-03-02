SET DEFINE OFF;
Insert into TRNT_CONFIG_TYPE
   (CONFIG_TYPE, DESCRIPTION, PROGRAM_NAME, APPLICATION_CODE, ACTIVE, 
    DISPLAY_ORDER, FILE_NAME_PREFIX, DEFAULT_TYPE)
 Values
   ('GLBAL', 'General Ledger Balance', 'TRNT_GL_BAL_EXTRACT', 'SQLGL', 'Y', 
    1, 'GLBALS', 'Y');
Insert into TRNT_CONFIG_TYPE
   (CONFIG_TYPE, DESCRIPTION, PROGRAM_NAME, APPLICATION_CODE, ACTIVE, 
    DISPLAY_ORDER, FILE_NAME_PREFIX, DEFAULT_TYPE)
 Values
   ('GLTRANS', 'General Ledger Transactions', 'TRNT_GL_TRANS_EXT', 'SQLGL', 'Y', 
    2, 'GLTRAN', 'Y');
Insert into TRNT_CONFIG_TYPE
   (CONFIG_TYPE, DESCRIPTION, PROGRAM_NAME, APPLICATION_CODE, ACTIVE, 
    DISPLAY_ORDER, FILE_NAME_PREFIX, DEFAULT_TYPE)
 Values
   ('FX', 'Foreign Exchange Rate', 'TRNT_FX_EXTRACT', 'SQLGL', 'Y', 
    3, 'FXRATE', 'Y');
Insert into TRNT_CONFIG_TYPE
   (CONFIG_TYPE, DESCRIPTION, PROGRAM_NAME, APPLICATION_CODE, ACTIVE, 
    DISPLAY_ORDER, FILE_NAME_PREFIX, DEFAULT_TYPE)
 Values
   ('FA', 'Fixed Asset Balance', 'TRNT_ASSETS_EXT', 'OFA', 'Y', 
    4, 'FABALS', 'Y');
Insert into TRNT_CONFIG_TYPE
   (CONFIG_TYPE, DESCRIPTION, PROGRAM_NAME, APPLICATION_CODE, ACTIVE, 
    DISPLAY_ORDER, FILE_NAME_PREFIX, DEFAULT_TYPE)
 Values
   ('INV', 'Inventory Balance', 'TRNT_INVEN_EXT', 'INV', 'Y', 
    5, 'INBALS', 'Y');
Insert into TRNT_CONFIG_TYPE
   (CONFIG_TYPE, DESCRIPTION, PROGRAM_NAME, APPLICATION_CODE, ACTIVE, 
    DISPLAY_ORDER, FILE_NAME_PREFIX, DEFAULT_TYPE)
 Values
   ('AP', 'Accounts Payable', 'TRNT_AP_EXTRACT', 'SQLGL', 'Y', 
    6, 'APBALS', 'Y');
Insert into TRNT_CONFIG_TYPE
   (CONFIG_TYPE, DESCRIPTION, PROGRAM_NAME, APPLICATION_CODE, ACTIVE, 
    DISPLAY_ORDER, FILE_NAME_PREFIX, DEFAULT_TYPE)
 Values
   ('AR', 'Accounts Receivable', 'TRNT_AR_EXTRACT', 'SQLGL', 'Y', 
    7, 'ARBALS', 'Y');

COMMIT;
