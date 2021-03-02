DROP TABLE APPS.TRNT_CONFIG_API_RESPONSE CASCADE CONSTRAINTS;

CREATE TABLE APPS.TRNT_CONFIG_API_RESPONSE
(
  API_ID                  NUMBER(10),
  CONFIG_ID               NUMBER(10),
  JSON_DATA               CLOB,
  CREATEDATE              DATE,
  RESPONSE_CODE           VARCHAR2(1000 BYTE),
  RESPONSE_DESCRIPTION    VARCHAR2(2000 BYTE),
  PROCESSCOMPLETEDDATE    DATE,
  CONFIG_TYPE             VARCHAR2(50 BYTE),
  ENABLE_ENCRYPTION_FLAG  VARCHAR2(10 BYTE),
  ENCRYPT_DATA            CLOB
)
LOB (ENCRYPT_DATA) STORE AS SECUREFILE (
  TABLESPACE  APPS_TS_TX_DATA
  ENABLE      STORAGE IN ROW
  CHUNK       8192
  NOCACHE
  LOGGING
      STORAGE    (
                  INITIAL          104K
                  NEXT             1M
                  MINEXTENTS       1
                  MAXEXTENTS       UNLIMITED
                  PCTINCREASE      0
                  BUFFER_POOL      DEFAULT
                 ))
LOB (JSON_DATA) STORE AS SECUREFILE (
  TABLESPACE  APPS_TS_TX_DATA
  ENABLE      STORAGE IN ROW
  CHUNK       8192
  NOCACHE
  LOGGING
      STORAGE    (
                  INITIAL          104K
                  NEXT             1M
                  MINEXTENTS       1
                  MAXEXTENTS       UNLIMITED
                  PCTINCREASE      0
                  BUFFER_POOL      DEFAULT
                 ))
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


--  There is no statement for index APPS.SYS_C00291495.
--  The object is created when the parent object is created.

ALTER TABLE APPS.TRNT_CONFIG_API_RESPONSE ADD (
  PRIMARY KEY
  (API_ID)
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
