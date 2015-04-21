mkdir data_source/jurisdictional

ogrinfo data_source/PlannedLandUsePhase1.gdb | tail -n +4 | cut -d " " -f2 | \
xargs -I {} ogr2ogr -f "ESRI Shapefile" data_source/jurisdictional/{}.shp data_source/PlannedLandUsePhase1.gdb/ {}

ogrinfo data_source/PlannedLandUsePhase2.gdb | tail -n +4 | cut -d " " -f2 | \
xargs -I {} ogr2ogr -f "ESRI Shapefile" data_source/jurisdictional/{}.shp data_source/PlannedLandUsePhase2.gdb/ {}

ogrinfo data_source/PlannedLandUsePhase3.gdb | tail -n +4 | cut -d " " -f2 | \
xargs -I {} ogr2ogr -f "ESRI Shapefile" data_source/jurisdictional/{}.shp data_source/PlannedLandUsePhase3.gdb/ {}

ogrinfo data_source/PlannedLandUsePhase4.gdb | tail -n +4 | cut -d " " -f2 | \
xargs -I {} ogr2ogr -f "ESRI Shapefile" data_source/jurisdictional/{}.shp data_source/PlannedLandUsePhase4.gdb/ {}

ogrinfo data_source/PlannedLandUsePhase5.gdb | tail -n +4 | cut -d " " -f2 | \
xargs -I {} ogr2ogr -f "ESRI Shapefile" data_source/jurisdictional/{}.shp data_source/PlannedLandUsePhase5.gdb/ {}

ogrinfo data_source/PlannedLandUsePhase6.gdb | tail -n +4 | cut -d " " -f2 | \
xargs -I {} ogr2ogr -f "ESRI Shapefile" data_source/jurisdictional/{}.shp data_source/PlannedLandUsePhase6.gdb/ {}