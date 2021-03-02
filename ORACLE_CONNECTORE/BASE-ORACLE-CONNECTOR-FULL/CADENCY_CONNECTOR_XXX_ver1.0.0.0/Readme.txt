pre-installation
================
step1: create a file directory using this command for saving the server files.
		"CREATE OR REPLACE DIRECTORY Trintech_dir AS 'FILE-PATH';"

step2:	"grant execute on dbms_crypto to to apps;"

Installation
=================

Step1:- Copy the Cadency_oracle_connector.zip file to local desktop and unzip it
        Copy the provided Cadency_oracle_connector folder to the database server
        Using Winscp or other file transfer tools
        Eg Path; \u01\install\APPS

Step2:- Login to the server using Sudo user(oracle/root)
        Change the permission of the Cadency_oracle_connector using the following command 
        CHMOD 777 Cadency_oracle_connector

Step3:- Preparing the environment to execute the new connector application
        Login to the database server using oracle user and execute the 
        Env file to make the system ready to execute sql statements
        login as: Oracle
        oracle@192.168.2.99's password:
        [oracle@apps ~]# cd  /u01/install/APPS/
        [oracle@apps APPS]# . EBSapps.env
        Please Select the RUN Mode while executing 
        Note:-<"The Environment Variable Name and Path Maybe Change Its Depend On the EBS Version
               Eg:->12.1.3 /u01/install/APPS/apps/apps_st/appl/
               Eg:->12.2.9 /u01/install/APPS/  ">
        
Step4:- Execute the Sh script(TRNT_RELEASE_MAIN_V01) provide in the installation folder
        Navigate to the path in step1 above
        And execute following command  in the prompt as below
        sh TRNT_RELEASE_MAIN_V01 <USERNAME> <Password> <SID>
        Verify the logs and error files if any errors
        Please resolve the error,
        if support need please contact econnector@trintech.com/sanath.mann@trintech.com



Step5:- Copy the below fmx file to the Application server
        CAD_CONFIG.FMX
        CAD_EXTRACT.FMX
        to $GL_TOP/forms/US/CAD_EXTRACT.fmx
        Note:-<"The FMX File Path Maybe Change Its Depend On the EBS Version
               Eg:12.1.3 /u01/install/APPS/apps/apps_st/appl/gl/12.0.0
               Eg:12.2.9 /u01/install/APPS/fs1/EBSapps/appl/gl/12.0.0/forms/US">

            If this forms dint work expected please follow the below step to compile,
            when compile successfully it should work 

Alternate Step: Copy the below fmb file to the Application server
      		Source is available in CADENCY_CONNECTOR_V01\Source\Forms Folder
       		CAD_CONFIG.FMB
       		CAD_EXTRACT.FMB
           	/u01/install/APPS/fs1/EBSapps/appl/au/12.0.0/forms/US
                Note:-<The FMB File Path Maybe Change Its Depend On the EBS Version>
       		And compile the following FMB 

   		Please provide the apps user name and password before compliling

   		frmcmp_batch module=$AU_TOP/forms/US/CAD_CONFIG.fmb output_file=$GL_TOP/forms/US/CAD_CONFIG.fmx userid=apps_username/apps_password module_type=FORM

   		frmcmp_batch module=$AU_TOP/forms/US/CAD_EXTRACT.fmb output_file=$GL_TOP/forms/US/CAD_EXTRACT.fmx userid=apps_username/apps_password module_type=FORM
---------------------------------------------------------------------------------------------------------------
Note:- "If any issues are faced during compilation process copy the below 3 FMB file  $FORMS_PATH FOLDER and Try Compiling Again"
      
        1.APPSTAND.fmb
        2.APSTAND.fmb
        3.GLSTAND.fmb
---------------------------------------------------------------------------------------------------------------
Post-Installation
=================
Step6:- Create the server file path in server("same directory path")(use file trasfer tools like winscp,filezila...etc..)

Step7:- Update directory path to "TRNT_DEFAULT_PARAMETER"Table
                 "update TRNT_DEFAULT_PARAMETER  set PARAM_VALUE=<FILE-PATH>where PARAM_TYPE='FILE_LOCATION';"
                  

Step8:- Please login to the application with the user has responsibility of user management  and add the responsibilty "Cadency" to the required users
         Login to the User which has added the responsibiliy, and check extracting the Data


