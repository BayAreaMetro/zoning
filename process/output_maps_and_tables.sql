


-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
----------OUTPUT RESULTING TABLE TO CSV----------
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

\COPY zoning.parcel_invalid TO '/vm_project_dir/zoning/invalid_parcels.csv' DELIMITER ',' CSV HEADER;

/*
BELOW WE CREATE TABLES WITH GEOGRAPHIC DATA
FOR VISUAL INSPECTION OF OF THE ABOVE
*/

CREATE TABLE zoning.unmapped_parcels AS
select * from parcel 
where geom_id not in (
SELECT geom_id from zoning.parcel_withdetails);

--output a table with geographic information and generic code info for review
DROP TABLE IF EXISTS zoning.parcel_withdetails;
CREATE TABLE zoning.parcel_withdetails AS
SELECT z.*, p.geom_id, p.geom
FROM zoning.parcel pz,
zoning.codes_dictionary z,
parcel p
WHERE pz.zoning_id = z.id AND p.geom_id = pz.geom_id;

CREATE INDEX zoning_parcel_withdetails_gidx ON zoning.parcel_withdetails using GIST (geom);
CREATE INDEX zoning_parcel_withdetails_geom_idx ON zoning.parcel_withdetails using hash (geom_id);
VACUUM (ANALYZE) zoning.parcel_withdetails;



CREATE INDEX zoning_unmapped_parcel_gidx ON zoning.unmapped_parcels using GIST (geom);
VACUUM (ANALYZE) zoning.unmapped_parcels;