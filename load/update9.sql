CREATE SCHEMA zoning;

DROP TABLE IF EXISTS zoning.update9;
CREATE TABLE zoning.update9
(JOINNUMA numeric,ID numeric,JURIS numeric,CITY numeric,NAME text,MIN_FAR text,MAX_FAR text,MAX_HEIGHT text,MIN_FRONT_ text,MAX_FRONT_ text,SIDE_SETBA text,REAR_SETBA text,MIN_DUA text,MAX_DUA text,COVERAGE text,MAX_DU_PER text,MIN_LOT_SI text,BUILDING_T text,HS text,HT text,HM text,OF_ text,HO text,SC text,IL text,IW text,IH text,RS text,RB text,MR text,MT text, ME text);

\COPY zoning.update9 FROM 'data_source/Parcels2010_Update9.csv' DELIMITER ',' CSV HEADER;

ALTER TABLE zoning.update9 ALTER COLUMN id TYPE int USING id::int;
ALTER TABLE zoning.update9 ALTER COLUMN joinnuma TYPE int USING joinnuma::int;
ALTER TABLE zoning.update9 ALTER COLUMN juris TYPE int USING juris::int;
ALTER TABLE zoning.update9 RENAME COLUMN id TO zoning_id;

DROP TABLE IF EXISTS zoning.update9_geo;
CREATE TABLE zoning.update9_geo AS
SELECT z.*, p.geom 
FROM zoning.update9 z,
public.parcels_mpg p
WHERE z.joinnuma =  p.joinnuma;

CREATE INDEX zoning_update9_geo ON zoning.update9_geo USING GIST (geom);