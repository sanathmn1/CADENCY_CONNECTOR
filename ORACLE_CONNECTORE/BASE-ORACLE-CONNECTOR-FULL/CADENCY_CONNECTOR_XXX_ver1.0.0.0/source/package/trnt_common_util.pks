DROP PACKAGE APPS.TRNT_COMMON_UTIL;

CREATE OR REPLACE PACKAGE APPS.trnt_common_util AS
    rm_special_char VARCHAR2(100);
    rm_leadzero VARCHAR2(100);

       TYPE txtfile IS RECORD (
      dataline   varchar2(1000));

   TYPE txtfile_tab IS TABLE OF txtfile
      INDEX BY BINARY_INTEGER;


    FUNCTION get_period_year (
        p_period_name IN VARCHAR2,
        p_ledger_id   IN  NUMBER
    ) RETURN NUMBER;

    FUNCTION get_period_end_date (
        p_period_name   IN       VARCHAR2,
        p_period_year   IN       NUMBER,
        p_ledger_id     IN       NUMBER
    ) RETURN DATE;

    FUNCTION get_conversion_rate (
        p_ledger_id         IN     NUMBER,
        p_from_currency     IN     VARCHAR2,
        p_to_code           IN     VARCHAR2,
        p_period_end_date   IN     DATE
    ) RETURN NUMBER;

function trnt_uac_api_encrypt_data (
         p_input_string         in CLOB
         )
         return clob ;

    FUNCTION get_db_name (
        p_file_path IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_dir_name (
        p_file_path IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_global_code (
        p_ledger_id   IN            NUMBER,
        p_config_id   IN            NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_local_code (
        p_ledger_id IN NUMBER
    ) RETURN VARCHAR2;

    PROCEDURE submit_request (
        p_config_id                 NUMBER,
        p_customer                 VARCHAR2 DEFAULT NULL
    );

    PROCEDURE create_segments_filter (
        p_config_id NUMBER
    );

    FUNCTION get_segment (
        p_column              VARCHAR2,
        p_ledger_id           VARCHAR2,
        p_chart_of_accounts   VARCHAR2,
        p_config_type         VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION format_field (
        p_text_field        VARCHAR2,
        p_rm_leadzero       VARCHAR2,
        p_rm_special_char   VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_filename_out (
        p_config_type VARCHAR2,
        p_config_code VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_default_param (
        p_param_type VARCHAR2
    ) RETURN VARCHAR2;


    FUNCTION clear_error_log RETURN VARCHAR2;

    FUNCTION trnt_uac_webservice (
        p_json_data CLOB,
        apid NUMBER
    ) RETURN VARCHAR2;

    FUNCTION trnt_encrypt_data (
        input_string CLOB
    ) RETURN CLOB;

    FUNCTION trnt_decrypt_data (
        encrypted_blob VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_token_uac( p_param_type VARCHAR2) RETURN VARCHAR2;

     FUNCTION get_token_uac_dyna RETURN VARCHAR2;

     FUNCTION trnt_get_description (
                        x_coa_id        IN NUMBER,
                        x_seg_num       IN NUMBER,
                        x_seg_val       IN VARCHAR2, 
                        x_language IN VARCHAR2  ) RETURN VARCHAR2;

FUNCTION Get_Jsonformat_for_UAC(p_dataline_tab     txtfile_tab,p_aid in varchar2,p_type in varchar2
,p_sid in varchar2,p_cid in varchar2,P_ENABLE_ENCRYPTION VARCHAR2,
p_config_id NUMBER,
p_config_type varchar2,
p_bid_enable_flag varchar2,
file_encrypt_flag varchar2
) return clob;

 PROCEDURE clob_to_file (p_clob      IN  CLOB,
                         p_directory_name       IN  VARCHAR2,
                         p_filename  IN  VARCHAR2);
END trnt_common_util;
/
