CREATE OR REPLACE FUNCTION fix_2012_geoms(exec boolean = FALSE) RETURNS text AS $function$
DECLARE
        sql_string text := '';
BEGIN
     SELECT array_to_string(array_agg(sql_statement), '') INTO sql_string
     FROM (
        SELECT 'DROP TABLE IF EXISTS ' || concat('zoning_2012_staging.', qry.shapefile_name) || '_invalid ;
                CREATE TABLE ' || concat('zoning_2012_staging.', qry.shapefile_name) || '_invalid AS
                SELECT *
                FROM ' || concat('zoning_2012_staging.', qry.shapefile_name) || '
                WHERE ST_IsValid(geom) = false;

                UPDATE ' || concat('zoning_2012_staging.', qry.shapefile_name) || '
                SET geom = st_multi(st_collectionextract(st_makevalid(geom), 3));

                DELETE FROM ' || concat('zoning_2012_staging.', qry.shapefile_name) || '
                WHERE GeometryType(geom) = ''GEOMETRYCOLLECTION'';'
        AS sql_statement
        FROM
            (
                select shapefile_name, substring(matchfield from 1 for 10)
                    FROM zoning_staging.shapefile_metadata
            ) qry
        ) s
    ;
    IF exec THEN 
        EXECUTE sql_string; 
        RETURN 'Success!';
    ELSE
        RETURN sql_string;
    END IF;
END;
$function$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION overlap_2012(exec boolean = FALSE) RETURNS text AS $function$
DECLARE
        sql_string text := '';
BEGIN
     SELECT array_to_string(array_agg(sql_statement), '') INTO sql_string
     FROM (
        SELECT 'CREATE TABLE
         zoning_2012_parcel_overlaps.'
         || qry.shapefile_name ||
         ' AS SELECT * from GetOverlapsGoeid(' ||
         qry.geoid10_int ||
         ', '||
         quote_literal(qry.matchfield) ||
         ', '
         || quote_literal(concat('zoning_2012_staging.', qry.shapefile_name)) ||
         ') as codes(geom_id bigint,
                    zoning_id varchar,
                    area double precision,
                    prop double precision,
                    geom geometry);
     '
        AS sql_statement
        FROM
            (
                select shapefile_name, substring(matchfield from 1 for 10) as matchfield, geoid10_int
                    FROM zoning_staging.shapefile_metadata
	    ) qry
        ) s;
    IF exec THEN
        EXECUTE sql_string;
        RETURN 'Success!';
    ELSE
        RETURN sql_string;
    END IF;
END;
$function$
LANGUAGE plpgsql;



