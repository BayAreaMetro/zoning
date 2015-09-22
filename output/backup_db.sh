# from http://stackoverflow.com/questions/3518218/moving-a-database-with-pg-dump-and-psql-u-postgres-db-name-results-in-er
# Dump all global objects, such as users and group
sudo -u postgres pg_dumpall -g -U postgres > /vm_project_dir/globals.sql

# #Dump schema of database:
sudo -u postgres pg_dump -Fp -s -v -f /vm_project_dir/db-schema.sql -U postgres mtc

#Dump contents of database:
sudo -u postgres pg_dump -Fc -v -f /vm_project_dir/full.dump -U postgres mtc

#to restore:

# sudo -u postgres createdb mtc
# sudo -u postgres psql mtc -c "create extension postgis;"
# sudo -u postgres psql mtc -c "create extension postgis_topology;"
# sudo -u postgres psql -f globals.sql
# psql -f db-schema.sql mtc
# pg_restore -a -d mtc -Fc full.dump


