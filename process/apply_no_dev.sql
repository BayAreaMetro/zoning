DROP TABLE IF EXISTS zoning.parcels_no_dev;
CREATE TABLE admin.parcels_details_no_dev AS
SELECT z.* FROM
	zoning.parcel_withdetails z,
	no_dev_source nd
WHERE ST_Within(nd.geometry,z.geom);
COMMENT ON TABLE zoning.parcel_intersection is 'st_within of zoning.parcel_withdetails and no_dev_source';

DELETE FROM zoning.parcel_withdetails
WHERE geom_id IN (SELECT geom_id FROM zoning.parcels_no_dev);

INSERT INTO zoning.parcel_withdetails
SELECT 
0000 as id, 
0000 as juris, 
text 'NA' as city,
text 'nodev' as tablename,
text 'nodev' as name,
0 as min_far, 
0 as max_height,
0 as max_far, 
0 as min_front_setback,
0 as max_front_setback,
0 as side_setback,
0 as rear_setback,
0 as min_dua,
0 as max_dua,           
0 as coverage,          
0 as max_du_per_parcel,
0 as min_lot_size,      
0 as hs,0 as ht,0 as hm,0 as of,0 as ho,0 as sc,0 as il,0 as iw,0 as ih,0 as rs,0 as rb,0 as mr,0 as mt,0 as me,
geom_id as geom_id,
geom as geom
from
zoning.parcels_no_dev;