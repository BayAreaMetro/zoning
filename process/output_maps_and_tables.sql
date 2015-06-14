


-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
----------OUTPUT RESULTING TABLE TO CSV----------
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

--\COPY zoning.parcel_invalid TO '/vm_project_dir/zoning/invalid_parcels.csv' DELIMITER ',' CSV HEADER;

--output a table with geographic information and generic code info for review
DROP TABLE IF EXISTS zoning.parcel_withdetails;
CREATE TABLE zoning.parcel_withdetails AS
SELECT z.*, p.geom_id, pz.tablename, p.geom
FROM zoning.parcel pz,
zoning.codes_dictionary z,
parcel p
WHERE pz.zoning_id = z.id AND p.geom_id = pz.geom_id;

CREATE INDEX zoning_parcel_withdetails_gidx ON zoning.parcel_withdetails using GIST (geom);
CREATE INDEX zoning_parcel_withdetails_geom_idx ON zoning.parcel_withdetails using hash (geom_id);
VACUUM (ANALYZE) zoning.parcel_withdetails;

INSERT INTO zoning.parcel_withdetails
select * from zoning.plu06_one_intersection;
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning.parcel_withdetails;

INSERT INTO zoning.parcel_withdetails
select * from zoning.plu06_many_intersection;
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning.parcel_withdetails;

CREATE TABLE zoning.parcel_withdetails_nogeom AS
SELECT
id,                
juris,             
city,              
name,
tablename,              
min_far,           
max_far,           
max_height,        
min_front_setback, 
max_front_setback, 
side_setback,      
rear_setback,      
min_dua,           
max_dua,           
coverage,          
max_du_per_parcel, 
min_lot_size,      
hs,                
ht,                
hm,                
of,                
ho,                
sc,                
il,                
iw,                
ih,                
rs,                
rb,                
mr,                
mt,                
me,                
geom_id
FROM zoning.parcel_withdetails;
\COPY zoning.parcel_withdetails_nogeom TO '/vm_project_dir/zoning/zoning_parcels.csv' DELIMITER ',' CSV HEADER;
DROP TABLE zoning.parcel_withdetails_nogeom;*/