-- Function: public.mergetables(text)

-- DROP FUNCTION public.mergetables(text);

CREATE OR REPLACE FUNCTION public.mergetables(sql_string text)
  RETURNS text AS
$BODY$
DECLARE
    	tables CURSOR FOR SELECT *
	      FROM information_schema.tables
	      WHERE table_schema = 'zoning_legacy_2012'
	      ORDER BY "table_name" ASC
	      LIMIT ((SELECT count(*)
		  FROM information_schema.tables
		  WHERE table_schema = 'public')-1);
		sql_string text := '';
BEGIN
	 FOR table_record IN tables LOOP
	 sql_string := (SELECT '
		 insert into zoning.lookup_new
		 select ogc_fid, ' 
		 || quote_LITERAL(table_record."table_name") || 
		 ', ST_Force2D(wkb_geometry) ' 
		 || ', CAST('
		 || qry.matchfield ||    
		 ' as text) as zoning, ' 
		 || qry.juris ||
		 ' from zoning_legacy_2012.'
		 || table_record."table_name" 
		FROM
			(
				select matchfield, juris
					FROM zoning.source_field_name s
				WHERE s.tablename = table_record."table_name") qry
			);
	 RAISE NOTICE '(%)', sql_string;
	 EXECUTE sql_string;
	 END LOOP;
	 RETURN sql_string;
	 --EXECUTE sql_string;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
