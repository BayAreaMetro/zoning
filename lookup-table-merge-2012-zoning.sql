CREATE TABLE zoning_legacy_2012.lookup (
	ogc_fid integer,
	tablename text, 
	geom geometry 
);

--the structure from this is from some nice person on stackoverflow, but i closed that tab and can't find it right now
CREATE OR REPLACE FUNCTION mergetables(sql_string text) RETURNS TEXT AS $$
DECLARE
    	tables CURSOR FOR SELECT *
	      FROM information_schema.tables
	      WHERE table_schema = 'public'
	      ORDER BY "table_name" ASC
	      LIMIT ((SELECT count(*)
		  FROM information_schema.tables
		  WHERE table_schema = 'public')-1);
		sql_string text := '';
BEGIN
	 FOR table_record IN tables LOOP
	 sql_string := sql_string || '
		 insert into lookup
		 select ogc_fid, ' || quote_LITERAL(table_record."table_name") || ', ST_Force2D(wkb_geometry) from ' || quote_IDENT(table_record."table_name") || ';';
	 END LOOP;
	 RAISE NOTICE 'Table_record:(%)', sql_string;
	 RETURN sql_string;
	 EXECUTE sql_string;
END;
$$ LANGUAGE plpgsql;
SELECT mergetables('');

ALTER TABLE zoning_legacy_2012.lookup ADD COLUMN id INTEGER;
CREATE SEQUENCE zoning_legacy_2012_lookup_seq;
UPDATE zoning_legacy_2012.lookup  SET id = nextval('zoning_legacy_2012_lookup_seq');
ALTER TABLE zoning_legacy_2012.lookup ALTER COLUMN id SET DEFAULT nextval('zoning_legacy_2012_lookup_seq');
ALTER TABLE zoning_legacy_2012.lookup ALTER COLUMN id SET NOT NULL;
ALTER TABLE zoning_legacy_2012.lookup ADD PRIMARY KEY (id);