--MAY NEED TO create extension hstore;
CREATE OR REPLACE FUNCTION select_row_from_source(pgeom geometry)
  RETURNS text AS
$BODY$
DECLARE 
result text;
sql_string text := '';
intersections text;
BEGIN
	IF EXISTS(
			SELECT * FROM
			zoning_legacy_2012.lookup as z
			WHERE ST_Intersects(z.geom, pgeom)
			LIMIT 1
			)
	THEN
		IF 	(SELECT count(*) FROM
			zoning_legacy_2012.lookup as z
			WHERE ST_Intersects(z.geom, pgeom))=1
		THEN
			sql_string := (SELECT 'SELECT hstore(g.*) 
					FROM (SELECT (r).* 
					FROM (SELECT (t #= hstore(''wkb_geometry'',null)) as r 
					FROM zoning_legacy_2012.' || 
					quote_ident(z.tablename) || 
					' as t WHERE ogc_fid=' || 
					z.ogc_fid || ') s) g '
			FROM
			zoning_legacy_2012.lookup as z
			WHERE ST_Intersects(z.geom, pgeom)
			LIMIT 1);
			RAISE NOTICE '(%)', sql_string;
			EXECUTE sql_string INTO result;
		ELSE
			SELECT 
			round(sum(ST_Area(geom))/min(parcelarea)) 
			FROM
			(SELECT z.zoning_id, ST_Area(p.geom) parcelarea, ST_Intersection(pgeom, z.geom) geom
			FROM
			zoning_legacy_2012.lookup as z, pgeom
			WHERE ST_Intersects(pgeom,z.geom)) foo 
			INTO intersections;
			RAISE NOTICE '(%)', intersections;
			--result := hstore(ARRAY[['novalue',CAST( intersections AS text )]]);
			--WHATS BELOW DOESN'T QUITE WORK FOR RETURNING PARCELS WITH MULTIPLE INTERSECTING ZONING GEOMS
			--THE PROBLEM IS THAT z.tablename returns multiple values, when just need first
			--tried "first" function from postgres wiki
			--but this requires some group by thing--need more time on it
			/*			sql_string := (SELECT 'SELECT hstore(g.*) 
			FROM (SELECT (r).* 
			FROM (SELECT (t #= hstore(''wkb_geometry'',null)) as r 
			FROM zoning_legacy_2012.' || 
			quote_ident(z.tablename) || 
			' as t WHERE ogc_fid IN' || 
			z.ogc_fid || ') s) g '
			FROM
			zoning_legacy_2012.lookup as z
			WHERE ST_Intersects(z.geom, pgeom)
			);
			result := sql_string ;	*/
		END IF;
	ELSE
	RAISE NOTICE 'no intersection';
	result := hstore(ARRAY[['novalue','0']]);
	END IF;
RETURN result;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
