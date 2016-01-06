DROP TABLE IF EXISTS zoning.zoning_staging_merged;
CREATE TABLE zoning.zoning_staging_merged
(
  tablename text,
  zoning text,
  juris integer,
  the_geom geometry(Multipolygon,26910)
);

select zoning.merge('zoning_staging');

DROP TABLE IF EXISTS zoning.merged_jurisdictions;
ALTER TABLE zoning.zoning_staging_merged
    RENAME TO merged_jurisdictions;