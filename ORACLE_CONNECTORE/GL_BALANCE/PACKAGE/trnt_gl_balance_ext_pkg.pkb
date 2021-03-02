DROP PACKAGE BODY APPS.TRNT_XXX_GL_BALANCE_EXT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.trnt_XXX_gl_balance_ext_pkg AS
/* $Header: trnt_gl_balance_ext_pkg.pkg, Version 1.0, 09-JAN-2020 $
***********************************************************************
* *
* History Log *
* *
***********************************************************************
* *
* App/Release : Oracle e-Business Suite 12.1.3 to 12.2.9*
* Module  : GENERAL LEDGER BALANCE*
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
* 1.1      13-OCT-2020 Sanath       Modified the main query *
* 1.2      14-OCT-2020 Sanath       Query fixed*

**********************************************************************/

    PROCEDURE trnt_gl_balance_ext_file (
        errbuff      OUT  VARCHAR2,
        retcode      OUT  NUMBER,
        p_config_id  IN   NUMBER
    ) IS

        l_period_end_date     VARCHAR2(20);
        l_period_name         VARCHAR2(20);
        l_count               NUMBER := 0;
        l_global_code         VARCHAR2(20);
        conver_rate_col       NUMBER := 0;
        l_gbl_amount          NUMBER;
        local_curr_code       VARCHAR2(10);
        l_trans_amount        NUMBER;
        l_local_amount        NUMBER;
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
        l_output_type         VARCHAR2(10);
        hd_flag               NUMBER := 1;
        l_text_data           CLOB;

        /*Declaration of variables for GL Balance Extract API*/
        v_extract_type        VARCHAR2(10);
        v_accountdesc         CLOB;
        v_period_end_date     CLOB;
        v_period_year         CLOB;
        v_period_num          CLOB;
        v_global_code         CLOB;
        v_global_amount       CLOB;
        v_local_curr_code     CLOB;
        v_local_trans_amount  CLOB;
        v_trans_curr_code     CLOB;
        v_sum_trans_amount    CLOB;
        gbl_amt               NUMBER(12, 2);
        trans_amt             NUMBER(12, 2);
        lcl_amt               NUMBER(12, 2);
        v_jdata_file          CLOB;
        v_jdata               CLOB;
        v_tableseq            NUMBER;
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
        l_trans_count         NUMBER;
        v_config_code         VARCHAR(100);
        len_v_jdata           NUMBER;
        txtfile_tab           trnt_common_util.txtfile_tab;
        indx                  NUMBER := 0;
        l_period_date         DATE;
        l_period_num          NUMBER;
        CURSOR cur_cad_gl_bal_ext IS
        SELECT
            decode(l_seg1, 'Y', nn.segment1, '')                                                                                  segment1,
            decode(l_seg2, 'Y', nn.segment2, '')                                                                                  segment2,
            decode(l_seg3, 'Y', nn.segment3, '')                                                                                  segment3,
            decode(l_seg4, 'Y', nn.segment4, '')                                                                                  segment4,
            decode(l_seg5, 'Y', nn.segment5, '')                                                                                  segment5,
            decode(l_seg6, 'Y', nn.segment6, '')                                                                                  segment6,
            decode(l_seg7, 'Y', nn.segment7, '')                                                                                  segment7,
            decode(l_seg8, 'Y', nn.segment8, '')                                                                                  segment8,
            decode(l_seg9, 'Y', nn.segment9, '')                                                                                  segment9,
            apps.gl_flexfields_pkg.get_description_sql(nn.chart_of_accounts_id, nn.account_key, nn.account_no)                    account_desc,
            nn.chart_of_accounts_id,
            nn.ledger_id,
            nn.ledger_name,
            nn.period_year,
            nn.period_name,
            local_curr_code,
            trans_curr_code,
            nn.global_curr_code,
            SUM(nn.sum_local_amount)                                                                                              sum_local_amount,
            decode(nn.local_curr_code, nn.trans_curr_code, SUM(nn.sum_trans_amount), SUM(sum_trans_amount_fk))                    sum_trans_amount,
            nn.global_conversion_rate
          FROM
            (
                SELECT
                    glc.segment1, --company,
                    glc.segment2, -- branch,
                    glc.segment3, -- account,
                    glc.segment4, -- cost_center,
                    glc.segment5,
                    glc.segment6,
                    glc.segment7,
                    glc.segment8,
                    glc.segment9,
                    decode(l_account_seg, 'SEGMENT1', glc.segment1, 'SEGMENT2', glc.segment2,
                           'SEGMENT3', glc.segment3, 'SEGMENT4', glc.segment4, 'SEGMENT5',
                           glc.segment5, '') account_no,
                    decode(l_account_seg, 'SEGMENT1', 1, 'SEGMENT2', 2,
                           'SEGMENT3', 3, 'SEGMENT4', 4, 'SEGMENT5',
                           5, '') account_key,
                    glcc.code_combination_id,
                    glcc.chart_of_accounts_id,
                    gb.ledger_id,
                    gll.name                                                                                                                       ledger_name,
                    gb.period_year,
                    lpad(gb.period_num, 2, '0')                                                                                                    period_name,
                    gll.currency_code                                                                                                              local_curr_code,
                    l_global_code                                                                                                                  global_curr_code,
                    gb.currency_code                                                                                                               trans_curr_code,
                    conver_rate_col                                                                                                                global_conversion_rate,
                    NULL                                                                                                                           sum_global_amount,
                    SUM((round(((gb.begin_balance_dr_beq + gb.period_net_dr_beq) -(gb.begin_balance_cr_beq + gb.period_net_cr_beq)),
                    8))) sum_local_amount,
                    SUM((round(((gb.begin_balance_dr_beq + gb.period_net_dr_beq) -(gb.begin_balance_cr_beq + gb.period_net_cr_beq)),
                    8))) sum_trans_amount,
                    SUM((round(((gb.begin_balance_dr + gb.period_net_dr) -(gb.begin_balance_cr + gb.period_net_cr)), 8)))                          sum_trans_amount_fk
                  FROM
                    gl_code_combinations      glcc,
                    gl_code_combinations_kfv  glc,
                    gl_ledgers                gll,
                    gl_balances               gb

                 WHERE
                        gb.ledger_id = l_ledger_id
                       AND gb.period_year = l_period_year
                       AND gb.period_name = nvl(l_period_name, gb.period_name)
                       AND gb.actual_flag = 'A'
                       AND gb.ledger_id = gll.ledger_id
                       AND gb.code_combination_id = glcc.code_combination_id
                       AND gb.code_combination_id = glc.code_combination_id
                       AND glcc.chart_of_accounts_id = gll.chart_of_accounts_id
                       AND glcc.chart_of_accounts_id = glc.chart_of_accounts_id
                      -- AND glcc.segment1 = v.flex_value
                       AND glcc.account_type IN (
                        'A',
                        'L',
                        'O',
                        'R',
                        'E'
                    )
                       AND glcc.enabled_flag = 'Y'                    
                       AND concatenated_segments IN (
                        SELECT
                            concatenated_segments
                          FROM
                            trnt_config_segment_list
                         WHERE
                            config_id = p_config_id
                    )
                 GROUP BY
                    glc.segment1,
                    glc.segment2,
                    glc.segment3,
                    glc.segment4,
                    glc.segment5,
                    glc.segment6,
                    glc.segment7,
                    glc.segment8,
                    glc.segment9,
                    glcc.code_combination_id,
                    glcc.chart_of_accounts_id,
                    gb.ledger_id,
                    gll.name,
                    gb.period_year,
                    gb.period_num,
                    gll.currency_code,
                    gb.currency_code

            ) nn
         GROUP BY
            decode(l_seg1, 'Y', nn.segment1, ''),
            decode(l_seg2, 'Y', nn.segment2, ''),
            decode(l_seg3, 'Y', nn.segment3, ''),
            decode(l_seg4, 'Y', nn.segment4, ''),
            decode(l_seg5, 'Y', nn.segment5, ''),
            decode(l_seg6, 'Y', nn.segment6, ''),
            decode(l_seg7, 'Y', nn.segment7, ''),
            decode(l_seg8, 'Y', nn.segment8, ''),
            decode(l_seg9, 'Y', nn.segment9, ''),
            apps.gl_flexfields_pkg.get_description_sql(nn.chart_of_accounts_id, nn.account_key, nn.account_no),
            global_curr_code,
            global_conversion_rate,
            nn.local_curr_code,
            nn.trans_curr_code,
            nn.ledger_id,
            nn.ledger_name,
            nn.period_year,
            nn.period_name,
            nn.chart_of_accounts_id

         ORDER BY
            1;

        CURSOR c_config IS
        SELECT * FROM trnt_config
         WHERE  config_id = p_config_id;

        rec_config            trnt_config%rowtype;

        CURSOR c_seg_sel IS
        SELECT  *  FROM trnt_segment_selection
         WHERE config_id = p_config_id AND segment_disp = 'Y'
         ORDER BY segment_slno ASC;

        rec_seg_sel           c_seg_sel%rowtype;
    BEGIN
        fnd_file.put_line(fnd_file.log, 'package_name:trnt_gl_balance_ext_pkg, procedure_name:trnt_gl_balance_ext_file_new');
        fnd_file.put_line(fnd_file.log, 'p_batch_id:'
                                        || fnd_global.conc_request_id
                                        || 'p_config_id:'
                                        || p_config_id);

        fnd_file.put_line(fnd_file.log, 'GLBAL , Start GL balance extract ');
        OPEN c_config;
        FETCH c_config INTO rec_config;
        CLOSE c_config;

        trnt_common_util.create_segments_filter(p_config_id);
        l_ledger_id := rec_config.ledger;
        l_period_name := rec_config.period_1;
        l_period_year := rec_config.fiscal_year;
        l_period_cutoff := rec_config.extra_days_prior_cutoff;
        l_file_path := rec_config.output_location;
        l_output_type := rec_config.output_type;
        fnd_file.put_line(fnd_file.log, 'GLBAL, ACCOUNT- ||Getting segment Details');
        l_account_seg := trnt_common_util.get_segment('ACCOUNT', l_ledger_id, rec_config.chart_of_accounts_id, rec_config.config_type);

        fnd_file.put_line(fnd_file.log, 'GLBAL, ACCOUNT-||Getting segment Details' || l_account_seg);
        fnd_file.put_line(fnd_file.log, 'Year and  period Selection');
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
                    trunc(sysdate - l_period_cutoff)
                  INTO l_period_date
                  FROM
                    dual;

                SELECT gp.period_name, gp.period_year, gp.period_num
                  INTO l_period_name, l_period_year, l_period_num
                  FROM gl_periods gp, gl_ledgers gll
                 WHERE     gll.period_set_name = gp.period_set_name
                       AND gll.accounted_period_type = gp.period_type
                       AND gll.ledger_id = l_ledger_id                                    --01
                       AND l_period_date BETWEEN gp.START_DATE AND gp.END_DATE;

            END IF;

            IF l_period_year IS NULL THEN
                l_period_year := trnt_common_util.get_period_year(l_period_name, l_ledger_id);
                IF l_period_year IS NULL THEN
                    fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                    || 'GLBALS_YEAR_NOT_FOUND: '
                                                    || 'Period Year is not found for Period'
                                                    || l_period_name);

                    retcode := 1;
                    return;
                END IF;

            END IF;

            l_period_end_date := trnt_common_util.get_period_end_date(l_period_name, l_period_year, l_ledger_id);
            IF l_period_end_date IS NULL THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                || 'GLBALS_PERIOD_END_DATE_NOT_FOUND: '
                                                || 'Period End Date is not found for '
                                                || l_period_name
                                                || ' and '
                                                || l_period_year);

                retcode := 1;
                return;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log, 'Error Code:'
                                                || 'GLBALS_PERIOD_DETAILS_NOT_FOUND: Please enter either Period year and period name or Cutoff Period'
                                                || dbms_utility.format_error_backtrace
                                                || sqlerrm);

                retcode := 1;
                return;
        END;

        /*Start Global Currency selection*/

        fnd_file.put_line(fnd_file.log, 'Start Global Currency selection');
        BEGIN
            l_global_code := trnt_common_util.get_global_code(l_ledger_id, p_config_id);
            IF l_global_code IS NULL THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                || 'GLBALS_GLOBAL_CURRENCY_CODE_NOT_FOUND: '
                                                || 'Global Currency Code is not found'
                                                || l_ledger_id);

                retcode := 1;
                return;
            END IF;

            local_curr_code := trnt_common_util.get_local_code(l_ledger_id);
            IF local_curr_code IS NULL THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                || 'GLBALS_LOCAL_CURRENCY_CODE_NOT_FOUND: '
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
                                                    || 'GLBALS_CONVERSION_RATE_NOT_FOUND: '
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
        IF l_output_type IN (
            'S',
            'X'
        ) THEN
                fnd_file.put_line(fnd_file.log, 'SERVER/Report and file path setting');
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

            l_database_name := trnt_common_util.get_db_name(l_file_path);
            l_directory_name := trnt_common_util.get_dir_name(l_file_path);
            v_filename := trnt_common_util.get_filename_out(rec_config.config_type, rec_config.config_code);
            fnd_file.put_line(fnd_file.log, 'Glbalance extractor File path name : '
                                            || l_file_path||'/'
                                            || v_filename);
            IF l_count = 0 THEN
                v_utlfile := utl_file.fopen(l_directory_name, v_filename, 'W');
            END IF;

        END IF;

        fnd_file.put_line(fnd_file.log, 'End of SERVER/Report and file path setting');
       -- End of SERVER/Report and file path setting

           /*Setting the header for the extract*/
        fnd_file.put_line(fnd_file.log, 'Setting the header for the extract');
        l_header_line := NULL;
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
        -----------------------------------
        ----------------------------------

         /*Setting the records for the extract*/

        fnd_file.put_line(fnd_file.log, 'setting the header based on the extract type');
        FOR rec IN cur_cad_gl_bal_ext LOOP

         /*Extracting header*/
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
        --End of Setting the header for the extract--
        ---Query for getting the transaction count---   

           -- IF
           --     rec.sum_local_amount <> 0 AND rec.sum_trans_amount <> 0
           -- THEN
                l_count := l_count + 1;
                BEGIN
                    l_gbl_amount := 0;
                    IF ( l_global_code <> local_curr_code ) THEN
                        l_gbl_amount := round((rec.sum_local_amount * conver_rate_col), 3);
                    ELSIF ( l_global_code = local_curr_code ) THEN
                        l_gbl_amount := rec.sum_local_amount;
                    END IF;

                END;

       /*Creating record from Query*/

                l_data_line := NULL;
                OPEN c_seg_sel;
                LOOP
                    FETCH c_seg_sel INTO rec_seg_sel;
                    EXIT WHEN c_seg_sel%notfound;
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
                                   || rpad(trnt_common_util.format_field(rec.account_desc, 'N', 'N'), 50, ' ')
                                   || chr(9);
                END IF;

                IF nvl(rec_config.rm_special_char_acc_desc, 'N') = 'Y' THEN
                    l_data_line := l_data_line
                                   || rpad(trnt_common_util.format_field(rec.account_desc, 'N', 'Y'), 50, ' ')
                                   || chr(9);
                END IF;

                l_data_line := l_data_line
                               || ( rec.period_year )
                               || chr(9)
                               || ( rec.period_name )
                               || chr(9);

                IF nvl(rec_config.period_end_date, 'N') = 'Y' THEN
                    l_data_line := l_data_line
                                   || to_char(to_date(l_period_end_date), 'MM/DD/YYYY')
                                   || chr(9);
                END IF;

                l_data_line := l_data_line
                               || l_global_code
                               || chr(9)
                               || to_char(l_gbl_amount, '99999999999999.00')
                               || chr(9)
                               || ( rec.local_curr_code )
                               || chr(9)
                               || to_char((rec.sum_local_amount), '99999999999999.00')
                               || chr(9)
                               || ( rec.trans_curr_code )
                               || chr(9)
                               || to_char((rec.sum_trans_amount), '99999999999999.00')
                               || chr(13);  
        /*GL Balance Extract API */

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

          --  END IF;

        END LOOP;

        IF l_output_type IN (
            'API'
        ) THEN
            fnd_file.put_line(fnd_file.log, 'extraction for api');
            BEGIN
                v_jdata := trnt_common_util.get_jsonformat_for_uac(txtfile_tab, 'CAD', 'GLBALS', 'EBS_APPS', rec_config.config_code,
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

        IF l_output_type IN (
            'JSON'
        ) THEN
         fnd_file.put_line(fnd_file.log, 'extraction for json');
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

         /*Writing the extract informations*/

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

        fnd_file.put_line(fnd_file.log, 'GLBAL, END GL balance extract ');
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
            fnd_file.put_line(fnd_file.log, 'Invalid Output Path: '
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
            fnd_file.put_line(fnd_file.log, 'GLBAL: ERROR, fiscal_year_exception Procedure TRNT_GL_BAL_EXTRACT');
            retcode := 1;
            return;
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Unexpected Error in Procedure TRNT_GL_BAL_EXTRACT'
                                            || ' - '
                                            || sqlerrm
                                            || dbms_utility.format_error_backtrace);

            utl_file.fclose(v_utlfile);
            retcode := 1;
            return;
    END trnt_gl_balance_ext_file;

END trnt_XXX_gl_balance_ext_pkg;
/
