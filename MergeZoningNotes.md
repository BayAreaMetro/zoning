#Zoning Source GDB Merge

These are notes on merging together all of the tables from the source geodatabases for the generic zoning project. 

The associated merge code is in this repository. 

##pacifica - pacificageneralplan, pacificagp_022009
Using pacificageneralplan and deleting pacificagp_022009 since it contains only 1 row and former has >400 

##santa clara - santaclaracity_zoningfeb05, santaclaracountygenplan - REMOVING SANTACLARACITY
It doesn't seem that the city data here matches the match field? zoning names do not match city data--they seem to be from countygenplan
the match field gp_designa does not exist in the city table
may need to re-do the generic zoning process for this one

##Napa 
Does not have a Match field - It seems that zone_desg was used though, although in the general table the spaces are replaced with - that is, RS 4 IS RS-4

##Not in Geodatabase Sources
These jurisdictions did not have a table in the source geodatabase:

American Canyon
Cloverdale
Fairfield
Healdsburg
Piedmont
Pinole
San Ramon
Saratoga
Sebastopol

This table in the GDB did not have an entry in the CityAssignments spreadsheet:

export_output

