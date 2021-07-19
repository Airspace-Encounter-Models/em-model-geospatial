# Copyright 2018 - 2021, MIT Lincoln Laboratory
# SPDX-License-Identifier: BSD-2-Clause
#!/bin/sh

# script/setup:
# Set up application for the first time after cloning, 
# or set it back to the initial first unused state.

####### DOWNLOAD Natural Earth Roads
URL_NE_ROADS="https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_roads_north_america.zip"

# Download file
wget $URL_NE_ROADS -O $AEM_DIR_GEOSPATIAL/data/NE-Roads-NA/ne_roads_current.zip

# Extract all files
unzip -j -o $AEM_DIR_GEOSPATIAL/data/NE-Roads-NA/ne_roads_current.zip -d $AEM_DIR_GEOSPATIAL/data/NE-Roads-NA/

####### DOWNLOAD EIA PIPELINES
URL_EIA_COP="https://www.eia.gov/maps/map_data/CrudeOil_Pipelines_US_EIA.zip"
URL_EIA_HGL="https://www.eia.gov/maps/map_data/HGL_Pipelines_US_EIA.zip"
URL_EIA_NGP="https://www.eia.gov/maps/map_data/NaturalGas_InterIntrastate_Pipelines_US_EIA.zip"
URL_EIA_PPP="https://www.eia.gov/maps/map_data/PetroleumProduct_Pipelines_US_EIA.zip"

# Download files
wget $URL_EIA_COP -O $AEM_DIR_GEOSPATIAL/data/EIA-CrudeOilPipelines/eia_cop_current.zip
wget $URL_EIA_HGL -O $AEM_DIR_GEOSPATIAL/data/EIA-HydrocarbonGasLiquidPipelines/eia_hgl_current.zip
wget $URL_EIA_NGP -O $AEM_DIR_GEOSPATIAL/data/EIA-NaturalGasPipelines/eia_ngp_current.zip
wget $URL_EIA_PPP -O $AEM_DIR_GEOSPATIAL/data/EIA-PetroProductPipeline/eia_ppp_current.zip

# Extract all files
unzip -j -o $AEM_DIR_GEOSPATIAL/data/EIA-CrudeOilPipelines/eia_cop_current.zip -d $AEM_DIR_GEOSPATIAL/data/EIA-CrudeOilPipelines/
unzip -j -o $AEM_DIR_GEOSPATIAL/data/EIA-HydrocarbonGasLiquidPipelines/eia_hgl_current.zip -d $AEM_DIR_GEOSPATIAL/data/EIA-HydrocarbonGasLiquidPipelines/
unzip -j -o $AEM_DIR_GEOSPATIAL/data/EIA-NaturalGasPipelines/eia_ngp_current.zip -d $AEM_DIR_GEOSPATIAL/data/EIA-NaturalGasPipelines/
unzip -j -o $AEM_DIR_GEOSPATIAL/data/EIA-PetroProductPipeline/eia_ppp_current.zip -d $AEM_DIR_GEOSPATIAL/data/EIA-PetroProductPipeline/

####### DOWNLOAD Global Self-consistent, Hierarchical, High-resolution Geography Database (GSHHG)
URL_GSHHG="https://www.ngdc.noaa.gov/mgg/shorelines/data/gshhg/latest/gshhg-shp-2.3.7.zip"

# Download file
wget $URL_GSHHG -O $AEM_DIR_GEOSPATIAL/data/GSHHG/gshhg_current.zip

# Unzip all files (does not use -j option)
unzip -o $AEM_DIR_GEOSPATIAL/data/GSHHG/gshhg_current.zip -d $AEM_DIR_GEOSPATIAL/data/GSHHG/

####### DOWNLOAD DHS HIFLD Electric Power Transmission LInes
URL_EPTS="https://opendata.arcgis.com/datasets/70512b03fe994c6393107cc9946e5c22_0.zip"

# Download file
wget $URL_EPTS -O $AEM_DIR_GEOSPATIAL/data/HIFLD-ElectricPowerTransmissionLines/epts_current.zip

# Unzip all files
unzip -j -o $AEM_DIR_GEOSPATIAL/data/HIFLD-ElectricPowerTransmissionLines/epts_current.zip -d $AEM_DIR_GEOSPATIAL/data/HIFLD-ElectricPowerTransmissionLines/

####### DOWNLOAD US WIND TURBINE DATABASE
URL_USWTDB="https://eerscmap.usgs.gov/uswtdb/assets/data/uswtdbSHP.zip"

# Download file from USGS website
wget $URL_USWTDB -O $AEM_DIR_GEOSPATIAL/data/USGS-WindTurbineDB/uswtdb_current.zip

# Unzip all files
unzip -j -o $AEM_DIR_GEOSPATIAL/data/USGS-WindTurbineDB/uswtdb_current.zip -d $AEM_DIR_GEOSPATIAL/data/USGS-WindTurbineDB/

####### DOWNLOAD GEOFABRIK OSM EXTRACTS
URL_GEOFABRIK_BASE="download.geofabrik.de/north-america/us"

# Create arrays
states=alabama:alaska:arizona:arkansas:california/norcal:california/socal:colorado:connecticut:delaware:florida:georgia:hawaii:idaho:illinois:indiana:iowa:kansas:kentucky:louisiana:maine:maryland:massachusetts:michigan:minnesota:mississippi:missouri:montana:nebraska:nevada:new-hampshire:new-jersey:new-mexico:new-york:north-carolina:north-dakota:ohio:oklahoma:oregon:pennsylvania:rhode-island:south-carolina:south-dakota:tennessee:texas:utah:vermont:virginia:washington:west-virginia:wisconsin:wyoming:puerto-rico

iso=US-AL:US-AK:US-AZ:US-AR:US-CA/norcal:US-CA/socal:US-CO:US-CT:US-DE:US-FL:US-GA:US-HI:US-ID:US-IL:US-IN:US-IA:US-KS:US-KY:US-LA:US-ME:US-MD:US-MA:US-MI:US-MN:US-MS:US-MO:US-MT:US-NE:US-NV:US-NH:US-NJ:US-NM:US-NY:US-NC:US-ND:US-OH:US-OK:US-OR:US-PA:US-RI:US-SC:US-SD:US-TN:US-TX:US-UT:US-VT:US-VA:US-WA:US-WV:US-WI:US-WY:US-PR

# Iterate over arrays to download data and extract into directories
# https://www.rosettacode.org/wiki/Loop_over_multiple_arrays_simultaneously#UNIX_Shell
# http://www.jochenhebbrecht.be/site/2012-10-25/linux/changing-a-forward-slash-another-character-in-bash
oldifs=$IFS
IFS=:
i=0
for wa in $states; do
	set -- $iso; shift $i; wb=$1

	URL_CURRENT=$URL_GEOFABRIK_BASE/$wa-latest-free.shp.zip
	FILE_DOWNLOAD=$AEM_DIR_GEOSPATIAL/data/OSM/$(echo $wb | sed -e 's/\//-/g').zip
	DIR_UNZIP=$AEM_DIR_GEOSPATIAL/data/OSM/$wb

	#echo $URL_CURRENT
	#echo $FILE_DOWNLOAD
	#echo $DIR_UNZIP

	# Download file 
	wget $URL_CURRENT -O $FILE_DOWNLOAD

	# Create directory
	mkdir -p $DIR_UNZIP

	# unzip only airspace class shape files
	# -j strips all path info, and all files go into the target 
	# -o to silently force overwrite
	# https://unix.stackexchange.com/a/59285/1408
	unzip -j -o $FILE_DOWNLOAD -d $DIR_UNZIP

	#printf '%s%s\n' $wa $wb

	# Advance counter
	i=`expr $i + 1`
done
IFS=$oldifs
