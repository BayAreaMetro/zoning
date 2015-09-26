DROP TABLE IF EXISTS zoning.codes_dictionary;
CREATE TABLE zoning.codes_dictionary (
	id integer,
	juris integer, 
	city text, 
	name text, 
	max_far numeric(10,3), 
	max_height numeric(20,3),
	max_dua numeric(10,3),
	max_du_per_parcel numeric(40,3),
	HS text,
	HT text, 
	HM text, 
	of text, 
	HO text, 
	SC text, 
	IL text, 
	IW text, 
	IH text, 
	RS text, 
	RB text, 
	MR text, 
	MT text, 
	ME text 
);

\COPY zoning.codes_dictionary FROM 'zoning_lookup.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

UPDATE zoning.codes_dictionary SET HS = case when HS = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET HT = case when HT = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET HM = case when HM = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET of = case when of = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET HO = case when HO = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET SC = case when SC = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET IL = case when IL = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET IW = case when IW = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET IH = case when IH = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET RS = case when RS = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET RB = case when RB = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET MR = case when MR = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET MT = case when MT = '' then '0' else '1' end;
UPDATE zoning.codes_dictionary SET ME = case when ME = '' then '0' else '1' end;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN HS TYPE INTEGER USING HS::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN HT TYPE INTEGER USING HT::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN HM TYPE INTEGER USING HM::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN of TYPE INTEGER USING of::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN HO TYPE INTEGER USING HO::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN SC TYPE INTEGER USING SC::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN IL TYPE INTEGER USING IL::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN IW TYPE INTEGER USING IW::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN IH TYPE INTEGER USING IH::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN RS TYPE INTEGER USING RS::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN RB TYPE INTEGER USING RB::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN MR TYPE INTEGER USING MR::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN MT TYPE INTEGER USING MT::INTEGER;
ALTER TABLE zoning.codes_dictionary ALTER COLUMN ME TYPE INTEGER USING ME::INTEGER;