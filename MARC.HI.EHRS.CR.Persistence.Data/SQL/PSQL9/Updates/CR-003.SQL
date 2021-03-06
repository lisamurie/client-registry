﻿/**
 * CR-003 - BUG FIX FOR MERGE CANDIDATES
 */
ALTER TABLE HSR_MRG_CAND_TBL DROP CONSTRAINT PK_HSR_MRG_CAND_TBL;
ALTER TABLE HSR_MRG_CAND_TBL ADD CONSTRAINT PK_HSR_CAND_TBL PRIMARY KEY (hsr_id, EFFT_VRSN_ID, cand_hsr_id, CAND_VRSN_ID);
CREATE INDEX HSR_MRG_CAND_HSR_IDX ON HSR_MRG_CAND_TBL(HSR_ID, CAND_HSR_ID);

-- @FUNCTION
-- GET DATABASE SCHEMA VERSION
--
-- RETURNS: THE MAJOR, MINOR AND RELEASE NUMBER OF THE DATABASE SCHEMA
CREATE OR REPLACE FUNCTION GET_SCH_VER() RETURNS VARCHAR AS
$$
BEGIN
	RETURN '1.1.1.0';
END;
$$ LANGUAGE plpgsql;