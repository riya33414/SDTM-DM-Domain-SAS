/*******************************************************************
* Project: SDTM Demographics (DM) Domain Programming
* Program: DM.sas
*
* Program Type: SDTM
* Purpose: To develop the SDTM Demographics (DM) domain from
*          sample clinical trial data.
*
* Standard: CDISC SDTM
* SAS Version: 9.4
* Operating System: Windows
*
* Author: Riya Jagtap
* Project Type: Clinical SAS Portfolio Project
*
* Description:
* This program demonstrates the transformation and derivation of
* subject-level demographic information into the SDTM DM domain.
*
* Key Activities:
* - Raw clinical data review
* - Variable mapping and derivation
* - Subject identifier creation
* - Date variable derivation
* - Dataset merging and transformation
* - SDTM DM dataset creation
*
* Note: This is a learning/portfolio project using sample data.
*******************************************************************/

/*******************************************************************
* 1. LIBRARY SETUP
*******************************************************************/

libname raw '/home/u64498565/clinical SAS/RAW clinical sas';

proc contents data=raw.dm;
run;

proc print data=raw.dm(obs=20);
run;

libname SDTM '/home/u64498565/clinical SAS/clinical';
option nofmterr;

/*******************************************************************
* 2. CLEAN WORK LIBRARY
*******************************************************************/
proc datasets lib=Work kill;
run;
quit;


/*   STUDYID  AAA-2022 */
/*   DOMAIN   set to 'DM' */
/*   USUBJID  Set to Cocatenation of STUDYID and DM.SUBNUM. */
/*   SUBJID   Set to DM.SUBJID or extract from SUBNUM */
/*   BRTHDTC  Set to DM.BRTHDAT IN IS0 8601 format */
/*      AGE set to DM.AGE */


/*******************************************************************
* 4. CREATE DM DEMOGRAPHIC INFORMATION
*******************************************************************/
proc contents data=raw.dm varnum;
run;

data DM1;

    set raw.dm(rename=(age=agex sex=sexx race=racex ETHNIC=ETHNICX));

    STUDYID = "AAA-2022";
    DOMAIN  = "DM";
    SITEID  = SITENUM;
    SUBJID  = SUBSTR(SUBNUM,4);
    USUBJID = CATX("-",STUDYID,SITEID,SUBJID);

    BRTHDTC = PUT(BRTHDAT,IS8601DA.);
/*    renaming variable because sdtm and raw has same var name */
      AGE= AGEX;
      AGEU= "YEARS";
      SEX= SEXX;
      RACE= RACEX;
         
         length ETHNIC $200;
         if ETHNICX= 'HISP'                   THEN ETHNIC= 'HISPANIC OR LATINO';
    ELSE IF ETHNICX= 'NHISP'             THEN ETHNIC= 'NOT HISPANIC OR LATINO';
    ELSE IF ETHNICX= 'U'                 THEN ETHNIC= 'UNKNOWN';
    ELSE IF ETHNICX='DECLINED TO ANSWER' THEN ETHNIC= 'NOT REPORTED';

KEEP STUDYID DOMAIN SITEID SUBJID USUBJID BRTHDTC AGE SEX AGEU RACE ETHNIC;
run;

  PROC SORT ;
     BY USUBJID ;
  RUN;
  
proc print data=dm1;
run;


/*******************************************************************
* 5. INFORMED CONSENT DATA
*******************************************************************/
proc contents data=RAW.IC varnum;
run;

data IC;
       SET RAW.IC;
       
     STUDYID= "AAA-2022";
     DOMAIN= 'DM';
     SITEID= SITENUM;
     SUBJID= SUBSTR(SUBNUM, 4);
     USUBJID= CATX("-",STUDYID,SITEID,SUBJID);
   
     RFICDTC = PUT(ICDAT, IS8601DA.);

     keep USUBJID RFICDTC ;
 RUN;
   
   PROC SORT;
          BY USUBJID;
          RUN;
          
   PROC PRINT DATA= WORK.IC;
   RUN;

/*******************************************************************
* 6. DISPOSITION DATA
*******************************************************************/
proc contents data=RAW.DS varnum;
run;

DATA DS;
        SET RAW.DS;
        
    STUDYID= "AAA-2022";
    DOMAIN= 'DM';
    SITEID= SITENUM;
    SUBJID= SUBSTR(SUBNUM, 4);
    USUBJID= CATX("-", STUDYID, SITEID, SUBJID);
    
        IF DSDTHDAT NE . THEN DTHDTC = PUT (DSDTHDAT, YYMMDD10.);
    IF DTHDTC NE ''  THEN DTHFL= 'Y';
    IF DSLVDAT NE .  THEN RFPENDTC= PUT (DSLVDAT, YYMMDD10.);
    
    KEEP USUBJID DTHDTC DTHFL RFPENDTC;
run;

proc sort data=DS;
    by USUBJID;
run;

PROC PRINT DATA= WORK.DS;
RUN;


/*******************************************************************
* 7. EXPOSURE DATA
*******************************************************************/
proc contents data=RAW.EX varnum;
run;
 
data EX; 
    SET RAW.EX; 
        
    STUDYID= "AAA-2022"; 
    DOMAIN='DM'; 
    SITEID= SITENUM; 
    SUBJID= SUBSTR(SUBNUM,4); 
    USUBJID= CATX("-", STUDYID, SITEID, SUBJID); 
  
    IF EXSTDAT NE . THEN DO; 
        RFXSTDTC= CATS(PUT(EXSTDAT, YYMMDD10.), 'T', PUT(EXSTTIM, TOD8.)); 
    END;
        
    KEEP USUBJID RFXSTDTC; 
RUN; 
        
PROC SORT DATA=EX; 
    BY USUBJID RFXSTDTC; 
RUN;

data EX_FINAL;
    set EX;
    by USUBJID;

    retain FIRST_EXPOSURE;

    if first.USUBJID then FIRST_EXPOSURE = RFXSTDTC;

    if last.USUBJID then do;
        RFXSTDTC = FIRST_EXPOSURE;
        RFXENDTC = RFXSTDTC;
        RFSTDTC  = RFXSTDTC;
        RFENDTC  = RFXENDTC;
        output;
    end;

    keep USUBJID RFXSTDTC RFSTDTC RFXENDTC RFENDTC;
run;

proc print data=EX_FINAL(obs=20);
    var USUBJID RFXSTDTC RFSTDTC RFXENDTC RFENDTC;
run;

/*******************************************************************
* 8. RANDOMIZATION / TREATMENT DATA
*******************************************************************/

DATA TRT;
    SET RAW.DUMMY_RND;

    LENGTH ARMCD ACTARMCD $8.
           ARM ACTARM $200.;

    STUDYID = "AAA-2022";
    DOMAIN  = "DM";

    /* Derive SITEID and SUBJID from existing USUBJID */
    SITEID = SUBSTR(USUBJID,10,3);
    SUBJID = SUBSTR(USUBJID,14);

    /* Re-create standardized USUBJID */
    USUBJID = CATX("-", STUDYID, SITEID, SUBJID);

    /* Planned treatment */
    ARMCD = TRTCD;

    IF ARMCD = "TQ" THEN
        ARM = "TQU";
    ELSE IF ARMCD = "PLACEBO" THEN
        ARM = "PLACEBO";

    /* Actual treatment */
    ACTARMCD = TRTCD;

    IF ACTARMCD = "TQ" THEN
        ACTARM = "TQU";
    ELSE IF ACTARMCD = "PLACEBO" THEN
        ACTARM = "PLACEBO";

    KEEP USUBJID ARMCD ARM ACTARMCD ACTARM;
RUN;

PROC SORT DATA=TRT;
    BY USUBJID;
RUN;

PROC PRINT DATA=WORK.TRT;
RUN;


/*******************************************************************
* 9. SCREEN FAILURE DATA
*******************************************************************/

DATA SCF;
    SET RAW.DAT_SUB;

    STUDYID = "AAA-2022";
    DOMAIN  = "DM";

    SITEID  = SITENUM;
    SUBJID  = SUBSTR(SUBNUM,4);
    USUBJID = CATX("-", STUDYID, SITEID, SUBJID);

    IF STATUSID = 15 THEN DO;
        ARMNRS  = "SCREEN FAILURE";
        ACTARMUD = "SCREEN FAILURE";
    END;

    KEEP USUBJID ARMNRS ACTARMUD;
RUN;


PROC SORT DATA=SCF;
    BY USUBJID;
RUN;


PROC PRINT DATA=WORK.SCF;
RUN;

/*******************************************************************
* 10. SUBJECT-LEVEL MERGE
*******************************************************************/

DATA FINAL;

    MERGE
        DM1   (IN=A)
        IC
        DS
        EX_FINAL
        TRT
        SCF;

    BY USUBJID;

    /* Keep only subjects present in DM1 */
    IF A;

    COUNTRY = "USA";

RUN;

/*******************************************************************
* 11. FINAL VARIABLE ATTRIBUTES
*******************************************************************/

        
DATA FINAL1;
RETAIN
STUDYID
DOMAIN 
USUBJID
SUBJID
RFSTDTC
RFENDTC
RFXSTDTC
RFXENDTC
RFICDTC
RFPENDTC
DTHDTC
DTHFL
SITEID
BRTHDTC
AGE 
AGEU
SEX
RACE
ETHNIC
ARMCD
ACTARMCD
ACTARM
ARMNRS
ACTARMUD
COUNTRY;
SET FINAL;

KEEP 
STUDYID
DOMAIN
USUBJID
SUBJID
RFSTDTC
RFENDTC
RFXSTDTC
RFXENDTC
RFICDTC
RFPENDTC
DTHDTC
DTHFL
SITEID
BRTHDTC
AGE 
AGEU
SEX
RACE
ETHNIC
ARMCD
ACTARMCD
ACTARM
ARMNRS
ACTARMUD
COUNTRY
;
RUN;
     
DATA SDTM.DM
    (LABEL="DEMOGRAPHICS");

    SET FINAL1;

RUN;

PROC PRINT DATA=WORK.FINAL1;
RUN;

ods pdf file='/home/u64498565/clinical SAS/clinical/DM_Output.pdf';
title "SDTM Demographics (DM) Domain";
title2 "Clinical SAS Portfolio Project";

proc print data=SDTM.DM noobs;
run;

title;
title2;

ods pdf close;



