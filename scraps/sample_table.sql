CREATE TABLE zoning.parcels319 (
id integer,
zoning integer,
parcel_id integer
);

COPY tmp_sample319 FROM '/zoning_data/geography_zoning_parcel_relation_3_19.txt' WITH (FORMAT csv, DELIMITER E'\t', HEADER TRUE);