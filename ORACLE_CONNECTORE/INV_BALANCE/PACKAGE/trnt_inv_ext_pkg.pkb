DROP PACKAGE BODY APPS.TRNT_xxx_INV_EXT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.trnt_xxx_inv_ext_pkg AS
/* $Header: trnt_inv_ext_pkg.pkg, Version 1.0, 09-JAN-2020 $
***********************************************************************
* *
* History Log *
* *
***********************************************************************
* *
* App/Release : Oracle e-Business Suite 12.1.3 to 12.2.9*
* Module  : INVENTORY BALANCE *
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
* 1.0      19-oct-2020 Aswini       ORG_ID  *
**********************************************************************/

    PROCEDURE trnt_inv_ext_file (
        errbuff      OUT  VARCHAR2,
        retcode      OUT  NUMBER,
        p_config_id  IN   NUMBER
    ) IS

        l_account_seg             VARCHAR2(100);
        l_header_line             VARCHAR2(2000);
        l_seg1                    VARCHAR2(100);
        l_seg2                    VARCHAR2(100);
        l_seg3                    VARCHAR2(100);
        l_seg4                    VARCHAR2(100);
        l_seg5                    VARCHAR2(100);
        l_seg6                    VARCHAR2(100);
        l_seg7                    VARCHAR2(100);
        l_seg8                    VARCHAR2(100);
        l_seg9                    VARCHAR2(100);
        l_ledger_id               VARCHAR2(100);
        l_data_line               VARCHAR2(2000);
        l_period_name             VARCHAR2(100);
        l_period_num              VARCHAR2(100);
        v_tableseq                NUMBER;
        l_period_year             NUMBER;
        l_period_cutoff           VARCHAR2(100);
        l_file_path               VARCHAR2(100);
        l_output_type             VARCHAR2(100);
        local_curr_code           VARCHAR2(100);
        l_global_code             VARCHAR2(100);
        conver_rate_col           NUMBER;
        l_period_end_date         VARCHAR2(100);
        fiscal_year_exception EXCEPTION;
        hd_flag                   NUMBER := 1;
        v_utlfile                 utl_file.file_type;
        l_count                   NUMBER := 0;
        l_gbl_amount              VARCHAR2(100);
        l_database_name           VARCHAR2(200);
        l_directory_name          VARCHAR2(200);
        v_filename                VARCHAR2(200);
        l_text_data               CLOB;
        v_jdata_file              CLOB;
        v_jdata                   CLOB;
        i                         NUMBER := 0;
        txtfile_tab               trnt_common_util.txtfile_tab;
        indx                      NUMBER := 0;
        l_invvaluationclass_from  NUMBER;
        l_invvaluationclass_to    NUMBER;
        l_invmaterial_from        NUMBER;
        l_invmaterial_to          NUMBER;
        l_invplant_from           NUMBER;
        l_invplant_to             NUMBER;
        l_cost_type               VARCHAR2(30);
        l_organization_id         NUMBER;
        l_organization_id_to         NUMBER;
        l_inv_category_set_id     NUMBER;
        l_period_date  date;

        CURSOR cur_cad_inv_ext IS
        SELECT
            nn.segment1,
            nn.segment2,
            nn.segment3,
            nn.segment4,
            nn.segment5,
            nn.segment6,
            nn.segment7,
            nn.segment8,
            nn.segment9,
            nn.category_set_id,
            nn.cost_type,
            nn.inventory_item_id,
      -- null INVENTORY_LOCATION_ID, 
            nn.ledger_id,
            nn.account_no,
            nn.account_key,
            nn.coa,
            apps.gl_flexfields_pkg.get_description_sql(nn.coa, nn.account_key, nn.account_no)                 account_desc,
            nn.currency_code                                                                                  local_curr_code,
            total_cost                                                                                        sum_local_amount,
            nn.currency_code                                                                                  trans_curr_code,
            total_cost                                                                                        sum_trans_amount,
            nn.item_desc,
          nn.organization_code,
           nn.organization_id,
            nn.ORGANIZATION_NAME     
          FROM
            (
                SELECT
                 decode(l_seg1, 'Y', gcck.segment1, '')                              segment1,
                 decode(l_seg2, 'Y', gcck.segment2, '')                              segment2,
                 decode(l_seg3, 'Y', gcck.segment3, '')                              segment3,
                 decode(l_seg4, 'Y', gcck.segment4, '')                              segment4,
                 decode(l_seg5, 'Y', gcck.segment5, '')                              segment5,
                 decode(l_seg6, 'Y', gcck.segment6, '')                              segment6,
                 decode(l_seg7, 'Y', gcck.segment7, '')                              segment7,
                 decode(l_seg8, 'Y', gcck.segment8, '')                              segment8,
                 decode(l_seg9, 'Y', gcck.segment9, '')                              segment9,
                    decode(l_account_seg, 'SEGMENT1', gcck.segment1, 'SEGMENT2', gcck.segment2,
                           'SEGMENT3', gcck.segment3, 'SEGMENT4', gcck.segment4, 'SEGMENT5',
                           gcck.segment5, '') account_no,
                    decode(l_account_seg, 'SEGMENT1', 1, 'SEGMENT2', 2,
                           'SEGMENT3', 3, 'SEGMENT4', 4, 'SEGMENT5',
                           5) account_key,
                    gcck.concatenated_segments                                                 segments,
                    gcck.code_combination_id                                                   ccid,
                    gl.ledger_id,
                    msib.inventory_item_id,
                    msib.description  item_desc,
                    mic.category_set_id,
                    cct.cost_type,
                    SUM(moqd.primary_transaction_quantity),
                    gcck.chart_of_accounts_id                                                  coa,
                    cic.item_cost,
                    SUM(moqd.primary_transaction_quantity * nvl(cic.item_cost, 0))             total_cost,
                       gl.currency_code,
                    ood.organization_code,
                    ood.organization_id,
                     ood.ORGANIZATION_NAME
                 
                  FROM
                    org_organization_definitions  ood,
                    gl_code_combinations_kfv      gcck,
                    cst_cost_types                cct,
                    mtl_system_items_b            msib,
                    mtl_onhand_quantities_detail  moqd,
                    cst_item_costs                cic,
                    mtl_secondary_inventories     msub,
                    mtl_item_categories           mic,
                    gl_ledgers                    gl
                 WHERE
                        1 = 1
                       AND gl.ledger_id = ood.set_of_books_id
                    -- AND cct.cost_type_id = p_cost_type_id
                       AND ood.organization_id = msib.organization_id
                       AND ood.organization_id = moqd.organization_id
                       AND ood.organization_id = cic.organization_id
                       AND mic.organization_id = cic.organization_id
                       AND cct.cost_type_id = cic.cost_type_id
                       AND msib.inventory_item_id = moqd.inventory_item_id
                       AND mic.inventory_item_id = moqd.inventory_item_id
                       AND msib.inventory_item_id = cic.inventory_item_id
                       AND moqd.organization_id = msub.organization_id
                       AND moqd.subinventory_code = msub.secondary_inventory_name
                       AND msub.material_account = gcck.code_combination_id
                       AND ood.organization_id BETWEEN l_organization_id and l_organization_id_to
                       AND msib.inventory_item_id BETWEEN nvl(l_invmaterial_from,msib.inventory_item_id) AND nvl (l_invmaterial_to,msib.inventory_item_id)
                       AND mic.category_set_id = nvl(l_inv_category_set_id,mic.category_set_id)
                       AND gl.ledger_id = l_ledger_id
                       and moqd.Date_received<=l_period_end_date --Prin
                       AND cct.cost_type = nvl(l_cost_type ,cct.cost_type)
                       AND gcck.concatenated_segments IN (
                            SELECT
                                concatenated_segments
                              FROM
                                trnt_config_segment_list
                             WHERE
                                config_id = p_config_id
                        ) 
                 GROUP BY
                    gcck.segment1,
                    gcck.concatenated_segments,
                    gcck.code_combination_id,
                    gcck.chart_of_accounts_id,
                    gl.ledger_id,
                    msib.inventory_item_id,
                    decode(l_account_seg, 'SEGMENT1', gcck.segment1, 'SEGMENT2', gcck.segment2,
                           'SEGMENT3', gcck.segment3, 'SEGMENT4', gcck.segment4, 'SEGMENT5',
                           gcck.segment5, ''),
                    decode(l_account_seg, 'SEGMENT1', 1, 'SEGMENT2', 2,
                           'SEGMENT3', 3, 'SEGMENT4', 4, 'SEGMENT5',
                           5),
                    cic.item_cost,
                    gl.currency_code,
                    mic.category_set_id,
                    msib.description,
                    cct.cost_type,
                    ood.organization_code,
                    ood.organization_id,
                    ood.ORGANIZATION_NAME,
                 decode(l_seg1, 'Y', gcck.segment1, ''),
                 decode(l_seg2, 'Y', gcck.segment2, ''),
                 decode(l_seg3, 'Y', gcck.segment3, ''),
                 decode(l_seg4, 'Y', gcck.segment4, ''),
                 decode(l_seg5, 'Y', gcck.segment5, ''),
                 decode(l_seg6, 'Y', gcck.segment6, ''),
                 decode(l_seg7, 'Y', gcck.segment7, ''),
                 decode(l_seg8, 'Y', gcck.segment8, ''),
                 decode(l_seg9, 'Y', gcck.segment9, '')
            ) nn;

        rec_inv_ext               cur_cad_inv_ext%rowtype;

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

        rec_seg_sel               c_seg_sel%rowtype;
        CURSOR c_config IS
        SELECT
            *
          FROM
            trnt_config
         WHERE
            config_id = p_config_id;

        rec_config                trnt_config%rowtype;
    BEGIN
        fnd_file.put_line(fnd_file.log, 'package_name:trnt_dev_inv_ext_pkg  procedure_name:TRNT_INV_EXT_FILE');
        fnd_file.put_line(fnd_file.log, 'p_batch_id:'
                                        || fnd_global.conc_request_id
                                        || 'p_config_id:'
                                        || p_config_id);

        fnd_file.put_line(fnd_file.log, 'Starting of TRNT_dev_INV_EXT_FILE');
        OPEN c_config;
        FETCH c_config INTO rec_config;
        CLOSE c_config;
        l_invmaterial_from := rec_config.invmaterial_from;
        l_invmaterial_to := rec_config.invmaterial_to;
        trnt_common_util.create_segments_filter(p_config_id);
        l_ledger_id := rec_config.ledger;
        l_period_cutoff := rec_config.extra_days_prior_cutoff;
        l_file_path := rec_config.output_location;
        l_output_type := rec_config.output_type;
        l_cost_type := rec_config.inv_cost_type;
        l_organization_id := rec_config.inv_organization_id;
         l_organization_id_to := rec_config.inv_organization_id_to;
        l_inv_category_set_id := rec_config.inv_category_set_id;
        fnd_file.put_line(fnd_file.log, 'INV, ACCOUNT- ||Getting segment Details');
        l_account_seg := trnt_common_util.get_segment('ACCOUNT', l_ledger_id, rec_config.chart_of_accounts_id, '');
        fnd_file.put_line(fnd_file.log, 'INV,ACCOUNT-||Getting segment Details' || l_account_seg);
        fnd_file.put_line(fnd_file.log, 'Year and  period Selection');

        ---Year and  period Selection
        if rec_config.period_1 is not null then
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
               AND gp.period_name = rec_config.period_1;           --'Dec-07';
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
                    (sysdate - l_period_cutoff)
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

            END IF;
            
           

            IF l_period_year IS NULL THEN
                l_period_year := trnt_common_util.get_period_year(l_period_name, l_ledger_id);
                IF l_period_year IS NULL THEN
                    fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                    || 'INV_YEAR_NOT_FOUND: '
                                                    || 'Period Year is not found for Period'
                                                    || l_period_name);

                    retcode := 1;
                    return;
                END IF;

            END IF;

            l_period_end_date := trnt_common_util.get_period_end_date(l_period_name, l_period_year, l_ledger_id);
            IF l_period_end_date IS NULL THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                || 'INV_PERIOD_END_DATE_NOT_FOUND: '
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
                                                || 'INV_PERIOD_DETAILS_NOT_FOUND: Please enter either Period year and period name or Cutoff Period'
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
                                                || 'INV_GLOBAL_CURRENCY_CODE_NOT_FOUND: '
                                                || 'Global Currency Code is not found'
                                                || l_ledger_id);

                retcode := 1;
                return;
            END IF;

            local_curr_code := trnt_common_util.get_local_code(l_ledger_id);
            IF local_curr_code IS NULL THEN
                fnd_file.put_line(fnd_file.log, 'Error Code: '
                                                || 'INV_LOCAL_CURRENCY_CODE_NOT_FOUND: '
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
                                                    || 'INV_CONVERSION_RATE_NOT_FOUND: '
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
          --  IF rec_config.file_encrypt_flag = 'N'
            --THEN
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
          --  END IF;

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
           
              l_header_line := l_header_line
                             || 'orgid'
                             || chr(9);
            l_header_line := l_header_line
                             || 'orgcode'
                             || chr(9);
             l_header_line := l_header_line
                             || 'orgdescription'
                             || chr(9);
            l_header_line := l_header_line
                             || 'costtype'
                             || chr(9);
            l_header_line := l_header_line
                             || 'categoryset'
                             || chr(9);
            l_header_line := l_header_line
                             || 'item'
                             || chr(9);
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
            FOR rec IN cur_cad_inv_ext LOOP
                IF hd_flag = 1 THEN
                   -- IF rec_config.file_encrypt_flag = 'N'
                   -- THEN
                    IF l_output_type IN (
                        'S',
                        'X'
                    ) THEN
                        utl_file.put_line(v_utlfile, l_header_line);
                    END IF;
                   -- END IF;

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

              --  IF rec.sum_local_amount <> 0 AND rec.sum_trans_amount <> 0 THEN
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
                        --Custom Field
                        END IF;

                    END LOOP;

                    CLOSE c_seg_sel;
                    
                     l_data_line := l_data_line
                                   || rec.organization_id
                                   || chr(9);   
                   l_data_line := l_data_line
                                   || rec.organization_code
                                   || chr(9);
                  l_data_line := l_data_line
                                   || rec.ORGANIZATION_NAME
                                   || chr(9);
                    l_data_line := l_data_line
                                   || rec.cost_type
                                   || chr(9);
                    l_data_line := l_data_line
                                   || rec.category_set_id
                                   || chr(9);
                    l_data_line := l_data_line
                                   || trnt_common_util.format_field(rec.inventory_item_id, rec_config.invmaterial_rm_lead_zero, rec_config.
                                   invmaterial_rm_spcl_chr)
                                   || chr(9);                          
                                   
                  --  END IF;

                    IF rec_config.exclude_ledg_output = 'N' THEN
                        l_data_line := l_data_line
                                       || rec.ledger_id
                                       || chr(9);
                    END IF;
                
                    l_data_line := l_data_line
                                   || rpad(trnt_common_util.format_field(rec.account_desc, 'N', 'Y'), 50, ' ')
                                   || chr(9)
                                   || l_period_year                   --(rec.period_year)
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
                                   || to_char((l_gbl_amount), '9999999999999.00')
                                   || chr(9)
                                   || ( rec.local_curr_code )
                                   || chr(9)
                                   || to_char((rec.sum_local_amount), '9999999999999.00')
                                   || chr(9)
                                   || ( rec.trans_curr_code )
                                   || chr(9)
                                   || to_char((rec.sum_trans_amount), '9999999999999.00')
                                   || chr(13);

                    /*INV Extract API */

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

                --END IF;

            END LOOP;

            IF l_output_type IN (
                'API'
            ) THEN
                BEGIN
                    fnd_file.put_line(fnd_file.log, 'extraction for api');
                    v_jdata := trnt_common_util.get_jsonformat_for_uac(txtfile_tab, 'CAD', 'INV', 'EBS_APPS', rec_config.config_code,
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

            -- Writing the extract informations
            ---for json----

         ---json--

            IF l_output_type IN (
                'JSON'
            ) THEN
                BEGIN
                    l_text_data := l_text_data || l_data_line;
                    v_jdata := trnt_common_util.get_jsonformat_for_uac(txtfile_tab, 'CAD', 'APBALS', 'EBS_APPS', rec_config.config_code,
                                        rec_config.enable_encryption, p_config_id, rec_config.config_type, NULL, NULL);
    --fnd_file.put_line(fnd_file.log,v_jdata);

                EXCEPTION
                    WHEN OTHERS THEN
                        fnd_file.put_line(fnd_file.log, sqlerrm);
                END;

               -- l_file_path := '/usr/trintech';

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

                utl_file.fclose(v_utlfile);
                retcode := 1;
            WHEN utl_file.write_error THEN
                fnd_file.put_line(fnd_file.log, 'Invalid Output Path: '
                                                || sqlcode
                                                || '. '
                                                || sqlerrm
                                                || '. '
                                                || dbms_utility.format_error_backtrace);

                utl_file.fclose(v_utlfile);
                retcode := 1;
            WHEN fiscal_year_exception THEN
                fnd_file.put_line(fnd_file.log, 'INV,ERROR,fiscal_year_exception Procedure TRNT_INV_EXTRACT');
                retcode := 1;
                return;
            WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log, 'Unexpected Error in Procedure TRNT_INV_EXTRACT'
                                                || ' - '
                                                || sqlerrm
                                                || dbms_utility.format_error_backtrace);

                fnd_file.put_line(fnd_file.log, 'INV,ERROR,Unexpected Error in Procedure TRNT_INV_EXTRACT');
                utl_file.fclose(v_utlfile);
                retcode := 1;
                return;
        END;

    END trnt_inv_ext_file;

END trnt_xxx_inv_ext_pkg;
/
