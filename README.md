# land-use-zoning-checks
QA and cleaning of zoning data

Requirements to use these scripts include PostgreSQL, PostGIS, Python (psycopg2), and GDAL. 

## Problem Statement

We need to know how each parcel is zoned in order to estimate how and where development on parcels could change. 

## Method

First we ask, are any of the [parcels-without-zoning](#parcels-without-zoning) covered by geometry in [zoning-2008](#zoning-2008) or [zoning-2012](#zoning-2012)? If so, in which [place-names](#place-names)? 

Then, we create [re-built-parcel-data](#re-built-parcel-data), assigning zoning from [parcels-and-zoning](#parcels-and-zoning), if existing, then [zoning-2012](#zoning-2012), if existing, or [zoning-2012](#zoning-2008) if not. If not any zoning, report Null. 

Also, we summarize [re-built-parcel-data](#re-built-parcel-data) by [place-names](#place-names).

##SQL Used to Do This:

#### A. Enumerate Parcels Missing Zoning Data
see `7_create_nozoning_parcels.py`

#### B. Summarize Potential Sources of Missing Zoning Data


#### C. Source Missing Zoning Data

#### D. Summarize Sourcing Process

## Data 

###Legacy Data

####parcels-and-zoning
parcel_id, zoning_id (data/parcels_to_zoning_2012.csv)

####zoning-and-use
zoning_id -> columns about allowed use (data/zoning_codes_base2012_sheet1.csv)

####parcels
parcel_id, geometry (ParcelsBuildings.gdb.zip - Feature Class ba8)

Note: Loaded Using QGIS

####zoning-2008
geometry -> zoning type (collected in 2008) - available for entire Bay Area. Mostly Homogeneous Schema [^2] 
(data/PLANNEDLANDUSE_2008.gdb)

####zoning-2012
geometry -> zoning type (collected in 2012) - fewer jurisdictions than 2008. Heterogeneous Schema 
(data/zoning_2012.gdb)

####place-names
The ADMINISTRATIVE.Places feature class from the MTC GIS Database (conversations with staff indicate that this may be from TomTom, although that would need to be confirmed.) (exported here to data/places.shp)

Note: Loaded from MTC GIS SQL Server to PostGIS using ArcMap

###New Data

####parcels-without-zoning:
(7). id, geometry

####re-built-parcel-data:
(8). id, geometry, source table

[1] Please note that file naming conventions are copied from the source data naming conventions to avoid confusion. Ideally in the future, a consistent naming convention should be applied.

[2] These data were received as 2 Personal GeoDatabases. In both cases, each jurisdiction or geographic area has its own feature class. In the 2012 dataset, each feature class contained different columns. In the 2008 data set tables were consistent, with the exception of a Priority Development Areas feature class. We converted the personal Geodatabases to File GeoDatabases using ArcMap with an Editor License. In short, to do this you export the Personal Geodatabase to XML by right clicking on it (in ArcCatalog) and selecting "Export to XML." Then you create a new File geodatabase and then right click and "Import from XML." [read more here](http://help.arcgis.com/en/arcgisdesktop/10.0/help/index.html#//003n00000032000000). These File Geodabases are in the data directory. 

[3] Since the 2012 Data included more than 100 tables, we created the sql to merge the tables using `5_merge_tables_for_lookup_plpgsql.sql`
