DROP PACKAGE BODY APPS.TRNT_xxx_EXCHANGE_RATE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.trnt_xxx_exchange_rate_pkg AS
/* $Header: trnt_exchange_rate_pkg.pkg, Version 1.0, 09-JAN-2020 $
***********************************************************************
* *
* History Log *
* *
***********************************************************************
* *
* App/Release : Oracle e-Business Suite 12.1.3 to 12.2.9*
* Module  : FOREIGN EXCHANGE RATE *
* Author  : Sanath Mannadath *
* Company : Trintech Inc *
* Description: This package extract data from Oracle EBS and Generate a file in the Oracle EBS server *
* Note: Do Not make any changes to this script, Without getting the Prior confirmation from Trintech Inc. *
* *
* Version    Date      Author         Change *
* ======= =========== ============ ================================*
* *
* 1.0      09-JAN-2020 Sanath       Initial Version *
* 1.0      12-JAN-2020 Prinsha      UAC API Added *
* 1.0      10-Feb-2020 Aswini	    Encryption Added *
* 1.0      05-Mar-2020 Vineeth      Added Period End Date *
**********************************************************************/
    PROCEDURE trnt_exchange_rate_file (
        errbuff      OUT  VARCHAR2,
        retcode      OUT  NUMBER,
        p_config_id  IN   VARCHAR2
    ) IS

        l_propsed_extract        VARCHAR2(20);
        l_conversion_date        VARCHAR2(20);
        l_trintech_rate_type_id  VARCHAR2(20);
        l_custom_text_field      VARCHAR2(20);
        l_erp_rate_type          VARCHAR2(20);
        v_schd_date              VARCHAR2(20) := NULL;
        lv_id                    utl_file.file_type;
        v_filename               VARCHAR2(1000);
        l_db                     VARCHAR(20);
        l_directory_name         VARCHAR2(100);
        l_database_name          VARCHAR2(200);
        lv_count                 NUMBER(5) DEFAULT 0;
        l_url                    VARCHAR2(100);
        l_file_path              VARCHAR2(200);
        l_customer_name          VARCHAR2(100);
        l_effective_date         VARCHAR2(20);
        l_custom_txt1            VARCHAR2(100);
        l_custom_text_json       VARCHAR2(100);
        l_custom_txt2            VARCHAR2(100);
        l_reverse_exchange_rate  NUMBER;
        l_cnt                    NUMBER;
        l_custom_label1          VARCHAR2(20);
        l_custom_label2          VARCHAR2(20);
        l_date_format            VARCHAR2(20);
        l_output_type            VARCHAR2(20);
        l_header_line            VARCHAR2(2000);
        l_data_line              VARCHAR2(2000);
        l_custom_txt_label       VARCHAR2(100);
      /*Declaration of variables for Exchange Rate Extract API*/
        v_extract_type           VARCHAR2(10);
        v_date                   CLOB;
        v_fromcurrency           CLOB;
        v_tocurrency             CLOB;
        v_exchangerate           CLOB;
        v_typeid                 CLOB;
        v_customtext1            CLOB;
        v_customtext2            CLOB;
        v_jdata                  CLOB;
        v_jdata_file             CLOB;
        v_tableseq               NUMBER;
        l_text_data              CLOB;
        txtfile_tab              trnt_common_util.txtfile_tab;
        indx                     NUMBER := 0;
        CURSOR gl_excng_rate_cur IS
        SELECT
            to_char(to_date(l_effective_date), l_date_format)         effective_date,
            from_currency,
            to_currency,
            round(conversion_rate, 8)                                 exchange_rate
          FROM
            gl_daily_rates             gdr,
            gl_daily_conversion_types  gdc
         WHERE
                gdr.conversion_type = gdc.conversion_type
               AND gdr.conversion_date <= l_effective_date
               AND length(gdr.from_currency) = 3
               AND length(gdr.to_currency) = 3
               AND gdc.user_conversion_type = nvl(l_erp_rate_type, gdr.conversion_type)
               AND conversion_date = (
                SELECT
                    MAX(conversion_date)
                  FROM
                    gl_daily_rates gd
                 WHERE
                        gd.from_currency = gdr.from_currency
                       AND gd.to_currency = gdr.to_currency
                       AND gd.conversion_date <= l_effective_date
            )
         ORDER BY
            1;

        CURSOR c_config IS
        SELECT
            config_id,
            config_code,
            config_desc,
            config_type,
            extract_type,
            output_type,
            output_location,
            custom_text1,
            custom_text2,
            erp_rate_type,
            trintech_rate_type,
            propsed_extract,
            propsed_extract_date,
            date_format,
            enable_encryption
           -- FILE_ENCRYPT_FLAG
          FROM
            trnt_config
         WHERE
            config_id = p_config_id;

        rec_config               c_config%rowtype;
        v_count                  NUMBER;
    BEGIN
        fnd_file.put_line(fnd_file.log, 'package_name:trnt_exchange_rate_pkg  procedure_name:trnt_exchange_rate_file');
        fnd_file.put_line(fnd_file.log, 'p_batch_id:'
                                        || fnd_global.conc_request_id
                                        || 'p_config_id:'
                                        || p_config_id);

        fnd_file.put_line(fnd_file.log, 'Start Of trnt exchange rate');
        OPEN c_config;
        FETCH c_config INTO rec_config;
        CLOSE c_config;
        l_propsed_extract           := rec_config.propsed_extract;--LAST/FIRST
        l_conversion_date           := rec_config.propsed_extract_date;
        l_erp_rate_type             := rec_config.erp_rate_type;
        l_file_path                 := rec_config.output_location;
        l_trintech_rate_type_id     := rec_config.trintech_rate_type;
        l_date_format               := nvl(rec_config.date_format, 'dd/mm/rrrr');
        l_custom_txt1               := rec_config.custom_text1;
        l_custom_txt2               := rec_config.custom_text2;
        l_output_type               := rec_config.output_type;
        l_custom_text_json          := rec_config.custom_text1;
        fnd_file.put_line(fnd_file.log, ' Date Format :' || l_date_format);
        BEGIN
            IF l_conversion_date IS NOT NULL THEN
                l_effective_date := l_conversion_date;
            ELSE
                l_effective_date := to_date(sysdate, 'DD-MON-YYYY');
            END IF;

            fnd_file.put_line(fnd_file.log, 'Conversion Date :' || l_effective_date);
         --Assigning cut off date to local variable--
            IF l_propsed_extract = 'LAST' THEN
                l_effective_date := to_date(last_day(add_months(l_effective_date, -1)), 'DD-MON-YYYY');
            ELSIF l_propsed_extract = 'FIRST' THEN
                l_effective_date := to_date(last_day(add_months(l_effective_date, -1)) + 1, 'DD-MON-YYYY');
            ELSE
                l_effective_date := to_date(l_effective_date, 'DD-MON-YYYY');
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                retcode := 1;
                fnd_file.put_line(fnd_file.log, 'Date format mismatch.'
                                                || sqlerrm
                                                || ' - '
                                                || dbms_utility.format_error_backtrace);

                fnd_file.put_line(fnd_file.log, chr(13));
                return;
        END;

        fnd_file.put_line(fnd_file.log, 'Effective Date :' || l_effective_date);
        l_db := trnt_common_util.get_db_name(l_file_path);
        IF l_db IS NULL THEN
            retcode := 1;
            fnd_file.put_line(fnd_file.log, 'Database can not be null :' || l_db);
        END IF;

        IF l_output_type IN (
            'S',
            'X'
        ) THEN
            IF l_file_path IS NULL THEN
                retcode := 1;
                fnd_file.put_line(fnd_file.log, 'Please enter the server file output path');
            END IF;

            fnd_file.put_line(fnd_file.log, 'deriving db name for the filepath');
         --deriving db name for the filepath--
            l_directory_name := trnt_common_util.get_dir_name(l_file_path);
            IF l_directory_name IS NULL THEN
                retcode := 1;
                fnd_file.put_line(fnd_file.log, 'No Oracle Directory available for the file path');
                return;
            END IF;

            v_filename := trnt_common_util.get_filename_out(rec_config.config_type, rec_config.config_code);
            fnd_file.put_line(fnd_file.log, 'Foregin Exchange File path name : '
                                            || l_file_path
                                            || v_filename);
            lv_id := utl_file.fopen(l_directory_name, v_filename, 'W');
            fnd_file.put_line(fnd_file.log, 'Open Data File.');
        END IF;

        fnd_file.put_line(fnd_file.log, 'setting the header');
        IF l_custom_txt1 IS NOT NULL THEN
            l_custom_txt_label := chr(9)
                                  || 'customtext';
        END IF;

        l_header_line := 'date'
                         || chr(9)
                         || 'fromcurrency'
                         || chr(9)
                         || 'tocurrency'
                         || chr(9)
                         || 'exchangerate'
                         || chr(9)
                         || 'typeid'
                         || l_custom_txt_label
                         || chr(13);

        IF l_output_type IN (
            'S',
            'X'
        ) THEN
            utl_file.put_line(lv_id, l_header_line);
        END IF;

        IF l_output_type IN (
            'R',
            'X'
        ) THEN
            fnd_file.put_line(fnd_file.output, l_header_line);
        END IF;

        IF l_output_type IN (
            'API'
        ) THEN
            indx := indx + 1;
            txtfile_tab(indx).dataline := l_header_line;  
        END IF;

        IF l_output_type IN (
            'JSON'
        ) THEN
            indx := indx + 1;
            txtfile_tab(indx).dataline := l_header_line;
        END IF;

        IF l_custom_txt1 IS NOT NULL THEN
            l_custom_txt1 := chr(9)
                             || l_custom_txt1;
        END IF;

        fnd_file.put_line(fnd_file.log, 'end of setting headers');
        fnd_file.put_line(fnd_file.log, 'begin of records');
        FOR gl_excng_rate_rec IN gl_excng_rate_cur LOOP
            lv_count := lv_count + 1;
            l_data_line := gl_excng_rate_rec.effective_date
                           || chr(9)
                           || gl_excng_rate_rec.from_currency
                           || chr(9)
                           || gl_excng_rate_rec.to_currency
                           || chr(9)
                           || to_char(gl_excng_rate_rec.exchange_rate, '9999999999.00000')
                           || chr(9)
                           || l_trintech_rate_type_id
                           || l_custom_txt1
                           || chr(13);
              /*Exchange Rate Extract API */

            SELECT
                extract_type
              INTO v_extract_type
              FROM
                trnt_config
             WHERE
                config_id = p_config_id;

            IF l_output_type IN (
                'S',
                'X'
            ) THEN
                utl_file.put_line(lv_id, l_data_line);
            END IF;

            IF l_output_type IN (
                'R',
                'X'
            ) THEN
                fnd_file.put_line(fnd_file.output, l_data_line);
            END IF;
   -----         

            IF l_output_type IN (
                'API'
            ) THEN
                indx := indx + 1;
                txtfile_tab(indx).dataline := l_data_line;
            END IF;

            IF l_output_type IN (
                'JSON'
            ) THEN
                indx := indx + 1;
                txtfile_tab(indx).dataline := l_data_line;
            END IF;

            SELECT
                COUNT(*)
              INTO v_count
              FROM
                gl_daily_rates             gdr,
                gl_daily_conversion_types  gdc
             WHERE
                    gdr.conversion_type = gdc.conversion_type
                   AND gdr.conversion_date <= l_effective_date
                   AND length(gdr.from_currency) = 3
                   AND length(gdr.to_currency) = 3
                   AND gdc.user_conversion_type = nvl(l_erp_rate_type, gdr.conversion_type)
                   AND conversion_date = (
                    SELECT
                        MAX(conversion_date)
                      FROM
                        gl_daily_rates gd
                     WHERE
                            gd.from_currency = gdr.from_currency
                           AND gd.to_currency = gdr.to_currency
                           AND gd.from_currency = gl_excng_rate_rec.to_currency
                           AND gd.to_currency = gl_excng_rate_rec.from_currency
                           AND gd.conversion_date <= l_effective_date
                );

            IF v_count = 0 THEN
                lv_count := lv_count + 1;
                l_data_line := gl_excng_rate_rec.effective_date
                               || chr(9)
                               || gl_excng_rate_rec.to_currency
                               || chr(9)
                               || gl_excng_rate_rec.from_currency
                               || chr(9)
                               || to_char(abs(1 / gl_excng_rate_rec.exchange_rate), '9999999999.00000')
                               || chr(9)
                               || l_trintech_rate_type_id
                               || l_custom_txt1
                               || chr(13);

                IF l_output_type IN (
                    'API'
                ) THEN
                    indx := indx + 1;
                    txtfile_tab(indx).dataline := l_data_line;
                END IF;

                IF l_output_type IN (
                    'JSON'
                ) THEN
                    indx := indx + 1;
                    txtfile_tab(indx).dataline := l_data_line;
                END IF;

                IF l_output_type IN (
                    'S',
                    'X'
                ) THEN
                    utl_file.put_line(lv_id, l_data_line);
                END IF;

                IF l_output_type IN (
                    'R',
                    'X'
                ) THEN
                    fnd_file.put_line(fnd_file.output, l_data_line);
                END IF;

            END IF;

        END LOOP;

        fnd_file.put_line(fnd_file.log, 'end of records');


               -----------Start Code for encryption --------
        IF l_output_type IN (
            'API'
        ) THEN
            BEGIN
                fnd_file.put_line(fnd_file.log, 'api extract');
                fnd_file.put_line(fnd_file.log, 'v_jdata' || v_jdata);
                v_jdata := trnt_common_util.get_jsonformat_for_uac(txtfile_tab, 'CAD', 'FXRATE', 'EBS_APPS', rec_config.config_code,
                                        rec_config.enable_encryption, p_config_id, rec_config.config_type, NULL, NULL);

            EXCEPTION
                WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.log, sqlerrm);
            END;

            fnd_file.put_line(fnd_file.log, 'api call');
            DECLARE
                v_webdat VARCHAR2(4000);
            BEGIN
                v_webdat := trnt_common_util.trnt_uac_webservice(v_jdata, v_tableseq);
                fnd_file.put_line(fnd_file.log, 'Result from API Server :  ' || v_webdat);
            END;

        END IF;

     --json--

        IF l_output_type IN (
            'JSON'
        ) THEN
        fnd_file.put_line(fnd_file.log, 'extract for json format');
            BEGIN
                v_jdata := trnt_common_util.get_jsonformat_for_uac(txtfile_tab, 'CAD', 'APBALS', 'EBS_APPS', rec_config.config_code,
                                        rec_config.enable_encryption, p_config_id, rec_config.config_type, NULL, NULL);
            EXCEPTION
                WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.log, sqlerrm);
            END;

            l_file_path := '/usr/trintech';
            l_directory_name := trnt_common_util.get_dir_name(l_file_path);
            IF l_directory_name IS NULL THEN
                fnd_file.put_line(fnd_file.log, 'No Oracle Directory available for the file path');
                return;
            END IF;

            l_database_name := trnt_common_util.get_db_name(l_file_path);
            l_directory_name := trnt_common_util.get_dir_name(l_file_path);
            v_filename := trnt_common_util.get_filename_out(rec_config.config_type, rec_config.config_code);
            IF rec_config.enable_encryption = 'Y' THEN
                v_filename := 'EJ_' || v_filename;
            ELSE
                v_filename := 'J_' || v_filename;
            END IF;

            trnt_common_util.clob_to_file(v_jdata, l_directory_name, v_filename);
        END IF;

        IF lv_count = 0 THEN
            retcode := 1;
            fnd_file.put_line(fnd_file.log, 'No Data To Extract and write into the file for the Date :' || l_effective_date);
            fnd_file.put_line(fnd_file.log, chr(13));
            return;
        END IF;                                
         --closing the file otherwise--

        IF l_output_type IN (
            'S'
        ) THEN
            fnd_file.put_line(fnd_file.output, 'Output option selected is server, Please find the file in server path ' || l_file_path);
        END IF;

        utl_file.fclose(lv_id);
        fnd_file.put_line(fnd_file.log, 'Closing Data File.');
        fnd_file.put_line(fnd_file.output, 'No of Records transfered to the data file :' || lv_count);
        fnd_file.put_line(fnd_file.output, ' ');
        fnd_file.put_line(fnd_file.output, 'Submitted User name  ' || fnd_profile.value('USERNAME'));

        fnd_file.put_line(fnd_file.output, ' ');
        fnd_file.put_line(fnd_file.output, 'Submitted Responsibility name ' || fnd_profile.value('RESP_NAME'));

        fnd_file.put_line(fnd_file.output, ' ');
        fnd_file.put_line(fnd_file.output, 'Submission Date :' || sysdate);
        IF l_output_type IN (
            'S',
            'X'
        ) THEN
            fnd_file.put_line(fnd_file.output, 'File was succesfully written to: '
                                               || l_file_path
                                               || chr(10));

            fnd_file.put_line(fnd_file.output, 'File was succesfully written to: '
                                         || l_file_path
                                         || chr(10));
        END IF;

    
    EXCEPTION
        WHEN utl_file.invalid_operation THEN
            fnd_file.put_line(fnd_file.log, 'invalid operation');
         
            retcode := 1;
            utl_file.fclose_all;
        WHEN utl_file.invalid_mode THEN
            fnd_file.put_line(fnd_file.log, 'invalid mode');
           
            retcode := 1;
            utl_file.fclose_all;
        WHEN utl_file.invalid_filehandle THEN
            fnd_file.put_line(fnd_file.log, 'invalid filehandle');
          
            retcode := 1;
            utl_file.fclose_all;
        WHEN utl_file.read_error THEN
            fnd_file.put_line(fnd_file.log, 'read error');
         
            retcode := 1;
            utl_file.fclose_all;
        WHEN utl_file.internal_error THEN
            fnd_file.put_line(fnd_file.log, 'internal error');
         
            retcode := 1;
            utl_file.fclose_all;
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'other error');
            fnd_file.put_line(fnd_file.log, dbms_utility.format_error_backtrace || sqlerrm);
         
            retcode := 1;
            utl_file.fclose_all;
    END trnt_exchange_rate_file;

END trnt_xxx_exchange_rate_pkg;
/
