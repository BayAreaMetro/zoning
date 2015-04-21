CREATE TABLE zoning.merged_jurisdictions
(
  ogc_fid integer,
  tablename text,
  zoning text,
  juris integer,
  the_geom geometry
);

CREATE OR REPLACE FUNCTION zoning.merge()
  RETURNS text AS
$BODY$
DECLARE
    	tables CURSOR FOR SELECT *
	      FROM information_schema.tables
	      WHERE table_schema = 'zoning_staging'
	      ORDER BY "table_name" ASC
	      LIMIT ((SELECT count(*)
		  FROM information_schema.tables
		  WHERE table_schema = 'zoning_staging')-1);
		sql_string text := '';
BEGIN
	 FOR table_record IN tables LOOP
	 sql_string := (SELECT '
		 insert into zoning.merged_jurisdictions
		 select ogc_fid, ' 
		 || quote_LITERAL(table_record."table_name") 
		 || ', CAST('
		 || qry.matchfield ||    
		 ' as text) as zoning, ' 
		 || qry.juris ||
		 ' as juris from zoning_staging.'
		 || table_record."table_name" || 
		 ', ST_Force2D(wkb_geometry) as the_geom ' 
		FROM
			(
				select substring(matchfield from 1 for 10) as matchfield, CAST(juris as text)
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
  LANGUAGE plpgsql VOLATILE;

select zoning.merge();

\COPY zoning.merged_jurisdictions to 'bay_area_zoning.sql';*/