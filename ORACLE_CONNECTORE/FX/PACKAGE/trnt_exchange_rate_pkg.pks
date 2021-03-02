DROP PACKAGE APPS.TRNT_xxx_EXCHANGE_RATE_PKG;

CREATE OR REPLACE PACKAGE APPS.trnt_xxx_exchange_rate_pkg AS
    pv_conversion_date VARCHAR2(20);
    PROCEDURE trnt_exchange_rate_file (
        errbuff       OUT           VARCHAR2,
        retcode       OUT           NUMBER,
        p_config_id   IN            VARCHAR2
    );

END trnt_xxx_exchange_rate_pkg;
/
