#Intro 

Use this repo to produce a CSV with a generic zoning code assigned to every parcel in the SF Bay Area in 2010. 

#Requirements

PostGIS 2.1, Postgres 9.3, GDAL 1.11 or > (1.10 could work but you won't be able to read/write from source File GDBs)

You can use the vagrant scripts here to set up an environment on the MTC Land Use Server: https://github.com/buckleytom/pg-app-dev-vm/tree/landuse-specific.  

For computers with less RAM/CPU's, try: https://github.com/buckleytom/pg-app-dev-vm/tree/master  

#Usage

The Makefile contains all the high level instructions on what data is needed, where to get it, pointers to scripts to load it into Postgres, and how parcel and zoning data are joined. 

##Data
At a high level, the data required are: 

filename|description
---------------|--------------
ba8parcels.sql | From feature class in source FileGDB 
city10_ba.shp | city boundaries (2010 census) MTC edits for water-features and others
county10_ca.shp | county boundaries (2010 census) MTC edits for water-features and others
match_fields_tables_zoning_2012_source.csv | From the [Project Management Spreadsheet](https://mtcdrive.box.com/shared/static/gz1azbpqrtj4icrm61yupwii3zl5y335.xlsx) - described below
parcels_spandex.sql | from [spandex](https://github.com/synthicity/spandex)
Parcels2010_Update9.csv | from forensic analysis of received data
jurisdictional/*.shp | A directory of shapefiles, one for each jurisdiction in the bay area for which we have data from the [6 Geodatabases](https://mtcdrive.box.com/s/9t14sb7ugnx24hrp84kmvku0aq5gdb27) discussed below.
zoning_codes_base2012.csv | from this [table](https://mtcdrive.app.box.com/login?redirect_url=%2Fs%2F9pkjbw1lvpd5qtpj1zpc2ccfbxfzly5t)
PLU2008_Updated.shp	| From the Planned Land Use project by ABAG

The makefile will fetch all the required data. It is hosted on MTC s3. Ask Kearey Smith for access to the s3 land use bucket if you do not have it already. You can also also just download the folder from the s3 web interface and put it in a folder called  in the same directory as this Makefile. 

You can use your MTC s3 keys to authenticate. To set this up do:

'''
cat >/.s3curl <<EOL
%awsSecretAccessKeys = (
    # corporate account
    company => {
        id => 'REPLACE_ME_WITH_YOUR_KEY_ID(THE SHORTER ONE)',
        key => 'REPLACE_ME_WITH_YOUR_SECRET_KEY',
    },
);
... 
EOL
'''

then 'chmod 600 ~/.s3curl' to set this file's permissions to be for your user only. 

Then run 'make' in the repository directory.

##Loading/Processing

If you already have the data, then run 'make' in the repository directory.

# Outcome

The outcome of this process is a table with three rows: parcel_id, zoning_id, prop

We expect that this table will change as we improve on our methods for mapping zoning data to parcels. 

#The Current Table:
Can be found [here](https://mtcdrive.box.com/s/4ytig75parn4mur4nci707kwlxxila4t)

##Field Names
* 'geom_id' is the unique id of a parcel from [spandex](https://github.com/synthicity/spandex)
* 'prop' is the 'proportion of the parcel in the given zone'  
* 'zoning_id' is the id of a generic interpretation of the allowed use of a site as defined in this [table](https://mtcdrive.app.box.com/login?redirect_url=%2Fs%2F9pkjbw1lvpd5qtpj1zpc2ccfbxfzly5t)

##Zoning/Parcel Intersection

This is a walkthrough of how we joined source zoning data (loaded into postgres) with source_intersection_zoning.sql by the numbers.

####Combining the source Geographic Data:

#####Project Management Spreadsheet

Our starting point for this work is a spreadsheet that was used to manage this project originally. It is available [here](https://mtcdrive.box.com/shared/static/gz1azbpqrtj4icrm61yupwii3zl5y335.xlsx). While this spreadsheet did not represent the zoning data project in its entirety, it offers a high level summary that we took as authoritative. In the process below it will be clear where the spreadsheet was missing information that we will add into the process as part of the final product. 

According to the above spreadsheet, [6 Geodatabases](https://mtcdrive.box.com/s/9t14sb7ugnx24hrp84kmvku0aq5gdb27) were used to manage the geographic data for this project, each containing feature classes for the various jurisdictions in the Bay Area. Our first step was to load the geometries from all of these feature classes into one table so that we could relate it to a table of geometries for parcel data. 

Loading scripts for the source data are all in this repository in 'load/load-2012-zoning.sh'

* 224789 zoning geometries (valid geoms).
 
  See load-2012-zoning.sh for how this was loaded into postgres from source
  We know that a few jurisdictions are missing. See MergeZoningNotes.md for more info. 

* 221032 zoning geometries (with source field names).
  
  Same as above but with fields that have a value in the "match field" as specified in the CityAssignments spreadsheet (and corrected as specified in the [Match Field Errors](#match-field-errors) section. 

#####Parcels

* 1953960 parcels (valid geoms).
  
  These were from [spandex](https://github.com/synthicity/spandex)
 
####Assigning Zoning to Parcels:
see process/source_intersection_zoning.sql for how this was done

* 1820670 parcel intersections with zoning (many to many join--st_intersects)

* 1311776 parcels intersect with only one zoning geometry

* 462655 parcels intersect with more than 1 zoning geometry

see process/source_intersection_zoning.sql for how this was done

We selected the 1311776 parcels that intersect with only one zoning geometry and inserted those into the table. 

####Intersection Conflict Resolution and Identifying Further Zoning Source Data

see process/lookup-table-merge-2012-zoning.sql for how this was loaded into postgres from source

#####Parcels with more than 1 Zoning assignment

We assigned zoning to parcels that intersected with multiple zones as follows. 

We split these parcels into a table of:  
parcel_overlaps - a table of parcels with multiple zoning intersections  
(each row includes parcel+any intersecting zone)  
921221 parcel + zone combinations  

For each of these parcels, we selected the zoning category with the highest proportion of area of intersection with the parcel. However, tens of thousands of parcels have more than 1 100% overlapping zoning geometry (see below). For those that had 1 maximum zoning overlap, we selected it and added it. 
This added 390363 parcels to the parcels/zoning table.

At this point the parcels/zoning table contained roughly ~1.7m (1702139) parcels, which is about 200k less than the spandex output.

######Parcels with more than 1 Zoning assignment because of jursdiction overlaps
We set aside a table of parcels where there were more than 1 equal max values for their intersection.  
145309 rows affected. (typically, these are 1 parcel with 2 100% overlaps, so figure about 70k parcels with 2x zones).   
These data can be downloaded as a shapefile [here](https://mtcdrive.box.com/s/7zzjl6o4knjje1ocwncnqx7e9aprmv6i).  

Many of these seem to be related to overlapping city/county zoning geometries. We use use census-based definitions of jurisdiction to decide which zone a parcel falls in.  

Based on this work, the count of parcels for which we have sourced zoning data was at:  
1772637

####Other Errors

#####Match Field Errors

The [Project Management Spreadsheet](#####Project Management Spreadsheet) contains errors in the "match field" which is the field that matches the source jurisdiction's zoning definition to those in the zoning_id table which we use as an output -- see [field names](##Field-Names).  

We added these name fixes to the end of 'load/load-generic-zoning-code-table.sql', before [Assigning Zoning to Parcels](####Assigning-Zoning-to-Parcels).

One of these errors, in the Richmond feature class, we did not detect until after completing the above steps. We added the necessary line to the loading script for future use. Then we used the process detailed in 'process/richmondmatchcodes.sql', to load richmond individually and append its parcels/zoning. 

#####Geospatial Data Outside Project Geodatabases

These jurisdictions did not have feature classes in the source geodatabase:

* American Canyon
* Cloverdale
* Fairfield
* Healdsburg
* Piedmont
* Pinole
* San Ramon
* Saratoga
* Sebastopol

We added these using the process in:

* 'load/update9.sql'
* 'process/update9places.sql'

And this [data](https://mtcdrive.box.com/shared/static/45ylob77atbejk867bmmbtlhjuf0ikbm.zip), 
which is a csv with the zoning for the these areas mapped to "joinnuma", and therefore the set of [parcel data, found in feature class ba8 of this File GDB](https://mtcdrive.box.com/s/uec9rjz6cimvpizlb2so3pupm22d56dq) used for the last round of this work. The vectorization of zoning data for the above jurisdictions (which we have as PDF's and various other non-vector formats), seems not to have been shared by the contractor that performed it. See the comments in the sql above for where there may have been errors in mapping the data using a parcel-to-parcel spatial intersection.  

After adding these data, the count of parcels with zoning data is at:
1857290

Still left to look at:
######Santa Clara City
The feature class for Santa Clara City in the base Geodatabases mentioned in [Project Management Spreadsheet] did not have a "match field" corresponding to the spreadsheet. That is, in the spreadsheet, the indicated "matchfield" was 'gp_designa'. However, that field does exist the feature class in the Geodatabase. We found a shapefile in the Santa Clara city folder that does have that matchfield which seems to be dated '02', so we use that, assuming that the feature class in the GDB was improperly added. However, there is also another shapefile in that folder that seems to match the feature class in the Geodatabases. This file may be more recent, since it seems to have a date in the name that is '05', however it was not part of the original process and has no generic zoning assignment. 

######Fairfield:
We need to add these data using a parcel-to-parcel match as with update9.sql, above. It seems there is are no vector data for source image of zoning. However, there is a spreadsheet mapping joinnuma to zoning_id. 

######Missing categories from Matchfields:
* Napa (some RI categories)  
	Does not have a Match field - It seems that zone_desg was used though, although in the general table the spaces are replaced with - that is, RS 4 IS RS-4
* public space in san jose
* https://github.com/MetropolitanTransportationCommission/zoning-qa/blob/master/process/richmondmatchcodes.sql#L31
