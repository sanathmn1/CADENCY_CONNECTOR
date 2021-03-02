SET DEFINE OFF;
Delete from TRNT_SEGMENT_CONFIG ;

insert into TRNT_SEGMENT_CONFIG (
   SELECT   chart_of_accounts_id application_id ,upper(segment_name) column_name,application_column_name,segment_name,enabled_flag disp_in_report,
   Display_flag disp_in_query,segment_num display_order,regexp_replace(replace(lower(segment_name),' ',''),'[^[:alnum:]'' '']', NULL) segment_disp_name,ledger_id
    FROM gl_ledgers gl,FND_ID_FLEX_SEGMENTS_VL f
   WHERE id_flex_num=chart_of_accounts_id
   and segment_num<=4
   and id_flex_code='GL#');


update trnt_segment_config set segment_disp_name='companycode'
where upper(segment_name)=upper('Company');

