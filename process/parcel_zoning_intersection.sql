--fix GEOMS

--SET UP PARCELS, SELECT VALID GEOMS ONLY, PUT THEM IN EPSG USED FOR ZONING

ALTER TABLE parcel 
   ALTER COLUMN geom 
   TYPE Geometry(MultiPolygon, 26910) 
   USING ST_Transform(geom, 26910);

CREATE TABLE parcel_invalid AS
SELECT *
FROM parcel
WHERE ST_IsValid(geom) = false;

CREATE TABLE parcel_geometrycollection
AS
SELECT *
FROM parcel
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';
--returns 0 rows

DELETE FROM parcel
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';

DELETE FROM parcel 
WHERE ST_IsValid(geom) = false;

create INDEX parcel_geom_id_idx ON parcel using hash (geom_id);
CREATE INDEX parcel_gidx ON parcel USING GIST (geom);
VACUUM (ANALYZE) parcel;

CREATE TABLE zoning.bay_area AS
SELECT 
	ogc_fid, tablename, juris, zoning, ST_MakeValid(the_geom) geom
FROM
	zoning.merged_jurisdictions;

CREATE TABLE zoning.invalid AS
SELECT *
FROM zoning.bay_area
WHERE ST_IsValid(geom) = false;

DELETE FROM zoning.bay_area 
WHERE ST_IsValid(geom) = false;

CREATE TABLE zoning.geometry_collection
AS
SELECT *
FROM zoning.bay_area
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';
--returns 0 rows

DELETE FROM zoning.bay_area
WHERE GeometryType(geom) = 'GEOMETRYCOLLECTION';

CREATE TABLE zoning.bay_area_generic AS 
SELECT c.id as zoning_id, z.geom FROM
zoning.codes_dictionary c,
zoning.bay_area z
WHERE c.juris=z.juris 
AND c.name = z.zoning;

CREATE INDEX zoning_bay_area_generic_gidx ON zoning.bay_area_generic USING GIST (geom);
CREATE INDEX zoning_bay_area_zoning_id_gidx ON zoning.bay_area_generic USING HASH (zoning_id);
VACUUM (ANALYZE) zoning.bay_area_generic;

--IN THE FUTURE, THESE SHOULD JUST BE PART OF THE parcel table?
DROP TABLE IF EXISTS zoning.parcel_counties;
CREATE TABLE zoning.parcel_counties AS
SELECT county.name10 as countyname1, county.namelsad10 as countyname2, county.geoid10 countygeoid,p.geom_id, p.geom FROM
			county10_ca county,
			parcel p
			WHERE ST_Intersects(county.wkb_geometry, p.geom);
--Query returned successfully: 1954393 rows affected, 142212 ms execution time.

DROP INDEX IF EXISTS zoning_parcel_counties_gidx;
CREATE INDEX zoning_parcel_counties_geomid_idx ON zoning.parcel_counties using GIST (geom);
VACUUM (ANALYZE) zoning.parcel_counties;

DROP TABLE IF EXISTS zoning_parcel_counties_gidx;
CREATE TABLE zoning.parcel_cities_counties AS
SELECT city.name10 as cityname1, city.namelsad10 as cityname2, city.geoid10 citygeoid, p.geom_id
FROM 
city10_ba city,
zoning.parcel_counties p 
WHERE ST_Intersects(city.wkb_geometry, p.geom);

DROP INDEX IF EXISTS zoning_parcel_cities_counties_geomid_idx;
CREATE INDEX zoning_parcel_cities_counties_geomid_idx ON zoning.parcel_cities_counties using hash (geom_id);
DROP INDEX IF EXISTS zoning_codes_dictionary_idx;
CREATE INDEX zoning_parcel_cities_counties_cityname_idx ON zoning.parcel_cities_counties using hash (cityname1);
VACUUM (ANALYZE) zoning.parcel_cities_counties;

CREATE TABLE zoning.parcel_intersection AS
SELECT p.geom_id,z.zoning_id FROM
	(select zoning_id, geom from zoning.bay_area_generic) AS z, 
	(select geom_id, geom from parcel) AS p
WHERE p.geom && z.geom AND
ST_Intersects(p.geom,z.geom);

CREATE TABLE zoning.parcel_intersection_count AS
SELECT geom_id, count(*) as countof FROM
			zoning.parcel_intersection
			GROUP BY geom_id;

CREATE INDEX zoning_parcel_intersection_count ON zoning.parcel_intersection_count (countof);
VACUUM (ANALYZE) zoning.parcel_intersection_count;

DROP VIEW IF EXISTS zoning.parcels_with_multiple_zoning;
CREATE VIEW zoning.parcels_with_multiple_zoning AS
SELECT geom_id, geom from parcel where geom_id
IN (SELECT geom_id FROM zoning.parcel_intersection_count WHERE countof>1);
--Query returned successfully: 462655 rows affected, 6854 ms execution time.


/*CREATE INDEX z_parcels_with_multiple_zoning_gidx ON zoning.parcels_with_multiple_zoning USING GIST (geom);
VACUUM (ANALYZE) zoning.parcels_with_multiple_zoning;*/

CREATE TABLE zoning.parcel_overlaps AS
SELECT 
	geom_id,
	zoning_id,
	sum(ST_Area(geom)) area,
	round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
	ST_Union(geom) geom
FROM (
SELECT p.geom_id, 
	z.zoning_id, 
 	ST_Area(p.geom) parcelarea, 
 	ST_Intersection(p.geom, z.geom) geom 
FROM (select geom_id, geom FROM zoning.parcels_with_multiple_zoning) as p,
(select zoning_id, geom from zoning.bay_area_generic) as z
WHERE ST_Intersects(z.geom, p.geom)
) f
GROUP BY 
	geom_id,
	zoning_id;

CREATE INDEX zoning_parcel_overlaps_gidx ON zoning.parcel_overlaps USING GIST (geom);
CREATE INDEX zoning_parcel_overlaps_geom_id_idx ON zoning.parcel_overlaps USING hash (geom_id);
CREATE INDEX zoning_parcel_overlaps_zoning_id_idx ON zoning.parcel_overlaps USING hash (zoning_id);

ALTER TABLE zoning.parcel_overlaps ADD COLUMN id INTEGER;
CREATE SEQUENCE zoning_parcel_overlaps_id_seq;
UPDATE zoning.parcel_overlaps  SET id = nextval('zoning_parcel_overlaps_id_seq');
ALTER TABLE zoning.parcel_overlaps ALTER COLUMN id SET DEFAULT nextval('zoning_parcel_overlaps_id_seq');
ALTER TABLE zoning.parcel_overlaps ALTER COLUMN id SET NOT NULL;
ALTER TABLE zoning.parcel_overlaps ADD PRIMARY KEY (id);

VACUUM (ANALYZE) zoning.parcel_overlaps;

-- PRINT OUT A SUMMARY OF THE RESULTS OF PARCEL overlaps:
/*
select width_bucket(prop, 0, 100, 9), count(*)
    from zoning.parcel_overlaps
group by 1
order by 1;
*/

--select only those pairs of geom_id, zoning_id in which
--the proportion of overlap is the maximum
DROP VIEW IF EXISTS zoning.parcel_overlaps_maxonly;
CREATE TABLE zoning.parcel_overlaps_maxonly AS
SELECT geom_id, zoning_id, prop 
FROM zoning.parcel_overlaps WHERE (geom_id,prop) IN 
( SELECT geom_id, MAX(prop)
  FROM zoning.parcel_overlaps
  GROUP BY geom_id
);
--Query returned successfully: 535672 rows affected, 2268 ms execution time.
--Unfortunately, many parcels have 2 max values

--So, create table of parcels with >1 max values
DROP TABLE IF EXISTS zoning.parcel_two_max;
CREATE TABLE zoning.parcel_two_max AS
SELECT geom_id, zoning_id, prop FROM 
zoning.parcel_overlaps_maxonly where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.parcel_overlaps_maxonly
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

DROP INDEX IF EXISTS zoning_codes_dictionary_idx;
CREATE INDEX zoning_codes_dictionary_idx ON zoning.codes_dictionary using hash (id);
VACUUM (ANALYZE) zoning.codes_dictionary;

CREATE TABLE zoning.parcel_in_cities AS
SELECT p2n.geom_id, p2n.zoning_id 
FROM 
zoning.parcel_cities_counties pcc,
(SELECT c.city, p2.geom_id, p2.zoning_id 
FROM
zoning.codes_dictionary c,
zoning.parcel_two_max p2 --parcel_two_max is a twice derived view on zoning.parcel_overlaps
WHERE c.id = p2.zoning_id) p2n
WHERE p2n.geom_id = pcc.geom_id
AND pcc.cityname1 = p2n.city;
--Query returned successfully: 48928 rows affected, 3750 ms execution time.

CREATE TABLE zoning.parcel_in_cities_doubles AS 
SELECT geom_id
FROM
(SELECT geom_id, count(*) AS countof
FROM zoning.parcel_in_cities
GROUP BY geom_id) p
WHERE p.countof>1;

DELETE FROM zoning.parcel_in_cities WHERE geom_id IN
(
SELECT geom_id
FROM
(SELECT geom_id, count(*) AS countof
FROM zoning.parcel_in_cities
GROUP BY geom_id) p
WHERE p.countof>1);
--Query returned successfully: 3121 rows affected, 87 ms execution time.

CREATE INDEX zoning_parcel_two_max_zoningid_idx ON zoning.parcel_two_max USING hash (zoning_id);
CREATE INDEX zoning_parcel_two_max_geomid_idx ON zoning.parcel_two_max USING hash (geom_id);
VACUUM (ANALYZE) zoning.parcel_two_max;

CREATE TABLE zoning.parcel_two_max_geo AS
SELECT two.zoning_id,p.geom_id,two.prop,p.geom 
FROM 
	(select zoning_id, geom_id, prop from zoning.parcel_two_max) as two,
	(select geom_id, geom from parcel) as p
WHERE two.geom_id = p.geom_id;

create INDEX zoning_parcel_in_cities_geomid_idx ON zoning.parcel_in_cities using hash (geom_id);
VACUUM (ANALYZE) zoning.parcel_in_cities;

--select parcels that have multiple overlaps that are not in cities
DROP VIEW IF EXISTS zoning.parcel_two_max_not_in_cities;
CREATE TABLE zoning.parcel_two_max_not_in_cities AS
SELECT * from zoning.parcel_two_max_geo WHERE geom_id 
NOT IN (
SELECT geom_id 
FROM
zoning.parcel_in_cities);

CREATE INDEX zoning_parcel_two_max_not_in_cities_gidx ON zoning.parcel_two_max_not_in_cities USING GIST (geom);

DROP TABLE IF EXISTS zoning.parcel_in_counties;
CREATE TABLE zoning.parcel_in_counties AS
SELECT p2n.geom_id, p2n.zoning_id, p2n.city, cb.name10 as countyname1, p2n.geom 
FROM 
	(SELECT c.city, p2.geom_id, p2.zoning_id, p2.geom
	FROM
	zoning.codes_dictionary c,
	zoning.parcel_two_max_not_in_cities p2
	WHERE c.id = p2.zoning_id) p2n,
	county10_ca cb
WHERE ST_Intersects(cb.wkb_geometry,p2n.geom);
--Query returned successfully: 50561 rows affected, 2052 ms execution time.

DROP TABLE IF EXISTS zoning.temp_parcel_county_table;
CREATE TABLE zoning.temp_parcel_county_table AS
SELECT * from 
zoning.parcel_in_counties p
WHERE 
regexp_replace(city, 'Unincorporated ','') = countyname1;
--Total query runtime: 2414 ms. -- 25403 rows retrieved.

create INDEX zoning_temp_parcel_county_table_geomid_idx ON zoning.temp_parcel_county_table using hash (geom_id);

/*
COPY PARCELS WITHIN MULTIPLE CITIES 
AND PARCELS WITHIN MULTIPLE COUNTIES 
TO A SEPARATE TABLE, AND THEN REMOVE 
THEM FROM THE PARCEL/ZONING MAPPING
BECAUSE WE CANNOT ASSIGN THEM 
ONLY 1 ZONING TYPE USING THE RULE 
BASED ON WHICH JURISDICTION THEY ARE LOCATED IN
*/

/*CREATE TABLE zoning.parcels_in_multiple_cities AS
SELECT * FROM zoning.parcel_in_cities WHERE geom_id IN
(
SELECT geom_id
FROM
(SELECT geom_id, count(*) AS countof
FROM zoning.parcel_in_cities
GROUP BY geom_id) p
WHERE p.countof>1);*/
--Query returned successfully: 3121 rows affected, 3337 ms execution time.

CREATE TABLE zoning.parcels_in_multiple_counties AS
SELECT * FROM zoning.temp_parcel_county_table WHERE geom_id IN
(
SELECT geom_id
FROM
(SELECT geom_id, count(*) AS countof
FROM zoning.temp_parcel_county_table
GROUP BY geom_id) p
WHERE p.countof>1);

\COPY zoning.parcels_in_multiple_cities TO '/zoning_data/parcels_in_multiple_cities.csv' DELIMITER ',' CSV HEADER;
--https://mtcdrive.box.com/shared/static/uumadei43eqxl5ll90fdtqz7nxhhg711.csv;

\COPY zoning.parcels_in_multiple_counties TO '/zoning_data/parcels_in_multiple_counties.csv' DELIMITER ',' CSV HEADER;
--https://mtcdrive.box.com/shared/static/ouya6lylpd4e1z5vqfz2gngebkmgfkur.csv;

DELETE FROM zoning.temp_parcel_county_table WHERE geom_id IN
(
SELECT geom_id
FROM
(SELECT geom_id, count(*) AS countof
FROM zoning.temp_parcel_county_table
GROUP BY geom_id) p
WHERE p.countof>1);
--Query returned successfully: 712 rows affected, 65 ms execution time.

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

--THE FOLLOWING IS A CHECK THAT PARCELS ARE STILL UNIQUE
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning.parcel;
--0

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
----------OUTPUT RESULTING TABLE TO CSV----------
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

\COPY zoning.parcel TO '/mnt/bootstrap/data_out/zoning_parcels.csv' DELIMITER ',' CSV HEADER;

/*
BELOW WE CREATE TABLES WITH GEOGRAPHIC DATA
FOR VISUAL INSPECTION OF OF THE ABOVE
*/

--create indexes for the query below
create INDEX zoning_parcel_lookup_geom_idx ON zoning.parcel using hash (geom_id);

--output a table with geographic information and generic code info for review
CREATE TABLE zoning.parcel_withdetails AS
SELECT z.*, p.geom_id, p.geom
FROM zoning.parcel pz,
zoning.codes_dictionary z,
parcel p
WHERE pz.zoning_id = z.id AND p.geom_id = pz.geom_id;

CREATE INDEX zoning_parcel_withdetails_gidx ON zoning.parcel_withdetails using GIST (geom);
CREATE INDEX zoning_parcel_withdetails_geom_idx ON zoning.parcel_withdetails using hash (geom_id);
VACUUM (ANALYZE) zoning.parcel_withdetails;

CREATE TABLE zoning.unmapped_parcels AS
select * from parcel 
where geom_id not in (
SELECT geom_id from zoning.parcel_withdetails);

CREATE INDEX zoning_unmapped_parcel_gidx ON zoning.unmapped_parcels using GIST (geom);
VACUUM (ANALYZE) zoning.unmapped_parcels;
