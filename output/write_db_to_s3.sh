today="$(date +'%Y/%m/%d/%H/%M')"
aws s3 cp /vm_project_dir/globals.sql s3://landuse/spandex/outputs/${today}/globals.sql
aws s3 cp /vm_project_dir/full.dump s3://landuse/spandex/outputs/${today}/full.dump
aws s3 cp /vm_project_dir/db-schema.sql s3://landuse/spandex/outputs/${today}/db-schema.sql