#Zoning Source GDB Merge

These are notes on merging together all of the tables from the source geodatabases for the generic zoning project. 

The associated merge code is in this repository (lookup-table-merge-2012-zoning.sql)

##Pacifica
pacificageneralplan, pacificagp_022009
Using pacificageneralplan and deleting pacificagp_022009 since it contains only 1 row and former has >400 

##Santa Clara 
santaclaracity_zoningfeb05, santaclaracountygenplan 
Removing santaclaracity for now because it doesn't seem that the city data here matches the match field? zoning names do not match city data--they seem to be from countygenplan.
The match field gp_designa does not exist in the city table.
May need to re-do the generic zoning process for this one

##Napa 
Does not have a Match field - It seems that zone_desg was used though, although in the general table the spaces are replaced with - that is, RS 4 IS RS-4

##Not in Geodatabase Sources
These jurisdictions did not have a table in the source geodatabase:

-American Canyon
-Cloverdale
-Fairfield
-Healdsburg
-Piedmont
-Pinole
-San Ramon
-Saratoga
-Sebastopol

This table in the GDB did not have an entry in the CityAssignments spreadsheet:

export_output

