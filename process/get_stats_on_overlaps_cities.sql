--select only those pairs of geom_id, zoning_id in which
--the proportion of overlap is the maximum
DROP TABLE IF EXISTS zoning.cities_parcel_overlaps_maxonly;
CREATE TABLE zoning.cities_parcel_overlaps_maxonly AS
SELECT geom_id, zoning_id, zoning, juris, prop, tablename
FROM zoning.cities_parcel_overlaps WHERE (geom_id,prop) IN 
( SELECT geom_id, MAX(prop)
  FROM zoning.cities_parcel_overlaps
  GROUP BY geom_id
);

--So, create table of parcels with >1 max values
DROP TABLE IF EXISTS zoning.cities_parcel_two_max;
CREATE TABLE zoning.cities_parcel_two_max AS
SELECT geom_id, zoning_id, zoning, juris, prop, tablename FROM 
zoning.cities_parcel_overlaps_maxonly where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.cities_parcel_overlaps_maxonly
	GROUP BY geom_id
	) b
	WHERE b.countof>1
	);
--Query returned successfully: 145309 rows affected, 817 ms execution time.

/*n
BELOW WE DEAL WITH THE PARCELS 
THAT ARE CLAIMED BY 2 (OR MORE) 
JURISDICTIONAL ZONING GEOMETRIES 
*/
