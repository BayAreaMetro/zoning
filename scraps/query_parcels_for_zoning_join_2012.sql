CREATE TABLE zoning.nozoning_zoning_ids12 AS 
SELECT p.joinnuma, z.id
	FROM zoning.nozoning p
		LEFT JOIN zoning.bayarea_2012 z ON ST_DWithin(p.geom, z.wkb_geometry, 0);
	--ORDER BY s.gid, ST_Distance(s.the_geom, h.the_geom);