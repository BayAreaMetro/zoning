CREATE OR REPLACE FUNCTION select_source_attr(pgeom geometry)
  RETURNS text AS
$BODY$
DECLARE 
result text;
sql_string text := '';
BEGIN	
	sql_string := (SELECT 'SELECT hstore(g.*) 
			FROM (SELECT (r).* 
			FROM (SELECT (t #= hstore(''wkb_geometry'',null)) as r 
			FROM zoning_legacy_2012.' || 
			quote_ident(z.tablename) || 
			' as t WHERE ogc_fid=' || 
			z.ogc_fid || ') s) g '
	FROM
	zoning_legacy_2012.lookup as z,
	zoning.parcels_generic_types as p
	WHERE ST_Intersects(z.geom, pgeom)
	LIMIT 1);
	RAISE NOTICE '(%)', sql_string;
	EXECUTE sql_string INTO result;
	RETURN result;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE