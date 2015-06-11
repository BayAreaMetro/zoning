CREATE OR REPLACE FUNCTION zoning.merge(schema_name text)
   RETURNS void AS
$BODY$
DECLARE
    	tables CURSOR FOR SELECT *
	      FROM information_schema.tables
	      WHERE table_schema = $1
	      ORDER BY "table_name" ASC
	      LIMIT ((SELECT count(*)
		  FROM information_schema.tables
		  WHERE table_schema = $1)-1);
		sql_string text := '';
BEGIN
	 FOR table_record IN tables LOOP
	 sql_string := (SELECT '
		 insert into zoning.' 
		 || $1 || 
		 '_merged select ' ||
		 quote_LITERAL(table_record."table_name") || 
		 ', CAST(' ||
		 qry.matchfield ||    
		 ' as text) as zoning, ' ||
	 	 qry.juris ||
		 ' as juris,' ||
		 'ST_Force2D(geom) as the_geom ' ||
		 'from ' || $1 || '.' ||
		 table_record."table_name"		 
		FROM
			(
				select substring(matchfield from 1 for 10) as matchfield, CAST(juris as text)
					FROM zoning.source_field_name s
				WHERE s.tablename = table_record."table_name") qry
			);
	 	RAISE NOTICE '%', sql_string;
	 	EXECUTE sql_string;
	 END LOOP;
	END;
$BODY$
  LANGUAGE plpgsql VOLATILE;

