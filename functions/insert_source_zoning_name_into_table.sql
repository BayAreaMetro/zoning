-- Function: public.get_zone(bigint)

-- DROP FUNCTION public.get_zone(bigint);
CREATE OR REPLACE FUNCTION public.insert_source_zoning_name_into_table(parcel pz_valid)
  RETURNS TABLE(parcel_id integer, zonename text, juris integer) AS
$BODY$
DECLARE 
sql_string text := '';
sql_exc text := '';
BEGIN
	sql_string := (SELECT 'INSERT INTO zoning.source_name SELECT ' 
			|| parcel.parcel_id ||
			' as parcel_id, CAST ('
			|| qry.matchfield ||    
			' as text) as zonename, ' || qry.juris || 
			' as integer FROM zoning_legacy_2012.' || 
			quote_ident(qry.tablename) || 
			' as t WHERE ogc_fid=' || 
			qry.ogc_fid
		FROM
			(
				select parcel.tablename, parcel.ogc_fid, s.matchfield, s.juris
					FROM zoning.source_field_name s
					WHERE s.tablename = parcel.tablename
			) qry
		--LIMIT 1
	);
	RAISE NOTICE '(%)', sql_string;
	EXECUTE sql_string ;
EXCEPTION WHEN OTHERS THEN
	sql_exc := ('INSERT INTO 
					zoning.no_source_name SELECT  
					ogc_fid,tablename,parcel_id,id as pzvalid_id FROM pz_valid WHERE 
					parcel_id=' || p_id
	);
	EXECUTE sql_exc ;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_zone(bigint)
  OWNER TO williamalonso;
