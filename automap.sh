#!/bin/bash

####################### AUTOMAP ############################
# Run this script in an empty directory, it will           #
# download the specified map from Geofabrik the first      #
# time, then run it again to update the map automatically. #
# The script can manage one map per directory.             #
############################################################


########### CONFIGURATION ##############
#### MAP
# Specify map and continent name and paths
# from download.geofabrik.de
#
# e.g:
#
# MAP="great-britain"
# CONTINENT="europe"
#
# or:
#
# MAP="wales"
# CONTINENT="europe/great-britain"
#
# or:
#
# MAP="europe"
# CONTINENT=""

MAP="great-britain"
CONTINENT="europe"

#### TOOLS
# Required tools web pages:
# mkgmap: http://www.mkgmap.org.uk/download/mkgmap.html
# splitter: http://www.mkgmap.org.uk/download/splitter.html
# osmconvert: http://wiki.openstreetmap.org/wiki/Osmconvert
# osmfilter: http://wiki.openstreetmap.org/wiki/Osmfilter
# osmupdate: http://wiki.openstreetmap.org/wiki/Osmupdate

# Specify file names for tools, as given on their web pages

MKGMAP="mkgmap-r3057"
SPLITTER="splitter-r314"
OSMCONVERT="osmconvert.c"
OSMFILTER="osmfilter.c"
OSMUPDATE="osmupdate.c"

# Specify URLs for tools
# These depend on names above and are unlikely to change

MKGMAPURL="http://www.mkgmap.org.uk/download/"$MKGMAP".tar.gz"
SPLITTERURL="http://www.mkgmap.org.uk/download/"$SPLITTER".tar.gz"
OSMCONVERTURL="http://m.m.i24.cc/"$OSMCONVERT
OSMFILTERURL="http://m.m.i24.cc/"$OSMFILTER
OSMUPDATEURL="http://m.m.i24.cc/"$OSMUPDATE

############## END OF CONFIGURATION ###################


#### Backup maps
#if [ -e $MAP.pbf ]; then
#    mv -f $MAP.osm.pbf oldpbfmap
#fi
echo "-----> Backing up o5m map"
if [ -e $MAP.o5m ]; then
    mv -f $MAP.o5m oldo5mmap
fi
echo


#### Cleanup
echo "-----> Cleanup"
rm -rf *img osmmap.tdb template.args areas.* densities-out.txt bounds cities*.zip *.poly *osm.pbf *o5m

#rm -rf osmconvert* osmfilter* osmupdate* splitter* mkgmap*
echo


echo "-----> Downloading tools"
if [ ! -e $MKGMAP ]; then
    echo "Installing mkgmap"
    wget $MKGMAPURL
    tar xf mkgmap*.tar.gz
fi
if [ ! -e $SPLITTER ]; then
    echo "Installing splitter"
    wget $SPLITTERURL
    tar xf splitter*.tar.gz
fi
if [ ! -e $OSMCONVERT ]; then
    echo "Installing osmconvert"
    wget $OSMCONVERTURL
    gcc osmconvert.c -lz -O2 -o osmconvert
fi
if [ ! -e $OSMFILTER ]; then
    echo "Installing osmfilter"
    wget $OSMFILTERURL
    gcc osmfilter.c -O2 -o osmfilter
fi
if [ ! -e $OSMUPDATE ]; then
    echo "Installing osmupdate"
    wget $OSMUPDATEURL
    gcc osmupdate.c -O2 -o osmupdate
fi
echo


#### Download poly file
POLYURL="http://download.geofabrik.de/$CONTINENT/$MAP.poly"

echo "-----> Downloading poly file"
wget $POLYURL

echo


#### Update maps
if [ -e "oldo5mmap" ]; then
    echo "-----> Updating o5m map"
    ./osmupdate -v oldo5mmap $MAP.o5m -B=$MAP.poly
    echo
else
    PBFMAPURL="http://download.geofabrik.de/$CONTINENT/$MAP-latest.osm.pbf"
    echo "----> Downloading pbf map"
    wget $PBFMAPURL
    echo
    echo "-----> Convert pbf map to o5m"
    ./osmconvert --verbose $MAP-latest.osm.pbf --out-o5m > $MAP.o5m
    echo
    echo "-----> Updating o5m map"
    mv -f $MAP.o5m oldo5mmap
    ./osmupdate -v oldo5mmap $MAP.o5m -B=$MAP.poly
    echo
fi


#### Split map
echo "-----> Splitting map"
CITIES="cities15000.zip"
CITIESURL="http://download.geonames.org/export/dump/"$CITIES
wget $CITIESURL
java -Xmx2048m -jar $SPLITTER/splitter.jar --geonames-file=$CITIES --output=o5m $MAP.o5m
echo


#### Extract boundaries
echo "-----> Extracting boundaries"
./osmfilter --verbose $MAP.o5m --keep-nodes= --keep-ways-relations="boundary=administrative =postal_code postal_code=" --out-o5m > $MAP-boundaries.o5m
echo

echo "-----> Preprocessing boundaries"
java -Xmx2048M -cp $MKGMAP/mkgmap.jar uk.me.parabola.mkgmap.reader.osm.boundary.BoundaryPreprocessor $MAP-boundaries.o5m bounds
echo


#### Create IMG file
# This is the mkgmap command used to generate the gmapsupp.img Garmin map file.
# Modify options and use your custom styles here.
# Options are described at http://wiki.openstreetmap.org/wiki/Mkgmap/help/options
# Several examples are given below, they work well for a bike GPS (Edge 705)


echo "-----> Creating gmapsupp.img file"

java -Xmx2048M -jar $MKGMAP/mkgmap.jar --route --latin1 --bounds=bounds --location-autofill=bounds,is_in,nearest --adjust-turn-headings --link-pois-to-ways --ignore-turn-restrictions --ignore-maxspeeds --check-roundabouts --make-all-cycleways --add-pois-to-areas --preserve-element-order --add-pois-to-lines --index --gmapsupp -c template.args

#java -Xmx3000M -jar $MKGMAP/mkgmap.jar --route --latin1 --bounds=bounds --location-autofill=bounds,is_in,nearest --adjust-turn-headings --link-pois-to-ways --ignore-turn-restrictions --ignore-maxspeeds --check-roundabouts --make-all-cycleways --add-pois-to-areas --preserve-element-order --add-pois-to-lines --reduce-point-density=5.4 --reduce-point-density-polygon=8 --min-size-polygon=10 --index --gmapsupp --style-file=style_CF --family-id=1500 -c template.args CFMaster_FID_1500.TYP

#java -Xmx3000M -jar $MKGMAP/mkgmap.jar --route --latin1 --bounds=bounds --location-autofill=bounds,is_in,nearest --adjust-turn-headings --link-pois-to-ways --ignore-turn-restrictions --ignore-maxspeeds --check-roundabouts --make-all-cycleways --add-pois-to-areas --preserve-element-order --add-pois-to-lines --index --gmapsupp --style-file=style_world --family-id=2000 -c template.args 2000.TYP

#java -Xmx3000M -jar $MKGMAP/mkgmap.jar --route --latin1 --bounds=bounds --location-autofill=bounds,is_in,nearest --adjust-turn-headings --link-pois-to-ways --ignore-turn-restrictions --ignore-maxspeeds --check-roundabouts --make-all-cycleways --add-pois-to-areas --preserve-element-order --add-pois-to-lines --index --gmapsupp --style-file=style_CF --family-id=1500 -c template.args CFMaster_FID_1500.TYP

echo
