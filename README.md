# Goal

The goal of this repository is to keep track of how data from various jurisdictions and sources about zoning were mapped to parcel data. 

# Outcome

The outcome of this process is a table with two rows: parcel_id, zoning_id

We expect that this table will change as we improve on our methods for mapping zoning data to parcels. 

#The Current Table:
Can be found [here](https://mtcdrive.box.com/s/4ytig75parn4mur4nci707kwlxxila4t)

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