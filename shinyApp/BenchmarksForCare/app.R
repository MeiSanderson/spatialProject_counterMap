####################################################

# ============================================================
#
# BENCH-marks For Care — Shiny App
# Aarhus University | Cultural Data Science: Spatial Analytics
# Authors: Aiswarya Roy & Mie Norre Engemann
# GitHub:   aiswary-a        MeiSanderson
#
# ============================================================

app_data <- readRDS("app_data.rds")
list2env(app_data, envir = .GlobalEnv)

library(pacman)
pacman::p_load(shiny, leaflet, leaflet.extras, sf, tidyverse, ggplot2, plotly)


# ── Colour palette ───────────────────────────────────────────

NAVY         <- "#0d1b2a"
NAVY_MID     <- "#132336"
NAVY_LIGHT   <- "#1e3a5f"
ORANGE       <- "#e8651a"
ORANGE_LIGHT <- "#f59c5a"
WHITE        <- "#ffffff"

BENCH_COLS <- c(
  hostile       = "#e8651a",
  sleep_friendly = "#52c48a",
  non_hostile   = "#ffc425"
)

VORONOI_COLS <- c(
  "Hostile"       = "#e8651a",
  "Sleep-Friendly" = "#52c48a",
  "Non-Hostile"   = "#ffc425",
  "Unknown"       = "#3a4a5a"
)

SUBMISSIONS_CSV <- "pending_submissions.csv"


# ── Language strings ─────────────────────────────────────────

i18n <- list(
  en = list(
    app_title      = "BENCH-marks For Care",
    app_sub        = "Mapping bench accessibility in Aarhus",
    nav_home       = "Home",
    nav_about      = "About",
    nav_roughsleep = "Rough Sleepers",
    nav_resources  = "Further Reading",
    nav_feedback   = "Feedback",
    lang_toggle    = "DA",
    sec_basemap    = "Basemap",
    sec_layers     = "Layers",
    sec_noise      = "Noise Reclassification",
    noise_label    = "Reclassify benches as hostile if exposed to \u226550 dB (night)",
    lyr_voronoi    = "Voronoi service areas",
    lyr_hostile    = "Hostile benches",
    lyr_sleepfriendly = "Sleep-friendly benches",
    lyr_nonhostile = "Non-hostile benches",
    lyr_unknown    = "Unclassified benches",
    lyr_submissions= "Pending submissions",
    sec_contribute = "Contribute",
    contribute_txt = "Click anywhere on the map to submit a bench.",
    btn_add        = "+ Add a bench",
    sec_stats      = "Summary Statistics",
    sec_graph      = "Homelessness in Aarhus",
    graph_note     = "Minimum estimates from VIVE biennial mapping reports (2009\u20132024).",
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
    notif_thanks   = "Bench submitted \u2014 thank you!",
    pending_label  = "bench(es) pending review",
    overview_pre   = "Public benches are rarely just benches. In Aarhus, as across Denmark, the design and placement of urban seating reflects decisions \u2014 often unspoken \u2014 about who is welcome in public space and who is not. This counter-map visualises the structural accessibility of benches for people experiencing rough sleeping, drawing on OpenStreetMap data and road traffic noise measurements to classify each bench as",
    overview_post  = "or",
    roughsleep_title = "Rough Sleepers",
    roughsleep_body1 = "The term 'rough sleepers' describes a sub-category of homelessness, where individuals sleep on the street instead of, e.g., sofa-jumping or staying in a shelter. However, finding places to sleep in public spaces can prove a challenge due to urban design excluding the needs of certain groups of people.",
    roughsleep_body2 = "This website focuses on how the benches in public spaces, specifically within Aarhus municipality, are, at times, designed in ways that deter and physically hinder the socially-vulnerable (like rough sleepers) from gathering or resting. Such benches are classified as hostile on this webpage in cases where the benches have separated seats, armrests, or otherwise prohibit lying down, or where they are subjected to > 50 dB Lnight due to road noise. On the other hand, benches classified as non-hostile, while not designed with the aforementioned hostility or subjected to the high level of noise pollution, may be slept on, do not facilitate it with features that may provide comfort or additional safety for the user. Lastly, benches facilitating sleep are labelled as sleep-friendly, because they enable lying down, have a backrest and no inter-seat armrest and are subjected to < 50 dB Lnight of road noise pollution.",
    roughsleep_body3 = "This website provides a \u2018Counter-Map\u2019 showing the spatial distribution of benches in Aarhus municipality and whether these benches deter or hinder sleeping or if they facilitate it. The goal is that you (yes, you!) go exploring in / on / within the map and perhaps better understand the perspective of rough sleepers. Perhaps you will consider the needs of rough sleepers on your next visit or walk around Aarhus municipality. You may even choose to come back to this website to add the benches you saw and whether they were hostile or not."
  ),
  da = list(
    app_title      = "BENCH-marks For Care",
    app_sub        = "Kortl\u00e6gning af b\u00e6nketilg\u00e6ngelighed i Aarhus",
    nav_home       = "Hjem",
    nav_about      = "Om projektet",
    nav_roughsleep = "Hjeml\u00f8se p\u00e5 gaden",
    nav_resources  = "Videre l\u00e6sning",
    nav_feedback   = "Feedback",
    lang_toggle    = "EN",
    sec_basemap    = "Grundkort",
    sec_layers     = "Lag",
    sec_noise      = "St\u00f8jomklassificering",
    noise_label    = "Omklassific\u00e9r b\u00e6nke som fjendtlige ved \u226550 dB (nat)",
    lyr_voronoi    = "Voronoi-serviceomr\u00e5der",
    lyr_hostile    = "Fjendtlige b\u00e6nke",
    lyr_sleepfriendly = "S\u00f8vnvenlige b\u00e6nke",
    lyr_nonhostile = "Ikke-fjendtlige b\u00e6nke",
    lyr_unknown    = "Uklassificerede b\u00e6nke",
    lyr_submissions= "Afventende indmeldinger",
    sec_contribute = "Bidrag",
    contribute_txt = "Klik et sted p\u00e5 kortet for at indmelde en b\u00e6nk.",
    btn_add        = "+ Tilf\u00f8j en b\u00e6nk",
    sec_stats      = "Oversigtsstatistik",
    sec_graph      = "Hjeml\u00f8shed i Aarhus",
    graph_note     = "Minimumsestimater fra VIVEs to\u00e5rlige kortl\u00e6gning (2009\u20132024).",
    bor_title      = "Rettighedserkl\u00e6ring for Personer i Hjeml\u00f8shed",
    bor_attr       = "Kilde: Housing Rights Watch",
    card_title     = "Videre l\u00e6sning",
    about_title    = "Om dette projekt",
    about_body     = "Dette projekt unders\u00f8ger den strukturelle og sociale tilg\u00e6ngelighed af offentlige b\u00e6nke i Aarhus Kommune gennem linsen af fjendtlig arkitektur og mod-kortl\u00e6gning. Udviklet som en del af kurset Spatial Analytics, Cultural Data Science, Aarhus Universitet.",
    feedback_title = "Feedback og kontakt",
    feedback_body  = "Har du en korrektion eller et forslag? Kontakt os: 202308450@post.au.dk eller 202309344@post.au.dk",
    modal_title    = "Indsend en b\u00e6nk til gennemgang",
    modal_loc      = "Placering",
    modal_backrest = "Rygl\u00e6n",
    modal_armrest  = "Arml\u00e6n",
    modal_liedown  = "Kan man ligge ned?",
    modal_covered  = "Overd\u00e6kket?",
    modal_sep      = "Adskilte s\u00e6der?",
    modal_notes    = "Noter (valgfrit)",
    modal_hint     = "Din indmelding vises straks p\u00e5 kortet og gennemg\u00e5s inden integration.",
    modal_cancel   = "Annuller",
    modal_submit   = "Indsend til gennemgang",
    notif_thanks   = "B\u00e6nk indsendt \u2014 tak!",
    pending_label  = "b\u00e6nk(e) afventer gennemgang",
    overview_pre   = "Offentlige b\u00e6nke er sj\u00e6ldent bare b\u00e6nke. I Aarhus, som i resten af Danmark, afspejler udformningen og placeringen af bym\u00f8bler beslutninger \u2014 ofte uskrevne \u2014 om, hvem der er velkomne i det offentlige rum, og hvem der ikke er. Dette mod-kort visualiserer den strukturelle tilg\u00e6ngelighed af b\u00e6nke for personer, der sover udend\u00f8rs, baseret p\u00e5 OpenStreetMap-data og vejtrafikst\u00f8jsm\u00e5linger, der klassificerer hver b\u00e6nk som",
    overview_post  = "eller",
    roughsleep_title = "Hjeml\u00f8se p\u00e5 gaden",
    roughsleep_body1 = "Begrebet 'hjeml\u00f8se p\u00e5 gaden' beskriver en underkategori af hjeml\u00f8shed, hvor personer sover p\u00e5 gaden i stedet for fx at sofa-surfe eller overnatte p\u00e5 et herberg. At finde steder at sove i det offentlige rum kan dog v\u00e6re en udfordring, da bydesign ofte ikke tager hensyn til visse gruppers behov.",
    roughsleep_body2 = "Dette website fokuserer p\u00e5, hvordan b\u00e6nke i det offentlige rum \u2014 s\u00e6rligt i Aarhus Kommune \u2014 til tider er udformet p\u00e5 m\u00e5der, der afskr\u00e6kker og fysisk forhindrer socialt s\u00e5rbare (som hjeml\u00f8se p\u00e5 gaden) i at samles eller hvile sig. S\u00e5danne b\u00e6nke klassificeres som fjendtlige, n\u00e5r de har adskilte s\u00e6der, arml\u00e6n, eller p\u00e5 anden vis forhindrer at ligge ned, eller n\u00e5r de er udsat for > 50 dB Lnat fra vejst\u00f8j. B\u00e6nke klassificeret som ikke-fjendtlige er ikke designet med ovenst\u00e5ende fjendtlighed og er ikke udsat for h\u00f8j st\u00f8jforurening. Endelig m\u00e6rkes b\u00e6nke, der muligg\u00f8r s\u00f8vn, som s\u00f8vnvenlige.",
    roughsleep_body3 = "Dette website pr\u00e6senterer et \u2018mod-kort\u2019, der viser den rumlige fordeling af b\u00e6nke i Aarhus Kommune og angiver, om de afskr\u00e6kker eller fremmer s\u00f8vn. M\u00e5let er, at du (ja, dig!) udforsker kortet og m\u00e5ske bedre forst\u00e5r perspektivet for hjeml\u00f8se p\u00e5 gaden."
  )
)


# ── Homelessness data ────────────────────────────────────────

homeless_data <- data.frame(
  year    = c(2009, 2011, 2013, 2015, 2017, 2019, 2022, 2024),
  denmark = c(4998, 5290, 5820, 6138, 6635, 6431, 5789, 5989),
  aarhus  = c(466,  588,  617,  668,  767,  750,  507,  556)
)


# ── Homeless Bill of Rights ──────────────────────────────────

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
    list(num = "II",   text = "Retten til v\u00e6rdig n\u00f8dovernatning"),
    list(num = "III",  text = "Retten til det offentlige rum"),
    list(num = "IV",   text = "Retten til ligebehandling"),
    list(num = "V",    text = "Retten til en adresse"),
    list(num = "VI",   text = "Retten til basale sanit\u00e6re faciliteter"),
    list(num = "VII",  text = "Retten til akut hj\u00e6lp"),
    list(num = "VIII", text = "Retten til at stemme"),
    list(num = "IX",   text = "Retten til databeskyttelse"),
    list(num = "X",    text = "Retten til privatlivets fred"),
    list(num = "XI",   text = "Retten til lovligt at g\u00f8re ting, som er n\u00f8dvendige for at overleve")
  )
)


# ── Further reading cards ────────────────────────────────────

reading_cards <- list(
  list(
    title = "Den Udst\u00f8dende By",
    desc  = "Exhibition catalogue on hostile design and law in Danish cities.",
    url   = "https://udenfor.dk/wp-content/uploads/2024/11/ProjektUdenfor_Katalog_Forsogsmuseet.pdf"
  ),
  list(
    title = "VIVE: Hjeml\u00f8shed i Danmark 2024",
    desc  = "Biennial mapping of homelessness in Denmark.",
    url   = "https://www.vive.dk/da/udgivelser/hjemloeshed-i-danmark-2024-22375/"
  ),
  list(
    title = "Dark Design \u2013 Aalborg Universitet",
    desc  = "Ole B. Jensen's research project on social exclusion in urban space.",
    url   = "https://formkraft.dk/dark-design-hvad-sker-der-med-den-rummelige-by/"
  ),
  list(
    title = "Projekt Udenfor",
    desc  = "Danish NGO working on homelessness and exclusionary design.",
    url   = "https://udenfor.dk"
  ),
  list(
    title = "ENG: Homeless Bill of Rights",
    desc  = "Housing Rights Watch declaration of rights for people experiencing homelessness.",
    url   = "https://udenfor.dk/wp-content/uploads/2024/09/20488_Aalborg_Universitet_Rettighedserklaering_UK_WEB.pdf"
  ),
  list(
    title = "DAN: Rettighedserkl\u00e6ring for Personer i Hjeml\u00f8shed",
    desc  = "Den dansk version af den europ\u00e6iske Homeless Bill of Rights udarbejdet af Housing Rights Watch.",
    url   = "https://www.feantsa.org/files/Home/Homeless-bill-of-rights/DK_Booklet.pdf"
  ),
  list(
    title = "OpenStreetMap",
    desc  = "The open mapping platform used as the primary bench data source.",
    url   = "https://www.openstreetmap.org"
  ),
  list(
    title = "BENCH-marks For Care: GitHub Repository",
    desc  = "Want to see the work behind the data and visuals? Take a look at our public GitHub repo!",
    url   = "https://github.com/MeiSanderson/spatialProject_counterMap"
  )
)


# ── CSS ──────────────────────────────────────────────────────

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

/* ── Global Bootstrap overrides ── */
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
.ov-friendly { color: #52c48a; font-weight: 600; }
.ov-nonhos   { color: #ffc425; font-weight: 600; }

/* ── Home layout ── */
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

/* ── Below-map ── */
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

/* ── Content pages ── */
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

/* ── Reading cards ── */
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

/* ── Footer ── */
.site-footer {
  background: ", NAVY_MID, ";
  border-top: 1px solid ", NAVY_LIGHT, ";
  text-align: center;
  padding: 12px 24px;
  font-size: .78rem !important;
  color: #5a6a7a;
  letter-spacing: .04em;
}
.site-footer a { color: #5a6a7a; text-decoration: underline; }
.site-footer a:hover { color: #8a9bb0; }
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


# ── Leaflet palettes ─────────────────────────────────────────

pal_bench <- colorFactor(
  palette  = c("#e8651a", "#52c48a", "#ffc425", "#3a4a5a"),
  levels   = c("hostile", "sleep_friendly", "non_hostile", NA),
  na.color = "#3a4a5a"
)

pal_voronoi <- colorFactor(
  palette  = c("#e8651a", "#52c48a", "#ffc425", "#3a4a5a"),
  levels   = c("Hostile", "Sleep-Friendly", "Non-Hostile", "Unknown"),
  na.color = "#3a4a5a"
)


# ── UI ───────────────────────────────────────────────────────

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

site_footer <- div(
  class = "site-footer",
  HTML('Project is licensed under <a href="https://creativecommons.org/licenses/by/4.0/" target="_blank">CC BY 4.0</a>')
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
  
  # ── HOME ──────────────────────────────────────────────────
  tabPanel(
    uiOutput("nav_home"),
    value = "home",
    
    div(class = "overview-banner",
        div(class = "overview-inner",
            uiOutput("overview_text_ui")
        )
    ),
    
    div(class = "home-layout",
        
        # LEFT SIDEBAR ────────────────────────────────────────
        div(class = "sidebar",
            
            div(class = "sidebar-section",
                uiOutput("label_basemap"),
                selectInput("basemap_choice", NULL,
                            choices  = c("Municipality" = "municipality",
                                         "Ringvej"      = "ringvej",
                                         "Ringgade"     = "ringgade"),
                            selected = "municipality")
            ),
            
            div(class = "sidebar-section",
                uiOutput("label_noise"),
                checkboxInput("use_noise_reclass", uiOutput("noise_cb_label"), value = FALSE)
            ),
            
            div(class = "sidebar-section",
                uiOutput("label_layers"),
                checkboxInput("show_voronoi",      uiOutput("lyr_voronoi"),      TRUE),
                sliderInput("voronoi_opacity", "Opacity of Voronoi Diagram", 0, 1, .3, step = .05, ticks = FALSE),
                checkboxInput("show_hostile",      uiOutput("lyr_hostile"),      TRUE),
                checkboxInput("show_sleepfriendly", uiOutput("lyr_sleepfriendly"), TRUE),
                checkboxInput("show_nonhostile",   uiOutput("lyr_nonhostile"),   TRUE),
                checkboxInput("show_unknown",      uiOutput("lyr_unknown"),      FALSE),
                checkboxInput("show_submissions",  uiOutput("lyr_submissions"),  TRUE)
            ),
            
            div(class = "sidebar-section",
                div(class = "legend-row",
                    div(class = "legend-dot", style = paste0("background:", BENCH_COLS["hostile"])),
                    span("Hostile")
                ),
                div(class = "legend-row",
                    div(class = "legend-dot", style = paste0("background:", BENCH_COLS["sleep_friendly"])),
                    span("Sleep-Friendly")
                ),
                div(class = "legend-row",
                    div(class = "legend-dot", style = paste0("background:", BENCH_COLS["non_hostile"])),
                    span("Non-Hostile")
                ),
                div(class = "legend-row",
                    div(class = "legend-dot", style = "background:#3a4a5a"),
                    span("Unclassified")
                ),
                div(class = "legend-row",
                    div(class = "legend-dot", style = "background:#ffffff; border:2px solid #cccccc"),
                    span("Pending submission")
                )
            ),
            
            div(class = "sidebar-section",
                uiOutput("label_contribute"),
                uiOutput("contribute_text"),
                actionButton("open_submit", "+ Add a bench"),
                uiOutput("pending_count")
            )
        ),
        
        # MAIN MAP ────────────────────────────────────────────
        div(class = "map-panel",
            leafletOutput("map")
        ),
        
        # RIGHT PANEL ─────────────────────────────────────────
        div(class = "rights-panel",
            uiOutput("rights_header"),
            uiOutput("rights_attr_ui"),
            uiOutput("rights_list_ui")
        ),
        
        # BELOW MAP ───────────────────────────────────────────
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
            div(uiOutput("voronoi_explainer"))
        )
        
    ) # end home-layout
  ),
  
  # ── ROUGH SLEEPERS ────────────────────────────────────────
  tabPanel(
    uiOutput("nav_roughsleep"),
    value = "roughsleep",
    div(class = "content-page",
        uiOutput("roughsleep_content")
    )
  ),
  
  # ── ABOUT ─────────────────────────────────────────────────
  tabPanel(
    uiOutput("nav_about"),
    value = "about",
    div(class = "content-page",
        uiOutput("about_content")
    )
  ),
  
  # ── FURTHER READING ───────────────────────────────────────
  tabPanel(
    uiOutput("nav_resources"),
    value = "resources",
    div(class = "content-page",
        uiOutput("resources_content")
    )
  ),
  
  # ── FEEDBACK ──────────────────────────────────────────────
  tabPanel(
    uiOutput("nav_feedback"),
    value = "feedback",
    div(class = "content-page",
        uiOutput("feedback_content")
    )
  )
  
) # end navbarPage


# ── SERVER ───────────────────────────────────────────────────

server <- function(input, output, session) {
  
  # ── Language ──────────────────────────────────────────────
  
  lang <- reactiveVal("en")
  
  observeEvent(input$lang_toggle, {
    new_lang <- if (lang() == "en") "da" else "en"
    lang(new_lang)
    flag  <- if (new_lang == "da") "\U0001F1EC\U0001F1E7" else "\U0001F1E9\U0001F1F0"
    label <- if (new_lang == "da") "EN" else "DA"
    session$sendCustomMessage("updateLangBtn", list(flag = flag, label = label))
  })
  
  t <- reactive({ i18n[[lang()]] })
  
  output$stats_title    <- renderText({ t()$sec_stats })
  output$graph_title    <- renderText({ t()$sec_graph })
  output$graph_note_txt <- renderText({ t()$graph_note })
  
  # ── Nav labels ────────────────────────────────────────────
  
  output$nav_home       <- renderUI(t()$nav_home)
  output$nav_about      <- renderUI(t()$nav_about)
  output$nav_roughsleep <- renderUI(t()$nav_roughsleep)
  output$nav_resources  <- renderUI(t()$nav_resources)
  output$nav_feedback   <- renderUI(t()$nav_feedback)
  
  # ── Overview banner ───────────────────────────────────────
  
  output$overview_text_ui <- renderUI({
    tr <- t()
    hostile_word  <- if (lang() == "da") "fjendtlig,"       else "hostile,"
    friendly_word <- if (lang() == "da") "s\u00f8vnvenlig," else "sleep-friendly,"
    nonhos_word   <- if (lang() == "da") "ikke-fjendtlig."  else "non-hostile."
    p(class = "overview-text",
      tr$overview_pre,
      tags$span(class = "ov-hostile",  hostile_word),
      tags$span(class = "ov-friendly", friendly_word),
      tr$overview_post, tags$span(class = "ov-nonhos", nonhos_word)
    )
  })
  
  # ── Sidebar labels ────────────────────────────────────────
  
  output$label_basemap     <- renderUI(tags$h5(t()$sec_basemap))
  output$label_noise       <- renderUI(tags$h5(t()$sec_noise))
  output$noise_cb_label    <- renderUI(span(t()$noise_label, style = "font-size:.95rem"))
  output$label_layers      <- renderUI(tags$h5(t()$sec_layers))
  output$lyr_voronoi       <- renderUI(t()$lyr_voronoi)
  output$lyr_hostile       <- renderUI(t()$lyr_hostile)
  output$lyr_sleepfriendly <- renderUI(t()$lyr_sleepfriendly)
  output$lyr_nonhostile    <- renderUI(t()$lyr_nonhostile)
  output$lyr_unknown       <- renderUI(t()$lyr_unknown)
  output$lyr_submissions   <- renderUI(t()$lyr_submissions)
  output$label_contribute  <- renderUI(tags$h5(t()$sec_contribute))
  output$contribute_text   <- renderUI(
    p(t()$contribute_txt, style = "font-size:.95rem; color:#8a9bb0; margin-bottom:8px")
  )
  
  # ── Rights panel ──────────────────────────────────────────
  
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
  
  # ── Basemap ───────────────────────────────────────────────
  
  active_basemap <- reactive({
    switch(input$basemap_choice,
           municipality = aarhus_municipality,
           ringvej      = aarhus_ringvej,
           ringgade     = aarhus_ringgade)
  })
  
  # ── Bench data ────────────────────────────────────────────
  
  active_benches <- reactive({
    bm <- active_basemap()
    b  <- benches_classified %>% sf::st_intersection(sf::st_make_valid(bm))
    if (input$use_noise_reclass && exists("bench_aarhus_night_streetNoise_50")) {
      noise_ids <- bench_aarhus_night_streetNoise_50$osm_id
      b <- b %>%
        dplyr::mutate(is_hostile = dplyr::case_when(
          osm_id %in% noise_ids & !is.na(is_hostile) ~ "hostile",
          TRUE ~ is_hostile
        ))
    }
    b
  })
  
  benches_wgs <- reactive({ sf::st_transform(active_benches(), 4326) })
  voronoi_wgs <- reactive({ sf::st_transform(voronoi_labelled, 4326) })
  
  # ── Submissions ───────────────────────────────────────────
  
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
  
  # ── Base leaflet map ──────────────────────────────────────
  
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.DarkMatter, group = "Dark") %>%
      addProviderTiles(providers$CartoDB.Positron,   group = "Light") %>%
      addProviderTiles(providers$OpenStreetMap,      group = "OSM") %>%
      addLayersControl(
        baseGroups    = c("Dark", "Light", "OSM"),
        overlayGroups = c("Voronoi", "Hostile", "Sleep-Friendly",
                          "Non-Hostile", "Unclassified", "Submissions"),
        options = layersControlOptions(collapsed = TRUE)
      ) %>%
      setView(lng = 10.2039, lat = 56.1629, zoom = 13)
  })
  
  # ── Voronoi layer ─────────────────────────────────────────
  
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
  
  # ── Bench point layers ────────────────────────────────────
  
  observe({
    b     <- benches_wgs()
    proxy <- leafletProxy("map")
    proxy %>%
      clearGroup("Hostile") %>%
      clearGroup("Sleep-Friendly") %>%
      clearGroup("Non-Hostile") %>%
      clearGroup("Unclassified")
    
    make_popup <- function(row) {
      label <- dplyr::case_when(
        row$is_hostile == "hostile"        ~ "Hostile",
        row$is_hostile == "sleep_friendly" ~ "Sleep-Friendly",
        row$is_hostile == "non_hostile"    ~ "Non-Hostile",
        TRUE                               ~ "Unclassified"
      )
      paste0(
        "<b>", label, "</b><br>",
        "Backrest: ", row$backrest,
        " | Armrest: ", row$armrest, "<br>",
        "Lie down: ", row$lying_down,
        " | Separated seats: ", row$seats.separated
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
      proxy <- add_layer(proxy, dplyr::filter(b, !is.na(is_hostile) & is_hostile == "hostile"),
                         "Hostile", "#e8651a")
    if (input$show_sleepfriendly)
      proxy <- add_layer(proxy, dplyr::filter(b, !is.na(is_hostile) & is_hostile == "sleep_friendly"),
                         "Sleep-Friendly", "#52c48a")
    if (input$show_nonhostile)
      proxy <- add_layer(proxy, dplyr::filter(b, !is.na(is_hostile) & is_hostile == "non_hostile"),
                         "Non-Hostile", "#ffc425")
    if (input$show_unknown)
      proxy <- add_layer(proxy, dplyr::filter(b, is.na(is_hostile)),
                         "Unclassified", "#3a4a5a")
  })
  
  # ── Submissions layer ─────────────────────────────────────
  
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
          ifelse(nchar(s$notes) > 0, paste0("Notes: ", s$notes, "<br>"), ""),
          "<span style='color:#888;font-size:.75rem'>", s$submitted_at, "</span>"
        )
      )
    }
  })
  
  # ── Stats table ───────────────────────────────────────────
  
  output$stats_table <- renderTable({
    benches_wgs() %>%
      sf::st_drop_geometry() %>%
      dplyr::mutate(Category = dplyr::case_when(
        is_hostile == "hostile"        ~ "Hostile",
        is_hostile == "sleep_friendly" ~ "Sleep-Friendly",
        is_hostile == "non_hostile"    ~ "Non-Hostile",
        TRUE                           ~ "Unclassified"
      )) %>%
      dplyr::count(Category, name = "Count") %>%
      dplyr::arrange(dplyr::desc(Count))
  }, striped = FALSE, hover = TRUE, spacing = "s",
  width = "100%", align = "lr", rownames = FALSE)
  
  # ── Wave graph ────────────────────────────────────────────
  
  output$homeless_graph <- renderPlotly({
    d <- homeless_data
    plot_ly(d, x = ~year) %>%
      add_trace(
        y = ~denmark, name = "Denmark (total)", type = "scatter", mode = "lines",
        fill = "tozeroy",
        line = list(color = "#4a5a6a", width = 2, shape = "spline"),
        fillcolor = "rgba(74,90,106,0.35)"
      ) %>%
      add_trace(
        y = ~aarhus, name = "Aarhus municipality", type = "scatter", mode = "lines",
        fill = "tozeroy",
        line = list(color = ORANGE, width = 2.5, shape = "spline"),
        fillcolor = "rgba(232,101,26,0.55)"
      ) %>%
      layout(
        paper_bgcolor = NAVY_MID, plot_bgcolor = NAVY_MID,
        font  = list(family = "DM Sans", color = WHITE, size = 13),
        xaxis = list(title = "", gridcolor = NAVY_LIGHT, tickcolor = "#3a4a5a", linecolor = "#3a4a5a"),
        yaxis = list(title = "Min. estimate (persons)", gridcolor = NAVY_LIGHT,
                     tickcolor = "#3a4a5a", linecolor = "#3a4a5a", titlefont = list(size = 12)),
        legend = list(orientation = "h", x = 0, y = -0.18, font = list(size = 12)),
        margin = list(l = 55, r = 10, t = 10, b = 45),
        hovermode = "x unified"
      )
  })
  
  # ── Voronoi explainer ─────────────────────────────────────
  
  output$voronoi_explainer <- renderUI({
    tagList(
      tags$h5("What are Voronoi diagrams?",
              style = paste0("font-family:'Bebas Neue',sans-serif;",
                             "font-size:1.8rem; letter-spacing:.06em;",
                             "color:#e8651a; margin-bottom:14px; font-weight:700;")),
      p("Each coloured region on the map represents the area closest to a particular bench \u2014 its",
        tags$em("service area."),
        "If the nearest bench to you is hostile (orange), you fall in an orange zone.",
        style = "font-size:.85rem; color:#a0b4c8; line-height:1.7;"),
      p("This lets us see not just where hostile benches are, but how much of the city's public space",
        "is effectively controlled by them \u2014 making invisible patterns of exclusion visible as geography.",
        style = "font-size:.85rem; color:#a0b4c8; line-height:1.7; margin-top:10px;")
    )
  })
  
  # ── Rough Sleepers page ───────────────────────────────────
  
  output$roughsleep_content <- renderUI({
    tr <- t()
    tagList(
      tags$h2(tr$roughsleep_title),
      p(tr$roughsleep_body1),
      p(tr$roughsleep_body2),
      p(tr$roughsleep_body3)
    )
  })
  
  # ── Content pages ─────────────────────────────────────────
  
  output$about_content <- renderUI({
    tagList(tags$h2(t()$about_title), p(t()$about_body))
  })
  
  output$resources_content <- renderUI({
    tagList(
      tags$h2(t()$card_title),
      tagList(lapply(reading_cards, function(card) {
        div(class = "reading-card",
            tags$a(href = card$url, target = "_blank", card$title),
            p(card$desc))
      }))
    )
  })
  
  output$feedback_content <- renderUI({
    tagList(tags$h2(t()$feedback_title), p(t()$feedback_body))
  })
  
  # ── Pending count ─────────────────────────────────────────
  
  output$pending_count <- renderUI({
    n <- nrow(submissions())
    if (n > 0)
      p(class = "sub-pending", sprintf("\u23f3 %d %s", n, t()$pending_label))
  })
  
  # ── Map click → modal ─────────────────────────────────────
  
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
  
  # ── Save submission ───────────────────────────────────────
  
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
                sep = ",", append = file.exists(SUBMISSIONS_CSV),
                col.names = !file.exists(SUBMISSIONS_CSV),
                row.names = FALSE, quote = TRUE)
    submissions(rbind(submissions(), new_row))
    removeModal()
    showNotification(t()$notif_thanks, type = "message", duration = 4)
  })
  
} # end server


# ── Assemble UI ──────────────────────────────────────────────

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body > .container-fluid { padding: 0 !important; }
  "))),
  title_banner,
  navbar_ui,
  site_footer
)

# ─────────────────────────────────────────────────────────────

shinyApp(ui, server)

####################################################