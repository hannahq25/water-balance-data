#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Impacts of Climate Change and Urbanization on Water Runoff],
  // abstract: [
  //   This is where you put your abstract.
  // ],
  authors: (
    (
      name: "Hannah Qian",
      department: [CEE],
      organization: [University of Illinois Urbana-Champaign],
      location: [Urbana, IL, USA],
      email: "si25@illinois.edu",
    ),
    (
      name: "Amy Bergbreiter  ",
      department: [CEE],
      organization: [University of Illinois Urbana-Champaign],
      location: [Urbana, IL, USA],
      email: "ameliab9@illinois.edu",
    ),
    (
      name: "Tzina Santos",
      department: [CEE],
      organization: [University of Illinois Urbana-Champaign],
      location: [Bacoor, Cavite, Philippines],
      email: "tsantos3@illinois.edu",
    ),
    (
      name: "Vasudha Bhogineni",
      department: [CEE],
      organization: [University of Illinois Urbana-Champaign],
      location: [Urbana, IL, USA],
      email: "bhogine2@illinois.edu",
    ),
  ),
  index-terms: ("Optional", "Keywords", "Here"),
  bibliography: bibliography("refs.bib"),
)
#show link: underline
#show raw: set text(font: "DejaVu Sans Mono", size: 0.8em)
#show table: set par(justify: false)

// = Background
= Data Sources
== Daily Historical Water Balance Products for the CONUS:
 A gridded daily historical water balance dataset covering the Continental United States @Tercek2023. The dataset was originally developed under the National Park Service Inventory and Monitoring Program and the National Park Service Climate Change Response Program. Version 1.5, the version currently available online, provides daily historic data (1980–2024) on #link("https://search.earthdata.nasa.gov/search?q=C2674700048-LPCLOUD")[NASA's Earthdata database] or an #link("https://npwbanalres.s3.us-west-2.amazonaws.com/index.html")[Amazon S3 bucket]. @HistBalanceData

== Future NPS Gridded Water Balance Model
 Future conditions of the aforementioned water balance dataset are available as 30-year averages (2040–2069 and 2070–2099, under both RCP 4.5 and RCP 8.5 #footnote[Representative Carbon Pathway 4.5 and 8.5 (scenarios with radiative forcing of 4.5 and 8.5 W/m^2 in 2100, respectively)]) for an assortment of climate models from a second Amazon S3 bucket @FutureBalanceData. Many references cite a THREDDS server for the water balance data; however, that server is no longer valid.

== Annual National Land Cover Database Collection 1.2 
 A database by the USGS that applies geospatial deep learning algorithms to the Landsat satellite imagery record to classify land cover and surface change characteristics across the US on an annual basis, beginning in 1985. The Land Cover Classification and Fractional Impervious Surface products will be most relevant to this project. The data is available to view and download through multiple platforms, including the MRLC Web Viewer @MRLCViewer.

== U.S. Climate Resilience Toolkit Climate Explorer
 A tool built by the EPA, NASA, NOAA, and USGS and hosted by the National Environmental Modeling and Analysis Center (NEMAC) at the University of North Carolina Asheville. The tool provides historical climate conditions across the US based on observations at weather stations and projected climate conditions based on global climate models for the Coupled Model Intercomparison Project Phase 5 (CMIP5) for the RCP 4.5 and RCP 8.5 emissions scenarios. Annual, locality-specific data can be downloaded through the online Climate Explorer tool @ClimateExplorer. 

== GridMET 
 Daily gridded meteorological data at about 4 km resolution @abatzoglou2013 @GridMETwebsite. This is the same precipitation and temperature forcing used by the water balance model. Using it for the curve number calculation keeps the two runoff estimates directly comparable. 

== SSURGO (Soil Survey Geographic Database) 
 The USDA NRCS soil database provides hydrologic soil groups (A–D), which are combined with land cover to assign curve numbers. 

== USGS Water Data for the Nation (formerly NWIS) 
 Daily mean discharge from a USGS stream gage at the outlet of the study watershed provides observed streamflow to validate the modeled runoff. The watershed boundary and drainage area will be obtained from USGS StreamStats @StreamStatsWebsite.
\ \
 Additional datasets may be incorporated as the project progresses. 

= Data Formats and Contents
== Daily Historical Water Balance Products for the CONUS 

The historical water balance data is available in the Network Common Data Form (netCDF) format. NetCDF files contain variables distributed across common dimensions, and attributes of each variable, which allow a single file to store variables across both spatial and time dimensions.   

The data are gridded over the entire continental US in 1 km cells, stored in daily time steps (`time` variable). It is projected in a Lambert Conformal Conic (LCC) projection, and each cell has LCC `x` and `y` coordinate.  The degree latitude/longitude is also stored as variables across the `x`/`y` dimensions. 

Version 1.5 of the water balance dataset was developed from daily meteorological data from GridMET: daily minimum and maximum temperature and daily precipitation. The model treats the soil as a "bucket" with a maximum capacity based on the USDA’s SSURGO soil database Available Water Storage parameter. Precipitation is classified as rain or snow based on temperature, adjusted for relative humidity @jennings2018. Potential evapotranspiration is calculated with the Oudin method, which uses temperature and latitude-based solar radiation @oudin2005. 

#figure(
  caption: [Historial Water Balance Variables],
  table(
    columns: (auto, auto, auto, auto),
    align: (center, left, center, center),
    table.header([*Variable*], [*Description*], [*Units*], [*Type*]),
    `rain`, "Daily rainwater", "mm/day", "Daily",

    `accumswe`, "Accumulated snow water equivalent. Precipitation not falling as rain accumulates here until temperatures cause the snow to melt.", "mm", "Accumulated",

    `soilwater`, "Water in the soil \"bucket\" at a given time. Added by rain and snowmelt, removed by evaporation and transpiration (" + `aet` + ").", "mm", "Accumulated",

    `runoff`, "Rain and snowmelt that cannot be captured in the soil bucket and is lost as runoff", "mm/day", "Daily",

    `pet`, "Potential evaporation and transpiration: the maximum that would occur if soil water were unlimited", "mm/day", "Daily",

    `aet`, "Actual evaporation and transpiration: the water actually removed from the soil bucket, limited by soil water", "mm/day", "Daily",

    `deficit`, "Difference between "+`pet`+" and "+ `aet`+". Greater than zero when climate and vegetation could support more evaporation and transpiration than the soil can supply; otherwise 0.", "mm/day", "Daily"
  ),
)

== Future NPS Gridded Water Balance Model
The future water balance data is available as Georeferenced Tagged Image File Format (GeoTIFF) files summarized as the 30-year means. A GeoTIFF file embeds georeferencing information within a TIFF image file. Each GeoTIFF represents a separate variable, similar to the variables in the historic dataset (rain, runoff, pet, etc.), and each pixel of the GeoTIFF stores a value for the variable for a particular georeferenced location. 

== Annual National Land Cover Database Collection 1.2 
The National Land Cover Database (NLCD) data is provided as Cloud-Optimized GeoTIFF (COG) files, similar to the future water balance data. Each GeoTIFF image corresponds to a year and a land cover variable. The table below shows the legend for Land Cover values according to the Annual National Land Cover Database (NLCD) Collection 1 Science Product User Guide @NLCDUserGuide.

#figure(
  caption: [NLCD Land Cover Legend],
  table(
    columns: (auto, auto, auto, auto),
    align: (center, left, center, left),
    table.header([*Pixel Value*], [*Land Cover Class*], [*Pixel Value*], [*Land Cover Class*]),
    "250", "No Data","42", "Evergreen Forest",
    "11", "Open Water","43", "Mixed Forest",
    "12", "Perennial Ice/Snow","52", "Shrub/Scrub",
    "21", "Developed, Open Space","71", "Grassland/Herbaceous",
    "22", "Developed, Low Intensity","81", "Pasture/Hay",
    "23", "Developed, Medium Intensity", "82", "Cultivated Crops",
    "24", "Developed, High Intensity","90", "Woody Wetlands",
    "31", "Barren Land (Rock/Sand/Clay)", "95", "Emergent Herbacous Wetlands",
    "41", "Deciduous Forest",
  ),
)

The data values for Fractional Impervious Area range from 0-100, representing the percentage of a 30-meter pixel that is covered with impervious surfaces. 

== U.S. Climate Resilience Toolkit Climate Explorer 
The Climate Explorer tracks the following variables: 

#figure(
  caption: [Climate Explorer Variables],
  table(
    columns: (auto, auto, auto),
    align: (center, left, center),
  table.header([*Variable*],[*Description*],[*Units*]),
  [`year`],[years from 1950-2013],[years],
  [`tmax`],[mean daily maximum temperature],[°C],
  [`tmin`],[mean daily minimum temperature],[°C],
  [`days_tmax_gt_100f`],[days with maximum temperatures above 100°F],[days],
  [`days_tmin_lt_32f`],[days with minimum temps below 0.0°C],[days],
  [`pcpn`],[precipitation],[in],
  [`days_pcpn_gt_1in`],[days with more than 1 inch of rain],[days],
  [`days_dry_days`],[days per year with no measurable rain],[days],
  [`hdd_65f`],[heating degree days],[°F-days],
  [`cdd_65f`],[cooling degree days],[°F-days],
  [`gdd`],[growing degree days],[°F-days],
  [`gddmod`],[modified growing degree days = growing - degree days minus degree-days over 86°F],[°F-days],
  )
)

For each variable, CSV files may be downloaded containing the following: 
\ \
1. Modeled History: annual projections generated for the past from global climate models for each variable in the Observations

#figure(
  caption: [Climate Explorer Modeled History Columns],
  table(
    columns: (auto, auto, auto),
    align: (center, left, center),
  table.header([*Column*],[*Description*],[*Units*]),
  [`weighted_mean`],[weighted mean #footnote[Weighted means were computed per Climate Science Special Report: Fourth National Climate Assessment, Volume I, Appendix B]<fn-weightedmean>],[variable dependent],
  [`min`],[mean daily maximum temperature],[variable dependent],
  [`max`],[mean daily minimum temperature],[variable dependent],
  )
)

2. Projections: annual projections generated for the future from global climate models for each variable in the Observations 

#figure(
  caption: [Climate Explorer Projections Columns],
  table(
    columns: (auto, auto, auto),
    align: (center, left, center),
  table.header([*Column*],[*Description*],[*Units*]),
  [`rcp45_weighted_mean`],[weighted mean@fn-weightedmean for RCP 4.5],[variable dependent],
  [`rcp45_min `],[minimum for RCP 4.5],[variable dependent],
  [`rcp45_max`],[maximum for RCP 4.5],[variable dependent],
  [`rcp85_weighted_mean`],[weighted mean@fn-weightedmean for RCP 8.5],[variable dependent],
  [`rcp85_min `],[minimum for RCP 8.5],[variable dependent],
  [`rcp85_max`],[maximum for RCP 8.5],[variable dependent],
  )
)
 
== GridMET
The gridMET data are available as NetCDF files, usually one file per variable per year, on a regular latitude–longitude grid (WGS84). This is also available through Google Earth Engine. Gridded daily time series covering the contiguous US from 1979 to the present, at about 4 km resolution (1/24°). It blends the spatial detail of PRISM climate data with the daily timing of NLDAS-2 reanalysis.

The dataset includes precipitation (`pr`, mm), daily maximum and minimum temperature (`tmmx`, `tmmn`, in Kelvin), relative and specific humidity, solar radiation, wind speed, and reference evapotranspiration. The project mainly uses precipitation, which drives the curve number runoff calculation, and temperature as an ML input. Since the water balance model was built from gridMET, both runoff estimates share the same climate forcing. 

== SSURGO (Soil Survey Geographic Database) 
The SSURGO Data has two linked parts: (1) the spatial part as vector polygons (soil map units), downloaded as shapefiles from Web Soil Survey, and (2) the tabular part as a set of relational tables of soil properties, delivered as text files with a Microsoft Access template. A gridded version, gSSURGO, packages the same data as a 10 m raster in an ESRI file geodatabase for each state, which is easier to overlay with other grids.

Static spatial data describes soil properties as mapped, with no time dimension. Mapping scales are typically 1:12,000 to 1:24,000, much finer than the other datasets. Each polygon is a map unit identified by a key (`mukey`). A map unit can contain several soil components, each with its own properties and share of the area. The tables are linked by keys: `mapunit` → `component` → `chorizon` (the soil layers). For this project, the key field is the hydrologic soil group (A, B, C, D, or dual groups like A/D), which ranks soils by how easily water infiltrates. The muaggatt table has a ready-made dominant hydrologic group per map unit (`hydgrpdcd`). Combined with NLCD land cover, it sets the curve number. 

= Project Proposal


/* REMOVE THIS LINE TO UNCOMMENT THE REST OF THE DOCUMENT

=== First Subsubsection

You can make sub, sub-sub, and sub-sub-sub sections by adding `=` signs in front of the section title. There needs to be a space between the last `=` sign and the title text.

To add citations to the report, go to #link("https://scholar.google.com"), search for a paper, click on the quotation mark icon below the search result, and copy the BibTeX entry. Then paste it into the `refs.bib` file. You can cite papers using the `@` symbol followed by the citation key, e.g., @lowry1951protein.

More information about citations can be found in the Typst documentation: #link("https://typst.app/docs/reference/model/cite").

Other options to get BibTeX entries for your references include #link("https://www.bibtex.com/converters/") and asking an LLM to generate the a BibTeX entry for you. (If you use an LLM, make sure to verify the generated BibTeX entry for correctness.)

To add figures to your report, save the image file in the `figures` folder and use the `#figure` command as shown below to include it in your document. You can specify the width of the image and add a caption. Then you can reference the figure like this: @proofread.

#figure(
  image("figures/proof-read.png", width: 80%),
  caption: [A humble request. (Copyright: University of the Fraser Valley.)],
) <proofread>

= Second Section

You can add tables using the `#table` command. Here is an example table:

#figure(
  caption: [Example Table],
  table(
    columns: (auto, auto, auto),
    table.header([*Column 1*], [*Column 2*], [*Column 3*]),
    "Row 1", "Data 1", [Data 2],
    image("figures/proof-read.png", width: 40%), "Data 3", "Data 4",
  ),
) <table-example>

You can reference the table like this: @table-example.

== Various Text Formatting Options

You can make text _italic_ by surrounding it with `_` symbols, *bold* by surrounding it with `*` symbols, and _*bold italic*_ by combining both. You can format `inline code snippets` by surrounding them with backtick (\`) characters.

You can create bullet point lists using `-` symbols:
- Bullet point 1
- Bullet point 2
  - Sub bullet point 1
  - Sub bullet point 2


You can create numbered lists using numbers followed by a period (or using `+` symbols, which number the items for you):
1. First item
2. Second item
  1. Sub item 1
  2. Sub item 2



== Equations

You can create equations using `$` symbols. For example, you can make an inline equation like this $E=m c^2$ or a displayed equation like this:

$ x < y => x gt.eq.not y $ <eq1>

You can reference the equation like this: Eq. @eq1.
