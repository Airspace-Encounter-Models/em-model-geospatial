# Uncorrelated Geospatial Model

MATLAB code to generate representative UAS trajectories based on open source geospatial features, such as those provided by OpenStreetMap.

Development is ongoing and future updates to this software are expected. This software is in the open [beta / preview stage](https://en.wikipedia.org/wiki/Software_release_life_cycle). Documentation will be improved in future updates.

- [Uncorrelated Geospatial Model](#uncorrelated-geospatial-model)
	- [Nomenclature](#nomenclature)
	- [Overview](#overview)
		- [Contribution](#contribution)
	- [Initial Setup](#initial-setup)
		- [Create Persistent System Environment Variable](#create-persistent-system-environment-variable)
		- [Scripts](#scripts)
		- [em-core](#em-core)
	- [Run Order](#run-order)
		- [0. Startup](#0-startup)
		- [1. Parse Geofabrik OSM Extracts](#1-parse-geofabrik-osm-extracts)
			- [OSMParse](#osmparse)
		- [2. Generate trajectories](#2-generate-trajectories)
			- [GenerateTracks](#generatetracks)
		- [3. Pair Trajectories](#3-pair-trajectories)
	- [Citations](#citations)
		- [Technical Concept](#technical-concept)
		- [OpenStreetMap](#openstreetmap)
		- [Geofabrik](#geofabrik)
	- [Distribution Statement](#distribution-statement)

## Nomenclature

Acronym | Phrase
 :--- | :---
AGL| above ground level
BVLOS | beyond visual line of sight
CFIT | controlled flight into terrain
MSL | mean sea level
OSM | OpenStreetMap

## Overview

### Contribution

Our overall objective was the development of low altitude unmanned and manned aircraft encounter models to support DAA research. A public, easily accessible corpus of UAS trajectories, however, is not available since beyond visual line of sight (BVLOS) operations are not routine and there is a lack of reporting requirements. Therefore, we seek to generate representative BVLOS UAS trajectories without actual UAS flights as training data.

## Initial Setup

This section specifies the run order and requirements for the initial setup the repository. Other repositories in this organization are reliant upon this setup being completed.

### Create Persistent System Environment Variable

 Immediately after cloning this repository, [create a persistent system environment](https://superuser.com/q/284342/44051) variable titled `AEM_DIR_GEOSPATIAL` with a value of the full path to this repository root directory.

On unix there are many ways to do this, here is an example using [`/etc/profile.d`](https://unix.stackexchange.com/a/117473). Create a new file `aem-env.sh` using `sudo vi /etc/profile.d/aem-env.sh` and add the command to set the variable:

```bash
export AEM_DIR_GEOSPATIAL=PATH TO DIRECTORY
```

You can confirm `AEM_DIR_GEOSPATIAL` was set in unix by inspecting the output of `env`.

### Scripts

This is a set of boilerplate scripts describing the [normalized script pattern that GitHub uses in its projects](https://github.blog/2015-06-30-scripts-to-rule-them-all/). The [GitHub Scripts To Rule Them All](https://github.com/github/scripts-to-rule-them-all) was used as a template. Refer to the [script directory README](./script/README.md) for more details.

You will need to run these scripts in this order to download the open source geospatial data.

1. [`script/setup.sh`](script/setup.sh)

### em-core

Complete the initial setup of the [`em-core`](https://github.com/Airspace-Encounter-Models/em-core) repository.

## Run Order

Code developed in Windows for Matlab 2018a. The dev machine had a CPU of Intel Xeon Gold 6130 at 2.10GHz and 64 GB of RAM. The built-in Matlab function `parfor` is used routinely throughout the code. With a local parallel pool (`parpool`) of 12 nodes, Matlab can claim 42+ GB of RAM and 50% CPU. Majority of the computation intensive work is related to working with digital elevation models.

### 0. Startup

Run the MATLAB startup script, [`startup_geospatial`](startup_geospatial.m).

### 1. Parse Geofabrik OSM Extracts

First, run [`RUN_1_OSM`](RUN_1_OSM.m) which calls [`OSMParse`](./code/osm/OSMParse.m) to load and parse the [Geofabrik OpenStreetMap extracts](./data/OSM/README.md). This will create a set of MATLAB tables for each specified ISO-3166-2 administrative boundary corresponding to features for land use, points of interest, railway, transportation, waterways, and roadways. This step is only for the OpenStreetMap data, other data sources are directly loaded and parsed in [Step 2 run script examples](#2-generate-trajectories).

#### OSMParse

Specifically, [`OSMParse`](./code/osm/OSMParse.m) has the following input parameters:

| Variable  |  Description | Example |
| :-------------| :--  | :-- |
| iso_3166_2 | Features to based trajectories off of | `US-MA`
| isSave | If true, save to file | `true`
| outName | Output filename | `OSM_1_US-MA.mat`
| isComputeElv | If true, calculate elevation for each feature | `false`
| dem | Digital elevation model name | `globe`

### 2. Generate trajectories

1. RUN in MATLAB, the `RUN_2-*` scripts to generate trajectories for specific features of interest. Trajectories will be rejected if projected to CFIT.

| Script  | Type | Generated Trajectories
| :------------- | :-- | :-- |
[`RUN_2_Landuse_POIS`](RUN_2_Landuse_POIS.m) | Pattern | Inspections of features of OSM points of interest polygons (e.g. golf course) or land use polygons (e.g. beach, cliff, farm, vineyard, etc.)
[`RUN_2_DOF`](RUN_2_DOF.m) | Point | Obstacle inspection
[`RUN_2_WindTurbine`](RUN_2_WindTurbine.m) | Point | Wind turbine inspection
[`RUN_2_ElectricTransmission`](RUN_2_ElectricTransmission.m) | Track | Electric power transmission line inspection
[`RUN_2_GSHHG`](RUN_OSM_2_GSHHG.m) | Track | Coastline and shoreline inspections
[`RUN_2_Pipeline`](RUN_2_Pipeline.m) | Track | Four types of pipeline inspection
[`RUN_2_Railway`](RUN_2_Railway.m) | Track | Railway inspection
[`RUN_2_Road`](RUN_2_Road.m) | Track | Freeway and primary road inspection
[`RUN_2_Waterway`](RUN_2_Waterway.m) | Track | Large river, stream, artificial waterway, and small drainage ditch inspection

#### GenerateTracks

Specifically, [`GenerateTracks`](./code/tracks/GenerateTracks.m) has the following input parameters:

| Variable  |  Description | Example |
| :-------------| :--  | :-- |
| S | Features to based trajectories off of | 
| outDirBase | Name of parent output directory | `[getenv('AEM_DIR_GEOSPATIAL') filesep 'output' filesep 'trajectories' filesep 'US-MA]`
| airspace | Output of [`RUN_Airspace_1.m`](https://github.com/Airspace-Encounter-Models/em-core/blob/master/matlab/utilities-1stparty/airspace/RUN_Airspace_1.m) from `em-core` | `[getenv('AEM_DIR_CORE') filesep 'output' filesep 'airspace.mat'];`
| alt_tol_ft | Altitude tolerance for terrain following | `25`
| demDir | Directory containing DEM | `[getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-SRTM1']`
| dem | Digital elevation model name | `srtm1`
| demDir | Directory containing backup DEM | `[getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-GLOBE']`
| dem | Digital elevation model name of backup | `globe`
| alt_ft_agl | Cruise altitude in feet AGL | `400`
| airspeed_kt | Cruise airspeed in knots | `60`
| climbRate_fps | Maximum climb rate | `16`
| descendRate_fps | Maximum descent rate | `-16`
| maxSpacing_ft | Maximum allow able spacing between sequential waypoints | `2000`
| trackMode | Trajectory behavior | `holdalt`
| pointRadius_ft | Lateral distance away from point being inspected | `250`
| pointHeight_ft | Maximum height when inspecting a point | `50`
| pointPts | Number of points when inspecting a point | `100`
| vertLef_ft | Vertical distance travel for each complete spiral leg | `25`
| S_obstacle | Table of obstacles that can't be flown through (deprecated) | `[]`
| isCheckObstacle | If true, remove trajectories that fly through any `S_obstacle` (deprecated) | `false`
| isRePathObstacle | If true, try to path plan around obstacles (deprecated) | `false`

### 3. Pair Trajectories

Refer to the [`em-pairing-geospatial`](https://github.com/Airspace-Encounter-Models/em-pairing-geospatial) or [`em-pairing-uncor-importancesampling`](https://github.com/Airspace-Encounter-Models/em-pairing-uncor-importancesampling) repositories on how to pair the generated trajectories to create encounters.

## Citations

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5115120.svg)](https://doi.org/10.5281/zenodo.5115120)

**Fill in once released**

### Technical Concept

<details> <summary> A. Weinert, M. Edwards, L. Alvarez, and S. Katz, “Representative Small UAS Trajectories for Encounter Modeling,” in AIAA Scitech 2020 Forum, 2020, pp. 1–10.</summary>
<p>

```tex
@inproceedings{weinertGeneratingRepresentativeSmall2018,
  title = {Representative Small UAS Trajectories for Encounter Modeling},
	url = {https://doi.org/10.2514/6.2020-0741},
	doi = {10.2514/6.2020-0741},
  booktitle = {AIAA Scitech 2020 Forum},
author = {Andrew J. Weinert and Matthew Edwards and Luis Alvarez and Sydney Michelle Katz},
	month = jan,
	year = {2020},
}
```
</p>
</details>

<details> <summary> A. Weinert and N. Underhill, “Generating Representative Small UAS Trajectories using Open Source Data,” in 2018 IEEE/AIAA 37th Digital Avionics Systems Conference (DASC), 2018, pp. 1–10.</summary>
<p>

```tex
@inproceedings{weinertGeneratingRepresentativeSmall2018,
	title = {Generating {Representative} {Small} {UAS} {Trajectories} using {Open} {Source} {Data}},
	url = {https://ieeexplore.ieee.org/document/8569745},
	doi = {10.1109/DASC.2018.8569745},
	booktitle = {2018 {IEEE}/{AIAA} 37th {Digital} {Avionics} {Systems} {Conference} ({DASC})},
	author = {Weinert, Andrew and Underhill, Ngaire},
	month = sep,
	year = {2018},
	keywords = {Aircraft, Atmospheric modeling, FAA, Monte Carlo methods, Standards, Surveillance, Trajectory},
	pages = {1--10}
}
```
</p>
</details>

### OpenStreetMap

This software uses data originally sourced from © OpenStreetMap contributors, which provides data under the [Open Database License](https://www.openstreetmap.org/copyright).

### Geofabrik

Geofabrik provides OpenStreetMap OSM extracts [free of restrictive licensing terms](https://www.geofabrik.de/geofabrik/free.html).

## Distribution Statement

DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited.

This material is based upon work supported by the Federal Aviation Administration under Air Force Contract No. FA8702-15-D-0001.

Any opinions, findings, conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the Federal Aviation Administration.

This document is derived from work done for the FAA (and possibly others), it is not the direct product of work done for the FAA. The information provided herein may include content supplied by third parties.  Although the data and information contained herein has been produced or processed from sources believed to be reliable, the Federal Aviation Administration makes no warranty, expressed or implied, regarding the accuracy, adequacy, completeness, legality, reliability or usefulness of any information, conclusions or recommendations provided herein. Distribution of the information contained herein does not constitute an endorsement or warranty of the data or information provided herein by the Federal Aviation Administration or the U.S. Department of Transportation.  Neither the Federal Aviation Administration nor the U.S. Department of Transportation shall be held liable for any improper or incorrect use of the information contained herein and assumes no responsibility for anyone’s use of the information. The Federal Aviation Administration and U.S. Department of Transportation shall not be liable for any claim for any loss, harm, or other damages arising from access to or use of data or information, including without limitation any direct, indirect, incidental, exemplary, special or consequential damages, even if advised of the possibility of such damages. The Federal Aviation Administration shall not be liable to anyone for any decision made or action taken, or not taken, in reliance on the information contained herein.
