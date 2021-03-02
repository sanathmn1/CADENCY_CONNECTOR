DROP PACKAGE BODY APPS.TRNT_COMMON_UTIL;

create or replace PACKAGE BODY    APPS.trnt_common_util AS
/* $Header: trnt_common_util.pkg, Version 1.0, 09-JAN-2020 $
***********************************************************************
* *
* History Log *
* *
***********************************************************************
* *
* App/Release : Oracle e-Business Suite 12.1.3 to 12.2.9*
* Module  : Common Package*
* Author  : Sanath Mannadath *
* Company : Trintech Inc *
* Description: This package extract data from Oracle EBS and Generate a file in the Oracle EBS server *
* Note: Do Not make any changes to this script, Without getting the Prior confirmation from Trintech Inc. *
* *
* Version    Date      Author         Change *
* ======= =========== ============ ================================*
* *
* 1.0      09-JAN-2020 Sanath       Initial Version *
* 1.1      09-OCT-2020 Prinsha      Fixed the segement issue 
**********************************************************************/
    FUNCTION get_period_year (
        p_period_name IN VARCHAR2,
        p_ledger_id IN NUMBER
    ) RETURN NUMBER IS
        lv_period_year NUMBER;
    BEGIN
        BEGIN
  SELECT DISTINCT p2.period_year
    INTO lv_period_year
    FROM gl_periods p2, gl_ledgers l
   WHERE     p2.period_set_name = l.period_set_name
         AND p2.period_type = l.accounted_period_type
         AND p2.period_name = p_period_name
         AND l.ledger_id = p_ledger_id;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END;

        RETURN lv_period_year;
    END;

    FUNCTION get_period_end_date (
        p_period_name   IN              VARCHAR2,
        p_period_year   IN              NUMBER,
        p_ledger_id     IN              NUMBER
    ) RETURN DATE IS
        l_period_end_date DATE;
    BEGIN
        BEGIN
            SELECT DISTINCT
                gp.end_date
            INTO l_period_end_date
            FROM
                gl_period_statuses   gp,
                gl_ledgers           gll
            WHERE
                gp.set_of_books_id = gll.ledger_id             --1
                AND gll.chart_of_accounts_id = gll.chart_of_accounts_id
                AND gp.period_name = ( p_period_name )   --'Jul-17'
                AND gp.period_year = p_period_year   --'2017'
                AND gll.ledger_id = p_ledger_id;

        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END;

        RETURN l_period_end_date;
    END;

    FUNCTION get_conversion_rate (
        p_ledger_id         IN                  NUMBER,
        p_from_currency     IN                  VARCHAR2,
        p_to_code           IN                  VARCHAR2,
        p_period_end_date   IN                  DATE
    ) RETURN NUMBER IS
        l_conver_rate NUMBER;
    BEGIN
        BEGIN
            SELECT DISTINCT
                MAX(round(gdr.conversion_rate, 8))
            INTO l_conver_rate
            FROM
                gl_daily_rates              gdr,
                gl_ledgers                  gll,
                gl_daily_conversion_types   gdc
            WHERE
                gdr.from_currency = p_from_currency --'INR'--(select attribute9 from fnd_lookup_values where lookup_type = 'TRNT_LEDGERS' and lookup_code = gll.ledger_id and language = 'US')--
                AND gdc.conversion_type = gdr.conversion_type
                AND gdr.to_currency = p_to_code            --'USD'
                AND gdr.conversion_date = (
                    SELECT
                        MAX(gdr.conversion_date)
                    FROM
                        gl_daily_rates              gdr,
                        gl_ledgers                  gll,
                        gl_daily_conversion_types   gdc
                    WHERE
                        gdr.from_currency = p_from_currency --'INR'
                        AND gdr.to_currency = p_to_code --'USD'
                        AND gdc.conversion_type = gdr.conversion_type
                        AND gdr.conversion_date <= p_period_end_date
                        AND gdc.user_conversion_type LIKE 'Period End%'
                        AND conversion_rate IS NOT NULL
                )
                AND gdc.user_conversion_type LIKE 'Period End%';

            IF l_conver_rate IS NULL THEN
                SELECT
                    MAX(conversion_rate)
                INTO l_conver_rate
                FROM
                    gl_daily_rates
                WHERE
                    from_currency = p_from_currency
                    AND to_currency = p_to_code
                    AND conversion_date = (
                        SELECT
                            MAX(conversion_date)
                        FROM
                            gl_daily_rates
                        WHERE
                            from_currency = p_from_currency
                            AND to_currency = p_to_code
                            AND conversion_date <= p_period_end_date
                    );

            END IF;

            IF l_conver_rate IS NULL THEN --check whether any reverse currency is available
                SELECT
                    MAX(conversion_rate)
                INTO l_conver_rate
                FROM
                    gl_daily_rates
                WHERE
                    from_currency = p_to_code
                    AND to_currency = p_from_currency
                    AND conversion_date = (
                        SELECT
                            MAX(conversion_date)
                        FROM
                            gl_daily_rates
                        WHERE
                            from_currency = p_to_code
                            AND to_currency = p_from_currency
                            AND conversion_date <= p_period_end_date
                    );

                l_conver_rate := 1 / l_conver_rate;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                RETURN 0;
        END;

        RETURN l_conver_rate;
    END;

function trnt_uac_api_encrypt_data (
         p_input_string         in CLOB
         )
        return clob   is

    l_blob            BLOB;
    l_clob            CLOB:='';

    num_key_bytes     NUMBER := 256 / 8;     -- key length 256 bits (32 bytes)
    key_bytes_raw     RAW (32);               -- stores 256-bit encryption key
    /*encryption_type   PLS_INTEGER
        :=   DBMS_CRYPTO.encrypt_aes256
           + DBMS_CRYPTO.chain_cbc
           + DBMS_CRYPTO.PAD_PKCS5;  */ --mufg crypo                 -- total encryption type
    iv_raw            RAW (16);
    v_varchar         VARCHAR2 (4000);
    v_encode_type     VARCHAR2 (50) := 'BASE64';
    v_secret_key      VARCHAR2 (50) :=trnt_common_util.get_default_param('UAC_SECRET_KEY');
    --'F3RBKH6YUF8VFRE8KOPLMNJHU6TGFRTE';
    iv_string         VARCHAR2 (50) :=trnt_common_util.get_default_param('UAC_STRING');
    --'1111111111111111';
    v_start           PLS_INTEGER := 1;
    v_buffer          PLS_INTEGER := 2000;

    BEGIN
   DBMS_LOB.CREATETEMPORARY (l_blob, TRUE);
   DBMS_LOB.CREATETEMPORARY (l_clob, TRUE);
    key_bytes_raw := UTL_I18N.string_to_raw (v_secret_key, 'AL32UTF8');
    iv_raw := UTL_I18N.string_to_raw (iv_string, 'UTF8');
   /* DBMS_CRYPTO.Encrypt (dst   => l_blob,
                         src   => p_input_string,
                         typ   => encryption_type,
                         key   => key_bytes_raw,
                         iv    => iv_raw); */ --mufg crypto                    
    FOR i IN 1 ..CEIL(DBMS_LOB.GETLENGTH (l_blob)/v_buffer)
    LOOP
    v_varchar :=DBMS_LOB.SUBSTR (l_blob, v_buffer, v_start);
    DBMS_LOB.WRITEAPPEND (l_clob, LENGTH (v_varchar), v_varchar);
    v_start := v_start + v_buffer;
    END LOOP;
    return l_clob;
END trnt_uac_api_encrypt_data;

    FUNCTION get_db_name (
        p_file_path IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_database_name VARCHAR2(200);
    BEGIN
        BEGIN
            SELECT
                name
            INTO l_database_name
            FROM
                v$database;

        EXCEPTION
            WHEN OTHERS THEN
                l_database_name := NULL;
        END;

        RETURN l_database_name;
    END get_db_name;

    FUNCTION get_dir_name (
        p_file_path IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_directory_name VARCHAR2(200);
    BEGIN
        BEGIN
            SELECT
                directory_name
            INTO l_directory_name
            FROM
                dba_directories
            WHERE
                directory_path = p_file_path
                AND ROWNUM = 1;

        EXCEPTION
            WHEN no_data_found THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: NO_DIR'
                                                || ' '
                                                || 'Directory Path not found for "'
                                                || p_file_path
                                                || '". Please enter a valid direcorty path');

                RETURN NULL;
        END;

        RETURN l_directory_name;
    END;

    FUNCTION get_global_code (
        p_ledger_id   IN            NUMBER,
        p_config_id   IN            NUMBER
    ) RETURN VARCHAR2 IS
        l_global_code VARCHAR2(200);
    BEGIN
        SELECT
            global_currency
        INTO l_global_code
        FROM
            trnt_config
        WHERE
            config_id = p_config_id;

        RETURN l_global_code;
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Get_Global_Code Failed' || sqlerrm);
            RETURN NULL;
    END;

    FUNCTION get_local_code (
        p_ledger_id IN NUMBER
    ) RETURN VARCHAR2 IS
        l_local_code VARCHAR2(200);
    BEGIN
        SELECT
            gll.currency_code
        INTO l_local_code
        FROM
            gl_ledgers gll
        WHERE
            gll.ledger_id = p_ledger_id;

        RETURN l_local_code;
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Get_Local_Code Failed' || sqlerrm);
            RETURN NULL;
    END;

    PROCEDURE submit_request (
        p_config_id                 NUMBER,
        p_customer   VARCHAR2 DEFAULT NULL
    ) IS

        l_responsibility_id   NUMBER;
        l_application_id      NUMBER;
        l_user_id             NUMBER;
        l_request_id          NUMBER;
        l_program             VARCHAR2(100);
        l_config_type         VARCHAR2(100);
        l_description         VARCHAR2(100);
        l_application         VARCHAR2(100);
        v_error               VARCHAR2(100);
        v_code                NUMBER;
    BEGIN
    fnd_file.put_line(fnd_file.log,'package_name := trnt_common_utils procedure_name := Submit_Request');
    fnd_file.put_line(fnd_file.log,'p_batch_id :='||fnd_global.conc_request_id);
    fnd_file.put_line(fnd_file.log,'p_config_id:='||p_config_id);
    fnd_file.put_line(fnd_file.log,'SR, START Submit Request');
        SELECT DISTINCT
            fr.responsibility_id,
            frx.application_id
        INTO
            l_responsibility_id,
            l_application_id
        FROM
            apps.fnd_responsibility      frx,
            apps.fnd_responsibility_tl   fr
        WHERE
            fr.responsibility_id = frx.responsibility_id
            AND upper(fr.responsibility_name) LIKE trnt_common_util.get_default_param('RESPONSIBILITY_NAME');

        SELECT
            user_id
        INTO l_user_id
        FROM
            fnd_user
        WHERE
            user_name = fnd_global.user_name;

        fnd_file.put_line(fnd_file.log,'SR, START Submit Request : ' || l_user_id);
        

            SELECT
                h.config_type,
                t.description,
                t.program_name,
                t.application_code
            INTO
                l_config_type,
                l_description,
                l_program,
                l_application
            FROM
                trnt_config        h,
                trnt_config_type   t
            WHERE
                h.config_type = t.config_type
                AND h.config_id = p_config_id
                AND default_type = 'Y';

     
        apps.fnd_global.apps_initialize(l_user_id, l_responsibility_id, l_application_id);

    --Submitting Concurrent Request
         fnd_file.put_line(fnd_file.log, 'START Submit Request : '
                                     || l_application
                                     || ' - '
                                     || l_program
                                     || ' - '
                                     || l_description);
       
              
                l_request_id := fnd_request.submit_request(application => l_application, program => l_program, description => l_description
                , start_time => SYSDATE, sub_request => false, argument1 => p_config_id);
      

        IF l_request_id = 0 THEN
            fnd_file.put_line(fnd_file.log, 'Concurrent request failed to submit');
        ELSE
            fnd_file.put_line(fnd_file.log, 'Successfully Submitted the Concurrent Request');
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Error While Submitting Concurrent Request '
                                            || TO_CHAR(sqlcode)
                                            || '-'
                                            || sqlerrm);

    END submit_request;

    PROCEDURE create_segments_filter (
        p_config_id NUMBER
    ) IS

        v_config_id         NUMBER;
        v_segment_set_id    NUMBER;
        v_segment_id        VARCHAR2(100);
        v_from_code         VARCHAR2(100);
        v_to_code           VARCHAR2(100);
        v_excepts           VARCHAR2(100);
        l_char_of_account   VARCHAR2(50);
        l_balance_sheet     VARCHAR2(5) := 'N';
        CURSOR c_set IS
        SELECT
            config_id,
            segment_set_id,
            segment_set_name,
            segment1_from,
            segment1_to,
            nvl(segment1_exclude, '*') segment1_exclude,
            segment2_from,
            segment2_to,
            nvl(segment2_exclude, '*') segment2_exclude,
            segment3_from,
            segment3_to,
            nvl(segment3_exclude, '*') segment3_exclude,
            segment4_from,
            segment4_to,
            nvl(segment4_exclude, '*') segment4_exclude,
            segment5_from,
            segment5_to,
            nvl(segment5_exclude, '*') segment5_exclude,
            segment6_from,
            segment6_to,
            nvl(segment6_exclude, '*') segment6_exclude,
            segment7_from,
            segment7_to,
            nvl(segment7_exclude, '*') segment7_exclude,
            segment8_from,
            segment8_to,
            nvl(segment8_exclude, '*') segment8_exclude,
            segment9_from,
            segment9_to,
            nvl(segment9_exclude, '*') segment9_exclude
        FROM
            trnt_config_segment
        WHERE
            config_id = p_config_id;

        crec                c_set%rowtype;

----------------------
    BEGIN
    fnd_file.put_line(fnd_file.log,'package_name := trnt_common_utils');
    fnd_file.put_line(fnd_file.log,'package_name := trnt_common_utils');
    fnd_file.put_line(fnd_file.log,'procedure_name := Create_Segments_Filter');
    fnd_file.put_line(fnd_file.log,'p_batch_id :='|| fnd_global.conc_request_id);
    fnd_file.put_line(fnd_file.log,'p_config_id :='|| p_config_id);
    fnd_file.put_line(fnd_file.log,'CSF, START Create_Segments_Filter');
        SELECT
            chart_of_accounts_id,
            balancesheet_acc_only
        INTO
            l_char_of_account,
            l_balance_sheet
        FROM
            trnt_config
        WHERE
            config_id = p_config_id;

        DELETE FROM trnt_config_segment_list
        WHERE
            config_id = p_config_id;

        OPEN c_set;
        LOOP
            FETCH c_set INTO crec;
            EXIT WHEN c_set%notfound;
            IF l_balance_sheet = 'Y' THEN
                INSERT INTO trnt_config_segment_list
                    ( SELECT
                        crec.config_id,
                        crec.segment_set_id,
                        concatenated_segments
                    FROM
                        gl_code_combinations_kfv
                    WHERE
                        chart_of_accounts_id = l_char_of_account
                        AND gl_account_type IN (
                            'A',
                            'L',
                            'O'
                        )
                        AND nvl(segment1, 0) BETWEEN nvl(crec.segment1_from, nvl(segment1, 0)) AND nvl(crec.segment1_to, nvl(segment1
                        , 0))
                        AND nvl(segment2, 0) BETWEEN nvl(crec.segment2_from, nvl(segment2, 0)) AND nvl(crec.segment2_to, nvl(segment2
                        , 0))
                        AND nvl(segment3, 0) BETWEEN nvl(crec.segment3_from, nvl(segment3, 0)) AND nvl(crec.segment3_to, nvl(segment3
                        , 0))
                        AND nvl(segment4, 0) BETWEEN nvl(crec.segment4_from, nvl(segment4, 0)) AND nvl(crec.segment4_to, nvl(segment4
                        , 0))
                        AND nvl(segment5, 0) BETWEEN nvl(crec.segment5_from, nvl(segment5, 0)) AND nvl(crec.segment5_to, nvl(segment5
                        , 0))
                        AND nvl(segment6, 0) BETWEEN nvl(crec.segment6_from, nvl(segment6, 0)) AND nvl(crec.segment6_to, nvl(segment6
                        , 0))
                        AND nvl(segment7, 0) BETWEEN nvl(crec.segment7_from, nvl(segment7, 0)) AND nvl(crec.segment7_to, nvl(segment7
                        , 0))
                        AND nvl(segment8, 0) BETWEEN nvl(crec.segment8_from, nvl(segment8, 0)) AND nvl(crec.segment8_to, nvl(segment8
                        , 0))
                        AND nvl(segment9, 0) BETWEEN nvl(crec.segment9_from, nvl(segment9, 0)) AND nvl(crec.segment9_to, nvl(segment9
                        , 0))
                        AND nvl(segment1, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment1_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment1_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment2, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment2_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment2_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment3, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment3_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment3_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment4, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment4_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment4_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment5, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment5_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment5_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment6, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment6_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment6_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment7, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment7_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment7_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment8, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment8_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment8_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment9, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment9_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment9_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                    );

            ELSE
                INSERT INTO trnt_config_segment_list
                    ( SELECT
                        crec.config_id,
                        crec.segment_set_id,
                        concatenated_segments
                    FROM
                        gl_code_combinations_kfv
                    WHERE
                        chart_of_accounts_id = l_char_of_account
                        AND nvl(segment1, 0) BETWEEN nvl(crec.segment1_from, nvl(segment1, 0)) AND nvl(crec.segment1_to, nvl(segment1
                        , 0))
                        AND nvl(segment2, 0) BETWEEN nvl(crec.segment2_from, nvl(segment2, 0)) AND nvl(crec.segment2_to, nvl(segment2
                        , 0))
                        AND nvl(segment3, 0) BETWEEN nvl(crec.segment3_from, nvl(segment3, 0)) AND nvl(crec.segment3_to, nvl(segment3
                        , 0))
                        AND nvl(segment4, 0) BETWEEN nvl(crec.segment4_from, nvl(segment4, 0)) AND nvl(crec.segment4_to, nvl(segment4
                        , 0))
                        AND nvl(segment5, 0) BETWEEN nvl(crec.segment5_from, nvl(segment5, 0)) AND nvl(crec.segment5_to, nvl(segment5
                        , 0))
                        AND nvl(segment6, 0) BETWEEN nvl(crec.segment6_from, nvl(segment6, 0)) AND nvl(crec.segment6_to, nvl(segment6
                        , 0))
                        AND nvl(segment7, 0) BETWEEN nvl(crec.segment7_from, nvl(segment7, 0)) AND nvl(crec.segment7_to, nvl(segment7
                        , 0))
                        AND nvl(segment8, 0) BETWEEN nvl(crec.segment8_from, nvl(segment8, 0)) AND nvl(crec.segment8_to, nvl(segment8
                        , 0))
                        AND nvl(segment9, 0) BETWEEN nvl(crec.segment9_from, nvl(segment9, 0)) AND nvl(crec.segment9_to, nvl(segment9
                        , 0))
                        AND nvl(segment1, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment1_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment1_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment2, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment2_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment2_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment3, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment3_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment3_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment4, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment4_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment4_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment5, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment5_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment5_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment6, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment6_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment6_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment7, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment7_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment7_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment8, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment8_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment8_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                        AND nvl(segment9, 0) NOT IN (
                            SELECT
                                regexp_substr(crec.segment9_exclude, '[^,]+', 1, level)
                            FROM
                                dual
                            CONNECT BY
                                regexp_substr(crec.segment9_exclude, '[^,]+', 1, level) IS NOT NULL
                        )
                    );

            END IF;

        END LOOP;
        CLOSE c_set;
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'DATA Prepration Failed'||sqlerrm);

    END create_segments_filter;

    FUNCTION get_segment (
        p_column              VARCHAR2,
        p_ledger_id           VARCHAR2,
        p_chart_of_accounts   VARCHAR2,
        p_config_type         VARCHAR2
    ) RETURN VARCHAR2 IS
        l_segment VARCHAR2(100);
    BEGIN
    /*
        SELECT
            application_column_name
        INTO l_segment
        FROM
            trnt_segment_config
        WHERE
            column_name = p_column
            AND ledger_id = p_ledger_id
            AND application_id = p_chart_of_accounts;
       */
        
        SELECT  s.application_column_name
        into l_segment
            FROM   FND_SEGMENT_ATTRIBUTE_VALUES s,gl_ledgers l
            WHERE  s.ID_FLEX_NUM =l.chart_of_accounts_id 
         AND s.ID_FLEX_CODE = 'GL#'
         AND s.SEGMENT_ATTRIBUTE_TYPE = 'GL_ACCOUNT'
         AND s.ATTRIBUTE_VALUE = 'Y'
        -- and s.Application_id=101
         and l.ledger_id=p_ledger_id ;--478
        
        return(l_segment);
    EXCEPTION
        WHEN no_data_found THEN
            return(0);
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'GET_SEGMENT Failed' || sqlerrm);
    END get_segment;

    FUNCTION format_field (
        p_text_field        VARCHAR2,
        p_rm_leadzero       VARCHAR2,
        p_rm_special_char   VARCHAR2
    ) RETURN VARCHAR2 IS
        l_text VARCHAR2(100);
    BEGIN
        l_text := p_text_field;

    --Removes Leading Zeros from company  
        IF l_text IS NOT NULL AND nvl(p_rm_leadzero, 'N') = 'Y' THEN
            l_text := nvl(ltrim(l_text, '0'), '0');
        END IF;

  --Removes Special Characters from whole text

        IF l_text IS NOT NULL AND nvl(p_rm_special_char, 'N') = 'Y' THEN
            SELECT
                regexp_replace(l_text, '[^[:alnum:]'' '']', NULL)
            INTO l_text
            FROM
                dual;

        END IF;

        return(l_text);
    EXCEPTION
        WHEN no_data_found THEN
            return(0);
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'format_text Failed' || sqlerrm);
    END format_field;

    FUNCTION get_filename_out (
        p_config_type VARCHAR2,
        p_config_code VARCHAR2
    ) RETURN VARCHAR2 IS

        l_file_prefix   VARCHAR2(100);
        l_file_name     VARCHAR2(200);
        v_instance_name Varchar2(100);
        CURSOR c1 IS
        SELECT
            file_name_prefix
        FROM
            trnt_config_type
        WHERE
            config_type = p_config_type;

    BEGIN
        OPEN c1;
        FETCH c1 INTO l_file_prefix;
        CLOSE c1;

        SELECT upper(INSTANCE_NAME) into v_instance_name FROM v$instance;

        l_file_name := l_file_prefix||'_'||v_instance_name
                       || '_'
                       || upper(p_config_code)
                       || '_'
                       || ( TO_CHAR(SYSDATE, 'YYYYMMDDHHMISS')
                            || '.txt' );

        return(l_file_name);
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Get_Filename_Out Failed' || sqlerrm);
    END get_filename_out;

    FUNCTION get_default_param (
        p_param_type VARCHAR2
    ) RETURN VARCHAR2 IS

        l_param_value VARCHAR2(100);
        CURSOR c1 IS
        SELECT
            param_value
        FROM
            trnt_default_parameter
        WHERE
            param_type = p_param_type
            AND active = 'Y';

    BEGIN
        OPEN c1;
        FETCH c1 INTO l_param_value;
        CLOSE c1;
        return(l_param_value);
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Get_default_param Failed' || sqlerrm);
            return(NULL);
    END get_default_param;

    FUNCTION clear_error_log RETURN VARCHAR2 IS
        l_param_value VARCHAR2(100);
    BEGIN
        EXECUTE IMMEDIATE 'truncate table TRNT_ERROR_LOGS';
        return(0);
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'clear_error_log Failed' || sqlerrm);
            return(1);
    END clear_error_log;

    FUNCTION trnt_uac_webservice (
        p_json_data CLOB,
        apid NUMBER
    ) RETURN VARCHAR2 IS

        req      utl_http.req;
        resp     utl_http.resp;
        url      VARCHAR2(500);
        result   CLOB;
        cont     VARCHAR2(4000);
        token    VARCHAR2(5000);
        v_token    VARCHAR2(5000);
        wallet   VARCHAR(500);
        logmsg number;
        req_length      binary_integer;
        offset          pls_integer := 1;
        amount          pls_integer := 2000;
        buffer          varchar2 (2000);
    BEGIN
    logmsg:=1;
    --fnd_file.put_line (fnd_file.LOG, 'trnt_uac_webservice');
        url :=trnt_common_util.get_default_param('UAC_URL');
       -- 'http://uac-ny1-dev1.ttech.cadency.host/uac/api/v1/process/';  
       logmsg:=2;
    v_token :=trnt_common_util.get_token_uac_dyna;
       token :='Token '||substr(v_token,12,(length(v_token)-13));
         logmsg:=2.1;
         fnd_file.put_line (fnd_file.LOG, 'token uac'||token);
        req := utl_http.begin_request(url, 'POST', 'HTTP/1.1');
        utl_http.set_header(req, 'user-agent', 'mozilla/4.0');
        utl_http.set_header(req, 'Content-Type', 'application/json');
        utl_http.set_header(req, 'Authorization', token);
        req_length := DBMS_LOB.getlength (p_json_Data);

  --If Message data under 32kb limit
   if req_length<=32767
   then
       UTL_HTTP.set_header (req, 'Content-Length', req_length); 
       utl_http.write_text(req, p_json_data);


-- If Message data more than 32kb   
   elsif req_length>32767
   then

    UTL_HTTP.set_header (req, 'Content-Length', req_length);
       WHILE (offset < req_length)
       LOOP
          DBMS_LOB.read (p_json_data,  --p_request_body,
                         amount,
                         offset,
                         buffer);
          UTL_HTTP.write_text (req, buffer);
          offset := offset + amount;

       END LOOP;

   end if;
    ---------    
        resp := utl_http.get_response(req);

    logmsg:=3;
 --for checking if it works
        BEGIN
            LOOP
                utl_http.read_line(resp, cont);
                result := result
                          || ' '
                          || cont;
            END LOOP;

            utl_http.end_response(resp);
        EXCEPTION
            WHEN utl_http.end_of_body THEN
                utl_http.end_response(resp);
        END;
logmsg:=4;
        fnd_file.put_line(fnd_file.log, result);
       UPDATE trnt_config_api_response
        SET
            response_code = resp.status_code,
            response_description = substr(resp.reason_phrase|| ''|| result, 0, 1900),
            processcompleteddate = SYSDATE
        WHERE
            api_id = apid;
            commit;
logmsg:=4;
        return(resp.status_code|| ' '|| resp.reason_phrase);--adddeedddprii
    EXCEPTION
        WHEN OTHERS THEN
            utl_http.end_response(resp);

   /*         UPDATE trnt_config_api_response
            SET
                response_code = resp.status_code,
                response_description = substr(resp.reason_phrase
                                              || ''
                                              || result, 0, 1900
                                        ),
                processcompleteddate = SYSDATE
            WHERE
                api_id = apid;*/
commit;
            return('error-'||logmsg||'-'||sqlerrm);
    END;

    FUNCTION trnt_encrypt_data (
        input_string CLOB
    ) RETURN CLOB IS

        output_string     CLOB;  
        encrypted_raw     RAW(4000); -- stores encrypted binary text
        decrypted_raw     RAW(4000); -- stores decrypted binary text
        num_key_bytes     NUMBER := 256 / 8; -- key length 256 bits (32 bytes)
        key_bytes_raw     RAW(32); -- stores 256-bit encryption key
        /*encryption_type   PLS_INTEGER :=  dbms_crypto.encrypt_aes256 
                                        + dbms_crypto.chain_cbc 
                                        + dbms_crypto.pad_pkcs5;*/--mufg crypto -- total encryption type
        iv_raw            RAW(16);
    BEGIN
        key_bytes_raw := 'AA01CD02C26E86913AFC212560B205B90C8F92D4B88B0BB884FA7B4D9EED3442';  --dbms_crypto.randombytes(num_key_bytes);
        iv_raw := null; --dbms_crypto.randombytes(16);

       /* encrypted_raw := dbms_crypto.encrypt(
        src => utl_i18n.string_to_raw(input_string, 'AL32UTF8'), 
        typ => encryption_type, 
        key => key_bytes_raw, 
        iv => iv_raw);     */ --mufg crypto

        output_string := utl_i18n.raw_to_char(encrypted_raw, 'AL32UTF8');
        return(output_string);
    END;

    FUNCTION trnt_decrypt_data (
        encrypted_blob VARCHAR2
    ) RETURN VARCHAR2 IS 

        output_string     VARCHAR2(5000);
        decrypted_blob    VARCHAR2(5000);
        num_key_bytes     NUMBER := 256 / 8;        -- key length 256 bits (32 bytes)
        key_bytes_raw     RAW(32);               -- stores 256-bit encryption key
      --  encryption_type   PLS_INTEGER :=          -- total encryption type
       --  dbms_crypto.encrypt_aes256 + dbms_crypto.chain_cbc + dbms_crypto.pad_pkcs5; mufg crypto
    BEGIN


  /* DBMS_CRYPTO.DECRYPT
      (  dst=> decrypted_blob,
         src => encrypted_blob,
         typ => encryption_type,
         key => key_bytes_raw,
         iv=> null
      );*/
   --output_string := UTL_I18N.RAW_TO_CHAR (decrypted_raw, 'AL32UTF8');
        return(decrypted_blob);
    END;

--decrypt function--

    FUNCTION get_token_uac(p_param_type VARCHAR2) RETURN VARCHAR2 AS
        token VARCHAR2(5000); 
    BEGIN
        IF trnt_common_util.get_default_param('UAC_TOKEN_ENCRYPT') = 'Y' THEN
       token := trnt_common_util.trnt_decrypt_data(trnt_common_util.get_default_param('UAC_TOKEN'));
        ELSE
          token := trnt_common_util.get_default_param('UAC_TOKEN');
        END IF;

        return( token);
    END get_token_uac;

        FUNCTION get_token_uac_dyna RETURN VARCHAR2 AS
        token VARCHAR2(5000); 

        req      utl_http.req;
        resp     utl_http.resp;
        url      VARCHAR2(500);
        result   CLOB;
        cont     VARCHAR2(4000);
        token    VARCHAR2(5000);
        wallet_path   VARCHAR(500);
        token_url VARCHAR(500);
        uac_url VARCHAR(500);
        p_json_usrname   VARCHAR(500);-- :='{"username":"afitestoracle ",  "password":"nPhV8xrvTx"}';
        UAC_USERNAME VARCHAR(100);
        UAC_PASSWORD  VARCHAR(100);
        p_json_data CLOB;  --json data from glbal extact
begin

---Getting Token---
      token_url := trnt_common_util.Get_default_param('UAC_URL_TOKEN'); 
      fnd_file.put_line (fnd_file.LOG, 'token_url'||token_url);
     -- 'http://uac-ny1-dev1.ttech.cadency.host/uac/api/v1/token-auth/';
     
      uac_url   :=trnt_common_util.Get_default_param('UAC_URL'); 
     -- fnd_file.put_line (fnd_file.LOG, 'uac_url'||uac_url);
     -- 'http://uac-ny1-dev1.ttech.cadency.host/uac/api/v1/process/';
     wallet_path  :=trnt_common_util.get_default_param('UAC_WALLET');  
     --'file:/u01/install/APPS/12.1.0/admin/EBSDB/wallet';
     UAC_USERNAME :=trnt_common_util.Get_default_param('UAC_USERNAME');--'afitestoracle';--
    -- fnd_file.put_line (fnd_file.LOG, 'UAC_USERNAME'||UAC_USERNAME);
     --trnt_common_util.get_default_param('UAC_USERNAME'); 
     UAC_PASSWORD :=trnt_common_util.Get_default_param('UAC_PASSWORD');--'PxWJwkp5rw';--
    -- fnd_file.put_line (fnd_file.LOG, 'UAC_PASSWORD'||UAC_PASSWORD);
     --trnt_common_util.get_default_param('UAC_PASSWORD');
       p_json_usrname:='{"username" :"'||UAC_USERNAME||'","password":"'||UAC_PASSWORD||'"}'; --:='{"username":"afitestoracle ",  "password":"nPhV8xrvTx"}';
       utl_http.set_wallet(wallet_path, 'oracle11g');
       req := utl_http.begin_request(token_url, 'POST', 'HTTP/1.1');
       utl_http.set_header(req, 'user-agent', 'mozilla/4.0');
       utl_http.set_header(req, 'Content-Type', 'application/json');
       utl_http.set_header(req, 'Content-Length', length(p_json_usrname));
       utl_http.write_text(req,p_json_usrname);
       resp := utl_http.get_response(req);
        BEGIN
            LOOP
               utl_http.read_line(resp, cont);
                result := result
                          || ' '
                          || cont;
            END LOOP;
            utl_http.end_response(resp);
        EXCEPTION
            WHEN utl_http.end_of_body THEN
                utl_http.end_response(resp);
        END;
        return result;
    END get_token_uac_dyna;

     FUNCTION trnt_get_description (
                        x_coa_id        IN NUMBER,
                        x_seg_num       IN NUMBER,
                        x_seg_val       IN VARCHAR2, 
                        x_language IN VARCHAR2  ) RETURN VARCHAR2 IS
        v_vsid		NUMBER;
        v_type		VARCHAR2(1);
        v_desc_table   VARCHAR2(240);
        v_val_col      VARCHAR2(240);
        v_desc_col     VARCHAR2(240);
        v_desc_sql     VARCHAR2(500);
        desc_cursor    INTEGER;
        seg_desc       VARCHAR2(1000);
        dummy          NUMBER;
        row_count      NUMBER := 0;
        v_sql_stmt     VARCHAR2(2000) ;
	v_cursor       INTEGER;
	v_return       INTEGER;

	l_seg_num      number;
	l_coa_id       number;
	l_seg_val      varchar2(240);
	l_vset_id      number;
    INVALID_SEGNUM EXCEPTION;

  BEGIN
        BEGIN
            /* Retrieve the value set id and validation type
               for the segment */
            SELECT S.flex_value_set_id,
                   VS.validation_type
            INTO   v_vsid,
                   v_type
            FROM   FND_ID_FLEX_SEGMENTS S,
                   FND_FLEX_VALUE_SETS VS
            WHERE  S.id_flex_num = x_coa_id
            AND	   S.application_id = 101
            AND	   S.id_flex_code = 'GL#'
            AND	   S.segment_num = x_seg_num
            AND	   S.enabled_flag = 'Y'
            AND	   VS.flex_value_set_id = S.flex_value_set_id;
        EXCEPTION
            /* Wrong combination of chart of accout id and
               segment number. */
            WHEN no_data_found THEN
                raise INVALID_SEGNUM;
        END;

        /* Determine the relevant tables to obtain the segment value
           description. */
        IF ( v_type = 'F' ) THEN
            /* table validation segment */
            SELECT application_table_name,
                   value_column_name,
                   meaning_column_name
            INTO   v_desc_table,
                   v_val_col,
                   v_desc_col
            FROM   FND_FLEX_VALIDATION_TABLES
            WHERE  flex_value_set_id = v_vsid;

            /* if no description column is defined,
               just return null. */
            IF ( v_desc_col is null ) THEN
                return (NULL);
            END IF;
        ELSE
            /* dependent or independent segment */
            v_desc_table := 'FND_FLEX_VALUES_TL';
            v_val_col := 'flex_value';
            v_desc_col := 'description';
        END IF;

        /* Retrieve the segment value description. */
        v_desc_sql :=
            'SELECT	' || v_desc_col ||
            ' FROM	' || v_desc_table ||
            ' WHERE	' || v_val_col || ' = :seg_val '||
            ' AND LANGUAGE = :language';
        /* For FND_FLEX_VALUES table, we have to filter values by
           flex_value_set_id */
        IF ( v_type <> 'F' ) THEN
            v_desc_sql := v_desc_sql ||
                'AND	flex_value_set_id = :vset_id';
        END IF;

        BEGIN

	    /* Introduced the cursor to fix bug# 3051914  */

	     v_cursor := dbms_sql.open_cursor;
       	dbms_sql.parse( v_cursor, v_desc_sql, dbms_sql.native);
        dbms_sql.bind_variable(v_cursor, 'seg_val' , x_seg_val );
        dbms_sql.bind_variable(v_cursor, 'language' , x_language );
	 IF ( v_type <> 'F' ) THEN
	   dbms_sql.bind_variable(v_cursor, 'vset_id' , v_vsid );

         END IF;

	dbms_sql.define_column(v_cursor ,1,seg_desc,1000);
	v_return := dbms_sql.execute (v_cursor ) ;
        v_return := dbms_sql.fetch_rows ( v_cursor );

	if v_return = 0 then
              raise no_data_found;
        end if;

        dbms_sql.column_value(v_cursor,1,seg_desc);

         /*   EXECUTE IMMEDIATE v_desc_sql
            INTO seg_desc
            USING x_seg_val; */

       dbms_sql.close_cursor(v_cursor);

        EXCEPTION
            WHEN no_data_found THEN
                dbms_sql.close_cursor(v_cursor);
                return (NULL);
            when  INVALID_SEGNUM then
             dbms_sql.close_cursor(v_cursor);
                return (NULL);
            WHEN OTHERS THEN
                dbms_sql.close_cursor(v_cursor);
	        return (NULL);
        END;

        RETURN seg_desc;

  END trnt_get_description;

     FUNCTION Get_Jsonformat_for_UAC(   p_dataline_tab     txtfile_tab,
                                        p_aid       in   VARCHAR2,
                                        p_type      in   VARCHAR2,
                                        p_sid       in   VARCHAR2,
                                        p_cid       in   VARCHAR2,
                                        P_ENABLE_ENCRYPTION VARCHAR2,
                                        p_config_id         NUMBER,
                                        p_config_type    VARCHAR2,
                                        p_bid_enable_flag VARCHAR2,
                                        file_encrypt_flag VARCHAR2
                                    ) 
                        return clob is 
        v_col_1     CLOB;
        v_col_2     CLOB;
        v_col_3     CLOB;
        v_col_4     CLOB;
        v_col_5     CLOB;
        v_col_6     CLOB;
        v_col_7     CLOB;
        v_col_8     CLOB;
        v_col_9     CLOB;
        v_col_10    CLOB;
        v_col_11    CLOB;
        v_col_12    CLOB;
        v_col_13    CLOB;
        v_col_14    CLOB;
        v_col_15    CLOB;

        V_LINE                  VARCHAR2(4000);
        v_result                CLOB;
        v_result1               CLOB;
        i                       NUMBER:=0;
        v_length                NUMBER;
        v_header                VARCHAR2(2000);
        v_ENABLE_ENCRYPTION     VARCHAR2(10);
        v_config_id             NUMBER;
        v_config_type           VARCHAR2(100);
        v_tableseq              NUMBER;
        v_bid_enable_flag       VARCHAR2(10);
        V_file_encrypt_flag     VARCHAR2(10);
        v_col_1_ch              VARCHAR2(100);
        v_col_2_ch              VARCHAR2(100);
        v_col_3_ch              VARCHAR2(100);
        v_col_4_ch              VARCHAR2(100);
        v_col_5_ch              VARCHAR2(100);
        v_col_6_ch              VARCHAR2(100);
        v_col_7_ch              VARCHAR2(100);
        v_col_8_ch              VARCHAR2(100);
        v_col_9_ch              VARCHAR2(100);
        v_col_10_ch             VARCHAR2(100);
        v_col_11_ch             VARCHAR2(100);
        v_col_12_ch             VARCHAR2(100);
        v_col_13_ch             VARCHAR2(100);
        v_col_14_ch             VARCHAR2(100);
        v_col_15_ch             VARCHAR2(100);

 begin
 v_ENABLE_ENCRYPTION    :=P_ENABLE_ENCRYPTION;
 v_config_id            :=p_config_id;
 v_config_type          :=p_config_type;
 v_bid_enable_flag      :=p_bid_enable_flag;

 if p_type='GLTRAN' and p_bid_enable_flag='Y' then
v_header:='"aid":"'||p_aid||'",
           "type":"'||p_type||'",
           "sid":"'||p_sid||'",
           "cid":"'||p_cid||'_API''",
           "mode":"T",
           "bid":'||TO_CHAR(SYSDATE, trnt_common_util.get_default_param('GLT_BATCHID_FORMAT'))
        || ',
           "filedata":';
 else
 v_header:='"aid":"'||p_aid||'",
           "type":"'||p_type||'",
           "sid":"'||p_sid||'",
           "cid":"'||p_cid||'_API''",
           "mode":"T",
           "filedata":';
  end if; 

    LOOP
        i:=i+1;

       begin
       V_LINE:= replace(p_dataline_tab(i).dataline,CHR(13),'');
       
       exception when others then
            if v_col_1_ch <>' ' then
                v_col_1:=substr(v_col_1,1,length(v_col_1)-1)||'],';
            end if;
            if v_col_2_ch <>' ' then
                v_col_2:=substr(v_col_2,1,length(v_col_2)-1)||'],';
            end if ;
            if v_col_3_ch <>' ' then
                v_col_3:=substr(v_col_3,1,length(v_col_3)-1)||'],';
            end if;
            if v_col_4_ch <>' ' then
                v_col_4:=substr(v_col_4,1,length(v_col_4)-1)||'],';
            end if;
            if v_col_5_ch <>' ' then
                v_col_5:=substr(v_col_5,1,length(v_col_5)-1)||'],';
            end if;
            if v_col_6_ch <>' ' then
                v_col_6:=substr(v_col_6,1,length(v_col_6)-1)||'],';
            end if;
            if v_col_7_ch <>' ' then
                v_col_7:=substr(v_col_7,1,length(v_col_7)-1)||'],';
            end if;
            if v_col_8_ch <>' ' then
                v_col_8:=substr(v_col_8,1,length(v_col_8)-1)||'],';
            end if;
            if v_col_9_ch <>' ' then
                v_col_9:=substr(v_col_9,1,length(v_col_9)-1)||'],';
            end if;
            if v_col_10_ch <>' ' then
                v_col_10:=substr(v_col_10,1,length(v_col_10)-1)||'],';
            end if;
            if v_col_11_ch <>' ' then
                v_col_11:=substr(v_col_11,1,length(v_col_11)-1)||'],';
            end if;
            if v_col_12_ch <>' ' then
                v_col_12:=substr(v_col_12,1,length(v_col_12)-1)||'],';
            end if;
            if v_col_13_ch <>' ' then
                v_col_13:=substr(v_col_13,1,length(v_col_13)-1)||'],';
            end if;
            if v_col_14_ch <>' ' then
                v_col_14:=substr(v_col_14,1,length(v_col_14)-1)||'],';
            end if;
            if v_col_15_ch <>' ' then
                v_col_15:=substr(v_col_15,1,length(v_col_15)-1)||'],'; 
            end if;      
       exit;
       end; 
       
     -- Last row blank removing Coma
        if i=p_dataline_tab.count+1 then
            if v_col_1_ch <>' ' then
                v_col_1:=substr(v_col_1,1,length(v_col_1)-1)||'],';
            end if;
            if v_col_2_ch <>' ' then
                v_col_2:=substr(v_col_2,1,length(v_col_2)-1)||'],';
            end if ;
            if v_col_3_ch <>' ' then
                v_col_3:=substr(v_col_3,1,length(v_col_3)-1)||'],';
            end if;
            if v_col_4_ch <>' ' then
                v_col_4:=substr(v_col_4,1,length(v_col_4)-1)||'],';
            end if;
            if v_col_5_ch <>' ' then
                v_col_5:=substr(v_col_5,1,length(v_col_5)-1)||'],';
            end if;
            if v_col_6_ch <>' ' then
                v_col_6:=substr(v_col_6,1,length(v_col_6)-1)||'],';
            end if;
            if v_col_7_ch <>' ' then
                v_col_7:=substr(v_col_7,1,length(v_col_7)-1)||'],';
            end if;
            if v_col_8_ch <>' ' then
                v_col_8:=substr(v_col_8,1,length(v_col_8)-1)||'],';
            end if;
            if v_col_9_ch <>' ' then
                v_col_9:=substr(v_col_9,1,length(v_col_9)-1)||'],';
            end if;
            if v_col_10_ch <>' ' then
                v_col_10:=substr(v_col_10,1,length(v_col_10)-1)||'],';
            end if;
            if v_col_11_ch <>' ' then
                v_col_11:=substr(v_col_11,1,length(v_col_11)-1)||'],';
            end if;
            if v_col_12_ch <>' ' then
                v_col_12:=substr(v_col_12,1,length(v_col_12)-1)||'],';
            end if;
            if v_col_13_ch <>' ' then
                v_col_13:=substr(v_col_13,1,length(v_col_13)-1)||'],';
            end if;
            if v_col_14_ch <>' ' then
                v_col_14:=substr(v_col_14,1,length(v_col_14)-1)||'],';
            end if;
            if v_col_15_ch <>' ' then
                v_col_15:=substr(v_col_15,1,length(v_col_15)-1)||'],'; 
            end if;
            EXIT;
        END IF;

        if i=1 then  -- First line header
          v_col_1_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 1);
          v_col_2_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 2);
          v_col_3_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 3);
          v_col_4_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 4);
          v_col_5_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 5);
          v_col_6_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 6);
          v_col_7_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 7);
          v_col_8_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 8);
          v_col_9_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 9);
          v_col_10_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 10);
          v_col_11_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 11);
          v_col_12_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 12);
          v_col_13_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 13);
          v_col_14_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 14);
          v_col_15_ch:= REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 15);


              if v_col_1_ch <>' ' then
                v_col_1:='"'||v_col_1_ch||'": [';
              end if;

              if v_col_2_ch <>' ' then
                v_col_2:='"'||v_col_2_ch||'": [';
              end if;

              if v_col_3_ch <>' ' then
                v_col_3:='"'||v_col_3_ch||'": [';
              end if;

              if v_col_4_ch <>' ' then
                v_col_4:='"'||v_col_4_ch||'": [';
              end if;

              if v_col_5_ch <>' ' then
                v_col_5:='"'||v_col_5_ch||'": [';
              end if;

              if v_col_6_ch <>' ' then
                v_col_6:='"'||v_col_6_ch||'": [';
              end if;
              if v_col_7_ch <>' ' then
                v_col_7:='"'||v_col_7_ch||'": [';
              end if;
              if v_col_8_ch <>' ' then
                v_col_8:='"'||v_col_8_ch||'": [';
              end if;
              if v_col_9_ch <>' ' then
                v_col_9:='"'||v_col_9_ch||'": [';
              end if;
              if v_col_10_ch <>' ' then
                v_col_10:='"'||v_col_10_ch||'": [';
              end if;
             if v_col_11_ch <>' ' then
                v_col_11:='"'||v_col_11_ch||'": [';
              end if; 
              if v_col_12_ch <>' ' then
                v_col_12:='"'||v_col_12_ch||'": [';
              end if;
             if v_col_13_ch <>' ' then
                v_col_13:='"'||v_col_13_ch||'": [';
              end if; 
              if v_col_14_ch <>' ' then
                v_col_14:='"'||v_col_14_ch||'": [';
             end if; 
              if v_col_15_ch <>' ' then
                v_col_15:='"'||v_col_15_ch||'": [';
              end if;   

          else

           if v_col_1_ch is not null then
                    v_col_1:= v_col_1 ||'"'||REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 1)||'",';
          end if;

            if v_col_2_ch is not null then
                v_col_2:= v_col_2 ||'"'||REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 2)||'",';
            end if;

            if v_col_3_ch is not null then
                v_col_3:= v_col_3 ||'"'||trim(REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 3))||'",';
            end if;

            if v_col_4_ch is not null then
                v_col_4:= v_col_4 ||'"'||trim(REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 4))||'",';
            end if;

            if v_col_5_ch is not null then
                v_col_5:= v_col_5 ||'"'||REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 5)||'",';
            end if;
            if v_col_6_ch is not null then
                v_col_6:= v_col_6 ||'"'||REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 6)||'",';
            end if;
            if v_col_7_ch is not null then
                v_col_7:= v_col_7 ||'"'||REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 7)||'",';
            end if;
            if v_col_8_ch is not null then
                v_col_8:= v_col_8 ||'"'||REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 8)||'",';
            end if;
            if v_col_9_ch is not null then
                v_col_9:= v_col_9 ||'"'||REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 9)||'",';
            end if;
            if v_col_10_ch is not null then
                v_col_10:= v_col_10 ||'"'||REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 10)||'",';
            end if;
            if v_col_11_ch is not null then
                v_col_11:= v_col_11 ||'"'||REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 11)||'",';
            end if;
            if v_col_12_ch is not null then
                v_col_12:= v_col_12 ||'"'||REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 12)||'",';
            end if;
           if v_col_13_ch is not null then
               v_col_13:= v_col_13 ||'"'||REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 13)||'",';
            end if;

            if v_col_14_ch is not null then
                v_col_14:= v_col_14 ||'"'||trim(REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 14))||'",';
            end if;
            if v_col_15_ch is not null then
                v_col_15:= v_col_15 ||'"'||REGEXP_SUBSTR(V_LINE, '[^'||CHR(9)||']+', 1, 15)||'",';
            end if;
          end if; 
  end loop; 

  v_result:=v_col_1||v_col_2||v_col_3||v_col_4||v_col_5||v_col_6||v_col_7||v_col_8||v_col_9||v_col_10||v_col_11||v_col_12||v_col_13||v_col_14||v_col_15;
 IF v_ENABLE_ENCRYPTION= 'Y' 
         THEN
          v_result1:='{'||v_header||'"'||v_result||'"}';
        v_result:=trnt_common_util.trnt_uac_api_encrypt_data(v_result);
        v_result:='{'||v_header||'"'||v_result||'"}';
        SELECT trnt_api_id_seq.NEXTVAL INTO v_tableseq FROM dual;
            INSERT INTO trnt_config_api_response (
                api_id,
                config_id,
                json_data,
                createdate,
                config_type,
                ENABLE_ENCRYPTION_FLAG,
                encrypt_data
            ) VALUES (
                v_tableseq,
                v_config_id,
                v_result1,
                SYSDATE,
                v_config_type,
                v_ENABLE_ENCRYPTION,
                v_result
            );

else

v_result:='{'||v_header||'{'||substr(v_result,1,length(v_result)-1)||'}}';

SELECT trnt_api_id_seq.NEXTVAL INTO v_tableseq FROM dual;

           INSERT INTO trnt_config_api_response (
                api_id,
                config_id,
                json_data,
                createdate,
                config_type,
                ENABLE_ENCRYPTION_FLAG
            ) VALUES (
                v_tableseq,
                v_config_id,
                v_result,
                SYSDATE,
                v_config_type,
                v_ENABLE_ENCRYPTION

            );
     end if;
    commit;
  return v_result;
 EXCEPTION
         WHEN OTHERS
         Then
return null;

end Get_Jsonformat_for_UAC;


PROCEDURE clob_to_file (p_clob      IN  CLOB,
                        p_directory_name       IN  VARCHAR2,
                        p_filename  IN  VARCHAR2)
AS
  l_file                UTL_FILE.FILE_TYPE;
  l_buffer              VARCHAR2(32767);
  l_amount              BINARY_INTEGER :=32767;
  l_pos                 INTEGER := 1;
  l_directory_name      VARCHAR2(200);
  v_filename            VARCHAR2(80);
  v_clob_length         number;


BEGIN
    l_directory_name :=p_directory_name;
    v_filename:= 'ENC_'||p_filename;
    v_clob_length:=length(p_clob);
    l_file := UTL_FILE.fopen(l_directory_name,v_filename, 'w',32767);
  LOOP
  EXIT WHEN l_pos >= v_clob_length;
    DBMS_LOB.read (p_clob, l_amount, l_pos, l_buffer);
    UTL_FILE.put(l_file, l_buffer);
    l_pos := l_pos + l_amount;

  END LOOP;
  utl_file.fflush(l_file);
  UTL_FILE.fclose(l_file);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
  fnd_file.put_line(fnd_file.log,'loop exit'||sqlerrm);
    -- Expected end.
    IF UTL_FILE.is_open(l_file) THEN 
      UTL_FILE.fclose(l_file);
    END IF;
  WHEN OTHERS THEN
    IF UTL_FILE.is_open(l_file) THEN
      UTL_FILE.fclose(l_file);
    END IF;

    RAISE;
END clob_to_file;
END trnt_common_util;
/