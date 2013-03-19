automap
=======

Script that automatically creates an up-to-date routable OpenStreetMap for a specified region in Garmin img format:

- downloads map generation tools (mkgmap, splitter, osm*) from their respective sites
- downloads a map from geofabrik.de: the first time, downloads the full specified map and updates it to latest OSM timestamp. If a map is already present in the directory, it only updates it, using the correct poly file for the map.
- handles pbf to o5m conversion
- splits maps using GeoName cities list
- extracts and preprocesses boundaries (administrative and postal codes)
- creates a routable map in Garmin format (gmapsupp.img) using your options and style
