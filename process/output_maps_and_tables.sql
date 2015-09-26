


-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
----------OUTPUT RESULTING TABLE TO CSV----------
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

--\COPY zoning.parcel_invalid TO '/vm_project_dir/zoning/invalid_parcels.csv' DELIMITER ',' CSV HEADER;

--output a table with geographic information and generic code info for review

#\COPY zoning.parcel TO '/vm_project_dir/zoning/zoning_parcels.csv' DELIMITER ',' CSV HEADER;
\COPY zoning.parcel_nodev_remove_zoning_id TO '/vm_project_dir/zoning/zoning_parcels.csv' DELIMITER ',' CSV HEADER;