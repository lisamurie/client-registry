﻿
/* 
 * POSTGRECR - MARC-HI CLIENT REGISTRY DATABASE SCHEMA FOR POSTGRESQL
 * VERSION: 2.0
 * AUTHOR: JUSTIN FYFE
 * DATE: JULY 12, 2012
 * FILES:
 *	POSTGRECR-DDL.SQL	- SQL CODE TO CREATE TABLES, INDECIES, VIEWS AND SEQUENCES
 *	POSTGRECR-SRCH.SQL	- SQL CODE TO CREATE SEARCH FUNCTIONS
 *	POSTGRESHR-FX.SQL	- SQL CODE TO CREATE SUPPORT PROCEDURES AND FUNCTIONS
 * DESCRIPTION:
 *	THIS FILE CLEANS AND THEN RE-CREATES THE POSTGRESQL CLIENT REGISTRY
 *	DATABASE SCHEMA INCLUDING TABLES, VIEWS, INDECIES AND SEQUENCES. 
 * LICENSE:
 * 	Licensed under the Apache License, Version 2.0 (the "License");
 * 	you may not use this file except in compliance with the License.
 * 	You may obtain a copy of the License at
 *
 *     		http://www.apache.org/licenses/LICENSE-2.0
 *
 * 	Unless required by applicable law or agreed to in writing, software
 * 	distributed under the License is distributed on an "AS IS" BASIS,
 * 	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * 	See the License for the specific language governing permissions and
 * 	limitations under the License.
 */

-- @DATABASE
-- CREATES THE DATABASE AND MODIFIES THE OWNER TO THE APPROPRIATE USER
-- CREATE DATABASE pgCR OWNER pgCR;

-- @LANGUAGE
-- REGISTER THE PLPGSQL LANGUAGE
--CREATE LANGUAGE PLPGSQL;

-- CORRECTS THE BYTEA ENCODING PROBLEM ON POSTGRESQL 9.X
SET bytea_output = ESCAPE;

-- CLEAN TABLES
DROP TABLE PSN_ALT_ID_TBL CASCADE;
DROP TABLE PSN_TEL_TBL CASCADE;
DROP TABLE ADDR_CMP_TBL CASCADE;
DROP TABLE PSN_ADDR_SET_TBL CASCADE;
DROP TABLE NAME_CMP_TBL CASCADE;
DROP TABLE PSN_NAME_SET_TBL CASCADE;
DROP TABLE PSN_RACE_TBL CASCADE;
DROP TABLE PSN_LANG_TBL CASCADE;
DROP TABLE PSN_MSK_TBL CASCADE;
DROP TABLE PSN_RLTNSHP_TBL CASCADE;
DROP TABLE PSN_VRSN_TBL CASCADE;
DROP TABLE PSN_TBL CASCADE;
DROP TABLE PSN_EXT_TBL CASCADE;
DROP TABLE EXT_TBL CASCADE;
DROP TABLE CMP_TBL CASCADE;
DROP TABLE HC_PTCPT_ALT_ID_TBL CASCADE;
DROP TABLE HC_PTCPT_TEL_TBL CASCADE;
DROP TABLE HSR_HC_PTCPT_ORIG_ID_TBL CASCADE;
DROP TABLE HSR_HC_PTCPT_TBL CASCADE;
DROP TABLE HC_PTCPT_TBL CASCADE;
DROP TABLE HSR_SDL_TBL CASCADE;
DROP TABLE SDL_ALT_ID_TBL CASCADE;
DROP TABLE SDL_TBL CASCADE;
DROP TABLE HSR_LNK_TBL CASCADE;
DROP TABLE HSR_VRSN_TBL CASCADE;
DROP TABLE HSR_TBL CASCADE;
DROP TABLE TS_TBL CASCADE;
DROP TABLE CD_TBL CASCADE;

-- CLEAN SEQUENCES
DROP SEQUENCE PSN_MSK_SEQ;
DROP SEQUENCE PSN_SEQ;
DROP SEQUENCE PSN_TEL_SEQ;
DROP SEQUENCE TS_SEQ;
DROP SEQUENCE CD_SEQ;
DROP SEQUENCE ADDR_CMP_SEQ;
DROP SEQUENCE NAME_CMP_SEQ;
DROP SEQUENCE PSN_RLTNSHP_SEQ;
DROP SEQUENCE PSN_LANG_SEQ;
DROP SEQUENCE EXT_SEQ;
DROP SEQUENCE CMP_SEQ;
DROP SEQUENCE HC_PTCPT_SEQ;
DROP SEQUENCE HC_PTCPT_TEL_SEQ;
DROP SEQUENCE HSR_SEQ;
DROP SEQUENCE SDL_SEQ;

-- @SEQUENCE
-- TIME STAMP COMPONENT TABLE IDENTIFIER
CREATE SEQUENCE TS_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
--
-- TIMESTAMP COMPONENT TABLE
-- 
-- PURPOSE: COMPLEX TIMES MAY BE REPRESENTED WITHIN THE HEALTH CARE DOMAIN. FOR EXAMPLE, ONE SERVICE EVENT MAY HAVE
--	    AN EFFECTIVE TIME AT ONE FIXED POINT IN TIME (JUN 11 2009), HOWEVER OTHERS (SUCH AS A STAY IN HOSPITAL) MAY
--	    HAVE A RANGE SPECIFIED. IT IS FOR THIS REASON THAT WE CHOOSE TO IMPLEMENT A TIME STAMP COMPONENT TABLE
--
CREATE TABLE TS_TBL
(
	TS_ID		DECIMAL(20,0) NOT NULL DEFAULT nextval('TS_SEQ'), -- UNIQUELY IDENTIFIES THIS TIMESTAMP
	TS_VALUE	TIMESTAMPTZ NOT NULL, -- IDENTIFIES THE VALUE OF THE TIMESTAMP
	TS_PRECISION	CHAR(1) NOT NULL DEFAULT 'F', -- IDENTIFIES THE PRECISION OF THE TIMESTAMP
	TS_CLS		CHAR(1) NOT NULL DEFAULT 'S', -- CLASSIFIES THE TYPE OF TIMESTAMP COMPONENT
	TS_SET_ID	DECIMAL(20,0), -- USED TO CORRELATE DISPARATE TIME COMPONENTS TOGETHER,
	CONSTRAINT PK_TS_TBL PRIMARY KEY (TS_ID),
	CONSTRAINT CK_TS_PRECISION CHECK (TS_PRECISION IN ('Y','M','D','H','m','S','F')), -- ALLOWED VALUES FOR PRECISION:
	--	Y	- YEAR
	--	M	- MONTH
	--	D	- DAY
	--	H	- HOUR
	--	m	- MINUTES
	--	S	- SECONDS
	--	F	- FRACTION SECTIONDS (MILLISECTIONS)
	CONSTRAINT CK_TS_CLS CHECK (TS_CLS IN ('S','L','U','W')) -- ALLOWED VALUES FOR CLASSIFICATION
	--	S	- JUST A SET COMPONENT
	--	L	- LOWER BOUND
	--	U	- UPPER BOUND
	--	W	- WIDTH
);

-- @INDEX
-- USING THE VALUES
CREATE INDEX TS_TBL_TS_VALUE_IDX ON TS_TBL (TS_VALUE);

-- @INDEX
-- LOOKUP BY TIME SET SEQUENCE SHOULD BE INDEXED
CREATE INDEX TS_TBL_TS_SET_ID_IDX ON TS_TBL(TS_SET_ID);

-- @SEQUENCE
-- CONCEPT DESCRIPTOR CODE TABLE STORAGE IDENTIFIER
CREATE SEQUENCE CD_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
--
-- THE CONCEPT DESCRIPTOR TABLE
--
-- PURPOSE: COMPLEX CODE SYSTEMS (SUCH AS SNOMED CT) ARE HIERARCHICAL IN NATURE AND ARE MADE UP OF MANY COMPONENTS,
--	    THIS MAKES IT DIFFICULT TO STORE THEM INLINE WITHIN A TABLE. THAT IS THE SOLE PURPOSE OF THIS TABLE, TO
--	    REGISTER CODES THAT ARE USED WITHIN THE SHARED HEALTH RECORD DATA.
--
CREATE TABLE CD_TBL
(
	CD_ID		DECIMAL(20,0) NOT NULL DEFAULT nextval('CD_SEQ'), -- UNIQUE IDENTIFIER OF THE CODE BEING USED
	CD_VAL		VARCHAR(20) NOT NULL, -- THE VALUE OF THE CODE
	CD_DOMAIN 	VARCHAR(48),  -- THE DOMAIN FROM WHICH THE CODE WAS SELECTED
	ORG_CNT_TYP	VARCHAR(48), -- THE CONTENT/TYPE OF THE ORIGINAL TEXT
	ORG_TEXT   	BYTEA, -- THE ORIGINAL TEXT OR MULTIMEDIA BEHIND THE REASON FOR SELECTING THE CODE
	CD_VRSN		VARCHAR(20), -- IDENTIFIES THE VERSION OF THE CODE DOMAIN FROM WHICH THE CODE WAS SELECTED
	CD_QLFYS	DECIMAL(20,0), -- IDENTIFIES THE CODE THAT THIS CODE TUPLE QUALIFIES
	CD_QLFYS_AS	CHAR(1), -- IDENTIFIES HOW THE CODE QUALIFIES
	CD_QLFYS_KV_ID	VARCHAR(48), -- IDENTIFIES THE KEY/VALUE CORRELATION ID
	CONSTRAINT PK_CD_TBL PRIMARY KEY (CD_ID),
	CONSTRAINT FK_CD_QLFYS_CD_TBL FOREIGN KEY (CD_QLFYS) REFERENCES CD_TBL(CD_ID)
);

-- @INDEX
-- MAY NEED TO LOOKUP CODES BASED ON THE CODE THAT THEY QUALIFY
CREATE INDEX CD_TBL_CD_QLFYS_IDX ON CD_TBL(CD_QLFYS);

-- @INDEX
-- LOOKUP BY CODE SYSTEM AND CODE
CREATE INDEX CD_TBL_CD_CD_DOMAIN_IDX ON CD_TBL(CD_DOMAIN, CD_VAL);


-- @SEQUENCE
-- HEALTH SERVICE RECORD TABLE IDENTIFIER SEQUENCE
CREATE SEQUENCE HSR_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
-- THE HEALTH SERVICE RECORD TABLE
--
-- PURPOSE: STORES INFORMATION RELATED TO HEALTH SERVICES EVENTS
-- 
CREATE TABLE HSR_TBL
(
	HSR_ID	DECIMAL(20,0) NOT NULL DEFAULT nextval('HSR_SEQ'), -- UNIQUELY IDENTIFIES THIS HEALTH SERVICE RECORD
	HSR_CLS DECIMAL(4) NOT NULL, -- CLASSIFIES THE TYPE OF HEALTH SERVICE RECORD
	CONSTRAINT PK_HSR_TBL PRIMARY KEY (HSR_ID)
);

-- @INDEX
-- THE HEALTH SERVICE RECORDS BY CLASSIFICATION CODE INDEX
CREATE INDEX HSR_CLS_IDX ON HSR_TBL(HSR_CLS);

-- @TABLE 
-- THE HEALTH SERVICE RECORD VERSION TABLE
--
-- PURPOSE: THIS TABLE ALLOWS MULTIPLE VERSIONS OF ONE HEALTH SERVICE RECORD TO BE KEPT, ALLOWING
-- 	    CLINICAL CHANGES IN DATA TO BE TRACKED.
--
CREATE TABLE HSR_VRSN_TBL 
(
	HSR_VRSN_ID	DECIMAL(20,0) NOT NULL DEFAULT nextval('HSR_SEQ'), -- UNIQUELY IDENTIFIES THE CURRENT VERSION OF HEALTH SERVICE RECORD
	EVT_TYP_CD_ID	DECIMAL(20,0), -- IDENTIFIES THE CLINICAL EVENT THAT OCCURRED
	CRTN_UTC	TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, -- IDENTIFIES THE TIME WHEN THE VERSION WAS CREATED
	AUT_UTC		TIMESTAMPTZ NOT NULL, -- IDENTIFIES THE TIME WHEN THE VERSION DATA WAS AUTHORED
	OBSLT_UTC	TIMESTAMPTZ,  -- IDENTIFIES THE TIME WHEN THE VERSION WAS OBSOLETED
	REFUTED_IND	BOOLEAN NOT NULL DEFAULT FALSE, -- IF TRUE, THEN THE SERVICE EVENT HAS BEEN REFUTED TO HAVE HAPPENED
	EFFT_TS_SET_ID	DECIMAL(20,0), -- IDENTIFIES THE EFFECTIVE TS TIME SET THAT REPRESENTS THE TIME (OR PERIOD) THIS 
	STATUS_CS	VARCHAR(10) NOT NULL DEFAULT 'new', -- IDENTIFIES THE STATUS OF THE HEALTH SERVICES RECORD
	LANG_CS		VARCHAR(10) NOT NULL DEFAULT 'en', -- IDENTIFIES THE LANGUAGE IN WHICH THE HEALTH SERVICE EVENT WAS PROVIDED
	HSR_ID		DECIMAL(20,0) NOT NULL, -- IDENTIFIES THE HEALTH SERVICE EVENT ID THAT THIS VERSION APPLIES TO
	RPLC_VRSN_ID	DECIMAL(20,0), -- IDENTIFIES THE VERSION THAT THIS HEALTH SERVICE EVENT REPLACES (OR OBSOLETES)
	CONSTRAINT PK_HSR_VRSN_TBL PRIMARY KEY (HSR_VRSN_ID),
	CONSTRAINT FK_EVT_TYP_CD_CD_TBL FOREIGN KEY (EVT_TYP_CD_ID) REFERENCES CD_TBL(CD_ID),
	--CONSTRAINT FK_EFFT_TS_SET_ID_TS_TBL FOREIGN KEY (EFFT_TS_SET_ID) REFERENCES TS_TBL(TS_SET_ID), CANT DO THIS AS A SET ID CANNOT BE UNIQUE
	CONSTRAINT FK_HSR_ID_HSR_TBL FOREIGN KEY (HSR_ID) REFERENCES HSR_TBL(HSR_ID),
	CONSTRAINT FK_RPLC_VRSN_ID_HSR_TBL FOREIGN KEY (RPLC_VRSN_ID) REFERENCES HSR_VRSN_TBL(HSR_VRSN_ID)
);

-- @SEQUENCE
-- THE SEQUENCE FOR THE PERSON OBJECT
CREATE SEQUENCE PSN_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
-- PERSON TABLE
--
-- PURPOSE: A PERSON IS AN ENTITY WHICH IS LIVING AND BREATHING. IN THIS CLIENT REGISTRY 
--	    MODEL THE PERSON TABLE STORES THE MASTER PERSON IDENTIFIER AND ALL DATA IS 
--	    STORED AS VERSION IN THE PERSON VERSION TABLE
--
CREATE TABLE PSN_TBL
(
	PSN_ID	DECIMAL(20,0) NOT NULL DEFAULT nextval('PSN_SEQ'), -- THE IDENTIFIER FOR THE PERSON RECORD
	CONSTRAINT PK_PSN_TBL PRIMARY KEY (PSN_ID)
);


-- @TABLE
-- PERSON VERSION TABLE
-- 
-- PURPOSE: THE CLIENT REGISTRY DATA MODEL IS VERSIONED AND EACH PERSON RECORD MAY CONTAIN
--	    MANY VERSIONS
CREATE TABLE PSN_VRSN_TBL
(
	PSN_VRSN_ID	DECIMAL(20,0) NOT NULL DEFAULT nextval('PSN_SEQ'), -- THE IDENTIFIER FOR THE VERSION 
	PSN_ID		DECIMAL(20,0) NOT NULL, -- THE IDENTIFIER OF THE PERSON TO WHICH THIS VERISON APPLIES
	RPLC_VRSN_ID	DECIMAL(20,0), -- THE IDENTIFIER OF THE VERSION THAT THIS VERSION REPLACES
	REG_VRSN_ID	DECIMAL(20,0) NOT NULL, -- THE IDENTIFIER OF THE REGISTRATION EVENT (HSR_VRSN_TBL) THAT CAUSED THIS VERSION OF THE PATIENT TO COME INTO BEING
	STATUS		VARCHAR(12) NOT NULL DEFAULT 'Active', -- THE STATUS OF THE VERSION
	CRT_UTC		TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, -- THE TIME THAT THE VERSION WAS CREATED
	OBSLT_UTC	TIMESTAMPTZ, -- THE TIMESTAMP AT WHICH TIME THE RECORD DID OR WILL BECOME OBSOLETE
	GNDR_CS		CHAR(1), -- THE GENDER CODE OF THE PERSON AS OF THE CURRENT VERSION
	BRTH_TS		DECIMAL(20,0), -- IDENTIFIES WHEN THE PERSON WAS BORN OR PURPORTED TO BE BORN
	DCSD_TS		DECIMAL(20,0), -- IDENTIFIES WHEN THE PERSON BECAME DECEASED
	MB_ORD		DECIMAL(2), -- IDENTIFIES THE ORDER OF A MULTIPLE BIRTH
	RLGN_CD_ID	DECIMAL(20,0), -- IDENTIFIES THE RELIGION CODE
	CONSTRAINT PK_PSN_VRSN_TBL PRIMARY KEY (PSN_VRSN_ID),
	CONSTRAINT FK_PSN_PSN_VRSN_TBL FOREIGN KEY (PSN_ID) REFERENCES PSN_TBL(PSN_ID),
	CONSTRAINT FK_RPLC_VRSN_TBL FOREIGN KEY (RPLC_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID),
	CONSTRAINT FK_RLGN_CD_CD_TBL FOREIGN KEY (RLGN_CD_ID) REFERENCES CD_TBL(CD_ID),
	CONSTRAINT FK_BRTH_TS_TS_TBL FOREIGN KEY (BRTH_TS) REFERENCES TS_TBL(TS_ID),
	CONSTRAINT FK_DCSD_TS_TS_TBL FOREIGN KEY (DCSD_TS) REFERENCES TS_TBL(TS_ID),
	CONSTRAINT FK_REG_VRSN_ID_HSR_VRSN_TBL FOREIGN KEY (REG_VRSN_ID) REFERENCES HSR_VRSN_TBL(HSR_VRSN_ID)
);

-- @SEQUENCE
-- RELATIONSHIP SEQUENCE
CREATE SEQUENCE PSN_RLTNSHP_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
-- PERSONAL RELATIONSHIP TABLE
-- 
-- PURPOSE: STORES THE RELATIONSHIPS THAT ONE PERSON HAS WITH ANOTHER
--
CREATE TABLE PSN_RLTNSHP_TBL
(
	RLTNSHP_ID	DECIMAL(20,0) NOT NULL DEFAULT nextval('PSN_RLTNSHP_SEQ'), -- UNIQUE IDENTIFIER FOR THE RELATIONSHIP
	SRC_PSN_ID	DECIMAL(20,0) NOT NULL, -- IDENTIFIES THE SOURCE VERSION IDENTIFIER
	TRG_PSN_ID	DECIMAL(20,0) NOT NULL, -- IDENTIFIES THE TARGET OF THE RELATIONSHIP
	KIND_CS		VARCHAR(10) NOT NULL, -- IDENTIFIES THE TYPE OF RELATIONSHIP
	EFFT_VRSN_ID	DECIMAL(20,0) NOT NULL, -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME EFFECTIVE
	OBSLT_VRSN_ID	DECIMAL(20,0), -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME OBSOLETE
	CONSTRAINT PK_PSN_RLTNSHP_TBL PRIMARY KEY (RLTNSHP_ID),
	CONSTRAINT FK_PSN_RLTNSHP_SRC_PSN_TBL FOREIGN KEY (SRC_PSN_ID) REFERENCES PSN_TBL(PSN_ID),
	CONSTRAINT FK_PSN_RLTNSHP_TRG_PSN_TBL FOREIGN KEY (TRG_PSN_ID) REFERENCES PSN_TBL(PSN_ID),
	CONSTRAINT FK_PSN_RLTNSHP_EFFT_VRSN_TBL FOREIGN KEY (EFFT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID),
	CONSTRAINT FK_PSN_RLTNSHP_OBSLT_VRSN_TBL FOREIGN KEY (OBSLT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID)
);

-- @INDEX
-- LOOKUP RELATIONSHIP BY SOURCE PERSON
CREATE INDEX PSN_RLTNSHP_SRC_PSN_ID_IDX ON PSN_RLTNSHP_TBL(SRC_PSN_ID);
	
-- @SEQUENCE
-- ADDRESS COMPONENT TABLE IDENTIFIER SEQUENCE
CREATE SEQUENCE ADDR_CMP_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
-- ADDRESS SET TABLE
--
-- PURPOSE: THE ADDRESS SETS WILL HAVE COMMON DATA THAT APPLIES TO ALL COMPONENTS IN THE SET
--  	    THIS TABLE ENSURES THAT THIS DATA CAN BE STORED. USES THE SAME SEQUENCE AS THE COMPONENT
--
CREATE TABLE PSN_ADDR_SET_TBL
(
	ADDR_SET_ID	DECIMAL(20,0) NOT NULL DEFAULT nextval('ADDR_CMP_SEQ'), -- THE IDENTIFIER FOR THE SEQUENCE
	ADDR_SET_USE	VARCHAR(32) NOT NULL, -- THE PRIMARY USE OF THE ADDRESS
	PSN_ID		DECIMAL(20,0) NOT NULL, -- THE VERSION OF THE CLIENT RECORD TO WHICH THIS ADDRESS SET APPLIES
	EFFT_VRSN_ID	DECIMAL(20,0) NOT NULL, -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME EFFECTIVE
	OBSLT_VRSN_ID	DECIMAL(20,0), -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME OBSOLETE
	CONSTRAINT PK_ADDR_SET_TBL PRIMARY KEY (ADDR_SET_ID),
	CONSTRAINT FK_ADDR_SET_PSN_TBL FOREIGN KEY (PSN_ID) REFERENCES PSN_TBL(PSN_ID),
	CONSTRAINT FK_ADDR_SET_EFFT_VRSN_TBL FOREIGN KEY (EFFT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID),
	CONSTRAINT FK_ADDR_SET_OBSLT_VRSN_TBL FOREIGN KEY (OBSLT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID)
);

-- @INDEX
-- LOOKUP ADDRESS SET BY PERSON ID
CREATE INDEX PSN_ADDR_SET_PSN_ID_IDX ON PSN_ADDR_SET_TBL(PSN_ID);

-- @TABLE
-- THE ADDRESS COMPONENT TABLE
--
-- PURPOSE: THE ADDRESS COMPONENT TABLE ALLOWS ADDRESSES TO BE STORED IN A COMPONENTIZED WAY. EACH ADDRESS CAN 
--	    BE MADE UP OF DIFFERENT COMPONENTS AND CAN BE LINKED TOGETHER IN AN ADDRESS SET
--
CREATE TABLE ADDR_CMP_TBL
(
	ADDR_CMP_ID	DECIMAL(20,0) NOT NULL DEFAULT nextval('ADDR_CMP_SEQ'), -- THE ADDRESS COMPONENT ID
	ADDR_CMP_CLS	DECIMAL(4) NOT NULL DEFAULT 1, -- THE ADDRESS COMPONENT CLASSIFICATION TYPE
	ADDR_CMP_VALUE	VARCHAR(255) NOT NULL, -- THE VALUE OF THE ADDRESS COMPONENT
	ADDR_SET_ID	DECIMAL(20,0), -- USED TO CORRELATE ONE OR MORE ADDRESS COMPONENTS INTO A SET
	CONSTRAINT PK_ADDR_CMP_TBL PRIMARY KEY (ADDR_CMP_ID)
);

-- @INDEX
-- LOOKUP BY ADDRESS SET
CREATE INDEX ADDR_CMP_TBML_ADDR_SET_ID_IDX ON ADDR_CMP_TBL(ADDR_SET_ID);

-- @INDEX
-- LOOKUP ADDRESS COMPONENT BY VALUE
CREATE INDEX ADDR_CMP_VALUE_ID ON ADDR_CMP_TBL(ADDR_CMP_VALUE);


-- @VIEW
-- PERSON ADDRESS SET VIEW
CREATE OR REPLACE VIEW PSN_ADDR_SET_VW AS
	SELECT A.PSN_ID, A.ADDR_SET_ID, A.ADDR_SET_USE, A.EFFT_VRSN_ID, A.OBSLT_VRSN_ID, B.ADDR_CMP_ID, B.ADDR_CMP_CLS, B.ADDR_CMP_VALUE
	FROM PSN_ADDR_SET_TBL A NATURAL JOIN ADDR_CMP_TBL B;

-- @SEQUENCE
-- THE NAME COMPONENT TABLE IDENTIFIER
CREATE SEQUENCE NAME_CMP_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
-- NAME SET TABLE
--
-- PURPOSE: THE NAME SETS WILL HAVE COMMON DATA THAT APPLIES TO ALL COMPONENTS IN THE SET
--  	    THIS TABLE ENSURES THAT THIS DATA CAN BE STORED. USES THE SAME SEQUENCE AS THE COMPONENT
--
CREATE TABLE PSN_NAME_SET_TBL
(
	NAME_SET_ID	DECIMAL(20,0) NOT NULL DEFAULT nextval('NAME_CMP_SEQ'), -- THE IDENTIFIER FOR THE SEQUENCE
	NAME_SET_USE	VARCHAR(32) NOT NULL, -- THE PRIMARY USE OF THE NAME
	PSN_ID		DECIMAL(20,0) NOT NULL, -- THE VERSION OF THE CLIENT RECORD TO WHICH THIS ADDRESS SET APPLIES
	EFFT_VRSN_ID	DECIMAL(20,0) NOT NULL, -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME EFFECTIVE
	OBSLT_VRSN_ID	DECIMAL(20,0), -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME OBSOLETE
	CONSTRAINT PK_NAME_SET_TBL PRIMARY KEY (NAME_SET_ID),
	CONSTRAINT FK_NAME_SET_PSN_TBL FOREIGN KEY (PSN_ID) REFERENCES PSN_TBL(PSN_ID),
	CONSTRAINT FK_NAME_SET_EFFT_VRSN_TBL FOREIGN KEY (EFFT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID),
	CONSTRAINT FK_NAME_SET_OBSLT_VRSN_TBL FOREIGN KEY (OBSLT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID)
);

-- @INDEX
-- LOOKUP NAME SET BY PERSON ID
CREATE INDEX PSN_NAME_SET_PSN_ID_IDX ON PSN_NAME_SET_TBL(PSN_ID);

-- @TABLE
-- THE NAME COMPONENT TABLE
--
-- PURPOSE: THE NAME COMPONENT TABLE ALLOWS FOR THE STORAGE OF COMPLEX NAME COMPONENTS
--
CREATE TABLE NAME_CMP_TBL
(
	NAME_CMP_ID	DECIMAL(20, 0) NOT NULL DEFAULT nextval('NAME_CMP_TBL'), -- THE NAME COMPONENT ID
	NAME_CMP_CLS	DECIMAL(4) NOT NULL DEFAULT 1, -- THE NAME COMPONENT TYPE
	NAME_CMP_VALUE	VARCHAR(255) NOT NULL, -- THE VALUE OF THE NAME COMPONENT
	NAME_SET_ID	DECIMAL(20,0), -- USED TO CORRELATE ONE OR MORE NAME COMPONENTS TOGETHER
	CONSTRAINT PK_NAME_CMP_TBL PRIMARY KEY (NAME_CMP_ID)
);

-- @INDEX
-- LOOKUP BY NAME SET ID SHOULD BE INDEXED
CREATE INDEX NAME_CMP_TBL_NAME_SET_ID_IDX ON NAME_CMP_TBL(NAME_SET_ID);

-- @INDEX
-- LOOKUP NAME COMPONENT BY VALUE
CREATE INDEX NAME_CMP_VALUE_ID ON NAME_CMP_TBL(NAME_CMP_VALUE);

-- @VIEW
-- PERSON NAME SET VIEW
CREATE OR REPLACE VIEW PSN_NAME_SET_VW AS
	SELECT A.PSN_ID, A.NAME_SET_ID, A.NAME_SET_USE, A.EFFT_VRSN_ID, A.OBSLT_VRSN_ID, B.NAME_CMP_ID, B.NAME_CMP_CLS, B.NAME_CMP_VALUE
	FROM PSN_NAME_SET_TBL A NATURAL JOIN NAME_CMP_TBL B;

-- @SEQUENCE 
-- TELECOMMUNICATIONS ADDRESS SEQUENCE
CREATE SEQUENCE PSN_TEL_SEQ START WITH 1 INCREMENT BY 1;


-- @TABLE
-- TELECOMMUNICATIONS ADDRESS TABLE
-- 
-- PURPOSE: CONTAINS A LIST OF ALL TELECOMMUNICATIONS ADDRESSES THAT HAVE BEEN ENTERED BY THE USER
--
CREATE TABLE PSN_TEL_TBL
(
	TEL_ID		DECIMAL(20,0) NOT NULL DEFAULT nextval('PSN_TEL_SEQ'), -- UNIQUE IDENTIFIER FOR THE TELECOMMUNICATIONS ADDRESS
	TEL_VALUE	VARCHAR(255) NOT NULL, -- VALUE OF THE TELECOMMUNICATIONS ADDRESS
	TEL_USE		VARCHAR(32), -- THE VALID USES OF THE TELECOMMUNICATIONS ADDRESS
	TEL_CAP		VARCHAR(32), -- THE CAPABILITIES OF THE TELECOMMUNICATIONS DEVICE
	PSN_ID		DECIMAL(20,0) NOT NULL, -- THE VERSION OF THE CLIENT RECORD TO WHICH THIS TELECOMMUNICATIONS ADDRESS APPLIE
	EFFT_VRSN_ID	DECIMAL(20,0) NOT NULL, -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME EFFECTIVE
	OBSLT_VRSN_ID	DECIMAL(20,0), -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME OBSOLETE
	CONSTRAINT PK_TEL_TBL PRIMARY KEY (TEL_ID),
	CONSTRAINT FK_TEL_PSN_TBL FOREIGN KEY (PSN_ID) REFERENCES PSN_TBL(PSN_ID),
	CONSTRAINT FK_TEL_EFFT_VRSN_TBL FOREIGN KEY (EFFT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID),
	CONSTRAINT FK_TEL_OBSLT_VRSN_TBL FOREIGN KEY (OBSLT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID)
);

-- @SEQUENCE
-- UNIQUE IDENTIFIERS FOR THE MASKING INDICATORS
CREATE SEQUENCE PSN_MSK_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
-- PERSON MASKING TABLE
CREATE TABLE PSN_MSK_TBL
(
	MSK_ID		DECIMAL(20,0) NOT NULL DEFAULT nextval('PSN_MSK_SEQ'), -- UNIQUE IDENTIFIER FOR THE MASKING CODE
	MSK_CS		VARCHAR(2) NOT NULL DEFAULT 'N', -- HL7V3 X_VERYBASICCONFIDENTIALITYKIND
	PSN_ID		DECIMAL(20,0) NOT NULL,  -- THE PERSON TO WHICH THE MASK APPLIES
	EFFT_VRSN_ID	DECIMAL(20,0) NOT NULL,  -- THE EFFECTIVE VERSION OF THE MASK
	OBSLT_VRSN_ID	DECIMAL(20,0), -- THE VERSION THAT THE MASK IS OR WILL BECOME OBSOLETE
	CONSTRAINT PK_MSK_TBL PRIMARY KEY (MSK_ID), 
	CONSTRAINT FK_MSK_PSN_TBL FOREIGN KEY (PSN_ID) REFERENCES PSN_TBL(PSN_ID),
	CONSTRAINT FK_MSG_EFFT_VRSN_TBL FOREIGN KEY (EFFT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID),
	CONSTRAINT FK_MSK_OBSLT_VRSN_TBL FOREIGN KEY (OBSLT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID)
);

-- @INDEX
-- LOOKUP TELECOMMUNICATIONS ADDRESS BY VALUE
CREATE INDEX PSN_TEL_VALUE_IDX ON PSN_TEL_TBL(TEL_VALUE);

-- @INDEX
-- LOOKUP TELECOMMUNICATIONS ADDRESS BY PERSON
CREATE INDEX PSN_TEL_PSN_ID_IDX ON PSN_TEL_TBL(PSN_ID);

-- @TABLE
-- ALTERNATE IDENTIFIERS FOR THE PERSON
--
-- PURPOSE: STORES ALTERNATE KNOWN IDENTIFIERS FOR THE SPECIFIED PATIENT
--
CREATE TABLE PSN_ALT_ID_TBL
(
	ID_DOMAIN	VARCHAR(256) NOT NULL, -- DOMAIN OF THE ALTERNATE IDENTIFIER
	ID_VALUE	VARCHAR(256) NOT NULL, -- VALUE OF THE ALTERNATE IDENTIFIER
	PSN_ID		DECIMAL(20,0) NOT NULL, -- THE VERSION OF THE CLIENT RECORD TO WHICH THIS IDENTIFIER APPLIES
	IS_HCN		BOOLEAN NOT NULL DEFAULT TRUE, -- TRUE IF THE IDENTIFIER IS A HEALTHCARE IDENTIFIER
	ID_PURP_CD_ID	DECIMAL(20,0), -- IDENTIFIER PURPOSE
	EFFT_VRSN_ID	DECIMAL(20,0) NOT NULL, -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME EFFECTIVE
	OBSLT_VRSN_ID	DECIMAL(20,0), -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME OBSOLETE
	CONSTRAINT PK_PSN_ALT_ID_TBL PRIMARY KEY (ID_DOMAIN, ID_VALUE, PSN_ID),
	CONSTRAINT FK_PSN_ALT_ID_PSN_TBL FOREIGN KEY (PSN_ID) REFERENCES PSN_TBL(PSN_ID),
	CONSTRAINT FK_PSN_ALT_ID_EFFT_VRSN_TBL FOREIGN KEY (EFFT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID),
	CONSTRAINT FK_PSN_ALT_ID_OBSLT_VRSN_TBL FOREIGN KEY (OBSLT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID),
	CONSTRAINT FK_PSN_ALT_ID_PURP_CD_TBL FOREIGN KEY (ID_PURP_CD_ID) REFERENCES CD_TBL(CD_ID)
);

-- @INDEX
-- LOOKUP ALTERNATE IDENTIFIER BY PERSON ID
CREATE INDEX PSN_ALT_ID_PSN_ID_IDX ON PSN_ALT_ID_TBL(PSN_ID);

-- @SEQUENCE
-- SEQUENCE FOR THE LANGUAGE TABLE
CREATE SEQUENCE PSN_LANG_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE 
-- COMMUNICATION LANGUAGES BY THE PERSON
-- 
-- PURPOSE: STORES THE WRITTEN AND VERBAL LANGUAGES THAT CAN BE USED TO COMMUNICATE WITH THE PERSON
--
CREATE TABLE PSN_LANG_TBL
(
	LANG_ID		DECIMAL(20,0) NOT NULL DEFAULT nextval('PSN_LANG_SEQ'), -- UNIQUE IDENTIFIER FOR THE LANGUAGE COMMUNCIATIONS
	LANG_CS		VARCHAR(3) NOT NULL, -- THE ISO-639-2 CODE FOR THE LANGUAGE OF COMMUNICATION
	MODE_CS		DECIMAL(1) NOT NULL DEFAULT 3, -- THE MODE OF UNDERSTANDING (1 = WRITTEN, 2 = VERBAL, 4 = FLUENT)
	PSN_ID		DECIMAL(20,0) NOT NULL, -- THE VERSION OF THE CLIENT RECORD TO WHICH THIS LANGUAGE APPLIES
	EFFT_VRSN_ID	DECIMAL(20,0) NOT NULL, -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME EFFECTIVE
	OBSLT_VRSN_ID	DECIMAL(20,0), -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME OBSOLETE
	CONSTRAINT PK_PSN_LANG_TBL PRIMARY KEY (LANG_ID),
	CONSTRAINT FK_PSN_LANG_PSN_TBL FOREIGN KEY (PSN_ID) REFERENCES PSN_TBL(PSN_ID),
	CONSTRAINT FK_PSN_LANG_EFFT_VRSN_TBL FOREIGN KEY (EFFT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID),
	CONSTRAINT FK_PSN_LANG_OBSLT_VRSN_TBL FOREIGN KEY (OBSLT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID),
	CONSTRAINT CK_PSN_LANG_MODE_CS CHECK (MODE_CS > 0 AND MODE_CS < 8)
);

-- @INDEX
-- LOOKUP PERSON LANGUAGE BY PERSON
CREATE INDEX PSN_LANG_PSN_ID_IDX ON PSN_LANG_TBL(PSN_ID);

-- @TABLE 
-- PERSON RACE TABLE
-- 
-- PURPOSE: STORES THE REGISTERED RACE OF THE PERSON(S)
--
-- NOTE: A RACE IS TIED TO THE PERSON RATHER THAN THE VERSION OF THE PERSON RECORD THIS MEANS
--       THAT ONCE A PERSON HAS BEEN ASSIGNED A RACE AND THE RACE HAS BEEN OBSOLETED, THEY CAN NO 
-- 	 LONGER BE ASSIGNED THE RACE AGAIN
--
CREATE TABLE PSN_RACE_TBL
(
	PSN_ID		DECIMAL(20,0) NOT NULL, -- THE VERSION OF THE CLIENT RECORD TO WHICH THIS RACE APPLIES		
	RACE_CD_ID	DECIMAL(20,0) NOT NULL, -- THE RACE CODE FOR THE PERSON RECORD
	EFFT_VRSN_ID	DECIMAL(20,0) NOT NULL, -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME EFFECTIVE
	OBSLT_VRSN_ID	DECIMAL(20,0), -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME OBSOLETE
	CONSTRAINT PK_PSN_RACE_TBL PRIMARY KEY (PSN_ID, RACE_CD_ID),
	CONSTRAINT FK_PSN_RACE_PSN_TBL FOREIGN KEY (PSN_ID) REFERENCES PSN_TBL(PSN_ID),
	CONSTRAINT FK_PSN_RACE_EFFT_VRSN_TBL FOREIGN KEY (EFFT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID),
	CONSTRAINT FK_PSN_RACE_OBSLT_VRSN_TBL FOREIGN KEY (OBSLT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID)
);

-- @SEQUENCE
-- EXTENSIONS SEQUENCE
CREATE SEQUENCE EXT_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
-- EXTENSIONS TABLE
-- 
-- PURPOSE: STORES EXTENSIONS THAT THE CLIENT REGISTRY COULD NOT UNDERSTAND BUT MUST REPRODUCE
-- 	    THIS IS EITHER SERIALIZED XML/BINARY REPRESENTING THE TYPE IN THE CLIENT REGISTRY SOFTWARE
--	    THAT HAS TO BE REPRODUCED
--
CREATE TABLE EXT_TBL
(
	EXT_ID		DECIMAL(10,0) NOT NULL DEFAULT nextval('EXT_SEQ'), -- UNIQUE IDENTIFIER FOR THE EXTENSION
	EXT_REP		CHAR(3) NOT NULL DEFAULT 'BIN', -- REPRESENTATION OF THE EXTENSION DATA
	EXT_TYP		VARCHAR(255) NOT NULL, -- THE .NET CLI TYPE WHICH THIS EXTENSION REPRESENTS
	EXT_DATA	BYTEA NOT NULL, -- VALUE OF THE REPRESENTATION
	CONSTRAINT PK_EXT_TBL PRIMARY KEY(EXT_ID)
);

-- @TABLE
-- PERSON EXTENSIONS TABLE
--
-- PURPOSE: EXTENDS THE EXT_TBL TO CONTAIN EXTENSION WHICH APPLY TO PERSON(S)
--
CREATE TABLE PSN_EXT_TBL
(
	PSN_ID		DECIMAL(20,0) NOT NULL, -- THE VERSION OF THE PERSON RECORD THIS 
	EFFT_VRSN_ID	DECIMAL(20,0) NOT NULL, -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME EFFECTIVE
	OBSLT_VRSN_ID	DECIMAL(20,0), -- THE VERSION IDENTIFIER WHERE THIS DATA BECAME OBSOLETE
	CONSTRAINT FK_PSN_EXT_PSN_TBL FOREIGN KEY (PSN_ID) REFERENCES PSN_TBL(PSN_ID),
	CONSTRAINT FK_PSN_EXT_EFFT_VRSN_TBL FOREIGN KEY (EFFT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID),
	CONSTRAINT FK_PSN_EXT_OBSLT_VRSN_TBL FOREIGN KEY (OBSLT_VRSN_ID) REFERENCES PSN_VRSN_TBL(PSN_VRSN_ID)
) INHERITS(EXT_TBL);


-- @INDEX
-- HSR VERSION BY HSR_ID
CREATE INDEX HSR_VRSN_TBL_HSR_ID_IDX ON HSR_VRSN_TBL(HSR_ID);

	
-- @TABLE
-- THE HEALTH SERVICE RECORD LINKAGE TABLE
--
-- PURPOSE: THIS TABLE ALLOWS A VERSION OF A HEALTH SERVICE RECORD TO BE LINKED TO ANOTHER HEALTH
--	    SERVICE EVENT
--
CREATE TABLE HSR_LNK_TBL
(
	HSR_ID		DECIMAL(20,0) NOT NULL, -- THE IDENTIFIER OF THE VERSION THAT IS BEING LINKED
	CMP_HSR_ID	DECIMAL(20,0) NOT NULL, -- THE IDENTIFIER OF THE RECORD THAT IS BEING LINKED TO
	LNK_CLS		DECIMAL(8,0) NOT NULL, -- THE CLASSIFICATION OF THE LINK
	CONDUCTION	BOOLEAN NOT NULL DEFAULT TRUE, -- TRUE IF PARENT PROPERTIES (AUTHOR, ETC) SHOULD BE CONDUCTED TO CHILD
	CONSTRAINT PK_HSR_LNK_TBL PRIMARY KEY (HSR_ID, CMP_HSR_ID),
	CONSTRAINT FK_HSR_ID_HSR_TBL FOREIGN KEY (HSR_ID) REFERENCES HSR_TBL(HSR_ID),
	CONSTRAINT FK_CMP_HSR_ID_HSR_TBL FOREIGN KEY (CMP_HSR_ID) REFERENCES HSR_TBL(HSR_ID)
);

-- @INDEX
-- NEED THE LOOKUP ON HSR_LNK_TBL TO BE QUICK BASED ON THE VERSION ID
CREATE INDEX HSR_LNK_TBL_HSR_ID_IDX ON HSR_LNK_TBL(HSR_ID);


-- @SEQUENCE 
-- SERVICE DELIVERY LOCATION TABLE UNIQUE IDENTIFIER
CREATE SEQUENCE SDL_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
-- SERVICE DELIVERY LOCATION INFORMATION TABLE
--
-- PURPOSE: HOLDS A LOCAL "CACHE" COPY OF THE SERVICE DELIVERY LOCATIONS USED BY RECORD WITHIN THE SHARED HEALTH RECORD
--
CREATE TABLE SDL_TBL
(
	SDL_ID		DECIMAL(20,0) NOT NULL DEFAULT nextval('SDL_SEQ'), -- INTERNALLY GENERATED, LOCAL IDENTIFIER FOR THE SDL
	SDL_NAME	VARCHAR(255) NOT NULL,  -- THE NAME OF THE SDL
	SDL_ADDR_SET_ID	DECIMAL(20,0), -- THE AD SET ID THAT REPRESENTS THE ADDRESS OF THIS SDL
	SDL_TYP_CD_ID	DECIMAL(20,0), -- THE CD ID THAT REPRESENTS THE TYPE OF THIS SDL
	CONSTRAINT PK_SDL_TBL PRIMARY KEY (SDL_ID),
	--CONSTRAINT FK_SDL_ADDR_SET_ID_ADDR_TBL FOREIGN KEY (SDL_ADDR_SET_ID) REFERENCES ADDR_CMP_TBL(ADDR_SET_ID), CANT DO THIS AS AN ADDR SET ID ISNT UNIQUE
	CONSTRAINT FK_SDL_TYP_CD_ID_CD_TBL FOREIGN KEY (SDL_TYP_CD_ID) REFERENCES CD_TBL(CD_ID)
);

-- @TABLE 
-- SERVICE DELIVERY LOCATION ALTERNATIVE IDENTIFIERS
--
-- PURPOSE: THE INTERNAL 20 DIGIT NUMBER FOR THE SERVICE DELIVERY LOCATION IDENTIFIER IS AN INTERNAL IDENTIFIER ISSUED BY THE
-- 	    SHARED HEALTH RECORD. IN ORDER TO LINK THIS TO IDENTIFIERS OUTSIDE OF THE SHARED HEALTH RECORD WE NEED TO 
--	    STORE DOMAIN SPECIFIC IDENTIFIERS FOR EACH LOCATION.
--
CREATE TABLE SDL_ALT_ID_TBL
(
	SDL_ID		DECIMAL(20,0) NOT NULL, -- THE INTERNAL IDENTIFIER OF THE SDL THIS ALT ID BELONGS TO
	ALT_ID_DOMAIN	VARCHAR(48) NOT NULL, -- AN OID REPRESENTING THE DOMAIN FROM WHICH THE ALTERNATIVE IDENTIFIER BELONGS
	ALT_ID		VARCHAR(255) NOT NULL, -- THE IDENTIFIER OF THE SDL WITHIN THE ALTERNATE DOMAIN
	CONSTRAINT PK_SDL_ALT_ID_TBL PRIMARY KEY (SDL_ID, ALT_ID_DOMAIN),
	CONSTRAINT FK_SDL_ID_SDL_TBL FOREIGN KEY (SDL_ID) REFERENCES SDL_TBL(SDL_ID)
);

-- @INDEX
-- NEED TO BE ABLE TO RESOLVE FROM A ID_DOMAIN+ID PAIR QUICKLY
CREATE UNIQUE INDEX SDL_ALT_ID_TBL_ALT_ID_IDX ON SDL_ALT_ID_TBL(ALT_ID_DOMAIN,ALT_ID);

-- @INDEX
-- NEED TO BE ABLE TO QUERY FROM SDL_ID QUICKLY
CREATE INDEX SDL_ALT_ID_TBL_SDL_ID_IDX ON SDL_TBL(SDL_ID);

-- @TABLE
-- SERVICE DELIVERY LOCATION TO HEALTH SERVICE RECORD ASSOCIATIVE TABLE
--
-- PURPOSE: ALLOWS THE LINKING OF ONE ORE MORE SERVICE DELIVERY LOCATIONS TO ONE OR MORE HEALTH SERVICE RECORDS
--
CREATE TABLE HSR_SDL_TBL
(
	HSR_ID	DECIMAL(20,0) NOT NULL, -- IDENTIFIES THE HEALTH SERVICE RECORD TO WHICH THIS SDL ASSOC IS BOUND
	SDL_ID		DECIMAL(20,0) NOT NULL, -- IDENTIFIES THE SERVICE DELIVERY LOCATION TO WHICH THIS ASSOC IS BOUND
	SDL_CLS		DECIMAL(8) NOT NULL, -- IDENTIFIES THE CLASSIFICATION (OR HOW) OF THE ROLE LINK
	CONSTRAINT PK_HSR_SDL_TBL PRIMARY KEY (HSR_ID, SDL_ID, SDL_CLS),
	CONSTRAINT FK_HSR_ID_HSR_TBL FOREIGN KEY (HSR_ID) REFERENCES HSR_TBL(HSR_ID),
	CONSTRAINT FK_SDL_ID_SDL_TBL FOREIGN KEY (SDL_ID) REFERENCES SDL_TBL(SDL_ID)
);



-- @SEQUENCE
-- HEALTH CARE PARTICIPANT IDENTIFIER SEQUENCE
CREATE SEQUENCE HC_PTCPT_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
-- HEALTHCARE PARTICIPANT TABLE 
--
-- PURPOSE: STORES LOCAL DEMOGRAPHIC VERSION RELATED TO PROVIDERS THAT PERFORM ACTS
--
CREATE TABLE HC_PTCPT_TBL
(
	PTCPT_ID		DECIMAL(20,0) NOT NULL DEFAULT nextval('HC_PTCPT_SEQ'), -- THE IDENTIFIER FOR THE 
	PTCPT_CLS_CS		CHAR(4) NOT NULL, -- CLASSIFIES THE TYPE OF PARTICIPANT
	PTCPT_TYP_CD_ID		DECIMAL(20,0), -- LINKS TO THE CODE THAT DESCRIBES THE PARTICIPANT TYPE
	PTCPT_ADDR_SET_ID	DECIMAL(20,0), -- LINKS TO THE ADDRESS SET THAT REPRESENTS THE LEGAL ADDRESS OF THE PARTICIPANT
	PTCPT_NAME_SET_ID	DECIMAL(20,0), -- LINKS TO THE NAME SET THAT REPRESENTS THE LEGAL NAME OF THE PARTICIPANT
	CONSTRAINT PK_HC_PTCPT_TBL PRIMARY KEY (PTCPT_ID), 
	CONSTRAINT FK_PTCPT_TYPE_CD_ID FOREIGN KEY (PTCPT_TYP_CD_ID) REFERENCES CD_TBL(CD_ID)
);

-- @TABLE
-- HEALTHCARE SERVICE RECORD TO HEALTHCARE PARTICIPANT TABLE ASSOCIATION
--
-- PURPOSE: LINKS ONE OR MORE HEALTH CARE PARTICIPANTS TO A VERSION OF A HEALTHCARE SERVICE RECORD
--
CREATE TABLE HSR_HC_PTCPT_TBL
(
	HSR_ID	 DECIMAL(20,0) NOT NULL, -- THE HEALTH SERVICES EVENT THAT IS BEING LINKED TO
	PTCPT_ID	 DECIMAL(20,0) NOT NULL, -- THE PARTICIPANT ID THAT IS BEING LINKED
	PTCPT_CLS	 DECIMAL(8) NOT NULL, -- IDENTIFIES HOW THE PARTICIPANT IS INVOLVED IN THE EVENT
	PTCPT_REP_ORG_ID DECIMAL(20,0), -- LINKS TO THE PARTICIPANT ORGANIZATION THAT THIS PARTICIPANT REPRESENTS
	CONSTRAINT PK_HSR_HC_PTCPT_TBL PRIMARY KEY(HSR_ID, PTCPT_ID, PTCPT_CLS), 
	CONSTRAINT FK_HSR_ID_HSR_TBL FOREIGN KEY (HSR_ID) REFERENCES HSR_TBL(HSR_ID),
	CONSTRAINT FK_PTCPT_ID_HC_PTCPT_TBL FOREIGN KEY (PTCPT_ID) REFERENCES HC_PTCPT_TBL(PTCPT_ID),
	CONSTRAINT FK_PTCPT_REP_ORG_ID FOREIGN KEY (PTCPT_REP_ORG_ID) REFERENCES HC_PTCPT_TBL(PTCPT_ID)
);

-- @INDEX
-- LOOKUP BY HEALTH SERVICE RECORD ID NEEDS TO BE INDEXED
CREATE INDEX HSR_HC_PTCPT_TBL_HSR_ID_IDX ON HSR_HC_PTCPT_TBL(HSR_ID);

-- @INDEX
-- LOOKUP BY HEALTHCARE PARTICIPANT NEEDS TO BE INDEXED
CREATE INDEX HSR_HC_PTCPT_TBL_PTCPT_ID ON HC_PTCPT_TBL(PTCPT_ID);

-- @INDEX
-- LOOKUP BY HEALTHCARE ORIGINAL IDENTIFIER
CREATE INDEX HSR_HC_PTCPT_TBL_PTCPT_HSR_CLS_IDX ON HSR_HC_PTCPT_TBL(HSR_ID, PTCPT_ID, PTCPT_CLS);


-- @TABLE
-- HEALTHCARE SERVICE RECORD TO HEALTHCARE PARTICIPANT TABLE ORIGINAL IDENTIFICATION ASSOCIATION
-- 
-- PURPOSE: LINKS ONE OR MORE ORIGINAL IDENTIFIERS TO A HSR_HC_PTCPT_TBL ASSOCIATION
--
CREATE TABLE HSR_HC_PTCPT_ORIG_ID_TBL
(
	HSR_ID	DECIMAL(20,0) NOT NULL,
	PTCPT_ID	DECIMAL(20,0) NOT NULL,
	PTCPT_CLS	DECIMAL(8) NOT NULL,
	ORIG_ID_DOMAIN	VARCHAR(48) NOT NULL,
	ORIG_ID		VARCHAR(48) NOT NULL,
	LICENSE_IND	BOOLEAN NOT NULL DEFAULT FALSE,
	CONSTRAINT PK_HSR_HC_PTCPT_ORIG_ID_TBL PRIMARY KEY (HSR_ID, PTCPT_ID, PTCPT_CLS, ORIG_ID_DOMAIN, ORIG_ID),
	CONSTRAINT FK_HSR_HC_PTCPT_ORIG_ID_HSR_HC_PTCPT_TBL FOREIGN KEY (HSR_ID, PTCPT_ID, PTCPT_CLS) REFERENCES HSR_HC_PTCPT_TBL(HSR_ID, PTCPT_ID, PTCPT_CLS)
);

-- @INDEX
-- LOOKUPS BY PARTICIPANT LINK MUST BE INDEXED
CREATE INDEX HSR_HC_PTCPT_ORIG_ID_IDX ON HSR_HC_PTCPT_ORIG_ID_TBL(HSR_ID, PTCPT_ID, PTCPT_CLS);

-- @SEQUENCE
-- SURROGATE KEY GENERATOR FOR HEALTHCARE PARTICIPANT TELECOM ID
CREATE SEQUENCE HC_PTCPT_TEL_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
-- HEALTHCARE PARTICIPANT TELECOMMUNICATIONS ADDRESS TABLE
--
-- PURPOSE: USED TO LINK ONE OR MORE TELECOMMUNICATIONS ADDRESSES (EMAIL, TELEPHONE, ETC...) TO A
--	    HEALTHCARE PROVIDER
--
CREATE TABLE HC_PTCPT_TEL_TBL
(
	TEL_ID		DECIMAL(20,0) NOT NULL DEFAULT nextval('HC_PTCPT_TEL_SEQ'), -- UNIQUELY IDENTIFIES THIS TELECOMMUNICATIONS ADDRESS
	TEL_USE		VARCHAR(4) NOT NULL, -- IDENTIFIES HOW THE TELECOMMUNICATIONS ADDRESS IS TO BE USED
	PTCPT_ID	DECIMAL(20,0) NOT NULL, -- IDENTIFIE THE PARTICIPANT THAT USES THIS TELECOMMUNICATIONS ADDRESS
	TEL_VALUE	VARCHAR(255) NOT NULL, -- IDENTIFIES THE ACTUAL TELECOMMUNICATIONS ADDRESS
	CONSTRAINT PK_HC_PTCPT_TEL_TBL PRIMARY KEY (TEL_ID),
	CONSTRAINT FK_PTCPT_ID_PTCPT_TBL FOREIGN KEY (PTCPT_ID) REFERENCES HC_PTCPT_TBL(PTCPT_ID)
);

-- @TABLE
-- HEALTHCARE PARTICIPANT ALTERNATE IDENTIFIERS TABLE
--
-- PURPOSE: USED TO LINK ONE OR MORE EXTERNAL IDENTIFIES TO A HEALTHCARE PARTICIPANT
--
CREATE TABLE HC_PTCPT_ALT_ID_TBL
(
	ALT_ID_DOMAIN	VARCHAR(48) NOT NULL,
	PTCPT_ID	DECIMAL(20,0) NOT NULL,
	ALT_ID		VARCHAR(48) NOT NULL,
	CONSTRAINT PK_HC_PTCPT_ALT_ID_TBL PRIMARY KEY (ALT_ID_DOMAIN, PTCPT_ID),
	CONSTRAINT FK_PTCPT_ID_HC_PTCPT_TBL FOREIGN KEY (PTCPT_ID) REFERENCES HC_PTCPT_TBL(PTCPT_ID)
);

-- @INDEX 
-- ALTERNATE IDENTIFIER LOOKUPS BY ALT ID NEED TO BE INDEXED
CREATE UNIQUE INDEX HC_PTCPT_ALT_ID_TBL_ALT_ID_IDX ON HC_PTCPT_ALT_ID_TBL(ALT_ID_DOMAIN,ALT_ID);


-- @INDEX
-- ALTERNATE IDENTIFIER LOOKUPS BY PARTICIPANT ID NEED TO BE INDEXED
CREATE INDEX HC_PTCPT_ALT_ID_TBL_PTCPT_ID_IDX ON HC_PTCPT_ALT_ID_TBL(PTCPT_ID);

-- @VIEW
-- HEALTHCARE PARTICIPANT VIEW
CREATE VIEW HSR_HC_PTCPT_VW AS
	SELECT HSR_HC_PTCPT_TBL.HSR_ID, PTCPT_ID, PTCPT_CLS, PTCPT_REP_ORG_ID, ORIG_ID_DOMAIN, ORIG_ID, LICENSE_IND
	FROM HSR_HC_PTCPT_TBL NATURAL JOIN HSR_HC_PTCPT_ORIG_ID_TBL;

-- @VIEW
-- SERVICE DELIVERY LOCATION VIEW
CREATE VIEW HSR_SDL_VW AS
	SELECT HSR_SDL_TBL.HSR_ID, SDL_CLS, SDL_TBL.SDL_ID, SDL_NAME, SDL_ADDR_SET_ID, SDL_TYP_CD_ID
	FROM HSR_SDL_TBL INNER JOIN SDL_TBL USING (SDL_ID);

-- @VIEW
-- HEALTH SERVICES RECORD LATEST VERSION VIEW
CREATE VIEW HSR_LTST_CRNT_VRSN_VW AS
	SELECT DISTINCT ON (HSR_TBL.HSR_ID) HSR_VRSN_TBL.*, HSR_TBL.HSR_CLS
	FROM HSR_TBL LEFT JOIN HSR_VRSN_TBL USING (HSR_ID) 
	ORDER BY HSR_TBL.HSR_ID, CRTN_UTC DESC;

-- @VIEW
-- HEALTH SERVICES RECORD ALL VERSIONS VIEW
CREATE VIEW HSR_VW AS
	SELECT HSR_VRSN_TBL.*, HSR_TBL.HSR_CLS
	FROM HSR_TBL LEFT JOIN HSR_VRSN_TBL USING(HSR_ID) 
	ORDER BY HSR_TBL.HSR_ID, CRTN_UTC DESC;
-- @SEQUENCE
-- COMPONENT SEQUENCE
CREATE SEQUENCE CMP_SEQ START WITH 1 INCREMENT BY 1;

-- @TABLE
-- HEALTH SERVICE RECORD COMPONENTS TABLE
--
-- PURPOSE: KEEPS TRACK OF ALL THE COMPONENTS A PARTICULAR HSR_VERSION HAS
--
CREATE TABLE CMP_TBL
(
	CMP_ID		DECIMAL(20,0) NOT NULL DEFAULT nextval('cmp_seq'),
	CNTR_TYP	VARCHAR(255) NOT NULL,
	CNTR_TBL_ID	DECIMAL(20,0) NOT NULL,
	CNTR_VRSN_ID	DECIMAL(20,0),
	CMP_TYP		VARCHAR(255) NOT NULL,
	CMP_TBL_ID	DECIMAL(20,0) NOT NULL,
	CMP_VRSN_ID	DECIMAL(20,0), 
	CMP_ROL_TYP	DECIMAL(8,0) NOT NULL,
	CONSTRAINT PK_HSR_CMP_TBL PRIMARY KEY (CMP_ID)
);

-- @INDEX
-- LOOKUP COMPONENT BY VERSION ID SHOULD BE INDEXED
CREATE INDEX CMP_CNTR_IDX ON CMP_TBL(CNTR_TBL_ID);

-- @INDEX
-- LOOKUP COMPONENT BY COMPONENT IDENTIFIER
CREATE INDEX CMP_CMP_IDX ON CMP_TBL(CMP_TBL_ID);