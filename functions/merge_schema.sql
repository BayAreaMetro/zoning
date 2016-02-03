CREATE OR REPLACE FUNCTION merge_schema(schema_name text)
   RETURNS void AS
$BODY$
DECLARE
    	tables CURSOR FOR SELECT *
	      FROM information_schema.tables
	      WHERE table_schema = $1
	      ORDER BY "table_name" ASC
	      LIMIT ((SELECT count(*)
		  FROM information_schema.tables
		  WHERE table_schema = $1));
		sql_string text := '';
BEGIN	
	 FOR table_record IN tables LOOP
	 sql_string := (SELECT '
		 insert into public.' 
		 || $1 || 
		 '_merged select ' ||
		 quote_LITERAL(table_record."table_name") || 
		 ', CAST(' ||
		 qry.matchfield ||    
		 ' as text) as zoning, ' ||
	 	 qry.juris_id ||
		 ' as juris,' ||
		 'ST_Force2D(geom) as the_geom ' ||
		 'from ' || $1 || '.' ||
		 table_record."table_name"		 
		FROM
			(
				select substring(matchfield from 1 for 10) as matchfield, CAST(juris_id as text)
					FROM zoning_staging.shapefile_metadata s
				WHERE s.shapefile_name = table_record."table_name") qry
			);
	 	RAISE NOTICE '%', sql_string;
	 	EXECUTE sql_string;
	 END LOOP;
	END;
$BODY$
  LANGUAGE plpgsql VOLATILE;

