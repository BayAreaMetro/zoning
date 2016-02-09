CREATE TABLE zoning_staging.parcel_non_plu06_non_2012 AS
SELECT *
FROM parcel
WHERE zoning_name IS NULL
  AND geoid10_int NOT IN
    (SELECT geoid10_int
     FROM admin_staging.jurisdictions
     WHERE collection_project_year=2006);


UPDATE parcel p
SET zoning_name='no_overlapping_code'
WHERE p.geom_id IN
    (SELECT geom_id
     FROM zoning_staging.parcel_non_plu06_non_2012);


CREATE VIEW zoning_staging.parcels_with_plu06_zoning AS
SELECT *
FROM parcel
WHERE geoid10_int IN
    (SELECT geoid10_int
     FROM admin_staging.jurisdictions
     WHERE collection_project_year=2006);


DROP TABLE IF EXISTS zoning_staging.parcels_with_plu06_intersection;


CREATE TABLE zoning_staging.parcels_with_plu06_intersection AS
SELECT p.geom_id,
       p.geom,
       z.OBJECTID AS plu06_objectid
FROM zoning_staging.parcels_with_plu06_zoning p,
     zoning_staging.plu06_may2015estimate z
WHERE z.geom && p.geom
  AND ST_Intersects(z.geom,p.geom);


DROP TABLE IF EXISTS zoning_staging.parcels_with_plu06_intersection_count;


CREATE TABLE zoning_staging.parcels_with_plu06_intersection_count AS
SELECT geom_id,
       count(*) AS countof
FROM zoning_staging.parcels_with_plu06_intersection
GROUP BY geom_id;


CREATE INDEX ON zoning_staging.parcels_with_plu06_intersection_count
USING btree (geom_id);

 VACUUM (ANALYZE) zoning_staging.parcels_with_plu06_intersection_count;


DROP TABLE IF EXISTS zoning_staging.parcel_overlaps_plu06;


CREATE TABLE zoning_staging.parcel_overlaps_plu06 AS
SELECT geom_id,
       plu06_objectid,
       sum(ST_Area(geom)) area,
       round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
       ST_Union(geom) geom
FROM
  ( SELECT p.geom_id,
           z.OBJECTID AS plu06_objectid,
           ST_Area(p.geom) parcelarea,
           ST_Intersection(p.geom, z.geom) geom
   FROM
     (SELECT geom_id,
             geom
      FROM zoning_staging.parcels_with_plu06_zoning
      WHERE geom_id IN
          (SELECT geom_id
           FROM zoning_staging.parcels_with_plu06_intersection_count
           WHERE countof>1)) AS p,

     (SELECT objectid,
             geom
      FROM zoning_staging.plu06_may2015estimate) AS z
   WHERE ST_Intersects(z.geom, p.geom) ) f
GROUP BY geom_id,
         plu06_objectid;

 /*
BEGIN ASSIGNMENT
*/

DROP TABLE IF EXISTS zoning_staging.parcel_overlaps_maxonly_plu;


CREATE TABLE zoning_staging.parcel_overlaps_maxonly_plu AS
SELECT geom_id,
       plu06_objectid,
       prop
FROM zoning_staging.parcel_overlaps_plu06
WHERE (geom_id,
       prop) IN
    (SELECT geom_id,
            MAX(prop)
     FROM zoning_staging.parcel_overlaps_plu06
     GROUP BY geom_id);


DROP TABLE IF EXISTS zoning_staging.plu06_one_intersection;

CREATE TABLE zoning_staging.plu06_one_intersection AS
SELECT p.geom_id,
       z.origgplu,
       '6' || lpad(cast(z.objectid AS text),4,'0000') AS zoning_id,
              100 AS prop,
              cast('plu06' AS text) AS tablename,
              p.geom
FROM
  (SELECT *
   FROM zoning_staging.unmapped_parcel_zoning_staging_plu
   WHERE geom_id IN
       (SELECT geom_id
        FROM zoning_staging.unmapped_parcel_intersection_count
        WHERE countof=1)) AS p,
     zoning_staging.plu06_may2015estimate z
WHERE p.plu06_objectid=z.objectid;


CREATE INDEX plu06_one_intersection_gidx
ON zoning_staging.plu06_one_intersection USING GIST (geom);

 VACUUM (ANALYZE) zoning_staging.plu06_one_intersection;


DROP TABLE IF EXISTS zoning_staging.plu06_many_intersection;


CREATE TABLE zoning_staging.plu06_many_intersection AS
SELECT p.geom_id,
       z.origgplu,
       '6' || lpad(cast(z.objectid AS text),4,'0000') AS zoning_id,
              p.prop,
              cast('plu06' AS text) AS tablename,
              p.geom
FROM
  (SELECT p2.*,
          pmax.prop
   FROM zoning_staging.unmapped_parcel_zoning_staging_plu p2,
                                                          zoning_staging.parcel_overlaps_maxonly_plu pmax
   WHERE pmax.geom_id=p2.geom_id
     AND p2.plu06_objectid=pmax.plu06_objectid) AS p,
     zoning_staging.plu06_may2015estimate z
WHERE p.plu06_objectid=z.objectid;

 COMMENT ON TABLE zoning_staging.plu06_many_intersection IS 'plu 06 intersection table with selected greatest max value of zoning_staging';


CREATE INDEX plu06_many_intersection_gidx
ON zoning_staging.plu06_many_intersection USING GIST (geom);

 VACUUM (ANALYZE) zoning_staging.plu06_one_intersection;


DROP TABLE IF EXISTS zoning_staging.plu06_many_intersection_two_max;


CREATE TABLE zoning_staging.plu06_many_intersection_two_max AS
SELECT *
FROM zoning_staging.plu06_many_intersection
WHERE (geom_id) IN
    ( SELECT geom_id
     FROM
       ( SELECT geom_id,
                count(*) AS countof
        FROM zoning_staging.plu06_many_intersection
        GROUP BY geom_id ) b
     WHERE b.countof>1 );

 --EXPORT pg_dump --table zoning_staging.parcel_withdetails > /mnt/bootstrap/zoning_staging/parcel_withdetails05142015.sql

DELETE
FROM zoning_staging.plu06_many_intersection
WHERE (geom_id) IN
    ( SELECT geom_id
     FROM
       ( SELECT geom_id,
                count(*) AS countof
        FROM zoning_staging.plu06_many_intersection
        GROUP BY geom_id ) b
     WHERE b.countof>1 );


CREATE INDEX plu06_one_intersection_geomid_idx ON
zoning_staging.plu06_one_intersection USING hash (geom_id);

 VACUUM (ANALYZE) zoning_staging.plu06_one_intersection;


INSERT INTO zoning_staging.parcel
SELECT geom_id,
       cast(zoning_id AS integer),
       cast(origgplu AS text) AS zoning_staging,
       -9999 AS juris,
       prop,
       tablename
FROM zoning_staging.plu06_one_intersection
WHERE geom_id NOT IN
    (SELECT geom_id
     FROM zoning_staging.parcel);


SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id)
FROM zoning_staging.parcel;

 VACUUM (ANALYZE) zoning_staging.parcel;


CREATE INDEX plu06_many_intersection_geomid_idx
ON zoning_staging.plu06_many_intersection USING hash (geom_id);

VACUUM (ANALYZE) zoning_staging.plu06_many_intersection;


INSERT INTO zoning_staging.parcel
SELECT geom_id,
       cast(zoning_id AS integer),
       cast(origgplu AS text) AS zoning_staging,
       -9999 AS juris,
       prop,
       tablename
FROM zoning_staging.plu06_many_intersection
WHERE geom_id NOT IN
    (SELECT geom_id
     FROM zoning_staging.parcel);


SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id)
FROM zoning_staging.parcel;

VACUUM (ANALYZE) zoning_staging.parcel;
