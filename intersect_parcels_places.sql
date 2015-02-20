DROP TABLE zoning.parcels_in_places;
CREATE TABLE zoning.parcels_in_places AS
SELECT n.name, n.name_1, p.joinnuma, p.geom from parcels_mpg_min as p 
	LEFT JOIN administrative.places as n ON ST_Intersects(n.geom, p.geom);

---FASTER:
CREATE TABLE zoning.parcels_not_in_places AS
SELECT n.name, n.name_1, p.joinnuma, p.geom 
FROM parcels_mpg_min as p, administrative.places as n 
WHERE NOT ST_Intersects(n.geom, p.geom);