CREATE TABLE zoning.parcel AS
SELECT geom_id, zoning_id, 100 AS prop, tablename
FROM zoning.parcel_intersection
WHERE geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count WHERE countof=1);

CREATE INDEX zoning_parcel_lookup_geom_idx ON zoning.parcel using hash (geom_id);
vacuum (analyze) zoning.parcel;

CREATE TABLE zoning.parcel_geo1 AS
SELECT z.*, p.geom
FROM zoning.parcel z, parcel p
WHERE p.geom_id = z.geom_id;
COMMENT ON TABLE zoning.parcel_geo1 is 'A geo-table of parcels with 1 intersection'

