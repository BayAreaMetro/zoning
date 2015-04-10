# Goal

The goal of this repository is to keep track of how data from various jurisdictions and sources about zoning were mapped to parcel data. 

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
  
  Same as above but with fields that have a value in the "match field" as specified in the CityAssignments spreadsheet. 
  Missing zoning Data is visible by visually comparing the zoning.lookup_new_valid table and the zoning.regional table. It      appears that in some case an entire jursidictions may be missing, but in another just 1 category (e.g. public space in san jose)

 see process/lookup-table-merge-2012-zoning.sql for how this was loaded into postgres from source

#####Parcels

* 1953960 parcels (valid geoms).
  
  These were from [spandex](https://github.com/synthicity/spandex)
 
####Intersection:
see process/source_intersection_zoning.sql for how this was done

* 1820670 parcel intersections with zoning (many to many join--st_intersects)

* 1311776 parcels intersect with one zoning geometry

* 462655 parcels intersect with more than 1 zoning geometry

###Final Output Table/CSV Process
see process/source_intersection_zoning.sql for how this was done

First, we selected the 1311776 parcels that intersect with one zoning geometry and inserted those into the table. 

Next, we added parcels that intersected with multiple zones as follows. 

We chose these parcels from a table of:
parcel_overlaps - a table of parcels with multiple zoning intersections
(each row includes parcel+any intersecting zone)
921221 rows

We chose them by the largest proportion of area of intersection. However, tens of thousands of parcels have more than 1 100% overlapping zoning geometry (see below). For those that had 1 maximum zoning overlap, we selected it and added it. 
This added 390363 rows. 

The final table includes roughly ~1.7m parcels, which is about 200k less than the spandex output. 

#####Parcels With 2 Overlapping Zones
We set aside a table of parcels where there were more than 1 equal max values for their intersection. 
145309 rows affected
(typically, these are 1 parcel with 2 100% overlaps, so figure about 70k parcels with 2x zones). 
These data can be downloaded as a shapefile [here](https://mtcdrive.box.com/s/7zzjl6o4knjje1ocwncnqx7e9aprmv6i)

Many of these seem to be related to overlapping city/county zoning geometries. We use use census-based definitions of jurisdiction to decide which zone a parcel falls in.

####Future Work:
#####Match Field Errors

In the zoning codes base table, the contents of some cities' match fields do not correspond to sourze zoning data (probably due to some kind of character error in excel or user entry). Need to deal with these individually.  

- Richmond
- Napa (some RI categories)

#####Fill in Missing Areas 

These are listed in ZoningMerge.md notes. We willsource results from the Update9 Geodatabase found in the source data. These data are in the form of zoning information mapped to parcels. We will join them to new parcels spatially. 
