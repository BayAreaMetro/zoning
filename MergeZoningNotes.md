#notes on the source zoning geodatabase tables/project management spreadsheet

##pacifica - pacificageneralplan, pacificagp_022009

using pacificageneralplan and deleting pacificagp_022009 since it contains only 1 row and former has >400 

##santa clara - santaclaracity_zoningfeb05, santaclaracountygenplan - REMOVING SANTACLARACITY
DOESN'T SEEM THAT THE CITY DATA HERE MATCHES THE MATCH FIELD? ZONING NAMES DO NOT MATCH CITY DATA--THEY SEEM TO BE FROM COUNTYGENPLAN
the match field gp_designa does not exist in the city table
MAY NEED TO RE-DO THE GENERIC ZONING PROCESS FOR THIS ONE

##Napa 
does not have a Match field - It seems that zone_desg was used though, although in the general table the spaces are replaced with - that is, RS 4 IS RS-4

##Not in Geodatabase Sources
these jurisdictions did not have a table in the source geodatabases for zoning.

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

