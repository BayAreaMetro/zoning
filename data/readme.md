The following are required (and accessible with the Makefile in the root directory)

filename|description
---------------|--------------
jurisdictional/*.shp | A directory of shapefiles of Zoning and General plans for the jurisdictions in the Bay Area--details in zoning_source_metadata.csv
a parcel table | these are assembled from source data [with this script](https://github.com/MetropolitanTransportationCommission/bayarea_urbansim/blob/master/data_regeneration/run.py)
city10_ba.shp | city boundaries (2010 census) MTC edits for water-features and others
county10_ca.shp | county boundaries (2010 census) MTC edits for water-features and others
zoning_codes_base2012.csv | Use these to map specific jurisdictional zoning to a generic taxonomy-from this [table](http://landuse.s3.amazonaws.com/zoning/zoning_codes_base2012.csv)
match_fields_tables_zoning_2012_source.csv | Names the column used in Zoning V2 which is used in the zoning taxonomy - from the [Project Management Spreadsheet](http://landuse.s3.amazonaws.com/zoning/CityAssignments_Nov3_2014.xlsx)
plu06_may2015estimate.shp | PLU 2006 data from [ABAG](http://gis.abag.ca.gov/)


