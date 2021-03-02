DROP TABLE APPS.TRNT_CONFIG CASCADE CONSTRAINTS;

CREATE TABLE APPS.TRNT_CONFIG
(
  CONFIG_ID                       NUMBER,
  CONFIG_CODE                     VARCHAR2(50 BYTE) NOT NULL,
  CONFIG_DESC                     VARCHAR2(500 BYTE),
  CONFIG_TYPE                     VARCHAR2(50 BYTE),
  EXTRACT_TYPE                    VARCHAR2(20 BYTE),
  OUTPUT_TYPE                     VARCHAR2(10 BYTE),
  OUTPUT_LOCATION                 VARCHAR2(200 BYTE),
  ACCOUNT_TYPE                    VARCHAR2(50 BYTE),
  LEDGER                          VARCHAR2(10 BYTE),
  CHART_OF_ACCOUNTS_ID            VARCHAR2(30 BYTE),
  EXCLUDE_LEDG_OUTPUT             VARCHAR2(5 BYTE),
  BALANCESHEET_ACC_ONLY           VARCHAR2(5 BYTE),
  EXTRA_DAYS_PRIOR_CUTOFF         VARCHAR2(10 BYTE),
  FISCAL_YEAR                     NUMBER,
  PERIOD_1                        VARCHAR2(50 BYTE),
  GLOBAL_CURRENCY                 VARCHAR2(10 BYTE),
  CUSTOM_TEXT1                    VARCHAR2(100 BYTE),
  CUSTOM_TEXT2                    VARCHAR2(100 BYTE),
  ERP_RATE_TYPE                   VARCHAR2(30 BYTE),
  TRINTECH_RATE_TYPE              VARCHAR2(20 BYTE),
  PROPSED_YN                      VARCHAR2(5 BYTE),
  PROPSED_EXTRACT                 VARCHAR2(10 BYTE),
  PROPSED_EXTRACT_DATE            DATE,
  DATE_FORMAT                     VARCHAR2(20 BYTE),
  TRANS_INCREMENTAL               VARCHAR2(5 BYTE) DEFAULT 'N',
  DEPRECIATION_AREA               NUMBER(10),
  CREATED_DATE                    DATE          DEFAULT SYSDATE,
  ENABLE_ENCRYPTION               CHAR(1 BYTE),
  ENCRYPTION_TYPE                 VARCHAR2(50 BYTE),
  PERIOD_END_DATE                 VARCHAR2(10 BYTE),
  RM_SPECIAL_CHAR_ACC_DESC        VARCHAR2(100 BYTE),
  BID_ENABLE_FLAG                 VARCHAR2(10 BYTE),
  ASSET_CLASS_SELECTION           VARCHAR2(10 BYTE),
  ASSET_NUMBER_SELECTION          VARCHAR2(10 BYTE),
  ASSETCLASS_RM_SPCL_CHAR         VARCHAR2(10 BYTE),
  ASSETNUMBER_RM_SPCL_CHAR        VARCHAR2(10 BYTE),
  ASSET_PERIOD_ENDDATE            VARCHAR2(10 BYTE),
  ASSET_NUMBER_RM_LEAD_ZERO       VARCHAR2(10 BYTE),
  ASSET_CLASS_RM_LEAD_ZERO        VARCHAR2(10 BYTE),
  ASSETCLASS_FROM                 NUMBER,
  ASSETCLASS_TO                   NUMBER,
  ASSETNUMBER_TO                  NUMBER,
  ASSETNUMBER_FROM                NUMBER,
  ASSETDATE                       DATE,
  INV_CATEGORY_TYPE_FROM          NUMBER,
  INV_CATEGORY_TYPE_TO            NUMBER,
  INVMATERIAL_FROM                NUMBER,
  INVMATERIAL_TO                  NUMBER,
  INV_CATEGORY_TYPE_RM_LEAD_ZERO  VARCHAR2(10 BYTE),
  INVMATERIAL_RM_LEAD_ZERO        VARCHAR2(10 BYTE),
  INV_CATEGORY_TYPE_RM_SPCL_CHR   VARCHAR2(10 BYTE),
  INVMATERIAL_RM_SPCL_CHR         VARCHAR2(10 BYTE),
  INV_CATEGORY_TYPE_DISPLAY       VARCHAR2(10 BYTE),
  INV_MATERIAL_SELECTION          VARCHAR2(10 BYTE),
  INV_ORGANIZATION_ID             NUMBER,
  INV_COST_TYPE                   VARCHAR2(30 BYTE),
  ASSET_BOOK_TYPE_CODE            VARCHAR2(20 BYTE),
  ASSET_BOOK_TYPE_CODE_DESC       VARCHAR2(20 BYTE),
  INV_CATEGORY_SET_ID             NUMBER,
  ASSET_BOOK_CLASS                VARCHAR2(20 BYTE),
  INV_ORGANIZATION_ID_TO          NUMBER,
  TRANSACTION_COUNT               VARCHAR2(10 BYTE)
)
TABLESPACE APPS_TS_TX_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
MONITORING;


CREATE UNIQUE INDEX APPS.CONFIG_ID_PK ON APPS.TRNT_CONFIG
(CONFIG_ID)
LOGGING
TABLESPACE APPS_TS_TX_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );

--  There is no statement for index APPS.SYS_C00291494.
--  The object is created when the parent object is created.

ALTER TABLE APPS.TRNT_CONFIG ADD (
  CONSTRAINT CONFIG_ID_PK
  PRIMARY KEY
  (CONFIG_ID)
  USING INDEX APPS.CONFIG_ID_PK
  ENABLE VALIDATE
,  UNIQUE (CONFIG_CODE)
  USING INDEX
    TABLESPACE APPS_TS_TX_DATA
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                NEXT             1M
                MINEXTENTS       1
                MAXEXTENTS       UNLIMITED
                PCTINCREASE      0
                BUFFER_POOL      DEFAULT
               )
  ENABLE VALIDATE);