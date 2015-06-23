--select only those pairs of geom_id, zoning_id in which
--the proportion of overlap is the maximum
DROP TABLE IF EXISTS zoning.counties_parcel_overlaps_maxonly;
CREATE TABLE zoning.counties_parcel_overlaps_maxonly AS
SELECT geom_id, zoning_id, prop, tablename
FROM zoning.counties_parcel_overlaps WHERE (geom_id,prop) IN 
( SELECT geom_id, MAX(prop)
  FROM zoning.counties_parcel_overlaps
  GROUP BY geom_id
);
