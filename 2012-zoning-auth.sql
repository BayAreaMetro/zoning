CREATE TABLE zoning.parcels_auth 
AS SELECT a.parcel_id,a.zoning_id 
FROM (SELECT parcel_id, zoning 
	as zoning_id 
	FROM zoning.parcels03_19_2012) 
	as a;

