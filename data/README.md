# Data

Directories to store geospatial datasets.

## Default Datasets

The following datasets have been used to generate representative trajectories:

| Source  | Data |
| :------------- | :-- |
Department of Homeland Security (DHS) Homeland Infrastructure Foundation-Level Data (HIFLD) | Electric Power Transmission Lines
Energy Information Administration (EIA) | Crude Oil Pipelines
Energy Information Administration (EIA) | Hydrocarbon Gas Liquid Pipelines
Energy Information Administration (EIA) | Natural Gas Pipelines
Energy Information Administration (EIA) | Petroleum Product Pipelines
Geofabrik | OpenStreetMap extracts
National Oceanic and Atmospheric Administration (NOAA) | Global Self-consistent, Hierarchical, High-resolution Geography Database (GSHHG)
Natural Earth (NE) | Roads
United States Geological Survey (USGS) | United States Wind Turbine Database (USWTDB)

## Other Datasets

The following datasets were identified for potential use in developing representative trajectories. The can potentially be leveraged with this open source code but they are not default nor developmental datasets.

### Airspace and Boundaries

* [FAA-National Security UAS Flight Restrictions](https://uas-faa.opendata.arcgis.com/datasets/0270b9d8a5d34217856cc03aaf833309_0)
* [FAA-Runways](http://ais-faa.opendata.arcgis.com/datasets/4d8fa46181aa470d809776c57a8ab1f6_0)
* [FAA-UAS Facility Map Data V2](https://uas-faa.opendata.arcgis.com/datasets/9fed384137ba47189c37c3249694041e_0)

### Federal / Nationwide

* [DOT-Dams](https://osav-usdot.opendata.arcgis.com/datasets/3e63fd98063f4a7fa1713bb62b0abe01_0?geometry=-32.871%2C3.287%2C-118.301%2C72.956)
* [HIFLD - NBI Bridges](https://hifld-geoplatform.opendata.arcgis.com/datasets/e02b036ccddf4a1a8f83b329940b41be_0?geometry=-68.82%2C17.802%2C-64.472%2C18.715)  
* [HIFLD-Natural Gas Liquid Pipelines](https://hifld-geoplatform.opendata.arcgis.com/datasets/natural-gas-liquid-pipelines)

### State / Local

* [AK-Transportation-Pipelines](http://www.asgdc.state.ak.us/#178)
* [AK-Transportation-Power Lines](http://www.asgdc.state.ak.us/#106)
* [Boston-Zoning Districts](https://data.boston.gov/dataset/zoning-districts)
* [Broward County-City Parks](http://gis.broward.org/GISData/Zipfiles/parkscity.zip)
* [Broward County-County Parks](http://gis.broward.org/GISData/Zipfiles/parkscounty.zip)
* [Broward County-Parcels](https://bcpasecure.net/InfoBroward/ProductMenu.asp) ($25 fee for custom property data files of Land Data File)
* [Denver-Zoning](https://www.denvergov.org/opendata/dataset/city-and-county-of-denver-zoning)
* [Denver-Building Outlines](https://www.denvergov.org/opendata/dataset/city-and-county-of-denver-building-outlines-2014)
* [Fort Lauderdale Zoning Districts](https://data-fortlauderdale.opendata.arcgis.com/datasets/zoning-districts?geometry=-82.019%2C25.929%2C-78.527%2C26.361)
* [Honolulu-Zoning Land Use Ordinance](http://honolulu-cchnl.opendata.arcgis.com/datasets/8068469b47834d3ca4bc299d4079f35f_0)
* [Kansas-Electric Transmission Lines](http://data.kansasgis.org/catalog/utilities_and_energy_resources/shp/elect_lines/KCC_ELTrans_170411.zip)
* [Massachusetts-Land Use (2005)](http://www.mass.gov/anf/research-and-tech/it-serv-and-support/application-serv/office-of-geographic-information-massgis/datalayers/lus2005.html)
* [Massachusetts-Protected and Recreational OpenSpace](http://www.mass.gov/anf/research-and-tech/it-serv-and-support/application-serv/office-of-geographic-information-massgis/datalayers/osp.html)
* [Massachusetts-Restricted MassGIS Data](http://www.mass.gov/anf/research-and-tech/it-serv-and-support/application-serv/office-of-geographic-information-massgis/order-restricted-data.htmls) (See note below)
* [Massachusetts-Trains](http://www.mass.gov/anf/research-and-tech/it-serv-and-support/application-serv/office-of-geographic-information-massgis/datalayers/trains.html)
* [Miami-Dade County GIS Open Data-Land Use](https://gis-mdc.opendata.arcgis.com/datasets/c33c1018d7b54b3ebf126da2d0e58e65_0)
* [Miami-Dade County GIS Open Data-Large Buildings 2013](https://gis-mdc.opendata.arcgis.com/datasets/1e87b925717747c7b59979caa7779039_1)
* [Miami-Dade County GIS Open Data-County Land Generalized](https://gis-mdc.opendata.arcgis.com/datasets/1172213a3e1243e0b2a8a513b05855d6_3)
* [New York State-Agricultural District Boundaries](http://gis.ny.gov/gisdata/inventories/details.cfm?DSID=400)
* [New York State-Hydrography 1:24,000](http://gis.ny.gov/gisdata/inventories/details.cfm?DSID=928)
* [Phoenix-City of Phoenix Parks](https://www.phoenix.gov/OpenDataFiles/Parks.txt)
* [Phoenix-Zoning](http://maps-phoenix.opendata.arcgis.com/datasets/d438c29d14ef407593279041e42fc015_0)
* [Phoenix-Park Boundary](http://maps-phoenix.opendata.arcgis.com/datasets/ec37c79e2c20440aa7eeaa5678ec309f_0)
* [Puerto Rico-Bridges](https://www.arcgis.com/home/item.html?id=bfd52bff528c4017be51fce9d3298464)

### Note regarding Restricted MassGIS Data

Complete basic contact information form at MassGIS website. Within 1-2 business days you should receive an email prompting you to download a .zip file. Download it and extract the contents into the appropriate directory. There are three restricted datasets: Public Water Supplies (Wells), MassDEP BWP Major Facilities, and Transmission Lines.  

## Distribution Statement

DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited.

This material is based upon work supported by the Federal Aviation Administration under Air Force Contract No. FA8702-15-D-0001.

Any opinions, findings, conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the Federal Aviation Administration.

This document is derived from work done for the FAA (and possibly others), it is not the direct product of work done for the FAA. The information provided herein may include content supplied by third parties.  Although the data and information contained herein has been produced or processed from sources believed to be reliable, the Federal Aviation Administration makes no warranty, expressed or implied, regarding the accuracy, adequacy, completeness, legality, reliability or usefulness of any information, conclusions or recommendations provided herein. Distribution of the information contained herein does not constitute an endorsement or warranty of the data or information provided herein by the Federal Aviation Administration or the U.S. Department of Transportation.  Neither the Federal Aviation Administration nor the U.S. Department of Transportation shall be held liable for any improper or incorrect use of the information contained herein and assumes no responsibility for anyone’s use of the information. The Federal Aviation Administration and U.S. Department of Transportation shall not be liable for any claim for any loss, harm, or other damages arising from access to or use of data or information, including without limitation any direct, indirect, incidental, exemplary, special or consequential damages, even if advised of the possibility of such damages. The Federal Aviation Administration shall not be liable to anyone for any decision made or action taken, or not taken, in reliance on the information contained herein.
