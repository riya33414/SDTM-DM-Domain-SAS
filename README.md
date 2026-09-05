# SDTM-DM-Domain-SAS
A Clinical SAS programming project demonstrating the development of the CDISC SDTM Demographics (DM) domain from raw clinical trial data using SAS 9.4. Includes data transformation, variable derivation, date conversion, dataset integration, and SDTM-compliant subject-level data creation.

## Project Overview

This project demonstrates the development of the SDTM Demographics (DM) domain from sample clinical trial data using SAS 9.4.

## Objective

To transform subject-level clinical trial data into an SDTM-compliant Demographics (DM) domain and perform basic validation checks.

## Tools & Technologies

- SAS 9.4
- SAS Studio
- CDISC SDTM
- Base SAS

## Programming Activities

- Raw clinical data review
- Subject identifier derivation
- USUBJID creation
- ISO 8601 date derivation
- Demographic variable mapping
- Reference start/end date derivation
- Dataset merging
- Basic SDTM validation checks

## SDTM DM Variables

The final DM dataset includes variables such as:

- STUDYID
- DOMAIN
- USUBJID
- SUBJID
- SITEID
- BRTHDTC
- AGE
- AGEU
- SEX
- RACE
- ETHNIC
- RFSTDTC
- RFENDTC
- RFXSTDTC
- RFXENDTC
- RFICDTC
- ARMCD
- ACTARMCD
- ARM
- ACTARM
- COUNTRY

## Repository Structure

```text
SDTM-DM-Domain-SAS
│
├── README.md
│
├── SAS_Programs
│   └── DM.sas
│
├── Documentation
│   └── SDTM_DM_Project_Report.pdf
│
├── Output
│   └── DM_Output.pdf
│
└── Screenshots
    ├── DM_Dataset.png
    └── SAS_Log.png
