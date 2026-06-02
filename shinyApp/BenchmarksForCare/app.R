####################################################

# ============================================================
#
# BENCH-marks For Care — Shiny App
# Aarhus University | Cultural Data Science: Spatial Analytics
# Authors: Aiswarya Roy & Mie Norre Engemann
# GitHub:    aiswary-a      MeiSanderson
#
# ============================================================
#
# Assumes these objects are produced by data_pipeline.R:
#   benches_classified                : sf with is_hostile col
#   voronoi_labelled                  : sf with category + area_m2 (UTM 32N)
#   baseMap_utm                       : sf boundary polygon (UTM 32N)
#   aarhus_ringvej                    : sf polygon (WGS84)
#   aarhus_ringgade                   : sf polygon (WGS84)
#   aarhus_municipality               : sf polygon (WGS84)
#   bench_aarhus_night_streetNoise_50 : sf — benches in ≥50 dB zones
#
# ============================================================

# tryCatch(
#   source("data_pipeline.R"),
#   error = function(e) stop("data_pipeline.R failed to load: ", conditionMessage(e))
# )

app_data <- readRDS("app_data.rds")
list2env(app_data, envir = .GlobalEnv)

library(pacman)
pacman::p_load(
  shiny, leaflet, leaflet.extras, sf,
  tidyverse, ggplot2, plotly
)


# ── Colour palette (catalogue-inspired) ──────────────────────

NAVY         <- "#0d1b2a"
NAVY_MID     <- "#132336"
NAVY_LIGHT   <- "#1e3a5f"
ORANGE       <- "#e8651a"
ORANGE_LIGHT <- "#f59c5a"
WHITE        <- "#ffffff"

# bench point colours
BENCH_COLS <- c(
  hostile             = "#e8651a",   # orange
  non_hostile         = "#ffc425",   # yellow
  non_hostile_covered = "#52c48a"    # green
)

# voronoi fill colours (slightly muted)
VORONOI_COLS <- c(
  "Hostile"     = "#e8651a",
  "Non-Hostile" = "#ffc425",
  "Unknown"     = "#3a4a5a"
)

SUBMISSIONS_CSV <- "pending_submissions.csv"


# ── Language strings ──────────────────────────────────────────

i18n <- list(
  en = list(
    app_title      = "BENCH-marks For Care",
    app_sub        = "Mapping bench accessibility in Aarhus",
    nav_home       = "Home",
    nav_about      = "About",
    nav_resources  = "Further Reading",
    nav_feedback   = "Feedback",
    lang_toggle    = "DA",
    sec_basemap    = "Basemap",
    sec_layers     = "Layers",
    sec_noise      = "Noise Reclassification",
    noise_label    = "Reclassify benches as hostile if exposed to ≥50 dB (night)",
    lyr_voronoi    = "Voronoi service areas",
    lyr_hostile    = "Hostile benches",
    lyr_nonhostile = "Non-hostile benches",
    lyr_friendly   = "Non-hostile (covered) benches",
    lyr_unknown    = "Unclassified benches",
    lyr_submissions= "Pending submissions",
    sec_contribute = "Contribute",
    contribute_txt = "Click anywhere on the map to submit a bench.",
    btn_add        = "+ Add a bench",
    sec_stats      = "Summary Statistics",
    sec_graph      = "Homelessness in Aarhus",
    graph_note     = "Minimum estimates from VIVE biennial mapping reports (2009–2024).",
    bor_title      = "Homeless Bill of Rights",
    bor_attr       = "Source: Housing Rights Watch",
    card_title     = "Further Reading",
    about_title    = "About This Project",
    about_body     = "This project investigates the structural and social accessibility of public benches in Aarhus municipality through the lens of hostile architecture and counter-mapping. Developed as part of the Spatial Analytics course, Cultural Data Science, Aarhus University.",
    feedback_title = "Feedback & Contact",
    feedback_body  = "Have a correction, suggestion, or want to get in touch? Email us at: 202308450@post.au.dk or 202309344@post.au.dk",
    modal_title    = "Submit a bench for review",
    modal_loc      = "Location",
    modal_backrest = "Backrest",
    modal_armrest  = "Armrest",
    modal_liedown  = "Can lie down?",
    modal_covered  = "Covered/sheltered?",
    modal_sep      = "Separated seats?",
    modal_notes    = "Notes (optional)",
    modal_hint     = "Your submission appears on the map immediately and will be reviewed before being merged into the main dataset.",
    modal_cancel   = "Cancel",
    modal_submit   = "Submit for review",
    notif_thanks   = "Bench submitted — thank you!",
    pending_label  = "bench(es) pending review",
    overview_pre   = "Public benches are rarely just benches. In Aarhus, as across Denmark, the design and placement of urban seating reflects decisions — often unspoken — about who is welcome in public space and who is not. This counter-map visualises the structural accessibility of benches for people experiencing rough sleeping, drawing on OpenStreetMap data and road traffic noise measurements to classify each bench as",
    overview_post  = "or"
  ),
  da = list(
    app_title      = "BENCH-marks For Care",
    app_sub        = "Kortlægning af bænketilgængelighed i Aarhus",
    nav_home       = "Hjem",
    nav_about      = "Om projektet",
    nav_resources  = "Videre læsning",
    nav_feedback   = "Feedback",
    lang_toggle    = "EN",
    sec_basemap    = "Grundkort",
    sec_layers     = "Lag",
    sec_noise      = "Støjomklassificering",
    noise_label    = "Omklassificér bænke som fjendtlige ved ≥50 dB (nat)",
    lyr_voronoi    = "Voronoi-serviceområder",
    lyr_hostile    = "Fjendtlige bænke",
    lyr_nonhostile = "Ikke-fjendtlige bænke",
    lyr_friendly   = "Ikke-fjendtlige (overdækkede) bænke",
    lyr_unknown    = "Uklassificerede bænke",
    lyr_submissions= "Afventende indmeldinger",
    sec_contribute = "Bidrag",
    contribute_txt = "Klik et sted på kortet for at indmelde en bænk.",
    btn_add        = "+ Tilføj en bænk",
    sec_stats      = "Oversigtsstatistik",
    sec_graph      = "Hjemløshed i Aarhus",
    graph_note     = "Minimumsestimater fra VIVEs toårlige kortlægning (2009–2024).",
    bor_title      = "Hjemløses Rettigheder",
    bor_attr       = "Kilde: Housing Rights Watch",
    card_title     = "Videre læsning",
    about_title    = "Om dette projekt",
    about_body     = "Dette projekt undersøger den strukturelle og sociale tilgængelighed af offentlige bænke i Aarhus Kommune gennem linsen af fjendtlig arkitektur og mod-kortlægning. Udviklet som en del af kurset Spatial Analytics, Cultural Data Science, Aarhus Universitet.",
    feedback_title = "Feedback og kontakt",
    feedback_body  = "Har du en korrektion eller et forslag? Kontakt os: 202308450@post.au.dk eller 202309344@post.au.dk",
    modal_title    = "Indsend en bænk til gennemgang",
    modal_loc      = "Placering",
    modal_backrest = "Ryglæn",
    modal_armrest  = "Armlæn",
    modal_liedown  = "Kan man ligge ned?",
    modal_covered  = "Overdækket?",
    modal_sep      = "Adskilte sæder?",
    modal_notes    = "Noter (valgfrit)",
    modal_hint     = "Din indmelding vises straks på kortet og gennemgås inden integration.",
    modal_cancel   = "Annuller",
    modal_submit   = "Indsend til gennemgang",
    notif_thanks   = "Bænk indsendt — tak!",
    pending_label  = "bænk(e) afventer gennemgang",
    overview_pre   = "Offentlige bænke er sjældent bare bænke. I Aarhus, som i resten af Danmark, afspejler udformningen og placeringen af bymøbler beslutninger — ofte uskrevne — om, hvem der er velkomne i det offentlige rum, og hvem der ikke er. Dette mod-kort visualiserer den strukturelle tilgængelighed af bænke for personer, der sover udendørs, baseret på OpenStreetMap-data og vejtrafikstøjsmålinger, der klassificerer hver bænk som",
    overview_post  = "eller"
  )
)


# ── Homelessness data (manually editable) ────────────────────
## Values taken from: https://www.vive.dk/media/pure/dx3jdedv/25690457

homeless_data <- data.frame(
  year    = c(2009, 2011, 2013, 2015, 2017, 2019, 2022, 2024),
  denmark = c(4998, 5290, 5820, 6138, 6635, 6431, 5789, 5989),
  aarhus  = c(466,  588,  617,  668,  767,  750,  507,  556)
)


# ── Homeless Bill of Rights (headers only) ───────────────────
## Source: Housing Rights Watch / Aalborg Universitet
## https://udenfor.dk/wp-content/uploads/2024/09/20488_Aalborg_Universitet_Rettighedserklaering_UK_WEB.pdf

bill_of_rights <- list(
  en = list(
    list(num = "I",    text = "The Right to Housing"),
    list(num = "II",   text = "Access to Decent Emergency Accommodation"),
    list(num = "III",  text = "The Right to Use Public Space and to Move Freely Within It"),
    list(num = "IV",   text = "The Right to Equal Treatment"),
    list(num = "V",    text = "The Right to a Postal Address"),
    list(num = "VI",   text = "The Right to Basic Sanitary Facilities"),
    list(num = "VII",  text = "The Right to Emergency Services"),
    list(num = "VIII", text = "The Right to Vote"),
    list(num = "IX",   text = "The Right to Data Protection"),
    list(num = "X",    text = "The Right to Privacy"),
    list(num = "XI",   text = "The Right to Carry Out Practices Necessary to Survival Within the Law")
  ),
  da = list(
    list(num = "I",    text = "Retten til bolig"),
    list(num = "II",   text = "Retten til værdig nødovernatning"),
    list(num = "III",  text = "Retten til det offentlige rum"),
    list(num = "IV",   text = "Retten til ligebehandling"),
    list(num = "V",    text = "Retten til en adresse"),
    list(num = "VI",   text = "Retten til basale sanitære faciliteter"),
    list(num = "VII",  text = "Retten til akut hjælp"),
    list(num = "VIII", text = "Retten til at stemme"),
    list(num = "IX",   text = "Retten til databeskyttelse"),
    list(num = "X",    text = "Retten til privatlivets fred"),
    list(num = "XI",   text = "Retten til lovligt at gøre ting, som er nødvendige for at overleve")
  )
)


# ── Further reading cards ────────────────────────────────────

reading_cards <- list(
  list(
    title = "Den Udstødende By",
    desc  = "Exhibition catalogue on hostile design and law in Danish cities.",
    url   = "https://udenfor.dk/wp-content/uploads/2024/11/ProjektUdenfor_Katalog_Forsogsmuseet.pdf"
  ),
  list(
    title = "VIVE: Hjemløshed i Danmark 2024",
    desc  = "Biennial mapping of homelessness in Denmark.",
    url   = "https://www.vive.dk/da/udgivelser/hjemloeshed-i-danmark-2024-22375/"
  ),
  list(
    title = "Dark Design – Aalborg Universitet",
    desc  = "Ole B. Jensen's research project on social exclusion in urban space.",
    url   = "https://formkraft.dk/dark-design-hvad-sker-der-med-den-rummelige-by/"
  ),
  list(
    title = "Projekt Udenfor",
    desc  = "Danish NGO working on homelessness and exclusionary design.",
    url   = "https://udenfor.dk"
  ),
  list(
    title = "Homeless Bill of Rights",
    desc  = "Housing Rights Watch declaration of rights for people experiencing homelessness.",
    url   = "https://udenfor.dk/wp-content/uploads/2024/09/20488_Aalborg_Universitet_Rettighedserklaering_UK_WEB.pdf"
  ),
  list(
    title = "OpenStreetMap",
    desc  = "The open mapping platform used as the primary bench data source.",
    url   = "https://www.openstreetmap.org"
  )
)


# ── CSS ───────────────────────────────────────────────────────
## Built with paste0 rather than sprintf to avoid % conflicts in CSS

make_css <- function(NAVY, WHITE, NAVY_MID, ORANGE, ORANGE_LIGHT, NAVY_LIGHT) {
  paste0("
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=DM+Sans:wght@300;400;500;600&display=swap');

* { box-sizing: border-box; margin: 0; padding: 0; }

body, .shiny-input-container, .selectize-input, table {
  font-family: 'DM Sans', sans-serif;
  font-size: 14px !important;
  background: ", NAVY, ";
  color: ", WHITE, ";
}

/* ── Navbar ── */
.navbar {
  background: ", NAVY_MID, " !important;
  border-bottom: 2px solid ", ORANGE, " !important;
  padding: 0 24px;
  min-height: 52px;
}
.navbar-brand { display: none; }
.navbar-nav > li > a {
  font-family: 'DM Sans', sans-serif !important;
  color: #8a9bb0 !important;
  font-size: 1.3rem !important;
  text-transform: uppercase;
  letter-spacing: .1em;
  padding: 16px 18px !important;
  transition: color .2s;
}
.navbar-nav > li > a:hover { color: ", ORANGE, " !important; background: transparent !important; }
.navbar-nav > li.active > a {
  color: ", ORANGE, " !important;
  background: transparent !important;
  border-bottom: 2px solid ", ORANGE, ";
}

/* ── Title banner ── */
.title-banner {
  background: ", NAVY, ";
  border-bottom: 3px solid ", ORANGE, ";
  padding: 20px 36px 16px 36px;
  display: flex;
  align-items: baseline;
  gap: 24px;
}
.title-main {
  font-family: 'Bebas Neue', sans-serif;
  font-size: 3.6rem;
  color: ", WHITE, ";
  letter-spacing: .06em;
  line-height: 1;
}
.title-sub {
  font-family: 'DM Sans', sans-serif;
  font-size: 1rem;
  color: #8a9bb0;
  font-weight: 300;
  letter-spacing: .03em;
}

/* ── Page / tab backgrounds ── */
.tab-content { background: ", NAVY, "; }
body > .container-fluid { padding: 0 !important; }

/* ── Global Bootstrap overrides — must come after Shiny loads ── */
p, li, span, td, th, label, input, select, textarea, .checkbox label {
  font-size: inherit !important;
}
.shiny-input-container > label { font-size: 1.1rem !important; }

/* ── Overview banner ── */
.overview-banner {
  background: ", NAVY_MID, ";
  border-bottom: 1px solid ", NAVY_LIGHT, ";
  padding: 18px 36px;
}
.overview-inner {
  max-width: 1100px;
  margin: 0 auto;
  text-align: center;
}
.overview-text {
  font-size: 1.25rem !important;
  color: #a0b4c8;
  line-height: 1.75;
  margin: 0;
}
.ov-hostile  { color: #e8651a; font-weight: 600; }
.ov-friendly { color: #ffc425; font-weight: 600; }
.ov-covered  { color: #52c48a; font-weight: 600; }

/* ── Home layout: sidebar | map | rights panel ── */
.home-layout {
  display: grid;
  grid-template-columns: 290px 1fr 280px;
  gap: 0;
}

/* ── Sidebar ── */
.sidebar {
  background: ", NAVY_MID, ";
  border-right: 1px solid ", NAVY_LIGHT, ";
  overflow-y: auto;
  padding: 22px 18px;
  display: flex;
  flex-direction: column;
  gap: 22px;
}
.sidebar-section h5 {
  font-family: 'Bebas Neue', sans-serif;
  font-size: 1.45rem;
  letter-spacing: .08em;
  color: #8a9bb0;
  margin-bottom: 10px;
  padding-bottom: 6px;
  border-bottom: 1px solid ", NAVY_LIGHT, ";
}
.sidebar .form-control,
.sidebar .selectize-input {
  background: ", NAVY, " !important;
  border: 1px solid ", NAVY_LIGHT, " !important;
  color: ", WHITE, " !important;
  border-radius: 4px;
  font-size: 1.1rem !important;
}
.sidebar .checkbox label,
.sidebar .control-label { color: #a0b4c8 !important; font-size: 1.25rem !important; }
.sidebar .irs-single, .sidebar .irs-min, .sidebar .irs-max { color: #a0b4c8 !important; font-size: 1.1rem !important; }
.sidebar .irs-bar, .sidebar .irs-bar-edge {
  background: ", ORANGE, " !important;
  border-color: ", ORANGE, " !important;
}
.sidebar .irs-slider { background: ", ORANGE, " !important; }

/* ── Add bench button ── */
#open_submit {
  width: 100%;
  background: ", ORANGE, ";
  border: none;
  color: white;
  font-family: 'DM Sans', sans-serif;
  font-size: .95rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: .08em;
  padding: 11px;
  border-radius: 4px;
  cursor: pointer;
  transition: background .2s;
}
#open_submit:hover { background: #c9541a; }

/* ── Map ── */
.map-panel { position: relative; min-width: 0; display: flex; flex-direction: column; }
#map { height: 100% !important; width: 100% !important; min-height: 500px; }

/* ── Below-map: stats + wave graph ── */
.below-map {
  grid-column: 1 / -1;
  background: ", NAVY_MID, ";
  border-top: 1px solid ", NAVY_LIGHT, ";
  padding: 28px 36px;
  display: grid;
  grid-template-columns: 1fr 1.2fr 1fr;
  gap: 36px;
  align-items: start;
}
.below-map h5 {
  font-family: 'Bebas Neue', sans-serif;
  font-size: 1.8rem;
  letter-spacing: .06em;
  color: ", ORANGE, ";
  margin-bottom: 14px;
}

/* ── Stats table ── */
table.dataTable, .table {
  background: transparent !important;
  color: ", WHITE, " !important;
  font-size: 1.2rem !important;
  width: 100% !important;
}
table.dataTable thead th, .table thead th {
  color: #8a9bb0 !important;
  border-bottom: 1px solid ", NAVY_LIGHT, " !important;
  font-weight: 500;
  text-transform: uppercase;
  font-size: .9rem !important;
  letter-spacing: .08em;
}
table.dataTable tbody tr, .table tbody tr { background: transparent !important; }
table.dataTable tbody tr:hover, .table tbody tr:hover { background: ", NAVY_LIGHT, " !important; }
table.dataTable tbody td, .table tbody td { border-color: ", NAVY_LIGHT, " !important; }
.graph-note { font-size: .72rem !important; color: #5a6a7a; margin-top: 8px; font-style: italic; }

/* ── Rights panel ── */
.rights-panel {
  background: ", NAVY_MID, ";
  border-left: 1px solid ", NAVY_LIGHT, ";
  overflow-y: auto;
  padding: 22px 18px;
}
.rights-panel h5 {
  font-family: 'Bebas Neue', sans-serif;
  font-size: 1.8rem;
  letter-spacing: .06em;
  color: ", ORANGE, ";
  margin-bottom: 4px;
}
.rights-attr {
  font-size: .9rem !important;
  color: #5a6a7a;
  font-style: italic;
  margin-bottom: 16px;
}
.rights-item {
  display: flex;
  gap: 12px;
  margin-bottom: 14px;
  align-items: flex-start;
}
.rights-num {
  font-family: 'Bebas Neue', sans-serif;
  font-size: 1.3rem;
  color: ", ORANGE, ";
  min-width: 32px;
  padding-top: 1px;
}
.rights-text {
  font-size: 1.15rem !important;
  color: #a0b4c8;
  line-height: 1.5;
}

/* ── Legend ── */
.legend-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 7px;
  font-size: 1.2rem !important;
  color: #a0b4c8;
}
.legend-dot { width: 11px; height: 11px; border-radius: 50%; flex-shrink: 0; }

/* ── Language toggle ── */
#lang_toggle {
  width: 100%;
  background: transparent;
  border: 1px solid ", NAVY_LIGHT, ";
  color: ", WHITE, ";
  font-family: 'DM Sans', sans-serif;
  font-size: 1rem;
  padding: 7px 10px;
  border-radius: 4px;
  cursor: pointer;
  transition: all .2s;
  text-align: center;
}
#lang_toggle:hover { background: ", ORANGE, "; border-color: ", ORANGE, "; }
.sub-pending { font-size: 1rem !important; color: ", ORANGE_LIGHT, "; margin-top: 6px; text-align: center; }

/* ── Content pages (About, Feedback, Further Reading) ── */
.content-page { max-width: 760px; margin: 60px auto; padding: 0 28px 60px 28px; }
.content-page h2 {
  font-family: 'Bebas Neue', sans-serif;
  font-size: 3.2rem;
  letter-spacing: .06em;
  color: ", ORANGE, ";
  margin-bottom: 20px;
}
.content-page h3 {
  font-family: 'Bebas Neue', sans-serif;
  font-size: 1.8rem;
  letter-spacing: .05em;
  color: ", WHITE, ";
  margin: 32px 0 12px 0;
}
.content-page p { font-size: 1.3rem !important; color: #a0b4c8; line-height: 1.8; margin-bottom: 12px; }
.content-page a { color: ", ORANGE_LIGHT, "; text-decoration: none; }
.content-page a:hover { text-decoration: underline; }

/* ── Reading cards (Further Reading tab) ── */
.reading-card {
  background: ", NAVY_MID, ";
  border-radius: 6px;
  padding: 16px;
  margin-bottom: 14px;
  border-left: 3px solid ", ORANGE, ";
  transition: border-color .2s;
}
.reading-card:hover { border-color: ", ORANGE_LIGHT, "; }
.reading-card a {
  font-family: 'DM Sans', sans-serif;
  font-size: 1.2rem !important;
  font-weight: 600;
  color: ", ORANGE_LIGHT, ";
  text-decoration: none;
  display: block;
  margin-bottom: 5px;
}
.reading-card p { font-size: 1.15rem !important; color: #8a9bb0; line-height: 1.5; margin: 0; }

/* ── Modal ── */
.modal-content {
  background: ", NAVY_MID, " !important;
  color: ", WHITE, " !important;
  border: 1px solid ", NAVY_LIGHT, ";
}
.modal-header { border-bottom: 1px solid ", NAVY_LIGHT, " !important; }
.modal-footer { border-top: 1px solid ", NAVY_LIGHT, " !important; }
.modal-title {
  font-family: 'Bebas Neue', sans-serif !important;
  font-size: 1.6rem !important;
  letter-spacing: .05em;
  color: ", ORANGE, " !important;
}
.modal-content label { color: #a0b4c8 !important; font-size: 1.1rem !important; }
.modal-content .form-control {
  background: ", NAVY, " !important;
  border: 1px solid ", NAVY_LIGHT, " !important;
  color: ", WHITE, " !important;
  font-size: 1.1rem !important;
}
.btn-success { background: ", ORANGE, " !important; border-color: ", ORANGE, " !important; font-size: 1.1rem !important; }
.btn-default { background: ", NAVY_LIGHT, " !important; border-color: #3a4a5a !important; color: ", WHITE, " !important; font-size: 1.1rem !important; }
")
}

app_css <- make_css(
  NAVY         = NAVY,
  WHITE        = WHITE,
  NAVY_MID     = NAVY_MID,
  ORANGE       = ORANGE,
  ORANGE_LIGHT = ORANGE_LIGHT,
  NAVY_LIGHT   = NAVY_LIGHT
)


# ── Leaflet palettes ──────────────────────────────────────────

# palette matches actual OSM data values: hostile, non_hostile, NA
# non_hostile_covered included for future data; NA → grey
pal_bench <- colorFactor(
  palette  = c("#e8651a", "#ffc425", "#52c48a", "#3a4a5a"),
  levels   = c("hostile", "non_hostile", "non_hostile_covered", NA),
  na.color = "#3a4a5a"
)

pal_voronoi <- colorFactor(
  palette  = c("#e8651a", "#ffc425", "#3a4a5a"),
  levels   = c("Hostile", "Non-Hostile", "Unknown"),
  na.color = "#3a4a5a"
)


# ── UI ────────────────────────────────────────────────────────

title_banner <- div(
  class = "title-banner",
  div(class = "title-main", "BENCH-marks For Care"),
  div(class = "title-sub",  "Mapping bench accessibility in Aarhus, Denmark"),
  div(style = "margin-left:auto; align-self:center;",
      actionButton("lang_toggle", HTML("\U0001F1E9\U0001F1EA  DA"),
                   style = paste0(
                     "background:transparent; border:1px solid #4a6080;",
                     "color:#fff; font-family:'DM Sans',sans-serif;",
                     "font-size:1rem; padding:6px 14px; border-radius:4px;",
                     "cursor:pointer;"
                   ))
  )
)

navbar_ui <- navbarPage(
  id    = "nav",
  title = NULL,
  collapsible = TRUE,
  header = tags$head(
    tags$style(HTML(app_css)),
    tags$script(HTML("
      Shiny.addCustomMessageHandler('updateLangBtn', function(data) {
        var btn = document.getElementById('lang_toggle');
        btn.innerHTML = data.flag + '  ' + data.label;
      });
    "))
  ),
  
  # ── HOME ────────────────────────────────────────────────
  tabPanel(
    uiOutput("nav_home"),
    value = "home",
    
    # OVERVIEW BANNER ──────────────────────────────────────
    div(class = "overview-banner",
        div(class = "overview-inner",
            uiOutput("overview_text_ui")
        )
    ),
    
    div(class = "home-layout",
        
        # LEFT SIDEBAR ──────────────────────────────────────
        div(class = "sidebar",
            
            # basemap selector
            div(class = "sidebar-section",
                uiOutput("label_basemap"),
                selectInput("basemap_choice", NULL,
                            choices  = c("Municipality" = "municipality",
                                         "Ringvej"      = "ringvej",
                                         "Ringgade"     = "ringgade"),
                            selected = "municipality"
                )
            ),
            
            # noise reclassification toggle
            div(class = "sidebar-section",
                uiOutput("label_noise"),
                checkboxInput("use_noise_reclass", uiOutput("noise_cb_label"), value = FALSE)
            ),
            
            # layer toggles
            div(class = "sidebar-section",
                uiOutput("label_layers"),
                checkboxInput("show_voronoi",     uiOutput("lyr_voronoi"),    TRUE),
                sliderInput("voronoi_opacity", "Opacity of Voronoi Diagram", 0, 1, .3, step = .05, ticks = FALSE),
                checkboxInput("show_hostile",     uiOutput("lyr_hostile"),    TRUE),
                checkboxInput("show_nonhostile",  uiOutput("lyr_nonhostile"), TRUE),
                checkboxInput("show_friendly",    uiOutput("lyr_friendly"),   TRUE),
                checkboxInput("show_unknown",     uiOutput("lyr_unknown"),    FALSE),
                checkboxInput("show_submissions", uiOutput("lyr_submissions"), TRUE)
            ),
            
            # legend
            div(class = "sidebar-section",
                div(class = "legend-row",
                    div(class = "legend-dot", style = paste0("background:", BENCH_COLS["hostile"])),
                    span("Hostile")
                ),
                div(class = "legend-row",
                    div(class = "legend-dot", style = paste0("background:", BENCH_COLS["non_hostile"])),
                    span("Non-Hostile")
                ),
                div(class = "legend-row",
                    div(class = "legend-dot", style = paste0("background:", BENCH_COLS["non_hostile_covered"])),
                    span("Non-Hostile (covered)")
                ),
                div(class = "legend-row",
                    div(class = "legend-dot", style = "background:#3a4a5a"),
                    span("Unclassified")
                ),
                div(class = "legend-row",
                    div(class = "legend-dot",
                        style = "background:#ffffff; border:2px solid #cccccc"),
                    span("Pending submission")
                )
            ),
            
            # contribute
            div(class = "sidebar-section",
                uiOutput("label_contribute"),
                uiOutput("contribute_text"),
                actionButton("open_submit", "+ Add a bench"),
                uiOutput("pending_count")
            )
        ),
        
        # MAIN MAP ──────────────────────────────────────────
        div(class = "map-panel",
            leafletOutput("map")
        ),
        
        # RIGHT PANEL: Homeless Bill of Rights ──────────────
        div(class = "rights-panel",
            uiOutput("rights_header"),
            uiOutput("rights_attr_ui"),
            uiOutput("rights_list_ui")
        ),
        
        # BELOW MAP: stats | wave graph | voronoi explainer ───
        div(class = "below-map",
            div(
              tags$h5(textOutput("stats_title")),
              tableOutput("stats_table")
            ),
            div(
              tags$h5(textOutput("graph_title")),
              plotlyOutput("homeless_graph", height = "200px"),
              p(class = "graph-note", style = "font-size:0.8rem; line-height:1.4; color:#8fa3b8;", textOutput("graph_note_txt"))
            ),
            div(
              uiOutput("voronoi_explainer")
            )
        )
        
    ) # end home-layout
  ),
  
  # ── ABOUT ───────────────────────────────────────────────
  tabPanel(
    uiOutput("nav_about"),
    value = "about",
    div(class = "content-page",
        uiOutput("about_content")
    )
  ),
  
  # ── FURTHER READING ─────────────────────────────────────
  tabPanel(
    uiOutput("nav_resources"),
    value = "resources",
    div(class = "content-page",
        uiOutput("resources_content")
    )
  ),
  
  # ── FEEDBACK ────────────────────────────────────────────
  tabPanel(
    uiOutput("nav_feedback"),
    value = "feedback",
    div(class = "content-page",
        uiOutput("feedback_content")
    )
  )
  
) # end navbarPage


# ── SERVER ────────────────────────────────────────────────────

server <- function(input, output, session) {
  
  # ── Language ────────────────────────────────────────────
  
  lang <- reactiveVal("en")
  
  observeEvent(input$lang_toggle, {
    new_lang <- if (lang() == "en") "da" else "en"
    lang(new_lang)
    flag  <- if (new_lang == "da") "\U0001F1EC\U0001F1E7" else "\U0001F1E9\U0001F1EA"
    label <- if (new_lang == "da") "EN" else "DA"
    session$sendCustomMessage("updateLangBtn", list(flag = flag, label = label))
  })
  
  t <- reactive({ i18n[[lang()]] })
  
  # rendered text outputs for below-map section
  output$stats_title    <- renderText({ t()$sec_stats })
  output$graph_title    <- renderText({ t()$sec_graph })
  output$graph_note_txt <- renderText({ t()$graph_note })
  
  # ── Nav labels ──────────────────────────────────────────
  
  output$nav_home      <- renderUI(t()$nav_home)
  output$nav_about     <- renderUI(t()$nav_about)
  output$nav_resources <- renderUI(t()$nav_resources)
  output$nav_feedback  <- renderUI(t()$nav_feedback)
  
  # ── Overview banner ──────────────────────────────────────
  
  output$overview_text_ui <- renderUI({
    tr <- t()
    hostile_word  <- if (lang() == "da") "fjendtlig,"  else "hostile,"
    friendly_word <- if (lang() == "da") "ikke-fjendtlig," else "non-hostile,"
    covered_word  <- if (lang() == "da") "overdækket." else "sheltered."
    p(class = "overview-text",
      tr$overview_pre,
      tags$span(class = "ov-hostile",  hostile_word),
      tags$span(class = "ov-friendly", friendly_word),
      tr$overview_post, tags$span(class = "ov-covered", covered_word)
    )
  })
  
  # ── Sidebar labels ──────────────────────────────────────
  
  output$label_basemap    <- renderUI(tags$h5(t()$sec_basemap))
  output$label_noise      <- renderUI(tags$h5(t()$sec_noise))
  output$noise_cb_label   <- renderUI(span(t()$noise_label, style = "font-size:.95rem"))
  output$label_layers     <- renderUI(tags$h5(t()$sec_layers))
  output$lyr_voronoi      <- renderUI(t()$lyr_voronoi)
  output$lyr_hostile      <- renderUI(t()$lyr_hostile)
  output$lyr_nonhostile   <- renderUI(t()$lyr_nonhostile)
  output$lyr_friendly     <- renderUI(t()$lyr_friendly)
  output$lyr_unknown      <- renderUI(t()$lyr_unknown)
  output$lyr_submissions  <- renderUI(t()$lyr_submissions)
  output$label_contribute <- renderUI(tags$h5(t()$sec_contribute))
  output$contribute_text  <- renderUI(
    p(t()$contribute_txt, style = "font-size:.95rem; color:#8a9bb0; margin-bottom:8px")
  )
  
  # ── Rights panel ────────────────────────────────────────
  
  output$rights_header  <- renderUI(tags$h5(t()$bor_title))
  output$rights_attr_ui <- renderUI(p(class = "rights-attr", t()$bor_attr))
  output$rights_list_ui <- renderUI({
    rights <- bill_of_rights[[lang()]]
    tagList(lapply(rights, function(right) {
      div(class = "rights-item",
          span(class = "rights-num",  right$num),
          span(class = "rights-text", right$text)
      )
    }))
  })
  
  # ── Basemap ─────────────────────────────────────────────
  
  active_basemap <- reactive({
    switch(input$basemap_choice,
           municipality = aarhus_municipality,
           ringvej      = aarhus_ringvej,
           ringgade     = aarhus_ringgade
    )
  })
  
  # ── Bench data (+ optional noise reclass) ───────────────
  
  active_benches <- reactive({
    bm <- active_basemap()
    # both benches_classified and basemap polygons are WGS84 — no reproject needed
    b  <- benches_classified %>%
      st_intersection(st_make_valid(bm))
    
    if (input$use_noise_reclass && exists("bench_aarhus_night_streetNoise_50")) {
      noise_ids <- bench_aarhus_night_streetNoise_50$osm_id
      b <- b %>%
        mutate(is_hostile = case_when(
          osm_id %in% noise_ids & !is.na(is_hostile) ~ "hostile",
          TRUE ~ is_hostile
        ))
    }
    b
  })
  
  benches_wgs <- reactive({ st_transform(active_benches(), 4326) })
  voronoi_wgs <- reactive({ st_transform(voronoi_labelled, 4326) })  # voronoi is UTM 32N from pipeline
  
  # ── Submissions ─────────────────────────────────────────
  
  submissions <- reactiveVal({
    if (file.exists(SUBMISSIONS_CSV)) {
      read.csv(SUBMISSIONS_CSV, stringsAsFactors = FALSE)
    } else {
      data.frame(lat = numeric(), lng = numeric(),
                 backrest = character(), armrest = character(),
                 lying_down = character(), covered = character(),
                 seats_separated = character(), notes = character(),
                 submitted_at = character(), stringsAsFactors = FALSE)
    }
  })
  
  pending_click <- reactiveVal(NULL)
  
  # ── Base leaflet map ────────────────────────────────────
  
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.DarkMatter, group = "Dark") %>%
      addProviderTiles(providers$CartoDB.Positron,   group = "Light") %>%
      addProviderTiles(providers$OpenStreetMap,      group = "OSM") %>%
      addLayersControl(
        baseGroups    = c("Dark", "Light", "OSM"),
        overlayGroups = c("Voronoi", "Hostile", "Non-Hostile",
                          "Non-Hostile (covered)", "Unclassified", "Submissions"),
        options = layersControlOptions(collapsed = TRUE)
      ) %>%
      setView(lng = 10.2039, lat = 56.1629, zoom = 13)
  })
  
  # ── Voronoi layer ───────────────────────────────────────
  
  observe({
    proxy <- leafletProxy("map")
    proxy %>% clearGroup("Voronoi")
    if (input$show_voronoi) {
      proxy %>% addPolygons(
        data        = voronoi_wgs(),
        group       = "Voronoi",
        fillColor   = ~pal_voronoi(category),
        fillOpacity = input$voronoi_opacity,
        color       = "white", weight = 0.4,
        popup       = ~paste0("<b>", category, "</b><br>Area: ", round(area_m2), " m\u00b2")
      )
    }
  })
  
  # ── Bench point layers ──────────────────────────────────
  
  observe({
    b     <- benches_wgs()
    proxy <- leafletProxy("map")
    
    proxy %>%
      clearGroup("Hostile") %>%
      clearGroup("Non-Hostile") %>%
      clearGroup("Non-Hostile (covered)") %>%
      clearGroup("Unclassified")
    
    make_popup <- function(row) {
      paste0(
        "<b>", ifelse(is.na(row$is_hostile), "Unclassified",
                      gsub("_", " ", row$is_hostile)), "</b><br>",
        "Backrest: ", row$backrest,
        " | Armrest: ", row$armrest, "<br>",
        "Lie down: ", row$lying_down,
        " | Covered: ", row$covered, "<br>",
        "Separated seats: ", row$seats.separated
      )
    }
    
    add_layer <- function(proxy, data, group, col) {
      if (nrow(data) == 0) return(proxy)
      proxy %>% addCircleMarkers(
        data        = data, group = group,
        radius      = 5, fillColor = col,
        fillOpacity = 0.85, color = "white", weight = 1.2,
        popup       = sapply(1:nrow(data), function(i) make_popup(data[i, ]))
      )
    }
    
    if (input$show_hostile)
      proxy <- add_layer(proxy,
                         filter(b, !is.na(is_hostile) & is_hostile == "hostile"),
                         "Hostile", "#e8651a")
    if (input$show_nonhostile)
      proxy <- add_layer(proxy,
                         filter(b, !is.na(is_hostile) & is_hostile == "non_hostile"),
                         "Non-Hostile", "#ffc425")
    if (input$show_friendly)
      proxy <- add_layer(proxy,
                         filter(b, !is.na(is_hostile) & is_hostile == "non_hostile_covered"),
                         "Non-Hostile (covered)", "#52c48a")
    if (input$show_unknown)
      proxy <- add_layer(proxy,
                         filter(b, is.na(is_hostile)),
                         "Unclassified", "#3a4a5a")
  })
  
  # ── Submissions layer ───────────────────────────────────
  
  observe({
    s     <- submissions()
    proxy <- leafletProxy("map")
    proxy %>% clearGroup("Submissions")
    if (input$show_submissions && nrow(s) > 0) {
      proxy %>% addCircleMarkers(
        lng = s$lng, lat = s$lat,
        group       = "Submissions",
        radius      = 6,
        fillColor   = ORANGE_LIGHT,
        fillOpacity = 0.9,
        color       = ORANGE, weight = 2,
        popup = paste0(
          "<b>\u23f3 Pending review</b><br>",
          "Backrest: ", s$backrest,
          " | Armrest: ", s$armrest, "<br>",
          ifelse(nchar(s$notes) > 0,
                 paste0("Notes: ", s$notes, "<br>"), ""),
          "<span style='color:#888;font-size:.45rem'>",
          s$submitted_at, "</span>"
        )
      )
    }
  })
  
  # ── Stats table ─────────────────────────────────────────
  
  output$stats_table <- renderTable({
    benches_wgs() %>%
      st_drop_geometry() %>%
      mutate(is_hostile = ifelse(is.na(is_hostile), "unclassified", is_hostile)) %>%
      count(is_hostile, name = "n") %>%
      rename(Category = is_hostile, Count = n) %>%
      arrange(desc(Count))
  }, striped = FALSE, hover = TRUE, spacing = "s",
  width = "100%", align = "lr", rownames = FALSE)
  
  # ── Wave graph ──────────────────────────────────────────
  ## Aarhus = orange filled wave; Denmark = grey filled wave underneath
  
  output$homeless_graph <- renderPlotly({
    d <- homeless_data
    
    plot_ly(d, x = ~year) %>%
      
      # Denmark — grey filled area (background wave)
      add_trace(
        y          = ~denmark,
        name       = "Denmark (total)",
        type       = "scatter",
        mode       = "lines",
        fill       = "tozeroy",
        line       = list(color = "#4a5a6a", width = 2, shape = "spline"),
        fillcolor  = "rgba(74,90,106,0.35)"
      ) %>%
      
      # Aarhus — orange filled area (foreground wave)
      add_trace(
        y          = ~aarhus,
        name       = "Aarhus municipality",
        type       = "scatter",
        mode       = "lines",
        fill       = "tozeroy",
        line       = list(color = ORANGE, width = 2.5, shape = "spline"),
        fillcolor  = "rgba(232,101,26,0.55)"
      ) %>%
      
      layout(
        paper_bgcolor = NAVY_MID,
        plot_bgcolor  = NAVY_MID,
        font          = list(family = "DM Sans", color = WHITE, size = 13),
        xaxis = list(
          title     = "",
          gridcolor = NAVY_LIGHT,
          tickcolor = "#3a4a5a",
          linecolor = "#3a4a5a"
        ),
        yaxis = list(
          title     = "Min. estimate (persons)",
          gridcolor = NAVY_LIGHT,
          tickcolor = "#3a4a5a",
          linecolor = "#3a4a5a",
          titlefont = list(size = 12)
        ),
        legend = list(
          orientation = "h", x = 0, y = -0.18,
          font = list(size = 12)
        ),
        margin = list(l = 55, r = 10, t = 10, b = 45),
        hovermode = "x unified"
      )
  })
  
  # ── Voronoi explainer ────────────────────────────────────
  output$voronoi_explainer <- renderUI({
    tagList(
      tags$h5("What are Voronoi diagrams?",
              style = paste0(
                "font-family:'Bebas Neue',sans-serif;",
                "font-size:1.8rem; letter-spacing:.06em;",
                "color:#e8651a; margin-bottom:14px; font-weight:700;"
              )),
      
      p(
        "Each coloured region on the map represents the area",
        "closest to a particular bench — its", tags$em("service area."),
        "If the nearest bench to you is hostile (orange), you fall",
        "in an orange zone.",
        style = "font-size:.85rem; color:#a0b4c8; line-height:1.7;"
      ),
      
      p(
        "This lets us see not just where hostile benches are,",
        "but how much of the city's public space is effectively",
        "controlled by them — making invisible patterns of exclusion",
        "visible as geography.",
        style = "font-size:.85rem; color:#a0b4c8; line-height:1.7; margin-top:10px;"
      )
    )
  })
  
  # ── Content pages ────────────────────────────────────────
  output$about_content <- renderUI({
    tagList(
      tags$h2(t()$about_title),
      p(t()$about_body)
    )
  })
  
  output$resources_content <- renderUI({
    tagList(
      tags$h2(t()$card_title),
      tagList(lapply(reading_cards, function(card) {
        div(class = "reading-card",
            tags$a(href = card$url, target = "_blank", card$title),
            p(card$desc)
        )
      }))
    )
  })
  
  output$feedback_content <- renderUI({
    tagList(
      tags$h2(t()$feedback_title),
      p(t()$feedback_body)
    )
  })
  
  # ── Pending count ────────────────────────────────────────
  
  output$pending_count <- renderUI({
    n <- nrow(submissions())
    if (n > 0)
      p(class = "sub-pending",
        sprintf("\u23f3 %d %s", n, t()$pending_label))
  })
  
  # ── Map click → submission modal ────────────────────────
  
  observeEvent(input$map_click, {
    click <- input$map_click
    pending_click(click)
    tr <- t()
    
    showModal(modalDialog(
      title = tr$modal_title,
      p(sprintf("%s: %.5f, %.5f", tr$modal_loc, click$lat, click$lng),
        style = "font-size:.9rem; color:#8a9bb0"),
      fluidRow(
        column(6,
               selectInput("sub_backrest", tr$modal_backrest, c("yes", "no", "unknown")),
               selectInput("sub_armrest",  tr$modal_armrest,  c("yes", "no", "unknown")),
               selectInput("sub_lying",    tr$modal_liedown,  c("yes", "no", "unknown"))
        ),
        column(6,
               selectInput("sub_covered",   tr$modal_covered, c("yes", "no", "unknown")),
               selectInput("sub_sep_seats", tr$modal_sep,     c("yes", "no", "unknown"))
        )
      ),
      textAreaInput("sub_notes", tr$modal_notes, rows = 2,
                    placeholder = "e.g. near bus stop, rusted, newly installed\u2026"),
      p(tr$modal_hint, style = "font-size:.88rem; color:#8a9bb0"),
      footer = tagList(
        modalButton(tr$modal_cancel),
        actionButton("confirm_submit", tr$modal_submit, class = "btn-success")
      ),
      easyClose = TRUE
    ))
  })
  
  # ── Save submission ──────────────────────────────────────
  
  observeEvent(input$confirm_submit, {
    click <- pending_click()
    req(click)
    
    new_row <- data.frame(
      lat             = click$lat,
      lng             = click$lng,
      backrest        = input$sub_backrest,
      armrest         = input$sub_armrest,
      lying_down      = input$sub_lying,
      covered         = input$sub_covered,
      seats_separated = input$sub_sep_seats,
      notes           = input$sub_notes,
      submitted_at    = format(Sys.time(), "%Y-%m-%d %H:%M"),
      stringsAsFactors = FALSE
    )
    
    write.table(new_row, SUBMISSIONS_CSV,
                sep       = ",",
                append    = file.exists(SUBMISSIONS_CSV),
                col.names = !file.exists(SUBMISSIONS_CSV),
                row.names = FALSE,
                quote     = TRUE)
    
    submissions(rbind(submissions(), new_row))
    removeModal()
    showNotification(t()$notif_thanks, type = "message", duration = 4)
  })
  
} # end server


# ── Assemble UI ───────────────────────────────────────────────

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body > .container-fluid { padding: 0 !important; }
  "))),
  title_banner,
  navbar_ui
)

# ────────────────────────────────────────────────────────────────────────────

shinyApp(ui, server)