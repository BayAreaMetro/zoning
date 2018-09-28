### About the CSV's in this directory:

The shapefiles listed in zoning_source_metadata.csv are used directly in the Makefile in order to fetch and then load all zoning and general plan from the 2012 effort.

`zoning_table_city_lookup.csv` is meant to be a list of all jurisdictions in the Bay Area. It is used to look up jurisdiction common names, and which jurisdictions are to be assigned zoning and general plan data from the 2006 data collection effort. In the future, we can probably just fold these 2 csv's together, at least in the database table representing all the jurisdictions.

`zoning_lookup` is a dictionary of generic qualities of allowed uses in urbansim. most of the columns are no longer used.

###About data used generally in this repository:

As for other data used here, the following are required (and accessible with the Makefile in the root directory)

filename|description
---------------|--------------
jurisdictional/*.shp | A directory of shapefiles of Zoning and General plans for the jurisdictions in the Bay Area--details in zoning_source_metadata.csv
a parcel table | these are assembled from source data [with this script](https://github.com/MetropolitanTransportationCommission/bayarea_urbansim/blob/master/data_regeneration/run.py)
city10_ba.shp | city boundaries (2010 census) MTC edits for water-features and others
county10_ca.shp | county boundaries (2010 census) MTC edits for water-features and others
zoning_codes_base2012.csv | Use these to map specific jurisdictional zoning to a generic taxonomy-from this [table](http://landuse.s3.amazonaws.com/zoning/zoning_codes_base2012.csv)
match_fields_tables_zoning_2012_source.csv | Names the column used in Zoning V2 which is used in the zoning taxonomy - from the [Project Management Spreadsheet](http://landuse.s3.amazonaws.com/zoning/CityAssignments_Nov3_2014.xlsx)
plu06_may2015estimate.shp | PLU 2006 data from [ABAG](http://gis.abag.ca.gov/)

####Fields in the `zoning_lookup.csv`

column name|description
----|----------------
id|generic zoning id
juris|jurisdiction id
city|city name
name|string of zoning type from source data
max_far|maximum floor-to-area ratio
max_height|maximum height
max_dua|maximum dwelling units per acre
max_du_per_parcel|maximum dwelling units per parcel
hs|single-family detached
ht|single-family attached
hm|multi-family
of|office
ho|hotel
sc|school
il|light industrial
iw|warehouse industrial
ih|heavy industrial
rs|strip mall retail
rb|big-box retail
mr|residential-focus mixed
mt|retail-focus mixed
me|employment-focus mixed

We expect that this table will change as we improve on our methods and data sources.
