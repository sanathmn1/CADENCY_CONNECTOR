SET DEFINE OFF;
delete from TRNT_DEFAULT_PARAMETER;


Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_VALUE, PARAM_DESC, ACTIVE)
 Values
   (1, 'FILE_LOCATION', '/tmp', 'Default file location', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_VALUE, PARAM_DESC, ACTIVE)
 Values
   (2, 'SEGMENT_ALLOWED', '4', 'Maxium Parameters Allowed', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_VALUE, PARAM_DESC, ACTIVE)
 Values
   (3, 'DEFAULT_LEDGER', '1', 'Default Ledger for screen setting', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_VALUE, PARAM_DESC, ACTIVE)
 Values
   (4, 'CUSTOM_FIELD1', 'customtext1', 'Extract_Label for Custom_Field1', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_VALUE, PARAM_DESC, ACTIVE)
 Values
   (5, 'CUSTOM_FIELD2', 'cutstomtext2', 'Extract_Label for Custom_Field1', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_VALUE, PARAM_DESC, ACTIVE)
 Values
   (6, 'DEFAULT_G_CURRENCY', 'USD', 'Default Global Currency', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_VALUE, PARAM_DESC, ACTIVE)
 Values
   (7, 'DATE_FORMAT', 'MM/DD/YYYY', 'Date Format in LOV', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (8, 'DATE_FORMAT', ' ', 'MMDDYYYY', 'Date Format in LOV', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (9, 'DATE_FORMAT', ' ', 'DD/MM/YYYY', 'Date Format in LOV', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (10, 'DATE_FORMAT', ' ', 'DDMMYYYY', 'Date Format in LOV', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (11, 'CUSTOM_TXT', 'Custom_text1', 'Custom_text1', 'To Display Custom text in GL Selection LOV', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (12, 'CUSTOM_TXT', 'Custom_text2', 'Custom_text2', 'To Display Custom text in GL Selection LOV', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (13, 'CUSTOM_TXT', 'Custom_text3', 'Custom_text3', 'To Display Custom text in GL Selection LOV', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_DESC, ACTIVE)
 Values
   (14, 'TRINTECH_RATE_TYPE', 'Default Rate type for Trintech', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_VALUE, PARAM_DESC, ACTIVE)
 Values
   (15, 'LOG_CLICK', '10', 'No of time the admin menu need to be clicked to access this form', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_VALUE, PARAM_DESC, ACTIVE)
 Values
   (16, 'RESPONSIBILITY_NAME', 'CADENCY', 'Responsibility Name should be specified', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_VALUE, PARAM_DESC, ACTIVE)
 Values
   (17, 'FX_L_TRNT_EXCHANGE_RATE', 'typeid', 'FX Label trintech exchange_rate type', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_VALUE, PARAM_DESC, ACTIVE)
 Values
   (18, 'GLT_BATCHID_FORMAT', 'RRRRMMDDHHMISS', 'GLT Batch ID Formate', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (19, 'GLT_ADDITIONAL_COL', 'h.JE_CATEGORY', 'Je_Category', 'GLT Additional Coloum', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (20, 'GLT_ADDITIONAL_COL', 'h.JE_SOURCE', 'Je_Source', 'GLT Additional Coloum', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (21, 'GLT_ADDITIONAL_COL', 'h.PERIOD_NAME', 'Period_Name', 'GLT Additional Coloum', 
    'N');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (22, 'GLT_ADDITIONAL_COL', 'h.Name', 'name', 'GLT Additional Coloum', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (23, 'GLT_ADDITIONAL_COL', 'h.CURRENCY_CODE', 'currencycode', 'GLT Additional Coloum', 
    'N');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (24, 'GLT_ADDITIONAL_COL', 'l.DESCRIPTION', 'description', 'GLT Additional Coloum', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (25, 'GLT_ADDITIONAL_COL', 'l.TAX_CODE', 'taxcode', 'GLT Additional Coloum', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (26, 'GLT_ADDITIONAL_COL', 'l.INVOICE_IDENTIFIER', 'invoiceidentifier', 'GLT Additional Coloum', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, ACTIVE)
 Values
   (27, 'UAC_URL', 'UAC_URL', 'http://uac-ny1-dev1.ttech.cadency.host/uac/api/v1/process/', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, ACTIVE)
 Values
   (28, 'OUTPUT_TYPE', 'X', 'SERVER & REPORT', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, ACTIVE)
 Values
   (29, 'OUTPUT_TYPE', 'R', 'REPORT', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, ACTIVE)
 Values
   (30, 'OUTPUT_TYPE', 'S', 'SERVER', 'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, ACTIVE)
 Values
   (31, 'OUTPUT_TYPE', 'API', 'API', 'Y');

Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (33, 'UAC_WALLET', 'UAC_WALLET', 'file:/u01/install/APPS/12.1.0/admin/EBSDB/wallet', 'UAC Wallet value', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (34, 'UAC_URL_TOKEN', 'UAC_URL_TOKEN', 'http://uac-ny1-dev1.ttech.cadency.host/uac/api/v1/token-auth/ ', 'UAC Token value', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (35, 'UAC_USERNAME', 'UAC_USERNAME', 'afitestoracle', 'USER NAME', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (36, 'UAC_PASSWORD', 'UAC_PASSWORD', 'PxWJwkp5rw', 'USER PASSWORD', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (37, 'UAC_SECRET_KEY', 'API', 'F3RBKH6YUF8VFRE8KOPLMNJHU6TGFRTE', 'uac secret key', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (38, 'UAC_STRING', 'API string', '1111111111111111', 'uac string', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (40, 'UAC_TOKEN_ENCRYPT', 'UAC_TOKEN_ENCRYPT', 'N', 'UAC token encryption yes or no', 
    'Y');
Insert into TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (41, 'CUSTOMER_VERSION_NUMBER', 'CUSTOMER_VERSION_NUMBER', 'STD', 'CUSTOMER_STANDARD VERSION', 
    'Y');

Insert into APPS.TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (43, 'ENABLE_ENCRYPTION_TYPE', 'ENABLE_ENCRYPTION_TYPE', 'Y', 'Enable Encryption in Screen ', 
    'Y');

Insert into APPS.TRNT_DEFAULT_PARAMETER
   (PARAM_ID, PARAM_TYPE, PARAM_CODE, PARAM_VALUE, PARAM_DESC, 
    ACTIVE)
 Values
   (42, 'GLT_ADDITIONAL_COL', 'h.accrual_rev_period_name', 'accrualrevperiodname', 'GLT Additional Coloum', 
    'Y');

update  TRNT_DEFAULT_PARAMETER set param_value=lower(replace(param_value,'_',''))
where PARAM_TYPE='GLT_ADDITIONAL_COL';

update trnt_default_parameter set param_value =(
select min(ledger_id) from gl_ledgers
where ledger_category_code='PRIMARY')
where param_type='DEFAULT_LEDGER';






COMMIT;
