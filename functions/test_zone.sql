CREATE OR REPLACE FUNCTION get_zone(p_id bigint)
  RETURNS TABLE(parcel_id integer, zonename text, juris integer) AS
$BODY$
DECLARE 
sql_string text := '';
BEGIN
	sql_string := (SELECT 'SELECT '	|| p_id ||
			' as parcel_id, CAST ('
			|| qry.matchfield ||    
			' as text) as zonename, ' || qry.juris || 
			' as integer FROM zoning_legacy_2012.' || 
			quote_ident(qry.tablename) || 
			' as t WHERE ogc_fid=' || 
			qry.ogc_fid
		FROM
			(
				select a.tablename, a.ogc_fid, s.matchfield, s.juris
					FROM zoning.source_field_name s,
					(select *
					from pz 
					WHERE pz.parcel_id = p_id
					LIMIT 1) a
				WHERE s.tablename = a.tablename
			) qry
		--LIMIT 1
	);
	RAISE NOTICE '(%)', sql_string;
	INSERT INTO zoning.source_name EXECUTE sql_string ;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
