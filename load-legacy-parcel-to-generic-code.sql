--load the best candidate csv of zoning data by parcel

CREATE TABLE zoning.parcels03_19_12 (
id integer,
zoning integer,
joinnuma integer
);

COPY zoning.parcels03_19_12 FROM '/zoning_data/geography_zoning_parcel_relation_3_19.txt' WITH (FORMAT csv, DELIMITER E'\t', HEADER TRUE);

--create authoritative parcel data table

CREATE TABLE zoning.parcels_auth 
AS SELECT a.joinnuma,a.zoning_id 
FROM (SELECT joinnuma, zoning 
	as zoning_id 
	FROM zoning.parcels03_19_2012) 
	as a;

---load the missing berkeley and richmond data

CREATE TEMP TABLE tmp_x (joinnuma integer, zoningid integer);

COPY tmp_x FROM '/zoning_data/csv_process/ParcelUpdateMay21BerkeleyDowntownZoning.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

ALTER TABLE tmp_x ALTER COLUMN joinnuma TYPE int USING joinnuma::int;
ALTER TABLE tmp_x ALTER COLUMN zoneid TYPE int USING zoneid::int;

INSERT INTO zoning.parcels_auth (joinnuma,zoning_id)
SELECT tmp_x.joinnuma as joinnuma, tmp_x.zoningid as zoning_id
FROM tmp_x;

DROP TEMP TABLE tmp_x;

CREATE TEMP TABLE tmp_x (joinnuma integer, zoningid integer);

COPY tmp_x FROM '/zoning_data/csv_process/ParcelUpdateMay21RichmondZoning.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

ALTER TABLE tmp_x ALTER COLUMN joinnuma TYPE int USING joinnuma::int;
ALTER TABLE tmp_x ALTER COLUMN zoneid TYPE int USING zoneid::int;

INSERT INTO zoning.parcels_auth (joinnuma,zoning_id)
SELECT tmp_x.joinnuma as joinnuma, tmp_x.zoningid as zoning_id
FROM tmp_x;

CREATE TABLE zoning.auth_geo AS
SELECT p2.joinnuma, p1.zoning_id, p2.geom
FROM zoning.parcels_auth as p1
    RIGHT JOIN public.parcels_mpg as p2 ON p1.joinnuma = p2.joinnuma;

CREATE INDEX parcel_auth_geo_idx ON zoning.parcel_auth_geo USING GIST (geom);

ALTER TABLE zoning.auth_geo ADD COLUMN id INTEGER;
CREATE SEQUENCE zoning_auth_geo_id_seq;
UPDATE zoning.auth_geo  SET id = nextval('zoning_auth_geo_id_seq');
ALTER TABLE zoning.auth_geo ALTER COLUMN id SET DEFAULT nextval('zoning_auth_geo_id_seq');
ALTER TABLE zoning.auth_geo ALTER COLUMN id SET NOT NULL;
ALTER TABLE zoning.auth_geo ADD PRIMARY KEY (id);

----- Load legacy code to generic type and information lookup table

CREATE TABLE zoning.codes_base2012 (
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

COPY zoning.codes_base2012 FROM '/zoning_data/zoning_codes_base2012.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

UPDATE zoning.codes_base2012 SET HS = case when HS = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET HT = case when HT = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET HM = case when HM = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET of = case when of = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET HO = case when HO = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET SC = case when SC = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET IL = case when IL = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET IW = case when IW = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET IH = case when IH = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET RS = case when RS = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET RB = case when RB = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET MR = case when MR = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET MT = case when MT = 'x' then 'TRUE' else 'FALSE' end;
UPDATE zoning.codes_base2012 SET ME = case when ME = 'x' then 'TRUE' else 'FALSE' end;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN HS TYPE BOOLEAN USING HS::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN HT TYPE BOOLEAN USING HT::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN HM TYPE BOOLEAN USING HM::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN of TYPE BOOLEAN USING of::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN HO TYPE BOOLEAN USING HO::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN SC TYPE BOOLEAN USING SC::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN IL TYPE BOOLEAN USING IL::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN IW TYPE BOOLEAN USING IW::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN IH TYPE BOOLEAN USING IH::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN RS TYPE BOOLEAN USING RS::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN RB TYPE BOOLEAN USING RB::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN MR TYPE BOOLEAN USING MR::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN MT TYPE BOOLEAN USING MT::BOOLEAN;
ALTER TABLE zoning.codes_base2012 ALTER COLUMN ME TYPE BOOLEAN USING ME::BOOLEAN;
