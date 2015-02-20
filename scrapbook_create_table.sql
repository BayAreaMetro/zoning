SELECT count(*) FROM zoning.nozoning_zoning_ids WHERE id IS NULL;
--~5000
SELECT count(*) FROM zoning.nozoning_zoning_ids12 WHERE id IS NULL;
--~52478
SELECT count(*) FROM zoning.nozoning_water_ids WHERE id IS NULL;

/*
produce a table with these headers this:
county name, jurisdiction name, # parcels without zoning, # polygons without zoning, # polygons that don't overlap 2012 zoning gdb, # polygons that don't overlap with 2008 gdb 
*/
CREATE TABLE nozoning_parcels_in_places AS
SELECT n.name, n.name_1, p.joinnuma, p.geom from zoning.nozoning as p 
	LEFT JOIN administrative.places as n ON ST_DWithin(p.geom, ST_Transform(n.geom,26910), 0);

--next:need to join the above selection to name, which is county name. 
--ran into problem that can't group by jurisdiction name(name_1) and also county name and get both back. 
--but later, should be able to use NIL values in join to fill in county parcels that are not in jurisdictions
--therefore, unincorporated county parcels
--because spatial join is expensive, doing that now, store, and will do count later. 
--also, might need to run the queries on whether parcels are in old zoning blocks again
SELECT n.name_1, count(p.geom) from zoning.nozoning as p 
	LEFT JOIN administrative.places as n ON ST_DWithin(p.geom, n.geom, 0) GROUP BY n.name_1;

DROP TABLE zoning.parcels_in_places;
CREATE TABLE zoning.parcels_in_places AS
SELECT n.name, n.name_1, p.joinnuma, p.geom from fewerparcels as p 
	LEFT JOIN administrative.places as n ON ST_DWithin(p.geom, ST_Transform(n.geom,26910), 0);

SELECT n.name, n.name_1, p.joinnuma, p.geom from fewerparcels as p,
administrative.places as n WHERE 
ST_CONTAINS(ST_Transform(n.geom,26910),p.geom)

 ALTER TABLE administrative.places 
   ALTER COLUMN geom 
   TYPE Geometry(Point, 32644) 
   USING ST_Transform(geom, 32644);

CREATE TABLE zoning.parcels_not_in_places AS
SELECT n.name, n.name_1, p.joinnuma, p.geom 
FROM parcels_mpg_min as p, administrative.places as n 
WHERE NOT ST_Intersects(n.geom, p.geom);