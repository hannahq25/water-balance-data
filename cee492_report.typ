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
= Data Sources <data-sources>
This project explores a collection of water and climate datasets to evaluate the ability to predict runoff under non-stationary climate and land use environments. In order to evaluate these, the project will combine and synthesize data from the following sources. 
== Daily Historical Water Balance Dataset (Daily Water Balance):
 The primary model-created dataset used as part of this project is a gridded daily historical water balance dataset covering the continental US (CONUS) @Tercek2023. The dataset was originally developed under the National Park Service Inventory and Monitoring Program and the National Park Service Climate Change Response Program. Version 1.5, the version currently available through the National Aeronautics and Space Administration (NASA), provides daily historic data (1980–2024) on #link("https://search.earthdata.nasa.gov/search?q=C2674700048-LPCLOUD")[NASA's Earthdata database] or an #link("https://npwbanalres.s3.us-west-2.amazonaws.com/index.html")[Amazon S3 bucket]. @HistBalanceData

== Future Conditions Water Balance Dataset (Future Water Balance)
 Tercek et al (2023) also used the same model method to project the data under various climate change scenarios and climate change models. These are available as 30-year averages (2040–2069 and 2070–2099, under both Representative Concentration Pathway (RCP) 4.5 and RCP 8.5 #footnote[RCP 4.5 and RCP 8.5 are emissions scenarios with radiative forcing of 4.5 and 8.5 W/m#super[2] in 2100, respectively.]) for an assortment of climate models from a second Amazon S3 bucket @FutureBalanceData. Many references cite a THREDDS server for the water balance data; however, that server is no longer valid.  The dataset also spans CONUS.

== GridMET 
 Version 1.5 of the Daily Water Balance dataset was developed using climate data available from Climatology Lab's GridMET dataset@abatzoglou2013 @GridMETwebsite. GridMET is a 4-km gridded daily time series dataset from 1979 through the present for CONUS. It blends the spatial detail of Parameter-elevation Regressions on Independent Slopes Model (PRISM) climate data with the daily timing of National Land Data Assimilation System Phase 2 (NLDAS-2) reanalysis. While the focus and calibration of the dataset is on climate variables such as precipitation and temperature, Climatology Lab also stores terrain data on a similar grid and spatial domain that can be used for modeling purposes. 

 == Multivariate Adaptive Constructed Analogs (MACA)
 Climatology Lab has also developed downscaled future conditions datasets titled Multivariate Adaptive Constructed Analogs (MACA). The MACA datasets downscale an assortment of climate models under both RCP 4.5 and RCP 8.5 to a 4-km grid for CONUS at a daily time interval.  For this project, the  MACAv2-METDATA dataset was used. The synthesized dataset for this project will be trained on the GridMET data and therefore should minimize biases between the historical and future conditions datasets.  Because of the significant amount of data available, this project utilized only one climate model data available from MACA, CNRM-CM5. CNRM-CM5 was chosen as the sample model because it more closely replicates extreme precipitation cycles in the Northeast United States, which typically sees similar weather patterns to the selected study area in Georgia (see @domain-selection). The MACA dataset is available through the Climatology Lab website @MACAwebsite.

 == U.S. Climate Resilience Toolkit Climate Explorer (Climate Explorer)
 Climate projections typically utilize an ensemble of datasets, simulations, or models to improve performance and reduce uncertainty. Therefore, the MACA data will be supported by annual ensemble data from Climate Explorer, a tool built by the Environmental Protection Agency (EPA), NASA, National Oceanic and Atmospheric Administration (NOAA), and the US Geological Survey (USGS) and hosted by the National Environmental Modeling and Analysis Center (NEMAC) at the University of North Carolina Asheville. The tool provides historical climate conditions across the US based on observations at weather stations and projected climate conditions based on global climate models for the Coupled Model Intercomparison Project Phase 5 (CMIP5) under RCP 4.5 and RCP 8.5. Annual, locality-specific data can be downloaded through the online Climate Explorer tool @ClimateExplorer. 

 == Soil Survey Geographic Database (SSURGO) <ssurgo-intro>
Runoff is impacted not only by climate, but also by soil conditions. Data on soil properties across CONUS are available through the Natural Resources Conservation Service's (NRCS) Soil Survey Geographic Database (SSURGO).  While the dataset has been updated over the years, there is no time dimension to the data unlike the other datasets discussed above.  The dataset categories areas spatially by soil type and provides tables detailing the properties of each soil type. The two primary variables that will be used as part of this project are the Hydrologic Soil Group and the Available Water Storage.  Both variables express the infiltration capacity of the soil type.  Hydrologic Soil Group expresses the soil type as either A, B, C, or D with A being the most permeable and D being the least permeable.  Available Water Storage expresses the amount of water that can be stored for use by plants up to a certain depth in the soil and stores the value in millimeters, typically ranging between 0 and 250 mm.  SSURGO data is available in statewide datasets from the NRCS website @SSURGO. 

== Annual National Land Cover Database Collection 1.2  (NLCD)
 While not utilized in the Daily Water Balance, the other major variable typically used when evaluating infiltration capacity is a land use.  Land use data predicts infiltration capacity by identifying impervious surfaces, where no infiltration is possible; barren land, which has moderate infiltration capacity; and different types of vegetative cover, which have greater capacities to intercept and absorb rainfall. The USGS has classified land cover and surface change characteristics across CONUS by applying geospatial deep learning algorithms to the Landsat satellite imagery record @NLCDUserGuide. The resulting data is available in the Annual National Land Cover Database Collection 1.2 (NLCD) on an annual basis, beginning in 1985. The Land Cover Classification and Fractional Impervious Surface products in the dataset are used in this project. The data is available to view and download through multiple platforms, including the Multi-Resolution Land Characteristics (MRLC) Web Viewer @MRLCViewer.

== USGS Water Data for the Nation (USGS Gage Data)
 While the Daily Water Balance dataset estimates runoff, it will be critical to validate the model results against observed runoff.  Observed runoff can be estimated from stream gages.  The USGS collects and distributes stream gage data for gages across CONUS.  Each gage has a unique site number and varying period of record and data collected.  For this project, the daily mean discharge was incorporated as the best dataset to validate the Daily Water Balance runoff estimates.  The USGS maintains a website for each gage and users can obtain data directly through the website or other Application Programming Interfaces (APIs).  
//  For example, the USGS Gage 02207120, Yellow River at GA 124, Near Lithonia, GA, has daily mean discharge for April 26, 1996 to present @02207120

 For each gage, the USGS also maintains its spatial watershed boundary in GeoJSON format, which can be accessed through its API @USGSAPI.

= Data Formats and Contents
Each of the datasets discussed above has a different data format and structure.  The following sections provide a brief overview of the data formats and contents for each dataset.
== Daily Water Balance 

The daily water balance data is available in the Network Common Data Form (NetCDF) format. NetCDF files contain variables distributed across common dimensions, and attributes of each variable, which allow a single file to store variables across both spatial and time dimensions.   

The data are gridded over the entire continental US in 1 km cells, stored in daily time steps (`time` variable). It is projected in a Lambert Conformal Conic (LCC) projection, and each cell has LCC `x` and `y` coordinate.  The degree latitude/longitude is also stored as variables across the `x`/`y` dimensions. 

Version 1.5 of the water balance dataset was developed from daily meteorological data from GridMET: daily minimum and maximum temperature and daily precipitation. The model treats the soil as a "bucket" with a maximum capacity based on the SSURGO soil database "Available Water Storage" parameter. Precipitation is classified as rain or snow based on temperature, adjusted for relative humidity @jennings2018. Potential evapotranspiration is calculated with the Oudin method, which uses temperature and latitude-based solar radiation @oudin2005. 

#figure(
  caption: [Historical Water Balance Variables],
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

== Future Water Balance
The future water balance data is available as Georeferenced Tagged Image File Format (GeoTIFF) files summarized as the 30-year means. A GeoTIFF file embeds georeferencing information within a TIFF image file. Each GeoTIFF represents a separate variable, similar to the variables in the historic dataset (rain, runoff, pet, etc.), and each pixel of the GeoTIFF stores a value for the variable for a particular georeferenced location. 

== GridMET
The gridMET data are available as NetCDF files, usually one file per variable per year, on a regular latitude–longitude grid in geographic coordinate system World Geodetic System 1984 (WGS84). 
// This is also available through Google Earth Engine. Gridded daily time series covering the contiguous US from 1979 to the present, at about 4 km resolution (1/24°). It blends the spatial detail of Parameter-elevation Regressions on Independent Slopes Model (PRISM) climate data with the daily timing of National Land Data Assimilation System Phase 2 (NLDAS-2) reanalysis.

The dataset includes precipitation (`pr`, in mm), daily maximum and minimum temperature (`tmmx`, `tmmn`, in Kelvin), relative and specific humidity, solar radiation, wind speed, and reference evapotranspiration. The project mainly uses precipitation and temperature. 

== MACA
The MACA dataset is also available as NetCDF files and was downloaded as one NetCDF file per model, per scenario, per variable.  As discussed in @data-sources, only one climate model (CNRM-CM5) was used for both RCP 4.5 and RCP 8.5 scenarios.  The variables used in this project are precipitation (`pr`, in mm), daily maximum and minimum temperature (`tmmx`, `tmmn`, in Kelvin).

Each variable/model pairing was analyzed in three  different scenarios: historical (1950-2005), RCP 4.5 (2006-2100), and RCP 8.5 (2006-2100).  

The MACA data is available in a roughly 4km grid spacing, similar to the GridMET data.  However, because it is stored in latitude/longitude, the grids are not uniform in size across CONUS.  The dataset is in the geographic coordinate system  WGS84.

== Climate Explorer 
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

== SSURGO
The SSURGO dataset, accessed as a statewide database for Georgia as part of this project, is available in two parts:
(1) a GeoTIFF file defining the soil type using a map unit key (`mukey`) for each grid cell, and 
(2) the tabular data describing the various soil property for each `mukey`. Each table for the state of Georgia was included in a geopackage (gpkg) database file. For this project, the key table is the Map Unit Aggregated Attribute (`muaggatt`) table, which stores the hydrologic soil group per map unit (`hydgrpdcd`) and the available water storage capacity (`aws150`). Both of these variables are used to calculate the infiltration capacity of the soil. 
// Although the data was collected and updated over time, the only available dataset the most recently collected soil conditions and therefore there is no time dimension to this data source.  

The GeoTIFF used for this project was in a 10m resolution in the European Petroleum Survey Group (EPSG) projection number 5070, also known as the NAD83 / Conus Albers projection. 

== NLCD
The NLCD data is provided as Cloud-Optimized GeoTIFF (COG) files, similar to the Future Water Balance data. Each GeoTIFF image corresponds to a year and a land cover variable. The table below shows the legend for Land Cover values according to the Annual National Land Cover Database (NLCD) Collection 1 Science Product User Guide @NLCDUserGuide.

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
    "31", "Barren Land (Rock/Sand/Clay)", "95", "Emergent Herbaceous Wetlands",
    "41", "Deciduous Forest",
  ),
)

The data values for Fractional Impervious Area range from 0-100, representing the percentage of a 30-meter pixel that is covered with impervious surfaces. 

== USGS Gage Data
The Water Data for the Nation dataset is a tabular time series, downloadable as CSV, tab-delimited text, or JSON. This can be obtained from the Water Data for the Nation website or programmatically with the USGS `dataretrieval` Python package. The dataset provides point data measured at one gage location as a daily time series, with many gages having records going back decades. 

Each gage has a site number and metadata including location and drainage area. Data are organized by parameter code: discharge is `00060`, in cubic feet per second, and daily mean values use statistic code `00003`. Each value carries a qualification code: `A` (approved, reviewed by USGS), `P` (provisional, may be revised), or `e` (estimated). Recent data are often still provisional, so the analysis should mainly use approved values. 

= Selecting a Study Area and Time Period <domain-selection>
Gwinnett County, GA was chosen as the focus area due to its rapid urbanization within the past several decades. For consistency and simplicity, all gridded variables were summarized by watershed for 15 gaged watersheds within Gwinnett County as shown in @locationmap.  
#figure(
  image("figures/LocationMap.png", width: 80%),
  caption: [Location of the 15 gaged watersheds evaluated in this report],
) <locationmap>
Analyzing runoff and stream flow requires the precision of daily data. However, urbanization trends are best observed, and future predictions are best made at annual or decadal intervals. Therefore, for each watershed and time period, the data was  summarized by the daily average, median, maximum, and minimum if available, and each statistical parameter was also estimated on an annual basis.

Although data in the datasets span the years 1950 to 2100, most of the data is only available between 1985 to 2024 for historical datasets and from 2025 to 2099 for future datasets.  Therefore this project will focus on those two time periods.  Most of the gage streamflow datasets do not begin until the mid-2000s, so much of the predictive modeling that relies on the stream gage data will be limited to the 20-year period between 2000 and 2025.

= Project Proposal

This project will compare the impacts of climate change versus urbanization on surface runoff and stream flows using the datasets discussed above. Specifically, the project will analyze the precipitation, evapotranspiration, soil infiltration, and temperature to understand the impacts these parameters have on runoff and to determine how changes in surface and climate conditions could impact the balance of water within the ecosystem.  

The project will evaluate impacts in urbanization by combining the NLCD land cover classifications with the SSURGO hydrologic soil groups to produce an Soil Conservation Service (SCS) curve number (CN).  CN is typically used in hydrologic modeling to estimate runoff during a specific storm event and can be combined with the daily rainfall data to estimate the runoff in an urbanized environment. 

Both estimates will be validated against gage discharge converted to runoff depth. If observed streamflow and CN runoff both increase over time while the water balance runoff does not, the increase can be attributed to urbanization rather than climate as long as climate-driven storm intensity is not a factor. 

A machine learning model will be used as a predictive element using land cover, impervious fraction, precipitation, temperature and the water balance model’s outputs to predict observed runoff. The model will then predict runoff under four cases: historical land cover with historical climate (baseline), future land cover with historical climate, and historical land cover  with projected RCP 4.5 and RCP 8.5 climate, with future land cover with projected RCP 4.5 and RCP 8.5 climate. Future land cover may be extrapolated from Annual NLCD trends. Comparing these results with the future water balance projections will show how much future runoff depends on urbanization versus climate. 
 = Exploratory Data Analysis

== Runoff and Streamgage

The daily mean discharge data was obtained from US Geological Survey (USGS) for the 14 streamgages in Gwinnett County, Georgia. The Wildcat Creek streamgage was excluded, since its recorded data (1953 – 1982) lies outside of the period scope of study (1985 -present). Streamgage data is the observed waterflow outside of a watershed, normally given by the USGS as daily values.  

The raw data file for each streamgage from USGS contains the date, corresponding mean discharge in cubic feet per second (ft3/s), and a date-value qualification value. The qualification codes include A (approved for publication), e (value has been estimated), R (records were revised), and P (provisional data subject to revision). The compiled data disregarded the provisional data and only retained the approved data. The days without a discharge value were also disregarded. Additionally, years with incomplete data, either: (a) not having a complete year (year with less than 360 days of data), (b) having no data at all, were also disregarded. 

The daily discharge data was converted into runoff (mm/day) by dividing it by the drainage area of the watersheds, obtained from (our reference paper). This will allow the streamgage data to be comparable to the gridded water balance and precipitation data. These were further converted into annual mean discharge, annual total runoff, and annual peak daily runoff by streamgage by year. The annual mean discharge is the average daily mean discharge value by year, annual total runoff is the sum of the daily runoff depths by year, and annual peak daily discharge is the largest recorded daily runoff depth in a year. 

Trendlines were fitted to the annual mean discharge values to determine if there is an increasing or decreasing trend for discharge per gage. The resulting trendlines are relatively flat, with low coefficient of determination (R2) values, ranging from 0.00 to 0.12. This means that yearly variability outweighs long-term changes based on observed discharge. However, the inconsistent availability of data among gage types for some watersheds (e.g., Yellow River near Snellville with a 16-year gap and other gages having complete records only from 2002), may limit the detection of long-term trends. This can be supported by seeing that Suwanee Creek, with continuous data from 1985 to 2023, showed one of the largest increases in annual mean discharge over time. Thus, the streamgage data should be interpreted with precipitation data to determine if the discharge has changed outside of wet or dry years. 

 = Predictive Modeling 