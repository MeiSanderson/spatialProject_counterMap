# ============================================================
#  data_pipeline.R
#  Loads and prepares all bench data for the Shiny app.
#
#  Produces:
#    baseMap                         — Aarhus municipality boundary (WGS84)
#    baseMap_utm                     — same, UTM 32N
#    aarhus_ringvej                  — ringvej polygon (WGS84)
#    aarhus_ringgade                 — ringgade polygon (WGS84)
#    benches_classified              — classified bench points (WGS84)
#    voronoi_labelled                — Voronoi polygons with category (UTM 32N)
#    bench_aarhus_night_streetNoise_50 — benches in ≥50 dB zones (UTM 32N)
# ============================================================

library(pacman)
pacman::p_load(sf, dplyr, osmdata, geodata, purrr)

# ------------------------------------------------------------
# 1. Base map — Aarhus municipality
# ------------------------------------------------------------

if (file.exists("data/gadm36_DNK_2_sp.rds")) {
  muns <- readRDS("data/gadm36_DNK_2_sp.rds") %>% st_as_sf()
} else {
  muns <- geodata::gadm(country = "Denmark", level = 2,
                        path = "data", version = "3.6") %>% st_as_sf()
}

muns$NAME_2[31] <- "Aarhus"
baseMap <- dplyr::filter(muns, NAME_2 == "Aarhus")
aarhus_municipality <- baseMap

# ------------------------------------------------------------
# 2. Ringvej / Ringgade polygons
# ------------------------------------------------------------

aarhus_ring     <- sf::read_sf("data/ringVejGade/ringVejGade.geojson")
aarhus_ringvej  <- dplyr::filter(aarhus_ring, Ringvejen == 1)
aarhus_ringgade <- dplyr::filter(aarhus_ring, Ringgaden == 1)

# ------------------------------------------------------------
# 3. Bench data — load from cache or fetch from OSM
# ------------------------------------------------------------

bench_cache <- "data/benches_osm_municipality.rds"

if (file.exists(bench_cache)) {
  benches <- readRDS(bench_cache)
} else {
  assign("has_internet_via_proxy", TRUE, environment(curl::has_internet))
  benches <- osmdata::opq(sf::st_bbox(baseMap)) %>%
    osmdata::add_osm_feature(key = "amenity", value = "bench") %>%
    osmdata::osmdata_sf() %>%
    purrr::pluck("osm_points") %>%
    sf::st_intersection(baseMap)
  saveRDS(benches, bench_cache)
}

# ------------------------------------------------------------
# 4. Classify benches
#    Logic mirrors MAIN.Rmd exactly:
#      hostile       — separated seats, armrest, or lying_down == no
#      sleep_friendly — can lie down, OR has backrest & no armrest
#      non_hostile   — no backrest (and not hostile)
#      NA            — insufficient tags to classify
# ------------------------------------------------------------

benches_classified <- benches %>%
  dplyr::mutate(
    
    has_backrest = dplyr::case_when(
      backrest == "yes" ~ TRUE,
      backrest == "no"  ~ FALSE,
      TRUE              ~ NA
    ),
    
    has_armrest = dplyr::case_when(
      armrest == "yes" ~ TRUE,
      armrest == "no"  ~ FALSE,
      TRUE             ~ NA
    ),
    
    can_lie_down = dplyr::case_when(
      lying_down == "yes" ~ TRUE,
      lying_down == "no"  ~ FALSE,
      TRUE                ~ NA
    ),
    
    has_separated_seats = dplyr::case_when(
      seats.separated == "yes" ~ TRUE,
      seats.separated == "no"  ~ FALSE,
      TRUE                     ~ NA
    ),
    
    is_hostile = dplyr::case_when(
      # --- hostile ---
      has_separated_seats == TRUE                                    ~ "hostile",
      has_armrest         == TRUE                                    ~ "hostile",
      can_lie_down        == FALSE                                   ~ "hostile",
      # --- sleep-friendly ---
      can_lie_down == TRUE                                           ~ "sleep_friendly",
      has_backrest == TRUE & (is.na(has_armrest) | has_armrest == FALSE) ~ "sleep_friendly",
      # --- non-hostile ---
      has_backrest == FALSE                                          ~ "non_hostile",
      TRUE                                                           ~ NA_character_
    )
)

cat("Hostility classification (pre-noise):\n")
print(table(benches_classified$is_hostile, useNA = "always"))

# ------------------------------------------------------------
# 5. Reproject to UTM 32N for spatial operations
# ------------------------------------------------------------

baseMap_utm <- sf::st_transform(baseMap, 25832)
benches_utm <- sf::st_transform(benches_classified, 25832)

# ------------------------------------------------------------
# 6. Noise pollution — reclassify sleep_friendly/non_hostile
#    benches in >=50 dB zones as hostile
# ------------------------------------------------------------

noise_file <- "data/aarhus_night_streetNoise_municipality.gpkg"

if (file.exists(noise_file)) {
  aarhus_night_streetNoise      <- sf::st_read(noise_file, quiet = TRUE)
  aarhus_night_streetNoise_50   <- dplyr::filter(aarhus_night_streetNoise, isov1 >= 50)
  bench_aarhus_night_streetNoise_50 <- sf::st_intersection(
    benches_utm,
    sf::st_transform(aarhus_night_streetNoise_50, sf::st_crs(benches_utm))
  )
  
  # reclassify: any classified bench in a >=50 dB zone becomes hostile
  noise_ids <- bench_aarhus_night_streetNoise_50$osm_id
  benches_utm <- benches_utm %>%
    dplyr::mutate(is_hostile = dplyr::case_when(
      osm_id %in% noise_ids & !is.na(is_hostile) ~ "hostile",
      TRUE ~ is_hostile
    ))
  # keep benches_classified (WGS84) in sync
  benches_classified <- benches_classified %>%
    dplyr::mutate(is_hostile = dplyr::case_when(
      osm_id %in% noise_ids & !is.na(is_hostile) ~ "hostile",
      TRUE ~ is_hostile
    ))
  
} else {
  warning("Noise pollution data not found — noise reclassification will be unavailable.")
  bench_aarhus_night_streetNoise_50 <- benches_utm[0, ]
}

cat("Hostility classification (post-noise):\n")
print(table(benches_classified$is_hostile, useNA = "always"))

# ------------------------------------------------------------
# 7. Voronoi service areas
# ------------------------------------------------------------

voronoi_raw <- benches_utm %>%
  sf::st_geometry() %>%
  sf::st_union() %>%
  sf::st_voronoi() %>%
  sf::st_collection_extract("POLYGON") %>%
  sf::st_sf() %>%
  sf::st_intersection(sf::st_make_valid(baseMap_utm))

voronoi_labelled <- voronoi_raw %>%
  sf::st_join(benches_utm["is_hostile"], join = sf::st_nearest_feature) %>%
  dplyr::mutate(
    area_m2  = as.numeric(sf::st_area(geometry)),
    category = dplyr::case_when(
      is_hostile == "hostile"       ~ "Hostile",
      is_hostile == "sleep_friendly" ~ "Sleep-Friendly",
      is_hostile == "non_hostile"   ~ "Non-Hostile",
      TRUE                          ~ "Unknown"
    )
  )

cat(sprintf(
  "Voronoi: %d total | %d Hostile | %d Sleep-Friendly | %d Non-Hostile | %d Unknown\n",
  nrow(voronoi_labelled),
  sum(voronoi_labelled$category == "Hostile"),
  sum(voronoi_labelled$category == "Sleep-Friendly"),
  sum(voronoi_labelled$category == "Non-Hostile"),
  sum(voronoi_labelled$category == "Unknown")
))

# ------------------------------------------------------------
# 8. Save
# ------------------------------------------------------------

saveRDS(list(
  baseMap                           = baseMap,
  baseMap_utm                       = baseMap_utm,
  aarhus_municipality               = aarhus_municipality,
  aarhus_ringvej                    = aarhus_ringvej,
  aarhus_ringgade                   = aarhus_ringgade,
  benches_classified                = benches_classified,
  voronoi_labelled                  = voronoi_labelled,
  bench_aarhus_night_streetNoise_50 = bench_aarhus_night_streetNoise_50
), "app_data.rds")

cat("app_data.rds saved.\n")