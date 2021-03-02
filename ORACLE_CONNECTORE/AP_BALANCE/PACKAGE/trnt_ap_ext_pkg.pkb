DROP PACKAGE BODY APPS.TRNT_xxx_AP_EXT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.trnt_xxx_ap_ext_pkg AS
/* $Header: trnt_ap_ext_pkg.pkg, Version 1.0, 09-JAN-2020 $
***********************************************************************
* *
* History Log *
* *
***********************************************************************
* *
* App/Release : Oracle e-Business Suite 12.1.3 to 12.2.9*
* Module  : ACCOUNT PAYABLE*
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
* 1.1      13-OCT-2020 Sanath       Modified the main query as per Requirements*
**********************************************************************/
    PROCEDURE trnt_ap_ext_file (
        errbuff      OUT  VARCHAR2,
        retcode      OUT  NUMBER,
        p_config_id  IN   NUMBER
    ) IS

        l_period_end_date     VARCHAR2(20);
        l_period_name         VARCHAR2(20);
        l_count               NUMBER := 0;
        l_global_code         VARCHAR2(20);
        conver_rate_col       NUMBER := 0;
        l_gbl_amount          NUMBER(16, 2);
        local_curr_code       VARCHAR2(10);
        l_trans_amount        NUMBER(16, 2);
        l_local_amount        NUMBER(16, 2);
        lv_customer_name      VARCHAR2(200);
        lv_url                VARCHAR2(200);
        v_utlfile             utl_file.file_type;
        v_filename            VARCHAR2(80);
        l_period_cutoff       NUMBER;
        l_period_year         VARCHAR2(10) := NULL;
        fiscal_year_exception EXCEPTION;
        l_database_name       VARCHAR2(200);
        l_directory_name      VARCHAR2(200);
        l_num_segments        NUMBER;
        l_ledger_id           VARCHAR2(200);
        l_file_path           VARCHAR2(200);
        l_header_line         VARCHAR2(2000);
        l_data_line           VARCHAR2(2000);
        local_conv_rate       NUMBER;
        l_period_num          VARCHAR2(200);
        l_seg1                VARCHAR2(20);
        l_seg2                VARCHAR2(20);
        l_seg3                VARCHAR2(20);
        l_seg4                VARCHAR2(20);
        l_seg5                VARCHAR2(20);
        l_seg6                VARCHAR2(20);
        l_seg7                VARCHAR2(20);
        l_seg8                VARCHAR2(20);
        l_seg9                VARCHAR2(20);
        l_account_seg         VARCHAR2(100);
        l_account_key         VARCHAR2(10);
        l_output_type         VARCHAR2(10);
        hd_flag               NUMBER := 1;

         /*Declaration of variables for Accounts Payable Extract API*/
        v_extract_type        VARCHAR2(10);
        v_accountdesc         CLOB;
        v_period_year         CLOB;
        v_period_num          CLOB;
        v_period_end_date     CLOB;
        v_global_code         CLOB;
        v_global_amount       CLOB;
        v_local_curr_code     CLOB;
        v_local_trans_amount  CLOB;
        v_trans_curr_code     CLOB;
        v_sum_trans_amount    CLOB;
        v_jdata_file          CLOB;
        v_jdata               CLOB;
        v_jdata_headers       CLOB;
        v_tableseq            NUMBER;
        gbl_amt               NUMBER(16, 2);
        trans_amt             NUMBER(16, 2);
        lcl_amt               NUMBER(16, 2);
        v_company             CLOB;
        v_department          CLOB;
        v_account             CLOB;
        v_ledger              CLOB;
        v_profitcenter        CLOB;
        v_segment1            CLOB;
        v_segment2            CLOB;
        v_segment3            CLOB;
        v_segment4            CLOB;
        v_segment5            CLOB;
        v_segment6            CLOB;
        v_segment7            CLOB;
        v_segment8            CLOB;
        v_segment9            CLOB;
        v_segment10_desc      CLOB;
        l_column_name         VARCHAR(100);
        v_encrypt_blob        BLOB;
        v_clob                CLOB;
        v_decrypt_blob        BLOB;
        v_clob_cnt_payload    CLOB;
        l_text_data           CLOB;
        txtfile_tab           trnt_common_util.txtfile_tab;
        indx                  NUMBER := 0;
        l_count_trial         NUMBER := 0;
        l_coa_id              NUMBER;
        l_as_of_date          DATE;


        CURSOR cur_cad_ap_bal_ext IS
       
          SELECT DECODE (l_seg1, 'Y', glc.segment1, '')    segment1,
                 DECODE (l_seg2, 'Y', glc.segment2, '')    segment2,
                 DECODE (l_seg3, 'Y', glc.segment3, '')    segment3,
                 DECODE (l_seg4, 'Y', glc.segment4, '')    segment4,
                 DECODE (l_seg5, 'Y', glc.segment5, '')    segment5,
                 DECODE (l_seg6, 'Y', glc.segment6, '')    segment6,
                 DECODE (l_seg7, 'Y', glc.segment7, '')    segment7,
                 DECODE (l_seg8, 'Y', glc.segment8, '')    segment8,
                 DECODE (l_seg9, 'Y', glc.segment9, '')    segment9,
                 DECODE (l_account_seg,
                         'SEGMENT1', glc.segment1,
                         'SEGMENT2', glc.segment2,
                         'SEGMENT3', glc.segment3,
                         'SEGMENT4', glc.segment4,
                         'SEGMENT5', glc.segment5,
                         '')                               account_no,
                 DECODE (l_account_seg,
                         'SEGMENT1', 1,
                         'SEGMENT2', 2,
                         'SEGMENT3', 3,
                         'SEGMENT4', 4,
                         'SEGMENT5', 5,
                         '')                               account_key,
                 glc.chart_of_accounts_id,
                 tb.ledger_id,
                 tb.code_combination_id,
                 gl.CURRENCY_CODE                          local_curr_code,
                 SUM (NVL (tb.acctd_rounded_cr, 0))- SUM (NVL (tb.acctd_rounded_dr, 0))      local_trans_amount,
                 tb.trx_currency_code                      trans_curr_code,
                 SUM (NVL (tb.entered_rounded_cr, 0))- SUM (NVL (tb.entered_rounded_dr, 0))    sum_trans_amount
            FROM xla_trial_balances      tb,
                 fnd_application_vl      app,
                 gl_code_combinations_kfv glc,
                 gl_ledgers              gl
           WHERE     tb.source_application_id = app.application_id
                 AND tb.code_combination_id = glc.code_combination_id
                 AND tb.ledger_id = l_ledger_id
                 AND app.application_id = 200
                 AND gl.LEDGER_ID = tb.LEDGER_ID
                 AND TRUNC (tb.gl_date) <= l_period_end_date
                 AND glc.concatenated_segments IN (SELECT concatenated_segments
                                                     FROM trnt_config_segment_list
                                                    WHERE config_id = p_config_id)
        GROUP BY DECODE (l_seg1, 'Y', glc.segment1, ''),
                 DECODE (l_seg2, 'Y', glc.segment2, ''),
                 DECODE (l_seg3, 'Y', glc.segment3, ''),
                 DECODE (l_seg4, 'Y', glc.segment4, ''),
                 DECODE (l_seg5, 'Y', glc.segment5, ''),
                 DECODE (l_seg6, 'Y', glc.segment6, ''),
                 DECODE (l_seg7, 'Y', glc.segment7, ''),
                 DECODE (l_seg8, 'Y', glc.segment8, ''),
                 DECODE (l_seg9, 'Y', glc.segment9, ''),
                 DECODE (l_account_seg,
                         'SEGMENT1', glc.segment1,
                         'SEGMENT2', glc.segment2,
                         'SEGMENT3', glc.segment3,
                         'SEGMENT4', glc.segment4,
                         'SEGMENT5', glc.segment5,
                         ''),
                 DECODE (l_account_seg,
                         'SEGMENT1', 1,
                         'SEGMENT2', 2,
                         'SEGMENT3', 3,
                         'SEGMENT4', 4,
                         'SEGMENT5', 5,
                         ''),
                 glc.chart_of_accounts_id,
                 tb.ledger_id,
                 tb.code_combination_id,
                 tb.trx_currency_code,
                 gl.CURRENCY_CODE
        ORDER BY 1;

        rec_trial_count       xla_trial_balances_gt%rowtype;
        CURSOR c_config IS
        SELECT * FROM trnt_config
         WHERE config_id = p_config_id;

        rec_config            trnt_config%rowtype;
        CURSOR c_seg_sel IS
        SELECT  * FROM trnt_segment_selection
         WHERE config_id = p_config_id
               AND segment_disp = 'Y'
         ORDER BY segment_slno ASC;

        rec_seg_sel           c_seg_sel%rowtype;
    BEGIN
        fnd_file.put_line(fnd_file.log, 'Start AP balance extract ');
        fnd_file.put_line(fnd_file.log, 'package_name:trnt_ap_ext_pkg' || ',procedure_name:trnt_ap_ext_file');
        fnd_file.put_line(fnd_file.log, 'p_batch_id:'
                                        || fnd_global.conc_request_id
                                        || ',p_config_id:'
                                        || p_config_id);

        OPEN c_config;
        FETCH c_config INTO rec_config;
        CLOSE c_config;
        trnt_common_util.create_segments_filter(p_config_id);
        l_ledger_id         := rec_config.ledger;
        l_period_name       := rec_config.period_1;
        l_period_year       := rec_config.fiscal_year;
        l_period_cutoff     := rec_config.extra_days_prior_cutoff;
        l_file_path         := rec_config.output_location;
        l_output_type       := rec_config.output_type;
        l_coa_id            := rec_config.chart_of_accounts_id;
        l_account_seg       := trnt_common_util.get_segment('ACCOUNT', l_ledger_id, rec_config.chart_of_accounts_id, rec_config.config_type);

        fnd_file.put_line(fnd_file.log, 'AP'
                                        || 'ACCOUNT- ||Getting segment Details'
                                        || l_account_seg
                                        || 'l_as_of_date'
                                        || l_as_of_date);

        SELECT
            decode(l_account_seg, 'SEGMENT1', 1, 'SEGMENT2', 2,
                   'SEGMENT3', 3, 'SEGMENT4', 4, 'SEGMENT5',
                   5, '')
          INTO l_account_key
          FROM
            dual;

        fnd_file.put_line(fnd_file.log, 'AP'
                                        || 'ACCOUNT-||Getting segment Details'
                                        || l_account_key);
        fnd_file.put_line(fnd_file.log, 'AP' || 'Year and Period Selection');


       /*Year and  period Selection*/
        BEGIN
            IF (
                l_period_cutoff IS NULL AND ( l_period_year IS NULL OR l_period_name IS NULL )
            ) THEN
                fnd_file.put_line(fnd_file.log, 'Please enter either Fiscal Year and Period  name or Cutoff Period');
                RAISE fiscal_year_exception;
                return;
            END IF;

            IF (
                    l_period_cutoff IS NOT NULL AND l_period_year IS NULL
                AND l_period_name IS NULL
            ) THEN
                SELECT
                    to_char(sysdate - l_period_cutoff, 'Mon-YY')
                  INTO l_period_name
                  FROM
                    dual;

            END IF;

            IF l_period_year IS NULL THEN
                l_period_year := trnt_common_util.get_period_year(l_period_name, l_ledger_id);
                IF l_period_year IS NULL THEN
                    fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                    || 'APBAL_YEAR_NOT_FOUND: '
                                                    || 'Period Year is not found for Period'
                                                    || l_period_name);

                    fnd_file.put_line(fnd_file.log, 'AP'
                                                    || 'APBAL_YEAR_NOT_FOUND:'
                                                    || 'Period Year is not found for Period'
                                                    || l_period_name);

                    retcode := 1;
                    return;
                END IF;

            END IF;

            l_period_end_date := trnt_common_util.get_period_end_date(l_period_name, l_period_year, l_ledger_id);
            fnd_file.put_line(fnd_file.log, l_period_end_date || 'l_period_end_date');
            IF l_period_end_date IS NULL THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                || 'APBALS_PERIOD_END_DATE_NOT_FOUND: '
                                                || 'Period End Date is not found for '
                                                || l_period_name
                                                || ' and '
                                                || l_period_year);

                retcode := 1;
                return;
            END IF;

            fnd_file.put_line(fnd_file.log, 'Fiscal Year: '
                                            || l_period_year
                                            || ' Period  name : '
                                            || l_period_name
                                            || ' Period_cutoff : '
                                            || l_period_cutoff);

        EXCEPTION
            WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log, 'Error Code:'
                                                || 'APBALS_PERIOD_DETAILS_NOT_FOUND: Please enter either Period year and period name or Cutoff Period'
                                                || dbms_utility.format_error_backtrace
                                                || sqlerrm);

                fnd_file.put_line(fnd_file.log, 'AP'
                                                || 'APBALS_PERIOD_END_DATE_NOT_FOUND:'
                                                || 'Period End Date is not found for '
                                                || l_period_name
                                                || ' and '
                                                || l_period_year);

                retcode := 1;
                return;
        END;

        BEGIN
            SELECT
                lpad(p2.period_num, 2, '0')
              INTO l_period_num
              FROM
                gl_periods  p2,
                gl_ledgers  l
             WHERE
                    l.ledger_id = l_ledger_id
                   AND p2.period_year = l_period_year
                   AND p2.period_name = l_period_name
                   AND p2.period_set_name = l.period_set_name
                   AND p2.period_type = l.accounted_period_type;

        EXCEPTION
            WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                || 'APBAL_PERIOD_NOT_FOUND: '
                                                || 'Period not found for Period'
                                                || l_period_name);

                fnd_file.put_line(fnd_file.log, 'AP'
                                                || ',APBAL_YEAR_NOT_FOUND:'
                                                || 'Period not found for Period'
                                                || l_period_name);

        END;

        fnd_file.put_line(fnd_file.log, 'Start Global Currency selection');


        /*Start Global Currency selection*/
        BEGIN
            l_global_code := trnt_common_util.get_global_code(l_ledger_id, p_config_id);
            IF l_global_code IS NULL THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                || 'APBALS_GLOBAL_CURRENCY_CODE_NOT_FOUND: '
                                                || 'Global Currency Code is not found'
                                                || l_ledger_id);

                retcode := 1;
                return;
            END IF;

            local_curr_code := trnt_common_util.get_local_code(l_ledger_id);
            IF local_curr_code IS NULL THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                || 'APBALS_LOCAL_CURRENCY_CODE_NOT_FOUND: '
                                                || 'Local Currency Code is not found for '
                                                || l_ledger_id);

                retcode := 1;
                return;
            END IF;

            IF local_curr_code = l_global_code THEN
                conver_rate_col := 1;
            ELSE
                conver_rate_col := trnt_common_util.get_conversion_rate(l_ledger_id, local_curr_code, l_global_code, l_period_end_date);
                IF conver_rate_col IS NULL THEN
                    fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                    || 'APBALS_CONVERSION_RATE_NOT_FOUND: '
                                                    || 'Conversion Rate is not found for '
                                                    || l_global_code
                                                    || ' and '
                                                    || l_period_end_date);

                    retcode := 1;
                    return;
                END IF;

            END IF;

        END;

        fnd_file.put_line(fnd_file.log, 'end of Global Currency selection');
       --end of Global Currency selection--

      /*SERVER/Report and file path setting*/
        fnd_file.put_line(fnd_file.log, 'SERVER/Report and file path setting');
        IF l_output_type IN (
            'S',
            'X'
        ) THEN
            IF l_file_path IS NULL THEN
                retcode := 1;
                fnd_file.put_line(fnd_file.log, 'Please enter the server file output path');
            END IF;
         --deriving db name for the filepath--

            l_directory_name := trnt_common_util.get_dir_name(l_file_path);
            IF l_directory_name IS NULL THEN
                retcode := 1;
                fnd_file.put_line(fnd_file.log, 'No Oracle Directory available for the file path');
                return;
            END IF;

            l_database_name     := trnt_common_util.get_db_name(l_file_path);
            l_directory_name    := trnt_common_util.get_dir_name(l_file_path);
            v_filename          := trnt_common_util.get_filename_out(rec_config.config_type, rec_config.config_code);
            fnd_file.put_line(fnd_file.log, 'AP balance extractor File path name : '
                                            || l_file_path
                                            || '/'
                                            || v_filename);

            IF l_count = 0 THEN
                v_utlfile := utl_file.fopen(l_directory_name, v_filename, 'W');
            END IF;

        END IF;

       -- End of SERVER/Report and file path setting--

   

           /*Setting the header for the extract */

        fnd_file.put_line(fnd_file.log, 'Setting the header for the extract');
        l_header_line := NULL;
        fnd_file.put_line(fnd_file.log, 'Setting the segements header for the extract');
        OPEN c_seg_sel;
        LOOP
            FETCH c_seg_sel INTO rec_seg_sel;
            EXIT WHEN c_seg_sel%notfound;
            IF rec_seg_sel.segment_name = 'SEGMENT1' THEN
                l_seg1 := 'Y';
            ELSIF rec_seg_sel.segment_name = 'SEGMENT2' THEN
                l_seg2 := 'Y';
            ELSIF rec_seg_sel.segment_name = 'SEGMENT3' THEN
                l_seg3 := 'Y';
            ELSIF rec_seg_sel.segment_name = 'SEGMENT4' THEN
                l_seg4 := 'Y';
            ELSIF rec_seg_sel.segment_name = 'SEGMENT5' THEN
                l_seg5 := 'Y';
            ELSIF rec_seg_sel.segment_name = 'SEGMENT6' THEN
                l_seg6 := 'Y';
            ELSIF rec_seg_sel.segment_name = 'SEGMENT7' THEN
                l_seg7 := 'Y';
            ELSIF rec_seg_sel.segment_name = 'SEGMENT8' THEN
                l_seg8 := 'Y';
            ELSIF rec_seg_sel.segment_name = 'SEGMENT9' THEN
                l_seg9 := 'Y';
            END IF;

            l_header_line := l_header_line
                             || rec_seg_sel.segment_label
                             || chr(9);
        END LOOP;

        CLOSE c_seg_sel;
        IF rec_config.exclude_ledg_output = 'N' THEN
            l_header_line := l_header_line
                             || 'ledger'
                             || chr(9);
        END IF;

        l_header_line := l_header_line
                         || 'accountdescription'
                         || chr(9)
                         || 'fiscalyear'
                         || chr(9)
                         || 'period'
                         || chr(9);

        fnd_file.put_line(fnd_file.log, 'checking the period end date check box value');
        IF nvl(rec_config.period_end_date, 'N') = 'Y' THEN
            l_header_line := l_header_line
                             || 'periodenddate'
                             || chr(9);
        END IF;

        l_header_line := l_header_line
                         || 'ccy1'
                         || chr(9)
                         || 'ccy1amt'
                         || chr(9)
                         || 'ccy2'
                         || chr(9)
                         || 'ccy2amt'
                         || chr(9)
                         || 'ccy3'
                         || chr(9)
                         || 'ccy3amt'
                         || chr(13);

        fnd_file.put_line(fnd_file.log, 'Setting the extraxt method');

         --Setting the records for the extract--          
        FOR rec IN cur_cad_ap_bal_ext LOOP
            IF hd_flag = 1 THEN
                IF l_output_type IN (
                    'S',
                    'X'
                ) THEN
                    utl_file.put_line(v_utlfile, l_header_line);
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

                hd_flag := 0;
            END IF;

            IF
                rec.local_trans_amount <> 0 AND rec.sum_trans_amount <> 0
            THEN
                l_count := l_count + 1;
                BEGIN
                    l_gbl_amount := 0;
                    IF ( l_global_code <> rec.local_curr_code ) THEN                    
                        l_gbl_amount := ( rec.local_trans_amount * conver_rate_col );
                    ELSIF ( l_global_code = rec.local_curr_code ) THEN
                        l_gbl_amount := rec.local_trans_amount;

                    END IF;

                END;

       --Creating record from Query--

                l_data_line := NULL;
                OPEN c_seg_sel;
                LOOP
                    FETCH c_seg_sel INTO rec_seg_sel;
                    EXIT WHEN c_seg_sel%notfound;
                    BEGIN
                        SELECT
                            column_name
                          INTO l_column_name
                          FROM
                            trnt_segment_config
                         WHERE
                                application_column_name = rec_seg_sel.segment_name
                               AND ledger_id = rec.ledger_id;

                    EXCEPTION
                        WHEN OTHERS THEN
                            l_column_name := 'XX';
                    END;

                    IF rec_seg_sel.segment_name = 'SEGMENT1' THEN
                        l_data_line := l_data_line
                                       || trnt_common_util.format_field(rec.segment1, rec_seg_sel.rm_leadzero, rec_seg_sel.rm_special_char)
                                       || chr(9);
                    ELSIF rec_seg_sel.segment_name = 'SEGMENT2' THEN
                        l_data_line := l_data_line
                                       || trnt_common_util.format_field(rec.segment2, rec_seg_sel.rm_leadzero, rec_seg_sel.rm_special_char)
                                       || chr(9);
                    ELSIF rec_seg_sel.segment_name = 'SEGMENT3' THEN
                        l_data_line := l_data_line
                                       || trnt_common_util.format_field(rec.segment3, rec_seg_sel.rm_leadzero, rec_seg_sel.rm_special_char)
                                       || chr(9);
                    ELSIF rec_seg_sel.segment_name = 'SEGMENT4' THEN
                        l_data_line := l_data_line
                                       || trnt_common_util.format_field(rec.segment4, rec_seg_sel.rm_leadzero, rec_seg_sel.rm_special_char)
                                       || chr(9);
                    ELSIF rec_seg_sel.segment_name = 'SEGMENT5' THEN
                        l_data_line := l_data_line
                                       || trnt_common_util.format_field(rec.segment5, rec_seg_sel.rm_leadzero, rec_seg_sel.rm_special_char)
                                       || chr(9);
                    ELSIF rec_seg_sel.segment_name = 'SEGMENT6' THEN
                        l_data_line := l_data_line
                                       || trnt_common_util.format_field(rec.segment6, rec_seg_sel.rm_leadzero, rec_seg_sel.rm_special_char)
                                       || chr(9);
                    ELSIF rec_seg_sel.segment_name = 'SEGMENT7' THEN
                        l_data_line := l_data_line
                                       || trnt_common_util.format_field(rec.segment7, rec_seg_sel.rm_leadzero, rec_seg_sel.rm_special_char)
                                       || chr(9);
                    ELSIF rec_seg_sel.segment_name = 'SEGMENT8' THEN
                        l_data_line := l_data_line
                                       || trnt_common_util.format_field(rec.segment8, rec_seg_sel.rm_leadzero, rec_seg_sel.rm_special_char)
                                       || chr(9);
                    ELSIF rec_seg_sel.segment_name = 'SEGMENT9' THEN
                        l_data_line := l_data_line
                                       || trnt_common_util.format_field(rec.segment9, rec_seg_sel.rm_leadzero, rec_seg_sel.rm_special_char)
                                       || chr(9);
                    ELSE
                        l_data_line := l_data_line
                                       || trnt_common_util.format_field(rec_seg_sel.segment_desc, 'N', 'N')
                                       || chr(9);     --Custom Field 
                    END IF;

                END LOOP;

                CLOSE c_seg_sel;
                IF rec_config.exclude_ledg_output = 'N' THEN
                    l_data_line := l_data_line
                                   || rec.ledger_id
                                   || chr(9);
                END IF;

                IF nvl(rec_config.rm_special_char_acc_desc, 'N') = 'N' THEN
                    l_data_line := l_data_line
                                   || rpad(trnt_common_util.format_field(apps.gl_flexfields_pkg.get_description_sql(rec.chart_of_accounts_id,
                                   rec.account_key, rec.account_no), 'N', 'N'), 50, ' ')
                                   || chr(9);
                ELSIF nvl(rec_config.rm_special_char_acc_desc, 'N') = 'Y' THEN
                    l_data_line := l_data_line
                                   || apps.gl_flexfields_pkg.get_description_sql(rec.chart_of_accounts_id, 3, rec.account_no)
                                   || chr(9);
                END IF;

                l_data_line := l_data_line
                               || ( l_period_year )
                               || chr(9)
                               || ( l_period_num )
                               || chr(9);

                IF nvl(rec_config.period_end_date, 'N') = 'Y' THEN
                    l_data_line := l_data_line
                                   || to_char(to_date(l_period_end_date), 'MM/DD/YYYY')
                                   || chr(9);
                END IF;

                l_data_line := l_data_line
                               || l_global_code
                               || chr(9)
                               || to_char(round(l_gbl_amount, 2), '99999999999999.00')
                               || chr(9)
                               || ( rec.local_curr_code )
                               || chr(9)
                               || to_char((rec.local_trans_amount), '99999999999999.00')
                               || chr(9)
                               || ( rec.trans_curr_code )
                               || chr(9)
                               || to_char((rec.sum_trans_amount), '99999999999999.00')
                               || chr(13);  

        /*Accounts Payable Extract API */

                SELECT
                    extract_type
                  INTO v_extract_type
                  FROM
                    trnt_config
                 WHERE
                    config_id = p_config_id;

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
                    utl_file.put_line(v_utlfile, l_data_line);
                END IF;

                IF l_output_type IN (
                    'R',
                    'X'
                ) THEN
                    fnd_file.put_line(fnd_file.output, l_data_line);
                END IF;

            END IF;

        END LOOP;
        --End of Setting the records for the extract -- 

        fnd_file.put_line(fnd_file.log, 'End of Setting the records for the extract ');
        IF l_output_type IN (
            'API'
        ) THEN
            BEGIN
                fnd_file.put_line(fnd_file.log, 'extracting the records for api');
                v_jdata := trnt_common_util.get_jsonformat_for_uac(txtfile_tab, 'CAD', 'APBALS', 'EBS_APPS', rec_config.config_code,
                                        rec_config.enable_encryption, p_config_id, rec_config.config_type, NULL, NULL);

            EXCEPTION
                WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.log, sqlerrm);
            END;

            DECLARE
                v_webdat VARCHAR2(4000);
            BEGIN
                fnd_file.put_line(fnd_file.log, 'uac call');
                v_webdat := trnt_common_util.trnt_uac_webservice(v_jdata, v_tableseq);
                fnd_file.put_line(fnd_file.log, 'Result from API Server :  ' || v_webdat);
            END;

        END IF;

        -- Writing the extract informations
        --json 

        IF l_output_type IN (
            'JSON'
        ) THEN
         fnd_file.put_line(fnd_file.log, 'extracting the records for json');
            BEGIN
                v_jdata := trnt_common_util.get_jsonformat_for_uac(txtfile_tab, 'CAD', 'APBALS', 'EBS_APPS', rec_config.config_code,
                                        rec_config.enable_encryption, p_config_id, rec_config.config_type, NULL, NULL);
            EXCEPTION
                WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.log, sqlerrm);
            END;   

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

        IF l_count = 0 THEN
            fnd_file.put_line(fnd_file.log, 'No Data To Extract and write into the file');
            return;
        END IF;

        utl_file.fclose(v_utlfile);
        IF l_output_type IN (
            'S'
        ) THEN
            fnd_file.put_line(fnd_file.output, 'Output option selected is server, Please find the file in server path ' || l_file_path);
        END IF;

        fnd_file.put_line(fnd_file.output, 'Number of records transferred to the data file: '
                                           || v_filename
                                           || ':'
                                           || l_count
                                           || chr(10));

        fnd_file.put_line(fnd_file.output, 'Submitted User Name: '
                                           || fnd_profile.value('USERNAME')
                                           || chr(10));

        fnd_file.put_line(fnd_file.output, 'Submitted Responsibility Name: '
                                           || fnd_profile.value('RESP_NAME')
                                           || chr(10));

        fnd_file.put_line(fnd_file.output, 'Submission Date: '
                                           || sysdate
                                           || chr(10));

        IF l_output_type IN (
            'S',
            'X'
        ) THEN
            fnd_file.put_line(fnd_file.output, 'File was succesfully written to: '
                                               || l_file_path
                                               || chr(10));
        END IF;

        fnd_file.put_line(fnd_file.log, 'APBAL' || 'END AP balance extract ');
    EXCEPTION
        WHEN utl_file.invalid_path THEN
            fnd_file.put_line(fnd_file.log, 'Invalid Output Path: '
                                            || sqlcode
                                            || '. '
                                            || sqlerrm
                                            || '. '
                                            || dbms_utility.format_error_backtrace);

            fnd_file.put_line(fnd_file.log, 'No OutPut File is Generated.');
            utl_file.fclose(v_utlfile);
            retcode := 1;
        WHEN utl_file.invalid_mode THEN
            fnd_file.put_line(fnd_file.log, 'Invalid Output Path: '
                                            || sqlcode
                                            || '. '
                                            || sqlerrm
                                            || '. '
                                            || dbms_utility.format_error_backtrace);

            fnd_file.put_line(fnd_file.log, 'No OutPut File is Generated.');
            utl_file.fclose(v_utlfile);
            retcode := 1;
        WHEN utl_file.invalid_filehandle THEN
            fnd_file.put_line(fnd_file.log, 'Invalid Output Path: '
                                            || sqlcode
                                            || '. '
                                            || sqlerrm
                                            || '. '
                                            || dbms_utility.format_error_backtrace);

            fnd_file.put_line(fnd_file.log, 'No OutPut File is Generated.');
            utl_file.fclose(v_utlfile);
            retcode := 1;
        WHEN utl_file.invalid_operation THEN
            fnd_file.put_line(fnd_file.log, 'invalid_operation'
                                            || 'Invalid Output Path: '
                                            || sqlcode
                                            || '. '
                                            || sqlerrm
                                            || '. '
                                            || dbms_utility.format_error_backtrace);

            fnd_file.put_line(fnd_file.log, 'No OutPut File is Generated.');
            utl_file.fclose(v_utlfile);
            retcode := 1;
        WHEN utl_file.write_error THEN
            fnd_file.put_line(fnd_file.log, 'Invalid Output Path: '
                                            || sqlcode
                                            || '. '
                                            || sqlerrm
                                            || '. '
                                            || dbms_utility.format_error_backtrace);

            fnd_file.put_line(fnd_file.log, 'No OutPut File is Generated.');
            utl_file.fclose(v_utlfile);
            retcode := 1;
        WHEN fiscal_year_exception THEN
            fnd_file.put_line(fnd_file.log, 'APBAL,'
                                            || 'ERROR,'
                                            || 'fiscal_year_exception Procedure TRNT_AP_BAL_EXTRACT');
            retcode := 1;
            return;
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Unexpected Error in Procedure TRNT_AP_BAL_EXTRACT'
                                            || ' - '
                                            || sqlerrm
                                            || dbms_utility.format_error_backtrace);

            utl_file.fclose(v_utlfile);
            retcode := 1;
            return;
    END trnt_ap_ext_file;

END trnt_xxx_ap_ext_pkg;
/
