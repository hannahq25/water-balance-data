#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Impacts of Climate Change and Urbanization on Water Runoff],
  // abstract: [
  //   This is where you put your abstract.
  // ],
  authors: (
    (
      name: "Hannah Qian",
      department: [Civil & Environmental Engineering],
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

// = Background
= Data Sources
== Daily Historical Water Balance Products for the CONUS:
 A gridded daily historical water balance dataset covering the Continental United States (historic water balance data) @Tercek2023. The dataset was originally developed under the National Park Service Inventory and Monitoring Program and the National Park Service Climate Change Response Program. Version 1.5, the version currently available online, provides daily historic data (1980–2024) on #link("https://search.earthdata.nasa.gov/search?q=C2674700048-LPCLOUD")[NASA's Earthdata database] or an #link("https://npwbanalres.s3.us-west-2.amazonaws.com/index.html")[Amazon S3 bucket]. @HistBalanceData

== Future NPS Gridded Water Balance Model
 Future conditions of the aforementioned water balance dataset are available as 30-year averages (2040–2069 and 2070–2099, under both RCP 4.5 and RCP 8.5 emissions scenarios) for an assortment of climate models from a second S3 bucket @FutureBalanceData. Many references cite a THREDDS server for this data; however, that server is no longer valid.

== Annual National Land Cover Database Collection 1.2 
 A database by the USGS that applies geospatial deep learning algorithms to the Landsat satellite imagery record to classify land cover and surface change characteristics across the conterminous US an on annual basis, beginning in 1985. The Land Cover Classification and Fractional Impervious Surface products will be most relevant to this project. The data is available to view and download through multiple platforms, including the MRLC Web Viewer @MRLCViewer.

== U.S. Climate Resilience Toolkit Climate Explorer
 A tool built by the EPA, NASA, NOAA, and USGS and hosted by the National Environmental Modeling and Analysis Center (NEMAC) at the University of North Carolina Asheville. The tool provides interactive graphs and maps of historical and projected climate conditions for localities across the US. Historical observations were recorded at weather and climate stations. Projections are generated from global climate models for the Coupled Model Intercomparison Project Phase 5 (CMIP5) for the RCP 4.5 and RCP 8.5 emissions scenarios. Annual, locality-specific data can be downloaded through the online Climate Explorer tool @ClimateExplorer. 

== GridMET 
 Daily gridded meteorological data at about 4 km resolution @abatzoglou2013 @GridMETwebsite. It is the same precipitation and temperature forcing used by the water balance model. Using it for the curve number calculation keeps the two runoff estimates directly comparable. 

== SSURGO (Soil Survey Geographic Database) 
 The USDA NRCS soil database provides hydrologic soil groups (A–D), which are combined with land cover to assign curve numbers. 

= Data Formats and Contents
== Daily Historical Water Balance Products for the CONUS 

The historical water balance data is available in Network Common Data Form (netCDF) format. NetCDF files contain variables distributed across common dimensions, and attributes of each variable, which allow a single file to store variables across both spatial and time dimensions.   

The data are gridded over the entire continental US in 1 km cells, stored in daily time steps (`time` variable). It is projected in a Lambert Conformal Conic (LCC) projection, and each cell has LCC x and y coordinate.  The degree latitude/longitude is also stored as variables across the x/y dimensions. 

Version 1.5 of the water balance dataset was developed from daily meteorological data from GridMET: daily minimum and maximum temperature and daily precipitation. The model treats the soil as a "bucket" with a maximum capacity based on the USDA’s SSURGO soil database Available Water Storage paramater. Precipitation is classified as rain or snow based on temperature, adjusted for relative humidity (Jennings et al., 2018). Potential evapotranspiration is calculated with the Oudin method, which uses temperature and latitude-based solar radiation (Oudin et al., 2005). 

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

== Annual National Land Cover Database Collection 1.2 
@NLCDUserGuide

== U.S. Climate Resilience Toolkit Climate Explorer 

== GridMET 

== SSURGO (Soil Survey Geographic Database) 

= Project Proposal

This project will compare the impacts of climate change versus urbanization on surface runoff and stream flows using the datasets discussed above. Specifically, the project will analyze the precipitation, evapotranspiration, soil infiltration, and temperature to understand the impacts these parameters have on runoff and to determine how changes in surface and climate conditions could impact the balance of water within the ecosystem.  

The project will evaluate impacts in urbanization by combining the NLCD land cover classifications with the SSURGO hydrologic soil groups to produce an SCS curve number (CN).  CN is typically used in hydrologic modeling to estimate runoff during a specific storm event and can be combined with the daily rainfall data to estimate the runoff in an urbanized environment. 

Both estimates will be validated against gage discharge converted to runoff depth. If observed streamflow and CN runoff both increase over time while the water balance runoff does not, the increase can be attributed to urbanization rather than climate. 

 
A machine learning model will be used as a predictive element using land cover, impervious fraction, precipitation, and temperature to predict observed runoff. The model will then predict runoff under two cases: land cover change with historical climate, and land cover change with projected RCP 4.5 and RCP 8.5 climate, with future land cover extrapolated from Annual NLCD trends. Comparing these results with the future water balance projections will show how much future runoff depends on urbanization versus climate. 