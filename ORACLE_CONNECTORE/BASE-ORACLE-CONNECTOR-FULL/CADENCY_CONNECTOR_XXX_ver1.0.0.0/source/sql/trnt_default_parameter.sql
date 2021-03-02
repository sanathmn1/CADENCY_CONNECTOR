DROP TABLE APPS.TRNT_DEFAULT_PARAMETER CASCADE CONSTRAINTS;

CREATE TABLE APPS.TRNT_DEFAULT_PARAMETER
(
  PARAM_ID     NUMBER,
  PARAM_TYPE   VARCHAR2(100 BYTE),
  PARAM_CODE   VARCHAR2(100 BYTE),
  PARAM_VALUE  VARCHAR2(100 BYTE),
  PARAM_DESC   VARCHAR2(200 BYTE),
  ACTIVE       VARCHAR2(1 BYTE)
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