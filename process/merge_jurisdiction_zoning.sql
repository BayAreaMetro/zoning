CREATE SCHEMA zoning;

CREATE TABLE zoning.jurisdiction_zoning
(
  ogc_fid integer,
  tablename text,
  zoning text,
  juris integer,
  the_geom geometry
);

CREATE OR REPLACE FUNCTION zoning.merge_jursidictions()
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
  LANGUAGE plpgsql VOLATILE;

COPY zoning.jurisdiction_zoning to 'jurisdiction_zoning.sql'
