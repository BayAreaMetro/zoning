# land-use-zoning-checks
QA and cleaning of zoning data

Requirements to use these scripts include PostgreSQL, PostGIS, Python (psycopg2), and GDAL. 

## Combining Legacy Zoning Data

Our starting point is:

1. a legacy set of standardized zoning assignments according to parcel with the columns: parcel_id, zoning_id
2. a standardized zoning lookup table with the columns: zoning_id, allowed_use
3. a legacy set of parcel data with an ID and a geometry: parcel_id, geom

Because the accuracy and consistency of this data is critical to understanding regional growth, we started by studying the consistency with source data from regional and local jurisdications. Parcel data and zoning data are inconsistent at best, but we hope to at least understand how errors in it may affect our final analysis. 

Legacy zoning data also included regional zoning information:

1. A file compiled in 2008 that covers most of the region
2. A file compiled in 2012 that covers jurisdictions in more geographic detail.



Our first task was to construct a table of the parcels for which we did not have zoning information, and to understand whether these parcels were covered geographically by the zoning data compiled in 2008 and/or 2012. 

In order to accomplish this task, at a high level, we created tables with collections of all of the geometries for zoning in 2008 and then in 2012, and then cross-referenced them with our existing parcel geometries. 

At a technical level, 
These data were received as 2 Personal GeoDatabases. In both cases, each jurisdiction or geographic area has its own feature class. In the 2012 dataset, each feature class contained different columns. In the 2008 data set tables were consistent, with the exception of a Priority Development Areas feature class. 

We converted the personal Geodatabases to File GeoDatabases using ArcMap with an Editor License. In short, to do this you export the Personal Geodatabase to XML by right clicking on it (in ArcCatalog) and selecting "Export to XML." Then you create a new File geodatabase and then right click and "Import from XML." [read more here](http://help.arcgis.com/en/arcgisdesktop/10.0/help/index.html#//003n00000032000000)

After that, we used OGR2OGR to load the data into PostGIS. Example scripts are in this repository [here](https://github.com/MetropolitanTransportationCommission/land-use-zoning-checks/blob/master/copy_legacy_zoning_geodatabase_to_postgis). 

Since the 2012 Data included more than 100 tables, we adapted a script to merge the geometries into 1 lookup table as seen in this [script](https://github.com/MetropolitanTransportationCommission/land-use-zoning-checks/blob/master/merge_tables_for_lookup_plpgsql.sql)

Finally, we wanted to know which data was missing by administrative jurisdiction. 

For this final goal, we used a version of the Census Edges file for places that has been clipped for water features and city boundaries and several sql queries included in this repository. 


