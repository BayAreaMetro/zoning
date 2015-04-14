# data_source/zoning_codes_dictionary.sql: /zoning_data/zoning_codes_dictionary.csv
# 	psql -f load/load-generic-zoning-table.sql

# data_source/plannedlanduse.sql: data_source/PlannedLandUsePhase1.gdb
# 	bash load/load-2012-zoning.sh

data_source/PlannedLandUsePhase1.gdb: data_source/PlannedLandUse1Through6.gdb.zip
	unzip -d data_source/ data_source/PlannedLandUse1Through6.gdb.zip

data_source/PlannedLandUse1Through6.gdb.zip: s3-curl/s3curl.pl
	perl s3-curl/s3curl.pl --id=company 
	-- http://landuse.s3.amazonaws.com/zoning/PlannedLandUse1Through6.gdb.zip \
	-o data_source/PlannedLandUse1Through6.gdb.zip

data_source/zoning_data/zoning_codes_dictionary.csv: s3-curl/s3curl.pl
	perl s3-curl/s3curl.pl --id=company \
	-- http://landuse.s3.amazonaws.com/zoning/zoning_data/zoning_codes_dictionary.csv -o data_source/zoning_codes_dictionary.csv 

s3curl/s3curl.pl: s3curl.zip
	unzip s3-curl.zip

s3curl.zip:
	curl -o s3-curl.zip http://s3.amazonaws.com/doc/s3-example-code/s3-curl.zip
