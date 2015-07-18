DROP TABLE IF EXISTS zoning.parcel_overlaps_maxonly_plu;
CREATE TABLE zoning.parcel_overlaps_maxonly_plu AS
SELECT geom_id, plu06_objectid, prop 
FROM zoning.parcel_overlaps_plu WHERE (geom_id,prop) IN 
( SELECT geom_id, MAX(prop)
  FROM zoning.parcel_overlaps_plu
  GROUP BY geom_id 
);

DROP TABLE IF EXISTS zoning.plu06_one_intersection; 
CREATE TABLE zoning.plu06_one_intersection AS
SELECT
p.geom_id,
'6' || lpad(cast(z.objectid as text),4,'0000') as zoning_id,
100 as prop,
'plu06' as tablename,
p.geom
from 
(select * from zoning.unmapped_parcel_zoning_plu
where geom_id in 
(select geom_id 
from zoning.unmapped_parcel_intersection_count 
WHERE countof=1)) as p,
zoning.plu06_may2015estimate z
WHERE p.plu06_objectid=z.objectid;

create INDEX plu06_one_intersection_gidx ON zoning.plu06_one_intersection using GIST (geom);
vacuum (analyze) zoning.plu06_one_intersection;

DROP TABLE IF EXISTS zoning.plu06_many_intersection;
CREATE TABLE zoning.plu06_many_intersection AS
SELECT
p.geom_id,
'6' || lpad(cast(z.objectid as text),4,'0000') as zoning_id,
p.prop,
'plu06' as tablename,
p.geom
from (select p2.*, pmax.prop 
	from zoning.unmapped_parcel_zoning_plu p2,
	zoning.parcel_overlaps_maxonly_plu pmax
	where pmax.geom_id=p2.geom_id AND
	p2.plu06_objectid=pmax.plu06_objectid) as p,
zoning.plu06_may2015estimate z
WHERE p.plu06_objectid=z.objectid;
COMMENT ON TABLE zoning.plu06_many_intersection IS 'plu 06 intersection table with selected greatest max value of zoning';

create INDEX plu06_many_intersection_gidx ON zoning.plu06_many_intersection using GIST (geom);
vacuum (analyze) zoning.plu06_one_intersection;

DROP TABLE IF EXISTS zoning.plu06_many_intersection_two_max;
CREATE TABLE zoning.plu06_many_intersection_two_max AS
SELECT * FROM 
zoning.plu06_many_intersection where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.plu06_many_intersection
	GROUP BY geom_id
	) b
	WHERE b.countof>1
	);

--EXPORT pg_dump --table zoning.parcel_withdetails > /mnt/bootstrap/zoning/parcel_withdetails05142015.sql

DELETE FROM 
zoning.plu06_many_intersection where (geom_id) IN
	(
	SELECT geom_id from 
	(
	select geom_id, count(*) as countof from 
	zoning.plu06_many_intersection
	GROUP BY geom_id
	) b
	WHERE b.countof>1
	);

create INDEX plu06_one_intersection_geomid_idx ON zoning.plu06_one_intersection using hash (geom_id);

VACUUM (ANALYZE) zoning.plu06_one_intersection;

INSERT INTO zoning.parcel
select geom_id,cast(zoning_id as integer),prop,tablename from zoning.plu06_one_intersection
WHERE geom_id NOT IN (SELECT geom_id from zoning.parcel);
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning.parcel;

VACUUM (ANALYZE) zoning.parcel;

create INDEX plu06_many_intersection_geomid_idx ON zoning.plu06_many_intersection using hash (geom_id);

VACUUM (ANALYZE) zoning.plu06_many_intersection;

INSERT INTO zoning.parcel
select geom_id,cast(zoning_id as integer),prop,tablename from zoning.plu06_many_intersection
WHERE geom_id NOT IN (SELECT geom_id from zoning.parcel);
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning.parcel;

VACUUM (ANALYZE) zoning.parcel;