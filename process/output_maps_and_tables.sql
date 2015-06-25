


-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
----------OUTPUT RESULTING TABLE TO CSV----------
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

--\COPY zoning.parcel_invalid TO '/vm_project_dir/zoning/invalid_parcels.csv' DELIMITER ',' CSV HEADER;

--output a table with geographic information and generic code info for review

DROP TABLE IF EXISTS zoning.parcel_withdetails_nogeom;
CREATE TABLE zoning.parcel_withdetails_nogeom AS
SELECT
z.id,                
z.juris,             
z.city,              
z.name,
z.tablename,              
z.min_far,           
z.max_far,           
z.max_height,        
z.min_front_setback, 
z.max_front_setback, 
z.side_setback,      
z.rear_setback,      
z.min_dua,           
z.max_dua,           
z.coverage,          
z.max_du_per_parcel, 
z.min_lot_size,      
z.hs,                
z.ht,                
z.hm,                
z.of,                
z.ho,                
z.sc,                
z.il,                
z.iw,                
z.ih,                
z.rs,                
z.rb,                
z.mr,                
z.mt,                
z.me,
z.nodev,                
z.geom_id,
p.ghsh_pnt_srfc,
p.ghsh_cntrd
FROM zoning.parcel_withdetails z,
parcel p
where p.geom_id=z.geom_id;

VACUUM (ANALYZE) zoning.parcel_withdetails_nogeom;
SELECT COUNT(geom_id) - COUNT(DISTINCT geom_id) FROM zoning.parcel_withdetails_nogeom;

\COPY zoning.parcel_withdetails_nogeom TO '/vm_project_dir/zoning/zoning_parcels.csv' DELIMITER ',' CSV HEADER;
DROP TABLE zoning.parcel_withdetails_nogeom;