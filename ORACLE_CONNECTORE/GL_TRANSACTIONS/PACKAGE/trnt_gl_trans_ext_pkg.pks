DROP PACKAGE APPS.TRNT_xxx_GL_TRANS_EXT_PKG;

CREATE OR REPLACE PACKAGE APPS.trnt_xxx_gl_trans_ext_pkg AS
    PROCEDURE trnt_gl_trans_ext_file (
        errbuff       OUT           VARCHAR2,
        retcode       OUT           NUMBER,
        p_config_id   IN            NUMBER
    );

END trnt_xxx_gl_trans_ext_pkg;
/
