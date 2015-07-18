DROP TABLE IF EXISTS zoning_cities_towns.export_output; -- SHOULD BE RENAME TO  monte_sereno--NEED TO UPDATE MATCH TABLE THOUGH
DROP TABLE IF EXISTS zoning_cities_towns.pacificagp_022009;
DROP TABLE IF EXISTS zoning_cities_towns.santaclaracity_zoningfeb05;

DROP TABLE IF EXISTS zoning.zoning_cities_towns_merged;
CREATE TABLE zoning.zoning_cities_towns_merged
(
  tablename text,
  zoning text,
  juris integer,
  the_geom geometry(Multipolygon,26910)
);

select zoning.merge('zoning_cities_towns');

--give it a more reasonable name
DROP TABLE IF EXISTS zoning.cities_towns;
ALTER TABLE zoning.zoning_cities_towns_merged
    RENAME TO cities_towns;