DROP PACKAGE BODY APPS.TRNT_xxx_FA_EXT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.trnt_xxx_fa_ext_pkg AS
/* $Header: trnt_fa_ext_pkg.pkg, Version 1.0, 09-JAN-2020 $
***********************************************************************
* *
* History Log *
* *
***********************************************************************
* *
* App/Release : Oracle e-Business Suite 12.1.3 to 12.2.9*
* Module  : GENERAL LEDGER *
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
* 1.0      16-OCT-2020 Sanath       Remove GT Table As It Is Not Working  *
**********************************************************************/

    PROCEDURE trnt_fa_ext_file (
        errbuff      OUT  VARCHAR2,
        retcode      OUT  NUMBER,
        p_config_id  IN   NUMBER
    ) IS

        l_account_seg        VARCHAR2(100);
        l_header_line        VARCHAR2(2000);
        l_seg1               VARCHAR2(100);
        l_seg2               VARCHAR2(100);
        l_seg3               VARCHAR2(100);
        l_seg4               VARCHAR2(100);
        l_seg5               VARCHAR2(100);
        l_seg6               VARCHAR2(100);
        l_seg7               VARCHAR2(100);
        l_seg8               VARCHAR2(100);
        l_seg9               VARCHAR2(100);
        l_ledger_id          VARCHAR2(100);
        l_data_line          VARCHAR2(2000);
        l_period_name        VARCHAR2(100);
        l_period_num         VARCHAR2(100);
        v_tableseq           NUMBER;
        l_period_year        NUMBER;
        l_period_cutoff      VARCHAR2(100);
        l_file_path          VARCHAR2(100);
        l_output_type        VARCHAR2(100);
        local_curr_code      VARCHAR2(100);
        l_global_code        VARCHAR2(100);
        conver_rate_col      NUMBER;
        l_period_end_date    VARCHAR2(100);
        fiscal_year_exception EXCEPTION;
        hd_flag              NUMBER := 1;
        v_utlfile            utl_file.file_type;
        l_count              NUMBER := 0;
        l_gbl_amount         VARCHAR2(100);
        l_database_name      VARCHAR2(200);
        l_directory_name     VARCHAR2(200);
        v_filename           VARCHAR2(200);
        l_text_data          CLOB;
        v_jdata_file         CLOB;
        v_jdata              CLOB;
        l_asset_number_from  NUMBER;
        l_asset_number_to    NUMBER;
        l_asset_class_from   NUMBER;
        l_asset_class_to     NUMBER;
        i                    NUMBER := 0;
        txtfile_tab          trnt_common_util.txtfile_tab;
        indx                 NUMBER := 0;
        l_book_type_code     VARCHAR2(20);
        l_book_class         VARCHAR2(10);
        l_period_date        DATE;
        CURSOR cur_cad_fa_ext IS
        SELECT
            decode(l_seg1, 'Y', a.segment1, '')segment1,
            decode(l_seg2, 'Y', a.segment2, '') segment2,
            decode(l_seg3, 'Y', a.segment3, '') segment3,
            decode(l_seg4, 'Y', a.segment4, '')  segment4,
            decode(l_seg5, 'Y', a.segment5, '') segment5,
            decode(l_seg6, 'Y', a.segment6, '') segment6,
            decode(l_seg7, 'Y', a.segment7, '')  segment7,          
            decode(l_seg8, 'Y', a.segment8, '')  segment8,                                                                                
            decode(l_seg9, 'Y', a.segment9, '')  segment9,                                                                                    
            a.asset_id   asset_number,
            a.asset_cost_acct    asset_class,
            a.asset_cost_account_ccid   ccid,
            a.ledger_id,
            apps.gl_flexfields_pkg.get_description_sql(a.chart_of_accounts_id, a.account_key, a.account_no) account_desc,
            a.account_key,
            a.chart_of_accounts_id   coa,
            a.currency_code  local_curr_code,
            SUM(a.asset_cost)  sum_local_amount,
            a.currency_code   trans_curr_code,
            SUM(a.asset_cost) sum_trans_amount
          FROM
            (
                SELECT DISTINCT
                    gcck.segment1,
                    gcck.segment2,
                    gcck.segment3,
                    gcck.segment4,
                    gcck.segment5,
                    gcck.segment6,
                    gcck.segment7,
                    gcck.segment8,
                    gcck.segment9,
                    dh.asset_id,
                    cb.asset_cost_acct,
                    gll.ledger_id,
                    cb.asset_cost_account_ccid,
                    cbagcc.chart_of_accounts_id,
                    gll.currency_code,
                    cb.asset_cost_acct account_no,
                    decode(l_account_seg, 'SEGMENT1', 1, 'SEGMENT2', 2,
                           'SEGMENT3', 3, 'SEGMENT4', 4, 'SEGMENT5',
                           5) account_key,
                   -- nvl(fb.cost, 0)asset_cost
                   nvl(fb.original_cost,0) asset_cost
                  FROM
                    fa_distribution_history   dh,
                    fa_category_books         cb,
                    gl_code_combinations_kfv  gcck,
                    gl_code_combinations_kfv  cbagcc,
                    gl_code_combinations_kfv  cbdgcc,
                    fa_book_controls          bc,
                    fa_asset_history          ah,
                    fa_books                  fb,
                   -- fa_reserve_ledger_gt      gt,
                    gl_ledgers                gll
                 WHERE
                        1 = 1
                       AND ah.asset_id = dh.asset_id
                       AND ah.asset_id = fb.asset_id
                      -- AND ah.asset_id = gt.asset_id
                       AND fb.book_type_code=dh.book_type_code
                       AND bc.book_type_code = dh.book_type_code
                       AND cb.book_type_code = dh.book_type_code
                       AND dh.code_combination_id = gcck.code_combination_id
                       AND cb.asset_cost_account_ccid = cbagcc.code_combination_id
                       AND cb.reserve_account_ccid = cbdgcc.code_combination_id
                       AND fb.date_ineffective IS NULL
                       AND dh.date_ineffective IS NULL
                       AND ah.category_id = cb.category_id
                       AND dh.asset_id BETWEEN nvl(l_asset_number_from,dh.asset_id) AND nvl(l_asset_number_to,dh.asset_id)
                       AND cb.asset_cost_acct BETWEEN nvl(l_asset_class_from,cb.asset_cost_acct) AND nvl(l_asset_class_to,cb.asset_cost_acct)
                       AND bc.book_type_code = nvl(l_book_type_code,bc.book_type_code) --'OPS CORP'         
                       AND bc.book_class = nvl(l_book_class,bc.book_class) --'CORPORATE'
                       AND bc.set_of_books_id = gll.ledger_id
                       AND bc.set_of_books_id = l_ledger_id --'01'
                       AND fb.date_placed_in_service <= l_period_end_date --'31-Jan-2010'
                       AND gcck.concatenated_segments IN (
                        SELECT
                            concatenated_segments
                          FROM
                            trnt_config_segment_list
                         WHERE
                            config_id = p_config_id)
                     ) a
         GROUP BY
            decode(l_seg1, 'Y', a.segment1, ''),
            decode(l_seg2, 'Y', a.segment2, ''),
            decode(l_seg3, 'Y', a.segment3, ''),
            decode(l_seg4, 'Y', a.segment4, ''),
            decode(l_seg5, 'Y', a.segment5, ''),
            decode(l_seg6, 'Y', a.segment6, ''),
            decode(l_seg7, 'Y', a.segment7, ''),
            decode(l_seg8, 'Y', a.segment8, ''),
            decode(l_seg9, 'Y', a.segment9, ''),
            a.asset_id,
            a.asset_cost_acct,
            a.asset_cost_account_ccid,
            a.ledger_id,
            apps.gl_flexfields_pkg.get_description_sql(a.chart_of_accounts_id, a.account_key, a.account_no),
            a.account_key,
            a.chart_of_accounts_id,
            a.currency_code,
            a.currency_code;

        rec_fa_ext           cur_cad_fa_ext%rowtype;
        CURSOR c_seg_sel IS
        SELECT
            *
          FROM
            trnt_segment_selection
         WHERE
                config_id = p_config_id
               AND segment_disp = 'Y'
         ORDER BY
            segment_slno ASC;

        rec_seg_sel          c_seg_sel%rowtype;
        CURSOR c_config IS
        SELECT
            *
          FROM
            trnt_config
         WHERE
            config_id = p_config_id;

        rec_config           trnt_config%rowtype;
    BEGIN
        fnd_file.put_line(fnd_file.log, 'package_name:trnt_fa_ext_pkg  procedure_name:TRNT_FA_EXT_FILE');
        fnd_file.put_line(fnd_file.log, 'p_batch_id:'
                                        || fnd_global.conc_request_id
                                        || 'p_config_id:'
                                        || p_config_id);

        fnd_file.put_line(fnd_file.log, 'Starting of TRNT_FA_EXT_FILE');
        OPEN c_config;
        FETCH c_config INTO rec_config;
        CLOSE c_config;
        l_asset_number_from     := rec_config.assetnumber_from;
        l_asset_number_to       := rec_config.assetnumber_to;
        l_asset_class_from      := rec_config.assetclass_from;
        l_asset_class_to        := rec_config.assetclass_to;
        trnt_common_util.create_segments_filter(p_config_id);
        l_ledger_id             := rec_config.ledger;
        l_period_cutoff         := rec_config.extra_days_prior_cutoff;
        l_file_path             := rec_config.output_location;
        l_output_type           := rec_config.output_type;
        l_book_type_code        := rec_config.asset_book_type_code;
        l_book_class            := rec_config.asset_book_class;
        fnd_file.put_line(fnd_file.log, 'FA, ACCOUNT- ||Getting segment Details');
        l_account_seg           := trnt_common_util.get_segment('ACCOUNT', l_ledger_id, rec_config.chart_of_accounts_id, rec_config.config_type);
        fnd_file.put_line(fnd_file.log, 'FA,ACCOUNT-||Getting segment Details' || l_account_seg);
        fnd_file.put_line(fnd_file.log, 'Year and  period Selection');
        ---Year and  period Selection-----
              if rec_config.period_1 is not null then
        SELECT
            gp.period_name,
            gp.period_year,
            gp.period_num
          INTO
            l_period_name,
            l_period_year,
            l_period_num
          FROM
            gl_periods  gp,
            gl_ledgers  gll
         WHERE
                gll.period_set_name = gp.period_set_name
               AND gll.accounted_period_type = gp.period_type
               AND gll.ledger_id = l_ledger_id                            --01
               AND gp.period_name = rec_config.period_1 ;           --'Dec-07';
         end if;
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
                    
                      SELECT
            gp.period_name,
            gp.period_year,
            gp.period_num
          --gp.START_DATE,gp.END_DATE
          INTO
            l_period_name,
            l_period_year,
            l_period_num
          FROM
            gl_periods  gp,
            gl_ledgers  gll
         WHERE
                gll.period_set_name = gp.period_set_name
               AND gll.accounted_period_type = gp.period_type
               AND gll.ledger_id = l_ledger_id                            --01
               AND l_period_date between gp.START_DATE and gp.END_DATE;   
 fnd_file.put_line(fnd_file.log, 'l_period_name'||l_period_name);
            END IF;
            
           


            IF l_period_year IS NULL THEN
                l_period_year := trnt_common_util.get_period_year(l_period_name,l_ledger_id);
                IF l_period_year IS NULL THEN
                    fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                    || 'FA_YEAR_NOT_FOUND: '
                                                    || 'Period Year is not found for Period'
                                                    || l_period_name);

                    retcode := 1;
                    return;
                END IF;

            END IF;

            l_period_end_date := trnt_common_util.get_period_end_date(l_period_name, l_period_year, l_ledger_id);
            IF l_period_end_date IS NULL THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                || 'FA_PERIOD_END_DATE_NOT_FOUND: '
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
                                                || 'FA_PERIOD_DETAILS_NOT_FOUND: Please enter either Period year and period name or Cutoff Period'
                                                || dbms_utility.format_error_backtrace
                                                || sqlerrm);

                retcode := 1;
                return;
        END;
        ----Start Global Currency selection

        fnd_file.put_line(fnd_file.log, 'Start Global Currency selection');
        BEGIN
            l_global_code := trnt_common_util.get_global_code(l_ledger_id, p_config_id);
            IF l_global_code IS NULL THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                || 'FA_GLOBAL_CURRENCY_CODE_NOT_FOUND: '
                                                || 'Global Currency Code is not found'
                                                || l_ledger_id);

                retcode := 1;
                return;
            END IF;

            local_curr_code := trnt_common_util.get_local_code(l_ledger_id);
            IF local_curr_code IS NULL THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                || 'FA_LOCAL_CURRENCY_CODE_NOT_FOUND: '
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
                                                    || 'FA_CONVERSION_RATE_NOT_FOUND: '
                                                    || 'Conversion Rate is not found for '
                                                    || l_global_code
                                                    || ' and '
                                                    || l_period_end_date);

                    retcode := 1;
                    return;
                END IF;

            END IF;

            fnd_file.put_line(fnd_file.log, 'end of Global Currency selection');
            ----end of Global Currency selection

            --SERVER/Report and file path setting
            fnd_file.put_line(fnd_file.log, 'server/Report and file path setting');
            IF l_output_type IN (
                'S',
                'X'
            ) THEN
                IF l_file_path IS NULL THEN
                    retcode := 1;
                    fnd_file.put_line(fnd_file.log, 'Please enter the server file output path');
                END IF;

                    ----deriving db name for the filepath

                fnd_file.put_line(fnd_file.log, 'deriving db name for the filepath');
                l_directory_name := trnt_common_util.get_dir_name(l_file_path);
                IF l_directory_name IS NULL THEN
                    retcode := 1;
                    fnd_file.put_line(fnd_file.log, 'No Oracle Directory available for the file path');
                    return;
                END IF;

                l_database_name := trnt_common_util.get_db_name(l_file_path);
                l_directory_name := trnt_common_util.get_dir_name(l_file_path);
                v_filename := trnt_common_util.get_filename_out(rec_config.config_type, rec_config.config_code);
                fnd_file.put_line(fnd_file.log, 'Fixed Asset File path name : '
                                                || l_file_path
                                                || v_filename);
                IF l_count = 0 THEN
                    v_utlfile := utl_file.fopen(l_directory_name, v_filename, 'W');
                END IF;

            END IF;

            -- End of SERVER/Report and file path setting

            fnd_file.put_line(fnd_file.log, 'End of SERVER/Report and file path setting');
            fnd_file.put_line(fnd_file.log, 'Setting the header for the extract');
            ---Setting the header for the extract
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
                    l_seg6 := 'Y';
                ELSIF rec_seg_sel.segment_name = 'SEGMENT9' THEN
                    l_seg7 := 'Y';                     
                END IF;

                l_header_line := l_header_line
                                 || rec_seg_sel.segment_label
                                 || chr(9);
            END LOOP;

            CLOSE c_seg_sel;
            IF rec_config.asset_class_selection = 'Y' THEN
                l_header_line := l_header_line
                                 || 'assetclass'
                                 || chr(9);
            END IF;

            IF rec_config.asset_number_selection = 'Y' THEN
                l_header_line := l_header_line
                                 || 'assetnumber'
                                 || chr(9);
            END IF;

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

            ---Setting the records for the extract

            fnd_file.put_line(fnd_file.log, 'Setting the records for the extract');
            FOR rec IN cur_cad_fa_ext LOOP
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
                ---End of Setting the header for the extract

               -- IF
               --     rec.sum_local_amount <> 0 AND rec.sum_trans_amount <> 0
              --  THEN
                    l_count := l_count + 1;
                    BEGIN
                        l_gbl_amount := 0;
                        IF ( l_global_code <> local_curr_code ) THEN
                            l_gbl_amount := round((rec.sum_local_amount * conver_rate_col), 3);
                        ELSIF ( l_global_code = local_curr_code ) THEN
                            l_gbl_amount := rec.sum_local_amount;
                        END IF;

                    END;

                    --Creating record from Query

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
                        --Custom Field-------
                        END IF;

                    END LOOP;

                    CLOSE c_seg_sel;
                    IF rec_config.asset_class_selection = 'Y' THEN
                        l_data_line := l_data_line
                                       || trnt_common_util.format_field(rec.asset_class, rec_config.asset_class_rm_lead_zero, rec_config.
                                       assetclass_rm_spcl_char)
                                       || chr(9);
                    END IF;

                    IF rec_config.asset_number_selection = 'Y' THEN
                        l_data_line := l_data_line
                                       || trnt_common_util.format_field(rec.asset_number, rec_config.asset_number_rm_lead_zero, rec_config.
                                       assetnumber_rm_spcl_char)
                                       || chr(9);                    
                    END IF;

                    IF rec_config.exclude_ledg_output = 'N' THEN
                        l_data_line := l_data_line
                                       || rec.ledger_id
                                       || chr(9);
                    END IF;

                    l_data_line := l_data_line
                                   || rpad(trnt_common_util.format_field(rec.account_desc, 'N', 'Y'), 50, ' ')
                                   || chr(9)
                                   || l_period_year                   
                                   || chr(9)
                                   || l_period_num
                                   || chr(9);

                    IF nvl(rec_config.period_end_date, 'N') = 'Y' THEN
                        l_data_line := l_data_line
                                       || to_char(to_date(l_period_end_date), 'MM/DD/YYYY')
                                       || chr(9);
                    END IF;

                    l_data_line := l_data_line
                                   || l_global_code
                                   || chr(9)
                                   ||   to_char(round(l_gbl_amount, 5), '9999999999.00')
                                   || chr(9)
                                   || ( rec.local_curr_code )
                                   || chr(9)
                                   || to_char(round(rec.sum_local_amount, 5), '9999999999.00')
                                   || chr(9)
                                   || ( rec.trans_curr_code )
                                   || chr(9)
                                   || to_char(round(rec.sum_trans_amount, 5), '9999999999.00')
                                   || chr(13);

                    /*FA Extract API */

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

               -- END IF;

            END LOOP;

            IF l_output_type IN (
                'API'
            ) THEN
                BEGIN
                    fnd_file.put_line(fnd_file.log, 'extraction for api');
                    v_jdata := trnt_common_util.get_jsonformat_for_uac(txtfile_tab, 'CAD', 'FA', 'EBS_APPS', rec_config.config_code,
                                        rec_config.enable_encryption, p_config_id, rec_config.config_type, rec_config.bid_enable_flag,
                                        NULL);

                EXCEPTION
                    WHEN OTHERS THEN
                        fnd_file.put_line(fnd_file.log, sqlerrm || 'jsonexception');
                END;

                fnd_file.put_line(fnd_file.log, 'uac call');
                DECLARE
                    v_webdat VARCHAR2(4000);
                BEGIN
                    v_webdat := trnt_common_util.trnt_uac_webservice(v_jdata, v_tableseq);
                    fnd_file.put_line(fnd_file.log, 'Result from API Server :  ' || v_webdat);
                END;

            END IF;

         ---json--

            IF l_output_type IN (
                'JSON'
            ) THEN
            fnd_file.put_line(fnd_file.log, 'extraction for json');
                BEGIN
                    l_text_data := l_text_data || l_data_line;
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

                l_database_name     := trnt_common_util.get_db_name(l_file_path);
                l_directory_name    := trnt_common_util.get_dir_name(l_file_path);
                v_filename          := trnt_common_util.get_filename_out(rec_config.config_type, rec_config.config_code);

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

            fnd_file.put_line(fnd_file.log, 'END FA extract ');
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

                fnd_file.put_line(fnd_file.log, 'write_error-Invalid Output Path: '
                                                || sqlcode
                                                || '. '
                                                || sqlerrm
                                                || '. '
                                                || dbms_utility.format_error_backtrace);

                fnd_file.put_line(fnd_file.log, 'No OutPut File is Generated.');
                utl_file.fclose(v_utlfile);
                retcode := 1;
            WHEN fiscal_year_exception THEN
                fnd_file.put_line(fnd_file.log, 'ERROR-fiscal_year_exception Procedure TRNT_FA_EXTRACT');
                retcode := 1;
                return;
            WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log, 'Unexpected Error in Procedure TRNT_FA_EXTRACT'
                                                || ' - '
                                                || sqlerrm
                                                || dbms_utility.format_error_backtrace);

                fnd_file.put_line(fnd_file.log, 'ERROR - Unexpected Error in Procedure TRNT_FA_EXTRACT');
                utl_file.fclose(v_utlfile);
                retcode := 1;
                return;
        END;

    END trnt_fa_ext_file;

END trnt_xxx_fa_ext_pkg;
/
