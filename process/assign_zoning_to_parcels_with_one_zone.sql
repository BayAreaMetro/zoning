CREATE TABLE zoning.parcel AS
SELECT geom_id, zoning_id, 100 AS prop, tablename
FROM zoning.parcel_intersection
WHERE geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count WHERE countof=1);