###Intro 

Produce a CSV with a generic zoning code assigned to every parcel in the SF Bay Area in 2010. 

###Requirements

[GNU Make](http://bost.ocks.org/mike/make/), PostGIS 2.1, Postgres 9.3, GDAL 1.11 or > (with both FileGDB driver and Postgres driver), [Amazon CLI](https://aws.amazon.com/cli/)

###Setting up PostgreSQL--Example

```
sudo -u postgres createdb sf_bayarea_landuse
sudo -u postgres psql sf_bayarea_landuse -c "CREATE USER ****** WITH PASSWORD '******';"
sudo -u postgres psql sf_bayarea_landuse -c "GRANT ALL PRIVILEGES ON DATABASE sf_bayarea_landuse to ******;
sudo -u postgres psql sf_bayarea_landuse -c "CREATE EXTENSION postgis;"
sudo -u postgres psql sf_bayarea_landuse -c "CREATE EXTENSION postgis_topology;"
sudo -u postgres psql sf_bayarea_landuse -c "GRANT ALL PRIVILEGES ON DATABASE sf_bayarea_landuse to ******;
```

###Usage

The [Makefile](https://github.com/MetropolitanTransportationCommission/zoning/blob/master/Makefile) contains pointers to what data is needed, where to get it, scripts to load it into Postgres, and scripts to join source parcel and zoning data.

In general we have treated the Makefile as the documentation of the data process. So start there if you need to change something. It will be closer to the data/process than this readme.

If you already have the environment set up, then you can simply type:

`make zoning_parcels.csv`  

This will download and load the necessary data (excepting parcels) into Postgres, and then assign a Zoning ID to the parcels. Parcels are now expected to be in the database, as output by the script [here](https://github.com/MetropolitanTransportationCommission/bayarea_urbansim/blob/master/data_regeneration/run.py).

### Outcome

The `zoning_parcels.csv` table output by this process is an input to UrbanSim. Download it  [here](https://landuse.s3.amazonaws.com/zoning/zoning_parcels.csv).

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
