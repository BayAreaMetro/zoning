DROP TABLE IF EXISTS zoning_staging.codes_dictionary;
CREATE TABLE zoning_staging.codes_dictionary (
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

\COPY zoning_staging.codes_dictionary FROM 'data/zoning_lookup.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

UPDATE zoning_staging.codes_dictionary SET HS = case when HS = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET HT = case when HT = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET HM = case when HM = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET of = case when of = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET HO = case when HO = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET SC = case when SC = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET IL = case when IL = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET IW = case when IW = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET IH = case when IH = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET RS = case when RS = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET RB = case when RB = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET MR = case when MR = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET MT = case when MT = '' then '0' else '1' end;
UPDATE zoning_staging.codes_dictionary SET ME = case when ME = '' then '0' else '1' end;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN HS TYPE INTEGER USING HS::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN HT TYPE INTEGER USING HT::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN HM TYPE INTEGER USING HM::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN of TYPE INTEGER USING of::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN HO TYPE INTEGER USING HO::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN SC TYPE INTEGER USING SC::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN IL TYPE INTEGER USING IL::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN IW TYPE INTEGER USING IW::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN IH TYPE INTEGER USING IH::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN RS TYPE INTEGER USING RS::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN RB TYPE INTEGER USING RB::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN MR TYPE INTEGER USING MR::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN MT TYPE INTEGER USING MT::INTEGER;
ALTER TABLE zoning_staging.codes_dictionary ALTER COLUMN ME TYPE INTEGER USING ME::INTEGER;


DROP TABLE IF EXISTS zoning_staging.code_additions;
CREATE TABLE zoning_staging.code_additions (
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

\COPY zoning_staging.code_additions FROM 'data/zoning_codes_fix_add_missing_codes.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

UPDATE zoning_staging.code_additions SET HS = case when HS = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET HT = case when HT = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET HM = case when HM = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET of = case when of = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET HO = case when HO = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET SC = case when SC = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET IL = case when IL = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET IW = case when IW = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET IH = case when IH = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET RS = case when RS = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET RB = case when RB = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET MR = case when MR = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET MT = case when MT = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning_staging.code_additions SET ME = case when ME = 'x' then 'TRUE' else 'FALSE' end;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN HS TYPE BOOLEAN USING HS::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN HT TYPE BOOLEAN USING HT::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN HM TYPE BOOLEAN USING HM::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN of TYPE BOOLEAN USING of::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN HO TYPE BOOLEAN USING HO::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN SC TYPE BOOLEAN USING SC::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN IL TYPE BOOLEAN USING IL::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN IW TYPE BOOLEAN USING IW::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN IH TYPE BOOLEAN USING IH::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN RS TYPE BOOLEAN USING RS::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN RB TYPE BOOLEAN USING RB::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN MR TYPE BOOLEAN USING MR::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN MT TYPE BOOLEAN USING MT::BOOLEAN;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN ME TYPE BOOLEAN USING ME::BOOLEAN;

ALTER TABLE zoning_staging.code_additions ALTER COLUMN HS TYPE INTEGER USING HS::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN HT TYPE INTEGER USING HT::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN HM TYPE INTEGER USING HM::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN of TYPE INTEGER USING of::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN HO TYPE INTEGER USING HO::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN SC TYPE INTEGER USING SC::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN IL TYPE INTEGER USING IL::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN IW TYPE INTEGER USING IW::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN IH TYPE INTEGER USING IH::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN RS TYPE INTEGER USING RS::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN RB TYPE INTEGER USING RB::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN MR TYPE INTEGER USING MR::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN MT TYPE INTEGER USING MT::INTEGER;
ALTER TABLE zoning_staging.code_additions ALTER COLUMN ME TYPE INTEGER USING ME::INTEGER;

INSERT INTO zoning_staging.codes_dictionary
SELECT * from zoning_staging.code_additions;


DROP TABLE IF EXISTS zoning.codes_string_matching_fixes;
CREATE TABLE zoning.codes_string_matching_fixes (
	tablename text,
	old_name text,
	juris integer,
	missing_id integer,
	correct_name text
);

\COPY zoning.codes_string_matching_fixes FROM 'zoning_codes_fix_string_errors.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

CREATE TABLE zoning.codes_string_matching_fix_replacements as
SELECT c.id,
c.juris,
c.city,
nc.correct_name,
c.min_far,
c.max_far,
c.max_height,
c.min_front_setback,
c.max_front_setback,
c.side_setback,
c.rear_setback,
c.min_dua,
c.max_dua,
c.coverage,
c.max_du_per_parcel,
c.min_lot_size,
c.HS,
c.HT,
c.HM,
c.of,
c.HO,
c.SC,
c.IL,
c.IW,
c.IH,
c.RS,
c.RB,
c.MR,
c.MT,
c.ME
from
zoning.codes_string_matching_fixes nc,
zoning.codes_dictionary c
where c.name = nc.old_name;

select count(*) from zoning.codes_string_matching_fix_replacements;

DELETE FROM zoning.codes_dictionary
WHERE id in (select id from zoning.codes_string_matching_fix_replacements);

INSERT INTO zoning.codes_dictionary
SELECT * from zoning.codes_string_matching_fix_replacements;
