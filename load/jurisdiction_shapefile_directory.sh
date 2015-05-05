mkdir jurisdictional

ogrinfo PlannedLandUsePhase1.gdb | tail -n +4 | cut -d " " -f2 | \
xargs -I {} ogr2ogr -f "ESRI Shapefile" jurisdictional/{}.shp PlannedLandUsePhase1.gdb/ {}

ogrinfo PlannedLandUsePhase2.gdb | tail -n +4 | cut -d " " -f2 | \
xargs -I {} ogr2ogr -f "ESRI Shapefile" jurisdictional/{}.shp PlannedLandUsePhase2.gdb/ {}

ogrinfo PlannedLandUsePhase3.gdb | tail -n +4 | cut -d " " -f2 | \
xargs -I {} ogr2ogr -f "ESRI Shapefile" jurisdictional/{}.shp PlannedLandUsePhase3.gdb/ {}

ogrinfo PlannedLandUsePhase4.gdb | tail -n +4 | cut -d " " -f2 | \
xargs -I {} ogr2ogr -f "ESRI Shapefile" jurisdictional/{}.shp PlannedLandUsePhase4.gdb/ {}

ogrinfo PlannedLandUsePhase5.gdb | tail -n +4 | cut -d " " -f2 | \
xargs -I {} ogr2ogr -f "ESRI Shapefile" jurisdictional/{}.shp PlannedLandUsePhase5.gdb/ {}

ogrinfo PlannedLandUsePhase6.gdb | tail -n +4 | cut -d " " -f2 | \
xargs -I {} ogr2ogr -f "ESRI Shapefile" jurisdictional/{}.shp PlannedLandUsePhase6.gdb/ {}