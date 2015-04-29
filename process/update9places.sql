select a.juris,  b.juris,  c.juris,  d.juris,  e.juris,  f.juris,  g.juris,  h.juris,  i.juris from 
(select distinct juris from zoning.codes where city like '%American Canyon%')  a,
(select distinct juris from zoning.codes where city like '%Cloverdale%')  b,
(select distinct juris from zoning.codes where city like '%Fairfield%')  c,
(select distinct juris from zoning.codes where city like '%Healdsburg%')  d,
(select distinct juris from zoning.codes where city like '%Piedmont%')  e,
(select distinct juris from zoning.codes where city like '%Pinole%')  f,
(select distinct juris from zoning.codes where city like '%San Ramon%')  g,
(select distinct juris from zoning.codes where city like '%Saratoga%')  h,
(select distinct juris from zoning.codes where city like '%Sebastopol%')  i
# result: ARRAY[53, 11, 10, 13, 95, 73, 80, 28, 17]

--ARRAY[53, 11, 10, 13, 95, 73, 80, 28, 17]

CREATE TABLE zoning.update9_intersection_count AS
SELECT geom_id, count(*) as countof FROM
			public.parcel newp,
			(select * from zoning.update9_geo where juris in (53, 11, 10, 13, 95, 73, 80, 28, 17)) oldp
			WHERE ST_Intersects(newp.geom, oldp.geom)
			GROUP BY geom_id;

DROP TABLE IF EXISTS zoning.update9parcels_with_multiple_zoning;
CREATE TABLE zoning.update9parcels_with_multiple_zoning AS
SELECT * from parcel where geom_id
IN (SELECT geom_id FROM zoning.update9_intersection_count WHERE countof>1);
--Query returned successfully: 462655 rows affected, 6854 ms execution time.

DROP TABLE IF EXISTS zoning.update9parcels_with_one_zone;
CREATE TABLE zoning.update9parcels_with_one_zone AS
SELECT * from parcel where geom_id
IN (SELECT geom_id FROM zoning.update9_intersection_count WHERE countof=1);
--Query returned successfully: 1311776 rows affected, 16436 ms execution time.

CREATE INDEX z_update9_parcels_with_multiple_zoning_gidx ON zoning.update9_parcels_with_multiple_zoning USING GIST (geom);

CREATE INDEX z_update9_parcels_with_one_zone_gidx ON zoning.update9_parcels_with_one_zone USING GIST (geom);

VACUUM (ANALYZE) zoning.parcels_with_multiple_zoning;
VACUUM (ANALYZE) zoning.parcels_with_one_zone;

DROP TABLE IF EXISTS zoning.update9parcel_overlaps;
CREATE TABLE zoning.update9parcel_overlaps AS
SELECT 
	geom_id,
	id,
	sum(ST_Area(geom)) area,
	round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
	ST_Union(geom) geom
FROM (
SELECT p.geom_id, 
	z.id,
 	ST_Area(p.geom) parcelarea, 
 	ST_Intersection(p.geom, z.the_geom) geom
FROM zoning.update9parcels_with_multiple_zoning p,
zoning.update9_geo as z
WHERE ST_Intersects(z.geom, p.geom)
) f
GROUP BY 
	geom_id,
	id;
--Query returned successfully: 872362 rows affected, 4129986 ms execution time.

DROP TABLE IF EXISTS zoning.update9parcel_overlaps_maxonly;
CREATE TABLE zoning.update9parcel_overlaps_maxonly AS
SELECT geom_id, zoning_id, prop 
FROM zoning.update9parcel_overlaps WHERE (geom_id,prop) IN 
( SELECT geom_id, MAX(prop)
  FROM zoning.update9parcel_overlaps
  GROUP BY geom_id
);


--create table of parcels with >1 max values
DROP TABLE IF EXISTS zoning.update9parcel_two_max;
CREATE TABLE zoning.update9parcel_two_max AS
SELECT geom_id, zoning_id, prop FROM 
zoning.update9parcel_overlaps_maxonly where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.update9parcel_overlaps_maxonly
	GROUP BY geom_id
	) b
	WHERE b.countof>1
	);
/* Query returned successfully: 212 rows affected, 87 ms execution time. */

--same for 1 max, except insert into parcel table
INSERT INTO zoning.parcel
SELECT geom_id, id, prop FROM 
zoning.update9parcel_overlaps_maxonly where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.parcel_overlaps_maxonly
	GROUP BY geom_id
	) b
	WHERE b.countof=1
	)
--Query returned successfully: 390363 rows affected, 1634 ms execution time.

drop table if exists zoning.tmp_update9geo;
create table zoning.tmp_update9geo as 
select z.*, p.geom from zoning.update9parcel_overlaps_maxonly z, parcel p where z.geom_id = p.geom_id;

drop table if exists zoning.tmp_update9geo_notcovered;
create table zoning.tmp_update9geo_notcovered as 
select * from 
zoning.tmp_update9geo z
WHERE z.geom_id NOT IN (select geom_id from zoning.parcel);

create table zoning.parcel_copy_two as
	SELECT * from zoning.parcel;

insert into zoning.parcel
	SELECT geom_id, zoning_id, 100 FROM
	zoning.tmp_update9geo_notcovered;
--Query returned successfully: 52885 rows affected, 7113 ms execution time.
--parcels with zoning now at 182k

select count (geom_id) - count (distinct geom_id) from zoning.parcel
--result: 49--where did these double counts come from?

select count (geom_id) - count (distinct geom_id) from zoning.tmp_update9geo_notcovered
--apparently from the inserted table

CREATE TABLE zoning.tmp_update9_doubles AS
SELECT * FROM  zoning.tmp_update9geo_notcovered WHERE geom_id IN
(
SELECT geom_id
FROM
(SELECT geom_id, count(*) AS countof
FROM zoning. zoning.tmp_update9geo_notcovered
GROUP BY geom_id) p
WHERE p.countof>1)

select z.*, c.name from zoning.tmp_update9_doubles z, zoning.codes_base2012 c where z.zoning_id=c.id order by geom_id
--these are actually in the update9 source! $@#$$#$ $%^%^%!
--not including them for now
DELETE FROM zoning.parcel
	WHERE geom_id in zoning.tmp_update9_doubles;
--Query returned successfully: 77 rows affected, 527 ms execution time.

--renaming to a non tmp table
ALTER TABLE zoning.tmp_update9_doubles RENAME TO zoning.update9_parcels_with_two_zones


