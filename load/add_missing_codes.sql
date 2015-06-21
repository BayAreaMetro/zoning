DROP TABLE IF EXISTS zoning.code_additions;
CREATE TABLE zoning.code_additions (
	id integer,
	juris integer, 
	city text, 
	name text, 
	min_far numeric(10,3), 
	max_far numeric(10,3), 
	max_height numeric(20,3),
	min_front_setback numeric(20,5),
	max_front_setback numeric(20,5),
	side_setback numeric(20,5),
	rear_setback numeric(20,5),
	min_dua numeric(10,3),
	max_dua numeric(10,3),
	coverage numeric(40,5),
	max_du_per_parcel numeric(40,3),
	min_lot_size numeric(40,4),
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

\COPY zoning.code_additions FROM 'zoning_codes_fix_add_missing_codes.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

UPDATE zoning.code_additions SET HS = case when HS = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET HT = case when HT = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET HM = case when HM = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET of = case when of = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET HO = case when HO = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET SC = case when SC = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET IL = case when IL = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET IW = case when IW = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET IH = case when IH = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET RS = case when RS = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET RB = case when RB = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET MR = case when MR = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET MT = case when MT = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.code_additions SET ME = case when ME = 'x' then 'TRUE' else 'FALSE' end;
ALTER TABLE zoning.code_additions ALTER COLUMN HS TYPE BOOLEAN USING HS::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN HT TYPE BOOLEAN USING HT::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN HM TYPE BOOLEAN USING HM::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN of TYPE BOOLEAN USING of::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN HO TYPE BOOLEAN USING HO::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN SC TYPE BOOLEAN USING SC::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN IL TYPE BOOLEAN USING IL::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN IW TYPE BOOLEAN USING IW::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN IH TYPE BOOLEAN USING IH::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN RS TYPE BOOLEAN USING RS::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN RB TYPE BOOLEAN USING RB::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN MR TYPE BOOLEAN USING MR::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN MT TYPE BOOLEAN USING MT::BOOLEAN;
ALTER TABLE zoning.code_additions ALTER COLUMN ME TYPE BOOLEAN USING ME::BOOLEAN;

ALTER TABLE zoning.code_additions ALTER COLUMN HS TYPE INTEGER USING HS::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN HT TYPE INTEGER USING HT::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN HM TYPE INTEGER USING HM::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN of TYPE INTEGER USING of::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN HO TYPE INTEGER USING HO::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN SC TYPE INTEGER USING SC::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN IL TYPE INTEGER USING IL::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN IW TYPE INTEGER USING IW::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN IH TYPE INTEGER USING IH::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN RS TYPE INTEGER USING RS::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN RB TYPE INTEGER USING RB::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN MR TYPE INTEGER USING MR::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN MT TYPE INTEGER USING MT::INTEGER;
ALTER TABLE zoning.code_additions ALTER COLUMN ME TYPE INTEGER USING ME::INTEGER;

INSERT INTO zoning.code_additions 
SELECT * from zoning.code_additions;