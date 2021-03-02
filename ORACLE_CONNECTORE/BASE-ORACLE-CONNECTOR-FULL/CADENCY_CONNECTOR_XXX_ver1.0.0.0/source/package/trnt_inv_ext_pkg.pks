DROP PACKAGE APPS.TRNT_xxx_INV_EXT_PKG;

CREATE OR REPLACE PACKAGE APPS.TRNT_xxx_INV_EXT_PKG AS 

   PROCEDURE TRNT_INV_EXT_FILE (
        errbuff       OUT           VARCHAR2,
        retcode       OUT           NUMBER,
        p_config_id   IN            NUMBER
    );

END TRNT_xxx_INV_EXT_PKG;
/
