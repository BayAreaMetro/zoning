CREATE OR REPLACE FUNCTION test_zone()
  RETURNS text AS
$BODY$
DECLARE 
result text;
sql_string text := '';
BEGIN
	sql_string := (SELECT 'SELECT '
			|| qry.matchfield ||    
			' FROM (SELECT (r).* 
			FROM (SELECT (t #= hstore(''wkb_geometry'',null)) as r 
			FROM zoning_legacy_2012.' || 
			quote_ident(qry.tablename) || 
			' as t WHERE ogc_fid=' || 
			qry.ogc_fid || ') s) g '
		FROM
			(select a.parcel_id, a.geom, a.tablename, a.ogc_fid, s.matchfield
			FROM 
			zoning.source_field_name s,
				(select *
				from pz limit 1) a
				WHERE s.tablename = a.tablename) qry
	--LIMIT 1
	);
	RAISE NOTICE '(%)', sql_string;
	EXECUTE sql_string INTO result;
RETURN result;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
