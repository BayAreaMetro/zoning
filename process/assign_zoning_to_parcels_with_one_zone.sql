DROP TABLE IF EXISTS zoning.parcel;
CREATE TABLE zoning.parcel AS
SELECT geom_id, zoning_id, 100 AS prop, tablename
FROM zoning.parcel_intersection
WHERE geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count WHERE countof=1);

DROP INDEX IF EXISTS zoning_parcel_lookup_geom_idx;
CREATE INDEX zoning_parcel_lookup_geom_idx ON zoning.parcel using hash (geom_id);
vacuum (analyze) zoning.parcel;

CREATE TABLE zoning.parcel_geo1 AS
SELECT z.*, p.geom
FROM zoning.parcel z, parcel p
WHERE p.geom_id = z.geom_id;
COMMENT ON TABLE zoning.parcel_geo1 is 'A geo-table of parcels with 1 intersection'

DROP INDEX IF EXISTS zoning_parcel_geo1_gidx;
CREATE INDEX zoning_parcel_geo1_gidx ON zoning.parcel_geo1 using GIST (geom);
vacuum (analyze) zoning.parcel_geo1;

CREATE TABLE zoning.parcel_contested AS
SELECT *
FROM parcel
WHERE geom_id NOT IN (SELECT geom_id FROM zoning.parcel);
COMMENT ON TABLE zoning.parcel_contested is 'A geo-table of parcels with more than 1 intersection';

DROP INDEX IF EXISTS zoning_parcel_contested_gidx;
CREATE INDEX zoning_parcel_contested_gidx ON zoning.parcel_contested using GIST (geom);

vacuum (analyze) zoning.parcel_contested;
vacuum (analyze) zoning.parcel_geo1;