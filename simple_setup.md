###PostgreSQL Setup

create a database
```
sudo -u postgres createdb sf_bayarea_landuse
sudo -u postgres psql sf_bayarea_landuse sf_bayarea_landuse -c "CREATE EXTENSION postgis;"
sudo -u postgres psql sf_bayarea_landuse sf_bayarea_landuse -c "CREATE EXTENSION postgis_topology;"
```

(optional) add a user 
```
psql sf_bayarea_landuse -c "CREATE USER *** WITH PASSWORD '***';"
psql sf_bayarea_landuse -c "GRANT ALL PRIVILEGES ON DATABASE sf_bayarea_landuse to ***;
```

dump the parcel table into it

```
pg_dump -t public.parcel landuse | psql sf_bayarea_landuse
```

in this example, we'll borrow the parcel table from the existing landuse
database so that we can skip the admin code assignment and save ourselves 
some time below under "load and assign administrative areas to parcels"

###Setup Zoning Metadata
clone the zoning repository
```
git clone https://github.com/MetropolitanTransportationCommission/zoning.git
```

load postgis extension for zoning processing
```
psql sf_bayarea_landuse -f functions/zoning_functions.sql 
```

create schemas to put things in:
```
psql sf_bayarea_landuse -f load/load-schema-names.sql
```

load generic zoning assignment tables
```
psql sf_bayarea_landuse -f load/load-generic-zoning-code-table.sql
psql sf_bayarea_landuse -f load/load-zoning-shapefile-metadata.sql
```

###Setup Administrative Metadata
get admin data
```
make city10_ba.shp
make county10_ba.shp
```

load and assign adminstrative areas to parcels
```
shp2pgsql -t 2D -s 26910 -I city10_ba.shp admin_staging.city10_ba | psql sf_bayarea_landuse
shp2pgsql -t 2D -s 26910 -I county10_ca.shp admin_staging.county10_ca | psql sf_bayarea_landuse
psql sf_bayarea_landuse -f process/create_jurisdictional_table.sql
```
normally we would do the following but, in the interest of time, 
the following line is obviated by the parcel dump above
```
psql sf_bayarea_landuse -f process/assign_city_name_by_county.sql
```

###Load 2012 Zoning Data and Process it
get zoning_data
```
make zoning_files
```

load zoning source data shapefiles from 2012
```
    ls jurisdictional/*.shp | cut -d "/" -f2 | sed 's/.shp//' | xargs -I {} shp2pgsql -t 2D -s 26910 -I jurisdictional/{} zoning_2012_staging.{} | psql sf_bayarea_landuse
```

do 2012 assignment by city
```
    psql sf_bayarea_landuse -c "SELECT fix_2012_geoms(TRUE);"
```

instead of doing this for every city, we will pg_dump from the landuse database and demonstrate functionality on just 1 single table. 
```
    pg_dump --schema zoning_2012_parcel_overlaps landuse | psql sf_bayarea_landuse
    psql sf_bayarea_landuse -c "SELECT overlap_2012(FALSE);"
```

to do all the cities we would have done:
```
    psql sf_bayarea_landuse -c "DROP SCHEMA IF EXISTS zoning_2012_parcel_overlaps CASCADE;"
    psql sf_bayarea_landuse -c "CREATE SCHEMA zoning_2012_parcel_overlaps;"
    psql sf_bayarea_landuse -c "SELECT overlap_2012(TRUE);"
```

###Assign the 2012 Data to Parcels:
```
    psql sf_bayarea_landuse -f process/assign_2012_zoning_to_parcels.sql
```

###Process 2006 Zoning Data
load zoning source data shapefile from 2006
```
    psql sf_bayarea_landuse -c "DROP TABLE IF EXISTS zoning.plu06_may2015estimate;"
    $(shp2pgsql) data/plu06_may2015estimate.shp zoning.plu06_may2015estimate | psql sf_bayarea_landuse
    psql sf_bayarea_landuse -f load/add-plu-2006.sql
```
clean and homogenize geometries
```
    psql sf_bayarea_landuse -f process/clean_plu06_geoms.sql
```
intersection with 2006:
```
    psql sf_bayarea_landuse -f process/assign_2006_zoning_to_parcels.sql
```

###Output Results:
output:
```
    psql sf_bayarea_landuse -c "process/assign_id.sql"
    psql sf_bayarea_landuse -c "\COPY zoning.parcel to 'zoning_parcels_no_dev_as_zero.csv' DELIMITER ',' CSV HEADER;"
```
