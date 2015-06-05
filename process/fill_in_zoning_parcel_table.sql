-------------------------------------------
-------------------------------------------
-------------------------------------------
-------------------------------------------
-------------------------------------------
-------------------------------------------
-------
--FILL IN ZONING.PARCEL TABLE
-------
CREATE TABLE zoning.parcel AS
SELECT geom_id, zoning_id, 100 AS prop
FROM zoning.parcel_intersection
WHERE geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count WHERE countof=1);

--same for 1 max, except insert those into the parcel table
INSERT INTO zoning.parcel
SELECT geom_id, zoning_id, prop FROM 
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

INSERT INTO zoning.parcel
SELECT z.geom_id, z.zoning_id, zo.prop
FROM
zoning.parcel_overlaps_maxonly zo,
zoning.parcel_in_cities z
WHERE z.geom_id = zo.geom_id
AND zo.zoning_id = z.zoning_id;
--Query returned successfully: 45807 rows affected, 1129 ms execution time.

INSERT INTO zoning.parcel
SELECT z.geom_id, z.zoning_id, zo.prop
FROM
zoning.parcel_overlaps_maxonly zo,
zoning.temp_parcel_county_table z
WHERE z.geom_id = zo.geom_id
AND zo.zoning_id = z.zoning_id;
--Query returned successfully: 24691 rows affected, 560 ms execution time.
