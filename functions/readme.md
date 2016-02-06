The functions in this directory can be used to generate SQL to help in the processing of zoning data. 

`zoning_functions.sql` contains the following:

1. `GetOverlaps() and GetOverlapsGeoid()` Are used to return statistics about the geometric overlap of multipolygon tables that are passed to them. They are called in function (3) below in order to determine which zoning categories to assign to a given parcel. Further documentation is available in the script itself. 

2. `fix_2012_geoms()` generates sql to check the validity of the geometry of the juridiction-based shapefiles. For every shapefile that is loaded from the /jurisdictional table to the zoning_2012_staging shema, SQL is generated to clean up the geometries in it. Also, an _invalid version of the table is created with those invalid geometries, in case we need to later debug the cleanup process. 

3. `overlap_2012()` generates sql to create tables where parcels are described by by the zoning geometries that overlay them, by jurisdiction. In the case that a zoning geometry cuts across a parcel, the tables that are output by this function cut the geometry of the parcel up according to the zoning geometries, and then assign columns that describe the relative area and proportion of the zoning coverage for each parcel. 

Example usage of (2) and (3):

```
psql dbname -f `2012_zoning.sql`
psql dbname -c `fix_2012_geoms(TRUE)`
psql dbname -c `overlap_2012(TRUE)`
```

Notice that by passing TRUE to the 2 functions, the SQL that is generated is immediately executed. Otherwise, the default is FALSE and the SQL is output to the terminal. Function (3) will take a long time to load if there are many large zoning shapefiles to process. 








