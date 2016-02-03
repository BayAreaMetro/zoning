DROP TABLE IF EXISTS public.zoning_2012_staging_merged;
CREATE TABLE public.zoning_2012_staging_merged
(
  shapefile_name text,
  zoning text,
  juris_id integer,
  the_geom geometry(Multipolygon,26910)
);

select merge_schema('zoning_2012_staging');

