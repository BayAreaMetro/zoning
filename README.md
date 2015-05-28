###Intro 

Produce a CSV with a generic zoning code assigned to every parcel in the SF Bay Area in 2010. 

###Requirements

[GNU Make](http://bost.ocks.org/mike/make/), PostGIS 2.1, Postgres 9.3, GDAL 1.11 or > (with both FileGDB driver and Postgres driver), [Amazon CLI](https://aws.amazon.com/cli/)

You can use the vagrant scripts here to set up an environment:  
https://github.com/buckleytom/postgis-gdal-ubuntu

###Usage

The Makefile contains all the necessary pointers to what data is needed, where to get it, scripts to load it into Postgres, and scripts to join source parcel and zoning data. 

If you're using this repository, you probably need to change something: the zoning file for a particular jurisdiction, or the parcel data that are being used. You may be working on the Land Use server at MTC, where there is a VM at NAPA/D/VMs/salter that contains a postgres database loaded with the most recent tables of the run of this script. If you are concerned about whether that VM is up to date, check the git log of the /zoning folder in there to see whether it is up to date with this repository. 

There are more make targets than are documented in this readme, which may be useful to you for whatever you are doing. Generic ones are at the bottom of the Makefile (e.g. `make clean_database`). Look at Loading/Processing for more on where you might need to start. 

####Data
The following are required: 

filename|description
---------------|--------------
jurisdictional/*.shp | Zoning v2 A directory of shapefiles, one for each jurisdiction in the bay area for which we have data from the [6 Geodatabases]((http://landuse.s3.amazonaws.com/zoning/PlannedLandUse1Through6.gdb.zip)) discussed below.
PLU2008_Updated.shp | Zoning v1 From the Planned Land Use project by ABAG
parcels_spandex.sql | Parcels v2 from [spandex](https://github.com/synthicity/spandex)
ba8parcels.sql | Parcels v1 From [feature class ba8 of this ParcelsBuildings.gdb GDB](http://landuse.s3.amazonaws.com/zoning/ParcelsBuildings.gdb.zip)
city10_ba.shp | city boundaries (2010 census) MTC edits for water-features and others
county10_ca.shp | county boundaries (2010 census) MTC edits for water-features and others
zoning_codes_base2012.csv | Use these to map specific jurisdictional zoning to a generic taxonomy-from this [table](http://landuse.s3.amazonaws.com/zoning/zoning_codes_base2012.csv)
match_fields_tables_zoning_2012_source.csv | Names the column used in Zoning V2 which is used in the zoning taxonomy - from the [Project Management Spreadsheet](http://landuse.s3.amazonaws.com/zoning/CityAssignments_Nov3_2014.xlsx) - described below
Parcels2010_Update9.csv | an update to missing jurisdictions (see below) - from forensic analysis of received data
plu06_may2015estimate.shp | PLU 2006 data from ABAG

It is recommended to use the makefile to fetch the above. They are hosted on MTC s3. You will need MTC s3 keys to authenticate for fetching data with the Makefile. Alternatively, you can download landuse bucket zoning folder from the s3 web interface and put it in a folder called `data_source/` in the same directory as this Makefile, however this is not recommended given the number of files required. 

To use the Makefile to get data, you will need Amazon's Command Line Interface:

https://aws.amazon.com/cli/

####Loading/Processing

If you already have the environment set up, then run:

`make load_data`  

This will download and load the necessary data into Postgres for processing. 

If you are updating a single city's zoning table, you will need to update it (see Zoning Data by Jurisdiction) and then run 

`make merge_source_zoning`

This creates a postgres table with all of the geometries of the source jurisdictional zoning in /data_source/jurisdictional. See [#zoning-data-by-jurisdiction] for more information. 

Next run:
(NOTE: this task takes 3 to 6 hours on a machine with A LOT of resources)

`make zoning_parcel_intersection`

This make target assigns a zoning_id (as found in the data_source/zoning_codes_base2012.csv) to each parcel. Several rules are applied to overcome issues with parcels that within multiple jurisdictions, and/or within multiple zoning geometries. 

Then run:
(NOTE: takes 45 minutes on a machine with A LOT of resources)

`make add_plu_2006`

To fill in parcels not yet filled with data from the '06 ABAG PLU project. Note that this last step resulted in a change in deliverable, from a two table system [(zoning id's, characteristics);(zoning_id's,geom_ids)] to a single table system [geom_id's, characteristics]. This change was to achieve approximately 200k in additional zoning assignments to parcels. 

###Zoning data by Jurisdiction
The command `make load_data` extracts the source zoning File Geodatabases to shapefiles in a folder in /jurisdictional. You can edit, inspect and change which data are used by jurisdiction here. Keep in mind that whatever changes you make, each jurisidictional zoning file must have a zoning column which maps to the generic zoning codes and match fields as specified by jurisidction in zoning_codes_base2012.csv and match_fields_tables_zoning_2012_source.csv. 
Also, all source zoning jurisdiction files are in [EPSG 26910](http://epsg.io/26910). 

### Outcome

####The Current Table:
Can be found [here](https://mtcdrive.box.com/s/4ytig75parn4mur4nci707kwlxxila4t)

The outcome of Loading/Processing is ~~a table with three rows: parcel_id, zoning_id, prop~~ a table with columns as specific in the "Fields in the Main Zoning Table" section of this README. 

Where 'NA' and -9999 represent values that don't exist. 

####Fields in the Main Zoning Table

column name|description|source (if applicable)
----|----------------|------------------
id|generic zoning id|zoning_codes_base2012
juris|jurisdiction id|zoning_codes_base2012
city|city name|zoning_codes_base2012
name|string of zoning type from source data|zoning_codes_base2012
min_far|minimum floor-to-area ratio
max_far|maximum floor-to-area ratio
max_height|maximum height
min_front_setback|
max_front_setback|
side_setback|
rear_setback|
min_dua|minimum dwelling units per acre
max_dua|maximum dwelling units per acre
coverage|
max_du_per_parcel|maximum dwelling units per parcel
min_lot_size|
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

####Notes/Appendix

######Stats on the output
you can use the branch at https://github.com/MetropolitanTransportationCommission/zoning/tree/qa-stats to run stats on the tables output by the above process. 

######Project Management Spreadsheet

Our starting point for this work is a spreadsheet that was used to manage this project originally. It is available [here](http://landuse.s3.amazonaws.com/zoning/CityAssignments_Nov3_2014.xlsx). While this spreadsheet did not represent the zoning data project in its entirety, it offers a high level summary that we took as authoritative. In the process below it will be clear where the spreadsheet was missing information that we will add into the process as part of the final product. 

According to the above spreadsheet, [6 Geodatabases](http://landuse.s3.amazonaws.com/zoning/PlannedLandUse1Through6.gdb.zip) were used to manage the geographic data for this project, each containing feature classes for the various jurisdictions in the Bay Area. Our first step was to load the geometries from all of these feature classes into one table so that we could relate it to a table of geometries for parcel data. 




Potential Places and categories needing improvement in source data:
######Santa Clara City
The feature class for Santa Clara City in the base Geodatabases mentioned in [Project Management Spreadsheet] did not have a "match field" corresponding to the spreadsheet. That is, in the spreadsheet, the indicated "matchfield" was 'gp_designa'. However, that field does exist the feature class in the Geodatabase. We found a shapefile in the Santa Clara city folder that does have that matchfield which seems to be dated '02', so we use that, assuming that the feature class in the GDB was improperly added. However, there is also another shapefile in that folder that seems to match the feature class in the Geodatabases. This file may be more recent, since it seems to have a date in the name that is '05', however it was not part of the original process and has no generic zoning assignment. 

######Fairfield:
We need to add these data using a parcel-to-parcel match as with update9.sql, above. It seems there is are no vector data for source image of zoning. However, there is a spreadsheet mapping joinnuma to zoning_id. 

######Missing categories from Matchfields:
* Napa (some RI categories)  
  Does not have a Match field - It seems that zone_desg was used though, although in the general table the spaces are replaced with - that is, RS 4 IS RS-4
* public space in san jose
* https://github.com/MetropolitanTransportationCommission/zoning-qa/blob/master/process/richmondmatchcodes.sql###L31
