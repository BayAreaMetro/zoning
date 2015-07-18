###Intro 

Produce a CSV with a generic zoning code assigned to every parcel in the SF Bay Area in 2010. 

###Requirements

[GNU Make](http://bost.ocks.org/mike/make/), PostGIS 2.1, Postgres 9.3, GDAL 1.11 or > (with both FileGDB driver and Postgres driver), [Amazon CLI](https://aws.amazon.com/cli/)

You can use this [repository](https://github.com/MetropolitanTransportationCommission/bayarea_urbansim_setup/tree/vagrant-ubuntu14-lindsay) to set up an environment. At [this commit](https://github.com/MetropolitanTransportationCommission/bayarea_urbansim_setup/commit/99d628524532a7c01dd1ae4de378109dc349b654) the processes here ran on a VM for over 7 hours on a machine with 70gb ram. 

###Usage

The [Makefile](https://github.com/MetropolitanTransportationCommission/zoning/blob/master/Makefile) contains all the necessary pointers to what data is needed, where to get it, scripts to load it into Postgres, and scripts to join source parcel and zoning data. In general we have treated the Makefile as the documentation of the data process. So start there if you need to change something. It will be closer to the data/process than this readme.

####Data
The following are required: 

filename|description
---------------|--------------
jurisdictional/*.shp | Zoning v2 A directory of shapefiles of Zoning plans for the jurisdictions in the Bay Area
a spandex parcel table | these are output from [spandex](https://github.com/synthicity/spandex)
city10_ba.shp | city boundaries (2010 census) MTC edits for water-features and others
county10_ca.shp | county boundaries (2010 census) MTC edits for water-features and others
zoning_codes_base2012.csv | Use these to map specific jurisdictional zoning to a generic taxonomy-from this [table](http://landuse.s3.amazonaws.com/zoning/zoning_codes_base2012.csv)
match_fields_tables_zoning_2012_source.csv | Names the column used in Zoning V2 which is used in the zoning taxonomy - from the [Project Management Spreadsheet](http://landuse.s3.amazonaws.com/zoning/CityAssignments_Nov3_2014.xlsx)
plu06_may2015estimate.shp | PLU 2006 data from [ABAG](http://gis.abag.ca.gov/)

It is recommended to use the makefile to fetch the necessary data.

If you already have the environment set up, then you can simply type:

`make zoning_parcels.csv`  

This will download and load the necessary data into Postgres, and then assign a Zoning ID to it.

### Outcome

The `zoning_parcels.csv` table output by this process is an input to UrbanSim and is therefore in the urbansim repository [here](https://github.com/synthicity/bayarea_urbansim/blob/master/data/zoning_parcels.csv).

####Fields in the `zoning_parcels` table:

column name|description
----------|------------
geom_id|the geometry based identifier for a parcel as output by Spandex
zoning_id|the zoning id for a parcel as found in the `zoning_lookup.csv`
proportion|coverage/overlap with zoning code for parcel
tablename|which source zoning file/tablename was assigned to this parcel
no_dev|site will not be developed in urbansim

The `zoning_id` column in this table can be used to look up the qualities of zoning relevant to UrbanSim, such as those in the table below. See [the lookup table](https://github.com/synthicity/bayarea_urbansim/blob/master/data/zoning_lookup.csv) for more details.

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
