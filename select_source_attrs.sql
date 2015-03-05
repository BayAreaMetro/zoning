CREATE OR REPLACE FUNCTION select_source_att(pgeom geometry)
  RETURNS text AS
$BODY$
DECLARE 
result text;
sql_string text := '';
BEGIN
	IF EXISTS(
			SELECT * FROM
			zoning_legacy_2012.lookup as z
			WHERE ST_Intersects(z.geom, pgeom)
			LIMIT 1
			)
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
	RAISE NOTICE 'no intersection';
	result := 'no intersecting source';	
	END IF;
RETURN result;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
