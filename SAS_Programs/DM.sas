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





libname SDTM '/home/u64498565/clinical SAS/clinical';
option nofmterr;

libname raw '/home/u64498565/clinical SAS/RAW clinical sas';

proc datasets lib=Work kill;
run;
quit;


/*   STUDYID  AAA-2022 */
/*   DOMAIN   set to 'DM' */
/*   USUBJID  Set to Cocatenation of STUDYID and DM.SUBNUM. */
/*   SUBJID   Set to DM.SUBJID or extract from SUBNUM */
/*   BRTHDTC  Set to DM.BRTHDAT IN IS0 8601 format */
/*      AGE set to DM.AGE */

data DM1;
/*   DM1 temporary dataset stored in WORK lib  */
 /*   if varible name in raw dataset and sdtm are same then we first rename raw variable */


 set raw.dm (rename=(age=agex sex=sexx race=racex ETHNIC=ETHNICX));
 length ETHNIC $200.;
 STUDYID= "AAA-2022";
 DOMAIN= "DM";
 SITEID= SITENUM;
 SUBJID= SUBSTR(SUBNUM,4);
 USUBJID= CATX("-", STUDYID, SITEID, SUBJID);
 
 /*  USUBJID= strip(STUDYID)||"-"||STRIP(SITEID)||"-"||STRIP(SUBJID); */
/*     USUBJID can be done by two ways by using strip and catx */
 
 
/* convert to character */
  BRTHDTC= PUT(BRTHDAT, IS8601DA.);
/*   renaming varibles bcoz sdtm and raw has same so renaming raw on */
  AGE= AGEX;
  AGEU= "YEARS";
  SEX= SEXX;
  RACE= RACEX;
  
/*   set to DM.ETHNIC and adjust value per controlled terminology */
    if ETHNICX= 'HISP'                   THEN ETHNIC= 'HISPANIC OR LATINO';
    ELSE IF ETHNICX= 'NHISP'             THEN ETHNIC= 'NOT HISPANIC OR LATINO';
    ELSE IF ETHNICX= 'U'                 THEN ETHNIC= 'UNKNOWN';
    ELSE IF ETHNICX='DECLINED TO ANSWER' THEN ETHNIC= 'NOT REPORTED';

  KEEP STUDYID DOMAIN SITEID SUBJID USUBJID BRTHDTC AGE SEX AGEU RACE ETHNIC;
RUN;
 
  PROC SORT ;
     BY USUBJID ;
  RUN;



data IC;
       SET RAW.IC;
       
     STUDYID= "AAA-2022";
     DOMAIN= 'DM';
     SITEID= SITENUM;
     SUBJID= SUBSTR(SUBNUM, 4);
/*      	join the variables for usubjid */
     USUBJID= CATX("-",STUDYID,SITEID,SUBJID);
     RFICDTC1= PUT (ICDAT, YYMMDD10.);
   
/*      (from) set to IC.ICDAT */
     RFICDTC= PUT(ICDAT, IS8601DA.);
     
     keep USUBJID RFICDTC ;
 RUN;
   
   PROC SORT;
          BY USUBJID;
          RUN;
          
   PROC PRINT DATA= WORK.IC;
   RUN;
 



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

   proc sort; 
           by USUBJID;
           RUN;
           

PROC PRINT DATA= WORK.DS;
RUN;




data EX;
       SET RAW.EX;
       
       STUDYID= "AAA-2022";
       DOMAIN='DM';
       SITEID= SITENUM;
       SUBJID= SUBSTR(SUBNUM,4);
       USUBJID= CATX("-", STUDYID, SITEID, SUBJID);
       
/*      IF EXSTDAT NE . THEN DO; */
/*      RFXSTDTC =PUT (EXSTDAT, YYMMDD10.) ||"T"|| PUT(EXSTTIM,TOD8.); */
/*      RFSTDTC=PUT(EXSTDAT, YYMMDD10.)    ||"T"|| PUT(EXSTTIM,TOD8.); */
/*       */
/*      RFXENDTC=PUT(EXSTDAT, YYMMDD10.)   ||"T"|| PUT(EXSTTIM,TOD8.); */
/*      RFENDTC=PUT(EXSTDAT, YYMMDD10.)    ||"T"|| PUT(EXSTTIM,TOD8.); */

/*       (or rather repeating same code 4 times use this) */

        IF EXSTDAT NE . THEN DO ;
        RFXSTDTC= CATS(PUT(EXSTDAT, YYMMDD10.), 'T', PUT(EXSTTIM, TOD8.));
        
        RFSTDTC = RFXSTDTC;
        RFXENDTC = RFXSTDTC;
        RFENDTC = RFXSTDTC;    
  END;
       
      KEEP USUBJID RFXSTDTC RFSTDTC RFXENDTC RFENDTC;
   RUN;
       
PROC SORT;
         BY USUBJID RFSTDTC;
         RUN;
 
 PROC SORT NODUPKEY;
           BY USUBJID;
           RUN;
           
 PROC PRINT DATA= WORK.ex; 
 RUN;
         
 PROC PRINT DATA= RAW.EX;
           WHERE EXSTDAT= . or EXSTTIM= .;
           
        VAR SUBNUM SITENUM EXSTDAT;
        RUN;
/*      (did proc print because they were showing blanks in some data rows of exstdat)   */
       
 
 DATA TRT;
         SET RAW.DUMMY_RND;
         
         LENGTH ARMCD ACTARMCD $8. ARM ACTARM $200.;
         STUDYID= "AAA-2022";
         DOMAIN= 'DM';
         SITEID= SUBSTR(USUBJID, 12, 3);
         SUBJID= SUBSTR(USUBJID, 15);
         USUBJID= CATX("-", STUDYID, SITEID, SUBJID);
         
         ARMCD=TRTCD;
         IF ARMCD= 'TQ'      THEN ARM= 'TQU';
         IF ARMCD= 'PLACEBO' THEN ARM= 'PLACEBO';
         
         ACTARMCD=TRTCD;
         IF ACTARMCD= 'TQ'      THEN ACTARM= 'TQU';
         IF ACTARMCD= 'PLACEBO' THEN ACTARM= 'PLACEBO';
         
         KEEP USUBJID ARMCD ARM ACTARMCD ACTARM;
         
 RUN;
 
  PROC SORT;
           BY USUBJID;
           RUN;
           
  PROC PRINT DATA=WORK.TRT;
  RUN;
        
        
DATA SCF;
        SET RAW.DAT_SUB;
        
        STUDYID= "AAA-2022";
        DOMAIN= 'DM';
        SITEID= SITENUM;
        SUBJID= SUBSTR(SUBNUM, 4);
        USUBJID= CATX("-" ,STUDYID, SITEID, SUBJID);
        
        IF STATUSID=15 THEN DO;
        ARMNRS= 'SCREEN FAILURE';
        ACTARMUD= 'SCREEN FAILURE';
        END;
        
        KEEP USUBJID ARMNRS ACTARMUD;
   RUN;
   
   PROC SORT;
           BY USUBJID;
           RUN;
           
   PROC PRINT DATA= WORK.SCF;
   RUN;
        
        
        
 DATA FINAL;
          MERGE DM1 (IN=A) IC DS EX TRT SCF;
          BY USUBJID;
          IF A;
          IF ARM= 'ASSIGNED, NOT TREATED' AND ACTARM EQ '' THEN DO;
             ARMNRS= 'NOT ASSIGNED'; 
/*              there is some mistake in above code */
          END;
          
          COUNTRY= 'USA';
 RUN;
        
        
        
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
     
/*  	apply attributes and save permanent lib        */

DATA SDTM.DM_ (LABEL='DEMOGRAPHICS');
SET FINAL1;
RUN;
        
