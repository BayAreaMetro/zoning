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