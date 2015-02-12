Copy (select *, data_type from information_schema.columns
WHERE table_name = 'parcels_mpg'
ORDER BY column_name) 
To '/legacy/prcls_data_dict.csv' With CSV;