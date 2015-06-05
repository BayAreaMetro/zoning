--FILL IN ZONING.PARCEL TABLE
-------
CREATE TABLE zoning.parcel_described AS
SELECT geom_id, zoning_id, 100 AS prop, 'one' as intersection_type
FROM zoning.parcel_intersection
WHERE geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count WHERE countof=1);

--same for 1 max, except insert those into the parcel table
INSERT INTO zoning.parcel_described
SELECT geom_id, zoning_id, prop, 'maxprop' as intersection_type FROM 
zoning.parcel_overlaps_maxonly where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.parcel_overlaps_maxonly
	GROUP BY geom_id
	) b
	WHERE b.countof=1
	);
--Query returned successfully: 390363 rows affected, 1634 ms execution time.

INSERT INTO zoning.parcel_described
SELECT z.geom_id, z.zoning_id, zo.prop, 'maxprop_cities' as intersection_type
FROM
zoning.parcel_overlaps_maxonly zo,
zoning.parcel_in_cities z
WHERE z.geom_id = zo.geom_id
AND zo.zoning_id = z.zoning_id;
--Query returned successfully: 45807 rows affected, 1129 ms execution time.

INSERT INTO zoning.parcel_described
SELECT z.geom_id, z.zoning_id, zo.prop, 'maxprop_counties' as intersection_type
FROM
zoning.parcel_overlaps_maxonly zo,
zoning.temp_parcel_county_table z
WHERE z.geom_id = zo.geom_id
AND zo.zoning_id = z.zoning_id;
--Query returned successfully: 24691 rows affected, 560 ms execution time.

create INDEX zoning_parcel_described_lookup_geom_idx ON zoning.parcel_described using hash (geom_id);

DROP TABLE zoning.parcel_described_geo;
CREATE TABLE zoning.parcel_described_geo AS
SELECT z.geom_id, cast(z.intersection_type as text), p.geom from
parcel p,
zoning.parcel_described z
WHERE p.geom_id=z.geom_id;

ALTER TABLE zoning.parcel_intersection_count_geo ADD primary key(geom_id);
