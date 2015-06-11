DROP TABLE IF EXISTS zoning.zoning_unincorporated_counties_merged;
CREATE TABLE zoning.zoning_unincorporated_counties_merged
(
  tablename text,
  zoning text,
  juris integer,
  the_geom geometry(Multipolygon,26910)
);

select zoning.merge('zoning_unincorporated_counties');

ALTER TABLE zoning.zoning_unincorporated_counties_merged
    RENAME TO unincorporated_counties;