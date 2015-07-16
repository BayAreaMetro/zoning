ALTER TABLE zoning.parcel ADD COLUMN nodev smallint NOT NULL DEFAULT 0;

UPDATE zoning.parcel as z
SET 
nodev = 1
FROM 
no_dev_source nd,
parcel p
WHERE 
p.geom_id = z.geom_id
AND ST_Within(nd.centroid,p.geom);
SELECT COUNT(*) from zoning.parcel where nodev=1;

DROP TABLE IF EXISTS zoning.parcel_nodev_remove_zoning_id;
CREATE TABLE zoning.parcel_nodev_remove_zoning_id AS
SELECT * FROM zoning.parcel;
comment on table zoning.parcel_nodev_remove_zoning_id is 'version of zoning.parcel where zoning_id has been changed to 00000 if nodev=1';

UPDATE zoning.parcel_nodev_remove_zoning_id SET
zoning_id = 00000 
WHERE nodev = 1;