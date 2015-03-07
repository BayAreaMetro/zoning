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