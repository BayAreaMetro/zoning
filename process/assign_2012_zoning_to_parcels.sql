DROP TABLE zoning_staging.zoning_2012_parcel_overlaps_merged;
CREATE TABLE IF NOT EXISTS 
    zoning_staging.zoning_2012_parcel_overlaps_merged
        (
          geom_id bigint,
          zoning_name text,
          area float,
          prop float, 
          geom geometry
        );

select merge_schema('zoning_2012_parcel_overlaps');

DROP TABLE IF EXISTS zoning_staging.zoning_2012_parcel_overlaps_stats;
CREATE TABLE zoning_staging.zoning_2012_parcel_overlaps_stats AS
SELECT geom_id, zoning_name, area, prop, geom FROM 
zoning_staging.zoning_2012_parcel_overlaps_merged where (geom_id) IN
  (
  SELECT geom_id from 
  (
  select geom_id, count(*) as countof from 
  zoning_staging.zoning_2012_parcel_overlaps_merged
  GROUP BY geom_id
  ) b
  WHERE b.countof>1
  );

ALTER TABLE parcel
    ADD COLUMN zoning_conflict boolean;

UPDATE parcel p
    SET zoning_conflict=true
WHERE p.geom_id IN
  (
  SELECT geom_id from 
  (
  select geom_id, count(*) as countof from 
  zoning_staging.zoning_2012_parcel_overlaps_merged
  GROUP BY geom_id
  ) b
  WHERE b.countof>1
  );

DROP TABLE IF EXISTS zoning_staging.zoning_2012_parcel_overlaps_maxonly;
CREATE TABLE zoning_staging.zoning_2012_parcel_overlaps_maxonly AS
SELECT geom_id, zoning_name, area, prop, geom
FROM zoning_staging.zoning_2012_parcel_overlaps_merged WHERE (geom_id,prop) IN 
( SELECT geom_id, MAX(prop)
  FROM zoning_staging.zoning_2012_parcel_overlaps_merged
  GROUP BY geom_id
);

UPDATE parcel p
    SET zoning_name=po.zoning_name
    FROM zoning_staging.zoning_2012_parcel_overlaps_maxonly po
    WHERE po.geom_id = p.geom_id;

DROP TABLE IF EXISTS zoning_staging.zoning_2012_parcel_overlaps_maxonly_conflict;
CREATE TABLE zoning_staging.zoning_2012_parcel_overlaps_maxonly_conflict AS
SELECT geom_id, zoning_name, area, prop, geom FROM 
zoning_staging.zoning_2012_parcel_overlaps_maxonly where (geom_id) IN
  (
  SELECT geom_id from 
  (
  select geom_id, count(*) as countof from 
  zoning_staging.zoning_2012_parcel_overlaps_maxonly
  GROUP BY geom_id
  ) b
  WHERE b.countof>1
  );

