CREATE TABLE zoning.parcels319 (
id integer,
zoning integer,
parcel_id integer
);

COPY tmp_sample319 FROM '/zoning_data/geography_zoning_parcel_relation_3_19.txt' WITH (FORMAT csv, DELIMITER E'\t', HEADER TRUE);

CREATE VIEW zoning.parcels319_geo AS
SELECT p2.joinnuma, p1.parcel_id, p1.zoning, p2.geom,
FROM zoning.parcels319 as p1
    INNER JOIN public.parcels_mpg as p2 ON p1.parcel_id = p2.joinnuma;