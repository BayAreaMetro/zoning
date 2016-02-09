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


CREATE OR REPLACE FUNCTION assign_2012(exec boolean = FALSE) RETURNS text AS $function$
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

--this function is based on the functions in this postgis add-ons repository: https://github.com/pedrogit/postgisaddons
--and these plpgsql tutorials: https://wiki.postgresql.org/wiki/Return_more_than_one_row_of_data_from_PL/pgSQL_functions

/*
Use this function to return a table with statistics on how 2 postgis polygon tables overlap.
The function returns rows with the unique id's of the tables passed to it where they intersect.
It also returns the area of overlap, the proportion of overlap, and the geometry of their intersection.

EXAMPLE USAGE:
select * from GetOverlaps('parcel','zoning_staging.santarosageneralplan','gp_landuse','geom') as codes(
        geom_id bigint,
        zoning_id varchar(50),
        area double precision,
        prop double precision,
        geom geometry);
*/

create or replace function GetOverlaps(_p text,_z text,_z_id text,_z_geom text) returns setof record as
'
declare
r record;
begin
    for r in EXECUTE ''SELECT
        geom_id,
        ''|| _z_id || '',
        sum(ST_Area(geom)) area,
        round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
        ST_Union(geom) geom
        FROM (
            SELECT p.geom_id,
                z.''|| _z_id || '',
                ST_Area(p.geom) parcelarea,
                ST_Intersection(p.geom, z.geom) geom
            FROM (select geom_id, geom FROM '' || _p || '') as p,
                 (select ''|| _z_id || '', '' || _z_geom ||
                 '' as geom FROM '' || _z || '') as z
            WHERE ST_Intersects(z.geom, p.geom)
            ) f
            GROUP BY
                geom_id,
                ''|| _z_id || '''' loop
return next r;
end loop;
return;
end
'
language 'plpgsql';

/*
modification of the above to filter parcels by a census jurisdiction geoid
*/

create or replace function GetOverlapsGoeid(_g_id int, _z_id text, _z text) returns setof record as
'
declare
r record;
begin
    for r in EXECUTE ''SELECT
        geom_id,
        ''|| _z_id || '',
        sum(ST_Area(geom)) area,
        round(sum(ST_Area(geom))/min(parcelarea) * 1000) / 10 prop,
        ST_Union(geom) geom
        FROM (
            SELECT p.geom_id,
                z.''|| _z_id || '',
                ST_Area(p.geom) parcelarea,
                ST_Intersection(p.geom, z.geom) geom
            FROM (select geom_id, geom FROM parcel WHERE geoid10_int = ''|| _g_id ||'') as p,
                 (select ''|| _z_id || '', geom as geom FROM '' || _z || '') as z
            WHERE ST_Intersects(z.geom, p.geom)
            ) f
            GROUP BY
                geom_id,
                ''|| _z_id || '''' loop
return next r;
end loop;
return;
end
'
language 'plpgsql';


----------------------
----------------------
--DEPRECATED FUNCTIONS
----------------------
----------------------

--used the following as part of the previous process but can probably drop them in the future:

CREATE OR REPLACE FUNCTION zoning.get_id(name text,juris int)
   RETURNS int AS
$$
  SELECT id
  from zoning.codes_dictionary
  WHERE name = $1
  AND juris = $2;
$$
  LANGUAGE sql;

geometry(Polygon,26910)

CREATE OR REPLACE FUNCTION set_multipolygon(schema_name text)
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
         INSERT INTO zoning_staging.'
         || $1 || '_merged SELECT
         geom_id,
         zoning_id as zoning_name,
         area,
         prop,
         geom
          from ' || $1 || '.' ||
         table_record."table_name");
        RAISE NOTICE '%', sql_string;
        EXECUTE sql_string;
     END LOOP;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE;


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
         INSERT INTO zoning_staging.'
         || $1 || '_merged SELECT
         geom_id,
         zoning_id as zoning_name,
         area,
         prop,
         geom
          from ' || $1 || '.' ||
         table_record."table_name");
        RAISE NOTICE '%', sql_string;
        EXECUTE sql_string;
     END LOOP;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE;
