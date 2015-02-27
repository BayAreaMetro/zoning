CREATE VIEW zoning.parcels_notin03_29_2012 AS
SELECT p1.parcel_id, p2.joinnuma
FROM zoning.parcels03_29_2012 as p1
    RIGHT JOIN public.parcels_mpg as p2 ON p1.parcel_id = p2.joinnuma;
SELECT count(*) FROM zoning.parcels_notin03_29_2012 WHERE parcel_id IS NULL;
--~76k