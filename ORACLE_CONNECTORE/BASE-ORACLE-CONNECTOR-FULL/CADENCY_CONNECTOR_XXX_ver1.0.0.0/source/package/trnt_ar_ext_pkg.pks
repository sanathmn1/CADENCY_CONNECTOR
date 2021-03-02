DROP PACKAGE APPS.TRNT_xxx_AR_EXT_PKG;

CREATE OR REPLACE PACKAGE APPS.trnt_xxx_ar_ext_pkg AS
    PROCEDURE trnt_ar_ext_file (
        errbuff       OUT           VARCHAR2,
        retcode       OUT           NUMBER,
        p_config_id   IN            NUMBER
    );

END trnt_xxx_ar_ext_pkg;
/
