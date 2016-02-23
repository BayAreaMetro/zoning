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
         ' AS SELECT * from get_overlaps(' ||
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
         ' AS SELECT * from get_overlaps(' ||
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

--this function is based on the functions in this postgis add-ons repository: https://github.com/pedrogit/postgisaddons
--these plpgsql tutorials: https://wiki.postgresql.org/wiki/Return_more_than_one_row_of_data_from_PL/pgSQL_functions
--as a derived work, it retains the GPL license as indicated in the addons

/*
Use this function to return a table with statistics on how 2 postgis polygon tables overlap.
The function returns rows with the unique id's of the tables passed to it where they intersect.
It also returns the area of overlap, the proportion of overlap, and the geometry of their intersection.
*/

create or replace function get_overlaps(_g_id int, _z_id text, _z text) returns setof record as
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

-------------------------------------------------------------------------------
-- PostGIS PL/pgSQL Add-ons - Main installation file
-- Version 1.23 for PostGIS 2.1.x and PostgreSQL 9.x
-- http://github.com/pedrogit/postgisaddons
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Copyright (C) 2013 Pierre Racine <pierreracine70@gmail.com>.
-- 
-------------------------------------------------------------------------------
---TRUNCATED TO JUST THIS 1 FUNCTION:
-------------------------------------------------------------------------------
-- ST_DifferenceAgg
--
--   geom1 geometry - Geometry from which to remove subsequent geometries
--                    in the aggregate.
--   geom2 geometry - Geometry to remove from geom1.
--
-- RETURNS geometry
--
-- Returns the first geometry after having removed all the subsequent geometries in
-- the aggregate. This function is used to remove overlaps in a table of polygons.
--
-- Refer to the self contained example below. Each geometry MUST have a unique ID 
-- and, if the table contain a huge number of geometries, it should be indexed.
--
-- Self contained and typical example removing, from a geometry, all
-- the overlapping geometries having a bigger area:
--
-- WITH overlappingtable AS (
--   SELECT 1 id, ST_GeomFromText('POLYGON((0 1, 3 2, 3 0, 0 1))') geom
--   UNION ALL
--   SELECT 2 id, ST_GeomFromText('POLYGON((1 1, 3.8 2, 4 0, 1 1))')
--   UNION ALL
--   SELECT 3 id, ST_GeomFromText('POLYGON((2 1, 4.6 2, 5 0, 2 1))')
--   UNION ALL
--   SELECT 4 id, ST_GeomFromText('POLYGON((3 1, 5.4 2, 6 0, 3 1))')
-- )
-- SELECT a.id, ST_DifferenceAgg(a.geom, b.geom) geom
-- FROM overlappingtable a, 
--      overlappingtable b
-- WHERE ST_Equals(a.geom, b.geom) OR 
--       ((ST_Contains(a.geom, b.geom) OR 
--         ST_Contains(b.geom, a.geom) OR 
--         ST_Overlaps(a.geom, b.geom)) AND 
--        (ST_Area(a.geom) < ST_Area(b.geom) OR 
--         (ST_Area(a.geom) = ST_Area(b.geom) AND 
--          ST_AsText(a.geom) < ST_AsText(b.geom))))
-- GROUP BY a.id;
--
-- In some cases you may want to use the polygons ids instead of the 
-- polygons areas to decide which one is removed from the other one.
-- You first have to ensure ids are unique for this to work. In that  
-- case you would replace:
--
--     ST_Area(a.geom) < ST_Area(b.geom) OR 
--     (ST_Area(a.geom) = ST_Area(b.geom) AND ST_AsText(a.geom) < ST_AsText(b.geom))
--
-- with:
--
--     a.id < b.id
--
-- to cut all the polygons with greatest ids from the polygons with 
-- smallest ids.
--
-- You might also want that the ids are only used as the last discriminant 
-- when two different polygons have the same area instead of using the arbitrary 
-- order created by the text version of the geometries. In that case you 
-- would replace:
--
--     ST_Area(a.geom) < ST_Area(b.geom) OR 
--     (ST_Area(a.geom) = ST_Area(b.geom) AND ST_AsText(a.geom) < ST_AsText(b.geom))
--
-- with:
--
--     ST_Area(a.geom) < ST_Area(b.geom) OR 
--     (ST_Area(a.geom) = ST_Area(b.geom) AND a.id < b.id)
--
-- to cut all the polygon with greatest id from the polygons with 
-- smallest id when they have the same area.
-----------------------------------------------------------
-- Pierre Racine (pierre.racine@sbf.ulaval.ca)
-- 10/18/2013 v. 1.14
-----------------------------------------------------------
-- ST_DifferenceAgg aggregate state function
CREATE OR REPLACE FUNCTION _ST_DifferenceAgg_StateFN(
    geom1 geometry, 
    geom2 geometry, 
    geom3 geometry
)
RETURNS geometry AS $$
    DECLARE
       newgeom geometry;
    BEGIN
        -- First pass: geom1 is null
        IF geom1 IS NULL AND NOT ST_IsEmpty(geom2) THEN
            newgeom = CASE 
                        WHEN ST_Equals(geom2, geom3) THEN geom2 
                        ELSE ST_Difference(geom2, geom3)
                      END;
        ELSIF NOT ST_IsEmpty(geom1) THEN
            newgeom = CASE 
                        WHEN ST_Equals(geom2, geom3) THEN geom1 
                        ELSE ST_Difference(geom1, geom3)
                      END;
        ELSE
            newgeom = geom1;
        END IF;

        IF NOT ST_IsEmpty(newgeom) THEN
            newgeom = ST_CollectionExtract(newgeom, 3);
        END IF;

        IF newgeom IS NULL THEN
            newgeom = ST_GeomFromText('MULTIPOLYGON EMPTY');
        END IF;

        RETURN newgeom;
    END;
$$ LANGUAGE plpgsql IMMUTABLE;

-----------------------------------------------------------
-- ST_DifferenceAgg aggregate
CREATE AGGREGATE ST_DifferenceAgg(geometry, geometry) (
  SFUNC=_ST_DifferenceAgg_StateFN,
  STYPE=geometry
);
-------------------------------------------------------------------------------


