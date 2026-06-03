# Spatial Project 2026: Benchmarks for Care - Counter-Mapping Benches in Aarhus, Denmark

## Overview
### Project Description
This project investigates the structural and social accessibility of public benches in Aarhus municipality, Denmark, through the lens of hostile architecture and counter-mapping. Using bench data from OpenStreetMap and road traffic noise data from Miljøstyrelsen, benches are classified as hostile, non-hostile, or sleep-friendly on the basis of their design features and acoustic environment — with particular attention to their accessibility for people experiencing rough sleeping. A counter map hosted on our ShinyApp is proposed as a proof-of-concept for making visible the spatial realities that conventional cartographic data leaves unrecorded. The project is developed as part of the Spatial Analytics course within the bachelor-level elective Cultural Data Science at Aarhus University.

### Repository Structure [idk, just proposal]
```
data/
  └── gadm/                               # where the Danish municipality data is stored upon its download in MAIN.rmd
  └── ringVejGade/                        # our Aarhus areas based on Ringvejen and Ringgaden
  └── benches_osm_municipality.rds        # bench data for Aarhus municipality
  └── benches_osm_ringgade.rds            # bench data for Aarhus area based on Ringgaden
  └── benches_osm_ringvej.rds             # bench data for Aarhus area based on Ringvejen
  └── gadm36_DNK_2_sp.rds                 # saved version of the Danish municipality data
  └── aarhus_night_streetNoise_municipality.gpkg    # the road noise pollution data downloaded and restricted to Aarhus municipality in Road_Noise_Pollution_Data_Download.RMD
  └── aarhus_night_streetNoise_ringgade.gpkg        # the road noise pollution data downloaded and restricted to Aarhus area based on Ringgaden in MAIN.rmd in Road_Noise_Pollution_Data_Download.RMD
  └── aarhus_night_streetNoise_ringvej.gpkg         # the road noise pollution data downloaded and restricted to Aarhus area based on Ringvejen in MAIN.rmd in Road_Noise_Pollution_Data_Download.RMD

out/
  └── afterNoise_benchClassification_municipality.csv       # distribution of classified benches (also based on road noise pollution); Aarhus municipality
  └── afterNoise_benchClassification_ringgade.csv           # distribution of classified benches (also based on road noise pollution); Aarhus area based on Ringgaden
  └── afterNoise_benchClassification_ringvej.csv            # distribution of classified benches (also based on road noise pollution); Aarhus area based on Ringvejen
  └── benchesVSnoisePollution_municipality.csv              # counts and proportions of benches subjected to above 50 dB Lnight road noise; Aarhus municipality
  └── benchesVSnoisePollution_ringgade.csv                  # counts and proportions of benches subjected to above 50 dB Lnight road noise; Aarhus area based on Ringgaden
  └── benchesVSnoisePollution_ringvej.csv                   # counts and proportions of benches subjected to above 50 dB Lnight road noise; Aarhus area based on Ringvejen
  └── initial_benchClassification_municipality.csv          # distribution of classified benches (before road noise pollution); Aarhus municipality
  └── initial_benchClassification_ringgade.csv              # distribution of classified benches (before road noise pollution); Aarhus area based on Ringgaden
  └── initial_benchClassification_ringvej.csv               # distribution of classified benches (before road noise pollution); Aarhus area based on Ringvejen



MAIN.Rmd                                    # MAIN script
Road_Noise_Pollution_Data_Download.RMD      # not to be run; originally used for loading the road noise data

README.md
LICENSE.txt

```

## Usage

Set the chooseBasemap variable in the second code chunk of MAIN.Rmd to select the spatial extent for the analysis:

```R
chooseBasemap <- "municipality"  # options: "ringvej", "ringgade", "municipality"
```

This controls which basemap is used throughout — Aarhus municipality as a whole, or the smaller areas bounded by Aarhus ringvej or ringgade respectively.

**TO ADD MORE TEXT ABOUT SHINY> APP HERE**

### Data Preparation
Most data is downloaded or generated automatically on first run. However, note the following:

* Noise pollution data (from Miljøstyrelsen via MiljøGIS) exceeds GitHub's file size limits and cannot be downloaded programmatically. Pre-processed versions clipped to each basemap are saved in data/ and loaded directly — the code originally used for downloading the data can be found in the Road_Noise_Pollution_Data_Download.RMD, but should not be run.
* Output files (classification counts, noise proportion tables) are saved automatically to out/ during the run of MAIN.rmd.

All data uses the WGS84 (EPSG:4326) CRS; no manual CRS conversion is required on input. Voronoi analysis transforms to EPSG:25832 (UTM 32N) internally.


## License
Shield: [![CC BY 4.0][cc-by-shield]][cc-by]

This work is licensed under a
[Creative Commons Attribution 4.0 International License][cc-by].

[![CC BY 4.0][cc-by-image]][cc-by]

[cc-by]: http://creativecommons.org/licenses/by/4.0/
[cc-by-image]: https://i.creativecommons.org/l/by/4.0/88x31.png
[cc-by-shield]: https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg


## Authors and Contact Details
Aiswarya Roy (202308450@post.au.dk) and Mie Norre Engemann (202309344@post.au.dk)  
Cultural Data Science, Spatial Analytics - Spring 2026


