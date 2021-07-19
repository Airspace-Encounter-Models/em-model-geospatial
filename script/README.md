# Scripts

This is a set of boilerplate scripts describing the [normalized script pattern that GitHub uses in its projects](https://github.blog/2015-06-30-scripts-to-rule-them-all/). The [GitHub Scripts To Rule Them All
](https://github.com/github/scripts-to-rule-them-all) was used as a template. They were tested using Ubuntu 18.04.3 LTS on Windows 10.

- [Scripts](#scripts)
  - [`AEM_DIR_GEOSPATIAL` and Execution](#aem_dir_geospatial-and-execution)
  - [Dependencies](#dependencies)
    - [Linux Shell](#linux-shell)
    - [Proxy and Internet Access](#proxy-and-internet-access)
    - [Superuser Access](#superuser-access)
  - [The Scripts](#the-scripts)
    - [script/bootstrap](#scriptbootstrap)
    - [script/setup](#scriptsetup)
      - [Data](#data)
    - [script/update](#scriptupdate)
    - [script/server](#scriptserver)
    - [script/test](#scripttest)
    - [script/cibuild](#scriptcibuild)
    - [script/console](#scriptconsole)
  - [Distribution Statement](#distribution-statement)

## `AEM_DIR_GEOSPATIAL` and Execution

These scripts assume that `AEM_DIR_GEOSPATIAL` and `AEM_DIR_CORE` has been set. Refer to the repository root [README](../README.md) for instructions.

## Dependencies

### Linux Shell

The scripts need to be run in a Linux shell. For Windows 10 users, you can use [Ubuntu on Windows](https://tutorials.ubuntu.com/tutorial/tutorial-ubuntu-on-windows#0).

If you modify these scripts, please follow the [convention guide](https://github.com/Airspace-Encounter-Models/em-overview/blob/master/CONTRIBUTING.md#convention-guide) that specifies an end of line character of `LF (\n)`. If the end of line character is changed to `CRLF (\r)`, you will get an error like this:

```bash
./setup.sh: line 2: $'\r': command not found
```

Specifically for Windows users, system drive and other connected drives are exposed in the `/mnt/` directory. For example, you can access the Windows C: drive via `cd /mnt/c`.

### Proxy and Internet Access

The scripts will download data using [`curl`](https://curl.haxx.se/docs/manpage.html) and [`wget`](https://manpages.ubuntu.com/manpages/trusty/man1/wget.1.html), which depending on your security policy may require a proxy.

The scripts assume that the `http_proxy` and `https_proxy` linux environments variables have been set.

```bash
export http_proxy=proxy.mycompany:port
export https_proxy=proxy.mycompany:port
export ftp_proxy=proxy.mycompany:port
export no_proxy=mycompanydomain
```

You may also need to [configure git to use a proxy](https://stackoverflow.com/q/16067534). This information is stored in `.gitconfig`:

```git
[http]
	proxy = http://proxy.mycompany:port
```

### Superuser Access

Depending on your security policy, you may need to run some scripts as a superuser or another user. These scripts have been tested using [`sudo`](https://manpages.ubuntu.com/manpages/disco/en/man8/sudo.8.html). Depending on how you set up your system variables, you may need to call [sudo with the `-E` flag](https://stackoverflow.com/a/8633575/363829), preserve env.

## The Scripts

Each of these scripts is responsible for a unit of work. This way they can be called from other scripts.

This not only cleans up a lot of duplicated effort, it means contributors can do the things they need to do, without having an extensive fundamental knowledge of how the project works. Lowering friction like this is key to faster and happier contributions.

The following is a list of scripts and their primary responsibilities, however not all maybe implemented. All are documented to support future development.

### script/bootstrap

*This repository does not have a `script/bootstrap`*

`script/bootstrap` is used solely for fulfilling dependencies of the project, such as packages, software versions, and git submodules. The goal is to make sure all required dependencies are installed.

### script/setup

[`script/setup`][setup] is used to set up a project in an initial state. This is typically run after an initial clone, or, to reset the project back to its initial state. This is also useful for ensuring that your bootstrapping actually works well.

#### Data

Commonly used datasets are downloaded by [`script/setup`][setup]. For this repository, the [Geofabrik OSM extracts for the all 50 USA states and Puerto Rico](https://download.geofabrik.de/north-america.html) are downloaded. They are extracted using `unzip` which is installed by scripts in `em-core`.

Refer to the [data directory README](../data/README.md) for more details.

### script/update

*This repository does not have a `script/update`*

`script/update` is used to update the project after a fresh pull.

### script/server

*This repository does not have a `script/server`*

`script/server` is used to start the application.

### script/test

*This repository does not have a `script/test`*

`script/test` is used to run the test suite of the application.

### script/cibuild

*This repository does not have a `script/cibuild`*

`script/cibuild` is used for your continuous integration server. This script is typically only called from your CI server.

### script/console

*This repository does not have a `script/console`*

`script/console`console is used to open a console for your application.

## Distribution Statement

DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited.

This material is based upon work supported by the Federal Aviation Administration under Air Force Contract No. FA8702-15-D-0001.

Any opinions, findings, conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the Federal Aviation Administration.

This document is derived from work done for the FAA (and possibly others), it is not the direct product of work done for the FAA. The information provided herein may include content supplied by third parties.  Although the data and information contained herein has been produced or processed from sources believed to be reliable, the Federal Aviation Administration makes no warranty, expressed or implied, regarding the accuracy, adequacy, completeness, legality, reliability or usefulness of any information, conclusions or recommendations provided herein. Distribution of the information contained herein does not constitute an endorsement or warranty of the data or information provided herein by the Federal Aviation Administration or the U.S. Department of Transportation.  Neither the Federal Aviation Administration nor the U.S. Department of Transportation shall be held liable for any improper or incorrect use of the information contained herein and assumes no responsibility for anyone’s use of the information. The Federal Aviation Administration and U.S. Department of Transportation shall not be liable for any claim for any loss, harm, or other damages arising from access to or use of data or information, including without limitation any direct, indirect, incidental, exemplary, special or consequential damages, even if advised of the possibility of such damages. The Federal Aviation Administration shall not be liable to anyone for any decision made or action taken, or not taken, in reliance on the information contained herein.

<!-- Relative Links -->
[bootstrap]: bootstrap.sh
[setup]: setup.sh
[update]: update.sh
[server]: server.sh
[test]: test.sh
[cibuild]: cibuild.sh
[console]: console.sh
