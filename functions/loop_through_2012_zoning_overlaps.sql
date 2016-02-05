CREATE OR REPLACE FUNCTION overlap_2012_shapefiles_and_parcels()
   RETURNS void AS
$BODY$
DECLARE
        shapefiles CURSOR FOR SELECT *
          FROM zoning_staging.shapefile_metadata;
        sql_string text := '';
BEGIN
     FOR table_record IN shapefiles LOOP
     sql_string := (SELECT '
         CREATE TABLE 
         zoning_2012_parcel_overlaps.' 
         || quote_ident(table_record."shapefile_name") ||
         ' AS SELECT * from GetOverlapsGoeid(' ||
         qry.geoid10_int || 
         ', '||
         quote_literal(qry.matchfield) ||    
         ', '
         || quote_literal(concat('zoning_2012_staging.', table_record."shapefile_name")) ||
         ') as codes(geom_id bigint, 
                    zoning_id varchar,
                    area double precision,
                    prop double precision,
                    geom geometry);'
        FROM
            (
                select substring(matchfield from 1 for 10) as matchfield, geoid10_int
                    FROM zoning_staging.shapefile_metadata s
                WHERE s.shapefile_name = table_record."shapefile_name") qry
            );
        RAISE NOTICE '%', sql_string;
        EXECUTE sql_string;
     END LOOP;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE;

select overlap_2012_shapefiles_and_parcels();