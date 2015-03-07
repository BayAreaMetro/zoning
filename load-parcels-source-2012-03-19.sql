--load the best candidate csv of zoning data by parcel

CREATE TABLE zoning.parcels03_19_12 (
id integer,
zoning integer,
parcel_id integer
);

COPY zoning.parcels03_19_12 FROM '/zoning_data/geography_zoning_parcel_relation_3_19.txt' WITH (FORMAT csv, DELIMITER E'\t', HEADER TRUE);

--create authoritative parcel data table

CREATE TABLE zoning.parcels_auth 
AS SELECT a.parcel_id,a.zoning_id 
FROM (SELECT parcel_id, zoning 
	as zoning_id 
	FROM zoning.parcels03_19_2012) 
	as a;

---load the missing berkeley and richmond data

CREATE TEMP TABLE tmp_x (joinnuma integer, zoningid integer);

COPY tmp_x FROM '/zoning_data/csv_process/ParcelUpdateMay21BerkeleyDowntownZoning.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

ALTER TABLE tmp_x ALTER COLUMN joinnuma TYPE int USING joinnuma::int;
ALTER TABLE tmp_x ALTER COLUMN zoneid TYPE int USING zoneid::int;

INSERT INTO zoning.parcels_auth (parcel_id,zoning_id)
SELECT tmp_x.joinnuma as parcel_id, tmp_x.zoningid as zoning_id
FROM tmp_x;

DROP TEMP TABLE tmp_x;

CREATE TEMP TABLE tmp_x (joinnuma integer, zoningid integer);

COPY tmp_x FROM '/zoning_data/csv_process/ParcelUpdateMay21RichmondZoning.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

ALTER TABLE tmp_x ALTER COLUMN joinnuma TYPE int USING joinnuma::int;
ALTER TABLE tmp_x ALTER COLUMN zoneid TYPE int USING zoneid::int;

INSERT INTO zoning.parcels_auth (parcel_id,zoning_id)
SELECT tmp_x.joinnuma as parcel_id, tmp_x.zoningid as zoning_id
FROM tmp_x;


/*THIS SHOULDN'T BE NECESSARY NOW
CREATE TABLE zoning.parcels03_19_geo AS
SELECT p2.joinnuma, p1.parcel_id, p1.zoning, p2.geom
FROM zoning.parcels319 as p1
    INNER JOIN public.parcels_mpg as p2 ON p1.parcel_id = p2.joinnuma;

CREATE INDEX parcels319_geo_idx ON zoning.parcels319_geo USING GIST (geom);*/