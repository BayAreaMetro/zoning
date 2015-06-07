COMMENT ON TABLE parcel is 'spandex parcels';
COMMENT ON TABLE zoning.parcels_with_multiple_zoning is 'spandex parcels-subset that intersects with >1 zoning geometries';
COMMENT ON TABLE zoning.parcels_with_one_zone is 'spandex parcels-subset that intersects with 1 zoning geometry';
COMMENT ON TABLE zoning.parcel_overlaps_maxonly  is 'subset of zoning.parcel_overlaps-parcel/zoning pair with highest % area';
COMMENT ON TABLE zoning.parcel_two_max is 'subset of zoning.parcel_overlaps_maxonly->1 parcel/zoning pair with highest % area (equal max values). this is probably due to two jurisdictional claims';
COMMENT ON TABLE zoning.parcel_counties is 'spandex parcels with their county name (2010 census)';
COMMENT ON TABLE zoning.parcel_cities_counties is 'spandex parcels with their city and county name (2010 census)';
COMMENT ON TABLE zoning.parcel_in_cities is 'subset of parcel_two_max-those in cities, with their city zoning claim assigned';
COMMENT ON TABLE zoning.parcel_in_cities_doubles is 'parcels deleted from parcel_in_cities b/c there were doubles'
COMMENT ON TABLE zoning.parcel_two_max_not_in_cities is 'subset of parcel_two_max-those NOT in cities';
COMMENT ON TABLE zoning.parcel_in_counties is 'subset of parcel_two_max_not_in_cities-those in counties, with their city zoning claim assigned';
COMMENT ON TABLE zoning.temp_parcel_county_table is 'removes "unincorporated" from countyname1 and doesnt seem critical but is used in parcels_in_multipl_counties';
COMMENT ON TABLE zoning.parcels_in_multiple_cities is 'parcels that fell in more than 1 census city';
COMMENT ON TABLE zoning.parcels_in_multiple_counties is 'parcels that fell in more than 1 census county';
COMMENT ON TABLE zoning.parcel_two_max_geo is 'for cartography';
COMMENT ON TABLE zoning.parcel_two_max_geo_overlaps is 'for cartography';
--output a table with geographic information and generic code info for review
COMMENT ON TABLE zoning.parcel_withdetails is 'spandex parcels with all the generic zoning columns';
COMMENT ON TABLE zoning.parcel_two_max_geo is 'for cartography';
COMMENT ON TABLE zoning.unmapped_parcels is 'spandex parcels not yet assigned zoning';
COMMENT ON TABLE zoning.unmapped_parcel_zoning is 'spandex parcels not yet assigned zoning--filled in from 2008 plu data';
