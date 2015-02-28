CREATE TABLE zoning.parcels03_29_2012 (
county text, 
city text, 
cityid integer, 
parcel_id integer, 
zoning text, 
zone_name text, 
min_far numeric(12,3), 
max_far numeric(12,3), 
max_height numeric(12,3), 
min_front_setback numeric(12,3), 
max_front_setback numeric(12,3), 
side_setback numeric(12,3), 
rear_setback numeric(12,3), 
min_dua numeric(12,3), 
max_dua numeric(12,3), 
coverage numeric(12,3), 
max_du_per_parcel numeric(12,3), 
min_lot_size numeric(12,3)
);

COPY zoning.parcels03_29_2012 FROM '/zoning_data/csv_process/q01ParcelZoning_3_29.csv' WITH (FORMAT csv, DELIMITER ',', HEADER TRUE);

CREATE TABLE zoning.parcels03_29_2012_geo AS
SELECT p2.joinnuma, p1.parcel_id, p1.zoning, p2.geom
FROM zoning.parcels03_29_2012 as p1
    INNER JOIN public.parcels_mpg as p2 ON p1.parcel_id = p2.joinnuma;

CREATE INDEX parcels03_29_2012_geo_idx ON zoning.parcels319_geo USING GIST (geom);