import os
USERNAME = os.environ['LANDUSE_USERNAME']
PASSWORD = os.environ['LANDUSE_PASSWORD']
HOST = os.environ['LANDUSE_HOST']
PORT = 15432 # os.environ['LANDUSE_PORT']

import pandas as pd
import numpy as np
import psycopg2
import numpy 
import psycopg2.extras
psycopg2.extensions.register_adapter(numpy.int64, psycopg2._psycopg.AsIs)

try:
    conn=psycopg2.connect("dbname=landuse user=%s password=%s host=%s port=%s" % (USERNAME, PASSWORD, HOST, PORT))
except:
    print "I am unable to connect to the database."

psycopg2.extras.register_hstore(conn)
cur = conn.cursor()
cur.execute("""SELECT joinnuma, 
				zoning.select_generic_source(joinnuma), 
				select_source_att(j.geom)::hstore 
				FROM (SELECT joinnuma, geom
				FROM zoning.auth_geo
				ORDER BY random()
				LIMIT 20) j""")

sample = cur.fetchall()

#  = pd.Series([ for x in sample])

# prcl_has_zoning_id = prcl_ids.isin(znng_id_arry)

# parcels_without_zoning_ids = [not x for x in prcl_has_zoning_id]

# query_ids= list(prcl_ids[parcels_without_zoning_ids])

# #create new table from missing values
# prcls_mssng_znng_frm_db = cur.execute("CREATE TABLE zoning.nozoning AS SELECT * FROM parcels_mpg WHERE joinnuma = ANY(%s)",[query_ids])

# prcls_mssng_znng_frm_db = cur.execute("CREATE INDEX nozoning_gix ON zoning.nozoning USING GIST (geom);")

# conn.commit()

