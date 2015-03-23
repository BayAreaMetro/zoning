# Goal

The goal of this repository is to keep track of how data from various jurisdictions and sources about zoning were mapped to parcel data. 

# Outcome

The outcome of this process is a table with two rows: parcel_id, zoning_id

We expect that this table will change as we improve on our methods for mapping zoning data to parcels. 

#The Current Table:
##Zoning/Parcel Intersection

This is a walkthrough of how we joined source zoning data (loaded into postgres) with source_intersection_zoning.sql by the numbers.

###Outcome Update:
We added the "prop" column to the stated outcome CSV, so that we know what proportion of the land area of a parcel was within the zoning id that we assigned to it.

####Source Data:

* 1953960 parcels (valid geoms)
see load-legacy-parcel-to-generic-code.sql for how this was loaded into postgres from source

* 224789 zoning geometries (valid geoms)
see load-2012-zoning.sh for how this was loaded into postgres from source

* 221032 zoning geometries (with source field names)
 Same as above but with fields that have a value in the "match field" as specified in the CityAssignments spreadsheet. 
 Missing zoning Data is visible by visually comparing the zoning.lookup_new_valid table and the zoning.regional table. It appears that in some case an entire jursidictions may be missing, but in another just 1 category (e.g. public space in san jose)

 see lookup-table-merge-2012-zoning.sql for how this was loaded into postgres from source
 
####Intersection:
see source_intersection_zoning.sql for how this was done

* 1820670 parcel intersections with zoning (many to many join--st_intersects)

* 1311776 parcels intersect with one zoning geometry

* 462655 parcels intersect with more than 1 zoning geometry

###Final Output Table/CSV Process
see source_intersection_zoning.sql for how this was done

First, we selected the 1311776 parcels that intersect with one zoning geometry and inserted those into the table. 

Next, we added parcels that intersected with multiple zones as follows. 

We chose these parcels from a table of:
parcel_overlaps - a table of parcels with multiple zoning intersections
(each row includes parcel+any intersecting zone)
921221 rows

We chose them by the largest proportion of area of intersection. However, tens of thousands of parcels have more than 1 100% overlapping zoning geometry (see below). For those that had 1 maximum zoning overlap, we selected it and added it. 
This added 390363 rows. 

The final table includes roughly ~170k parcels, which is about 20k less than the spandex output. 

####Parcels With 2 Overlapping Zones
We set aside a table of parcels where there were more than 1 equal max values for their intersection. 
145309 rows affected
(typically, these are 1 parcel with 2 100% overlaps, so figure about 70k parcels with 2x zones). 

#Process for Creating the Old Table
The current table is [here](https://mtcdrive.box.com/s/5kppk48fgh1953oj4w2ks50332de3uq5):
(badata/juris/loc/zoning/parcel_zoning_id_joinnuma.csv)

This table was made by selecting the best candidate files necessary to create it from a folder of legacy files, as detailed here in the file [here](https://github.com/MetropolitanTransportationCommission/land-use-zoning-checks/blob/master/forensics_project_management_folder.txt). We then used the sql [here](https://github.com/MetropolitanTransportationCommission/land-use-zoning-checks/blob/master/load-legacy-parcel-to-generic-code.sql) to load that data. 

#Generic Zoning Categories and Information (e.g. FAR)
These data are [here](https://mtcdrive.box.com/s/9pkjbw1lvpd5qtpj1zpc2ccfbxfzly5t)

They are from the source excel file (M:\Data\Urban\JurisdictionsPolicies\ZoningPlans\zoning_codes_base2012.xlsx) and no changes were made to them. 

# Next Version of Table

We are working on an updated version of the zoning to parcel mapping that joins the data to updated parcel data that we have received and attempts to develop a clearer solution to the problem where ~25% of parcels intersect with more than 1 zoning layer. 

## Problem Statement

We need to know how each parcel is zoned in order to estimate how and where development on parcels could change. 

## Method

First we ask, are any of the [parcels-without-zoning](#parcels-without-zoning) covered by geometry in [zoning-2008](#zoning-2008) or [zoning-2012](#zoning-2012)? If so, in which [place-names](#place-names)? 

Then, we create [re-built-parcel-data](#re-built-parcel-data), assigning zoning from [parcels-and-zoning](#parcels-and-zoning), if existing, then [zoning-2012](#zoning-2012), if existing, or [zoning-2008](#zoning-2008) if not. If not any zoning, report Null. 

Also, we summarize [re-built-parcel-data](#re-built-parcel-data) by [place-names](#place-names).

## Results:

1. Enumerate Parcels Missing Zoning Data (`parcels-without-zoning-create.py`)
2. Summarize Potential Sources of Missing Zoning Data (`data/qa-summary.csv`)
3. Source Missing Zoning Data (in progress)
4. Summarize Sourcing Process (in progress)

## Data 

###Legacy Data

####parcels-and-zoning
parcel_id, zoning_id 

in data/parcels_to_zoning_2012.csv

####zoning-and-use
zoning_id -> columns about allowed use 

in data/zoning_codes_base2012_sheet1.csv

####parcels
parcel_id, geometry 

in ParcelsBuildings.gdb.zip - Feature Class ba8

Note: Loaded Using QGIS

####zoning-2008
geometry -> zoning type (collected in 2008) - available for entire Bay Area. Mostly Homogeneous Schema [^2] 

in data/PLANNEDLANDUSE_2008.gdb

####zoning-2012
geometry -> zoning type (collected in 2012) - fewer jurisdictions than 2008. Heterogeneous Schema 

in data/zoning_2012.gdb

####place-names
The ADMINISTRATIVE.Places feature class from the MTC GIS Database (conversations with staff indicate that this may be from TomTom, although that would need to be confirmed.) (exported here to data/places.shp)

Note: Loaded from MTC GIS SQL Server to PostGIS using ArcMap

###New Data

####parcels-without-zoning:
(7). id, geometry
see `parcels-without-zoning-create.py`

####re-built-parcel-data:
(8). id, geometry, source table

[1] Please note that file naming conventions are copied from the source data naming conventions to avoid confusion. Ideally in the future, a consistent naming convention should be applied.

[2] These data were received as 2 Personal GeoDatabases. In both cases, each jurisdiction or geographic area has its own feature class. In the 2012 dataset, each feature class contained different columns. In the 2008 data set tables were consistent, with the exception of a Priority Development Areas feature class. We converted the personal Geodatabases to File GeoDatabases using ArcMap with an Editor License. In short, to do this you export the Personal Geodatabase to XML by right clicking on it (in ArcCatalog) and selecting "Export to XML." Then you create a new File geodatabase and then right click and "Import from XML." [read more here](http://help.arcgis.com/en/arcgisdesktop/10.0/help/index.html#//003n00000032000000). These File Geodabases are in the data directory. 

[3] Since the 2012 Data included more than 100 tables, we created the sql to merge the tables using `5_merge_tables_for_lookup_plpgsql.sql`
