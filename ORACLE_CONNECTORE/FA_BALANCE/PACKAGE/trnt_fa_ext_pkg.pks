DROP PACKAGE APPS.TRNT_xxx_FA_EXT_PKG;

CREATE OR REPLACE PACKAGE APPS.trnt_xxx_fa_ext_pkg
AS
 PROCEDURE TRNT_FA_EXT_FILE(errbuff          OUT VARCHAR2,
                                    retcode          OUT NUMBER,
                                    p_config_id   IN     NUMBER);
end trnt_xxx_fa_ext_pkg;
/
