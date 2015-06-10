#from http://stackoverflow.com/questions/3518218/moving-a-database-with-pg-dump-and-psql-u-postgres-db-name-results-in-er
#Dump all global objects, such as users and group
pg_dumpall -g -U postgres > /vm_project_dir/globals.sql

#Dump schema of database:
pg_dump -Fp -s -v -f /vm_project_dir/db-schema.sql -U postgres mtc

#Dump contents of database:
pg_dump -Fc -v -f /vm_project_dir/full.dump -U postgres mtc

#to restore:

# sudo -u postgres psql -f globals.sql
# psql -f schema.sql dbname
# pg_restore -a -d dbname -Fc full.dump

#write to s3
today="$(date +'%Y/%m/%d')"
aws s3 cp /vm_project_dir/globals.sql s3://landuse/spandex/outputs/${today}/globals.sql
aws s3 cp /vm_project_dir/full.dump s3://landuse/spandex/outputs/${today}/full.dump
aws s3 cp /vm_project_dir/db-schema.sql s3://landuse/spandex/outputs/${today}/db-schema.sql
