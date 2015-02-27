CREATE TABLE zoning.staging_richmondupdate521 (
joinnuma decimal,
zoneid decimal
);

COPY zoning.richmondupdate521 FROM '/zoning_data/ParcelUpdateMay21RichmondZoning.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

ALTER TABLE zoning.staging_richmondupdate521 ALTER COLUMN joinnuma TYPE int USING joinnuma::int;
ALTER TABLE zoning.staging_richmondupdate521 ALTER COLUMN zoneid TYPE int USING zoneid::int;

CREATE VIEW zoning.richmond_parcels_notin319 AS
SELECT p1.parcel_id, p2.joinnuma
FROM zoning.parcels319 as p1
    LEFT JOIN zoning.staging_richmondupdate521 as p2 ON p1.parcel_id = p2.joinnuma;

SELECT count(*) FROM zoning.richmond_parcels_notin319 WHERE joinnuma IS NULL;