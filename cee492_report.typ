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
#set math.equation(numbering: none)

// = Background
= Data Sources <data-sources>
This project explores a collection of water and climate datasets to evaluate the ability to predict runoff under non-stationary climate and land use environments. In order to evaluate these, the project will combine and synthesize data from the following sources. 
== Daily Historical Water Balance Dataset (Daily Water Balance):
 The primary model-created dataset used as part of this project is a gridded daily historical water balance dataset covering the continental US (CONUS) @Tercek2023. The dataset was originally developed under the National Park Service Inventory and Monitoring Program and the National Park Service Climate Change Response Program. Version 1.5, the version currently available through the National Aeronautics and Space Administration (NASA), provides daily historic data (1980–2024) on #link("https://search.earthdata.nasa.gov/search?q=C2674700048-LPCLOUD")[NASA's Earthdata database] or an #link("https://npwbanalres.s3.us-west-2.amazonaws.com/index.html")[Amazon S3 bucket]. @HistBalanceData
/*
== Future Conditions Water Balance Dataset (Future Water Balance)
 Tercek et al (2023) also used the same model method to project the data under various climate change scenarios and climate change models. These are available as 30-year averages (2040–2069 and 2070–2099, under both Representative Concentration Pathway (RCP) 4.5 and RCP 8.5 #footnote[RCP 4.5 and RCP 8.5 are emissions scenarios with radiative forcing of 4.5 and 8.5 W/m#super[2] in 2100, respectively.]) for an assortment of climate models from a second Amazon S3 bucket @FutureBalanceData. Many references cite a THREDDS server for the water balance data; however, that server is no longer valid.  The dataset also spans CONUS.
*/
== GridMET 
 Version 1.5 of the Daily Water Balance dataset was developed using climate data available from Climatology Lab's GridMET dataset@abatzoglou2013 @GridMETwebsite. GridMET is a 4-km gridded daily time series dataset from 1979 through the present for CONUS. It blends the spatial detail of Parameter-elevation Regressions on Independent Slopes Model (PRISM) climate data with the daily timing of National Land Data Assimilation System Phase 2 (NLDAS-2) reanalysis. While the focus and calibration of the dataset is on climate variables such as precipitation and temperature, Climatology Lab also stores terrain data on a similar grid and spatial domain that can be used for modeling purposes. 
/*
 == Multivariate Adaptive Constructed Analogs (MACA)
 Climatology Lab has also developed downscaled future conditions datasets titled Multivariate Adaptive Constructed Analogs (MACA). The MACA datasets downscale an assortment of climate models under both RCP 4.5 and RCP 8.5 to a 4-km grid for CONUS at a daily time interval.  For this project, the  MACAv2-METDATA dataset was used. The synthesized dataset for this project will be trained on the GridMET data and therefore should minimize biases between the historical and future conditions datasets.  This project utilized only one climate model data available from MACA, CNRM-CM5, due to the significant amount of data available. CNRM-CM5 was chosen as the sample model because it more closely replicates extreme precipitation cycles in the Northeast United States, which typically sees similar weather patterns to the selected study area in Georgia (see @domain-selection). The MACA dataset is available through the Climatology Lab website @MACAwebsite.

 == U.S. Climate Resilience Toolkit Climate Explorer (Climate Explorer)
 Climate projections typically utilize an ensemble of datasets, simulations, or models to improve performance and reduce uncertainty. Therefore, the MACA data will be supported by annual ensemble data from Climate Explorer, a tool built by the Environmental Protection Agency (EPA), NASA, National Oceanic and Atmospheric Administration (NOAA), and the US Geological Survey (USGS) and hosted by the National Environmental Modeling and Analysis Center (NEMAC) at the University of North Carolina Asheville. The tool provides historical climate conditions across the US based on observations at weather stations and projected climate conditions based on global climate models for the Coupled Model Intercomparison Project Phase 5 (CMIP5) under RCP 4.5 and RCP 8.5. Annual, locality-specific data can be downloaded through the online Climate Explorer tool @ClimateExplorer. 
*/
 == Soil Survey Geographic Database (SSURGO) <ssurgo-intro>
Runoff is impacted not only by climate, but also by soil conditions. Data on soil properties across CONUS are available through the Natural Resources Conservation Service's (NRCS) Soil Survey Geographic Database (SSURGO).  While the dataset has been updated over the years, there is no time dimension to the data unlike the other datasets discussed above.  The dataset categorizes areas spatially by soil type and provides tables detailing the properties of each soil type. The two primary variables that will be used as part of this project are the Hydrologic Soil Group and the Available Water Storage.  Both variables express the infiltration capacity of the soil type.  Hydrologic Soil Group expresses the soil type as either A, B, C, or D, with A being the most permeable and D being the least permeable.  Available Water Storage expresses the amount of water that can be stored for use by plants up to a certain depth in the soil and stores the value in millimeters (mm), typically ranging between 0 and 250 mm.  SSURGO data are available in statewide datasets from the NRCS website @SSURGO. 

== Annual National Land Cover Database Collection 1.2  (NLCD)
 While not utilized in the Daily Water Balance, the other major variable typically used when evaluating infiltration capacity is land use.  Land use data predicts infiltration capacity by identifying: (a) impervious surfaces, where no infiltration is possible, (b) barren land, which has moderate infiltration capacity, and (c) different types of vegetative cover, which have greater capacities to intercept and absorb rainfall. The US Geological Survey (USGS) has classified land cover and surface change characteristics across CONUS by applying geospatial deep learning algorithms to the Landsat satellite imagery record @NLCDUserGuide. The resulting data are available in the Annual NLCD Collection 1.2 on an annual basis, beginning in 1985. The Land Cover Classification and Fractional Impervious Surface products in the dataset are used in this project. The data are available to view and download through multiple platforms, including the Multi-Resolution Land Characteristics (MRLC) Web Viewer @MRLCViewer.

== USGS Water Data for the Nation (USGS Gage Data)
 While the Daily Water Balance dataset estimates runoff, it will be critical to validate the model results against observed runoff.  Observed runoff can be estimated from stream gages.  The USGS collects and distributes stream gage data for gages across CONUS.  Each gage has a unique site number and varying period of record and data collected.  For this project, the daily mean discharge was incorporated as the best dataset to validate the Daily Water Balance runoff estimates.  The USGS maintains a website for each gage and users can obtain data directly through the website or other Application Programming Interfaces (APIs).  
//  For example, the USGS Gage 02207120, Yellow River at GA 124, Near Lithonia, GA, has daily mean discharge for April 26, 1996 to present @02207120

 For each gage, the USGS also maintains its spatial watershed boundary in GeoJSON format, which can be accessed through its API @USGSAPI.

= Data Formats and Contents
Each of the datasets discussed above has a different data format and structure.  The following sections provide a brief overview of the data formats and contents for each dataset.
== Daily Water Balance 

The daily water balance data are available in the Network Common Data Form (NetCDF) format. NetCDF files contain variables distributed across common dimensions, and attributes of each variable, which allow a single file to store variables across both spatial and time dimensions.   

The data are gridded over the entire continental US in 1 kilometer (km) cells, stored in daily time steps (`time` variable). This is projected in a Lambert Conformal Conic (LCC) projection, and each cell has an LCC `x` and `y` coordinate.  The degree latitude/longitude is also stored as variables across the `x`/`y` dimensions. 

Version 1.5 of the water balance dataset was developed from daily meteorological data from GridMET: daily minimum and maximum temperature, and daily precipitation. The model treats the soil as a "bucket" with a maximum capacity based on the SSURGO soil database "Available Water Storage" parameter. Precipitation is classified as rain or snow based on temperature, adjusted for relative humidity @jennings2018. Potential evapotranspiration is calculated with the Oudin method, which uses temperature and latitude-based solar radiation @oudin2005. 

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
/*
== Future Water Balance
The future water balance data are available as Georeferenced Tagged Image File Format (GeoTIFF) files summarized as the 30-year means. A GeoTIFF file embeds georeferencing information within a TIFF image file. Each GeoTIFF represents a separate variable, similar to the variables in the historic dataset (rain, runoff, pet, etc.), and each pixel of the GeoTIFF stores a value for the variable for a particular georeferenced location. 
*/
== GridMET
The GridMET data are available as NetCDF files, usually one file per variable per year, on a regular latitude–longitude grid in geographic coordinate system World Geodetic System 1984 (WGS84). The GridMET dataset spans the years 1979 to the present.
// This is also available through Google Earth Engine. Gridded daily time series covering the contiguous US from 1979 to the present, at about 4 km resolution (1/24°). It blends the spatial detail of Parameter-elevation Regressions on Independent Slopes Model (PRISM) climate data with the daily timing of National Land Data Assimilation System Phase 2 (NLDAS-2) reanalysis.

The dataset includes precipitation, daily maximum and minimum temperature, which are the primary climate variables for the project. Other variables, that may be used as part of the project, included in the dataset such as srad, vpd and pdsi. The table below lists the variables used in this project.

#figure(
  caption: [GridMET Variables],
  table(
    columns: (auto, auto, auto),
    align: (center, left, center),
  table.header([*Variable*],[*Description*],[*Units*]),
  [`pr`],[daily accumulated precipitation],[mm/day],
  [`tmmx`],[daily maximum air temperature],[K],
  [`tmmn`],[daily minimum air temperature],[K],
  [`srad`],[Downward surface shortwave solar radiation],[W/m²],
  [`vpd`],[mean vapor pressure deficit],[kPa],
  [`pdsi`],[Palmer Drought Severity Index (ten-day severity indicator)],[none],
  )
)
/*
== MACA
The MACA dataset is also available as NetCDF files and was downloaded as one NetCDF file per model, per scenario, per variable.  As discussed in @data-sources, only one climate model (CNRM-CM5) was used for both RCP 4.5 and RCP 8.5 scenarios.  The variables used in this project are precipitation (`pr`, in mm), daily maximum and minimum temperature (`tmmx`, `tmmn`, in Kelvin).

Each variable/model pairing was analyzed in three  different scenarios: historical (1950-2005), RCP 4.5 (2006-2100), and RCP 8.5 (2006-2100).  

The MACA data are available in a roughly 4km grid spacing, similar to the GridMET data.  However, because it is stored in latitude/longitude, the grids are not uniform in size across CONUS.  The dataset is in the geographic coordinate system  WGS84.

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
*/
== SSURGO
The SSURGO dataset, accessed as a statewide database for Georgia as part of this project, is available in two parts:
(1) a GeoTIFF file defining the soil type using a map unit key (`mukey`) for each grid cell, and 
(2) the tabular data describing the various soil properties for each `mukey`. Each table for the state of Georgia was included in a geopackage (gpkg) database file. For this project, the key table is the Map Unit Aggregated Attribute (`muaggatt`) table, which stores the hydrologic soil group per map unit (`hydgrpdcd`) and the AWS capacity (`aws150`). Both of these variables are used to calculate the infiltration capacity of the soil. 
// Although the data was collected and updated over time, the only available dataset the most recently collected soil conditions and therefore there is no time dimension to this data source.  

The GeoTIFF used for this project was in a 10m resolution in the European Petroleum Survey Group (EPSG) projection number 5070, also known as the NAD83 / Conus Albers projection. 

== NLCD
The NLCD data are provided as Cloud-Optimized GeoTIFF (COG) files. Each GeoTIFF image corresponds to a year and a land cover variable. The table below shows the legend for Land Cover values according to the Annual NLCD Collection 1 Science Product User Guide @NLCDUserGuide.

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
In addition, because of the intense urbanization in all of the Gwinnett Watersheds, a sixteenth watershed was selected nearby without urbanization over the study period.  The gage, Chattahoochee River at Helen, GA (USGS Gage 02330450) was selected as a control watershed to compare the results of the Gwinnett County watersheds to a watershed that has not been impacted by urbanization.  

Analyzing runoff and stream flow requires the precision of daily data. However, urbanization trends are best observed at annual or decadal intervals. Therefore, for each watershed and time period, the data was  summarized by the daily average, median, maximum, and minimum if available, and each statistical parameter was also estimated on an annual basis.

Although data in the datasets span the years 1950 to present, most of the data are only available between 1985 to 2024 for historical datasets.  Therefore this project will focus on this time period.  Most of the gage streamflow datasets do not begin until the mid-2000s, so the predictive modeling will focus on gages with a full record (02335000 and 02334885).

= Exploratory Data Analysis

== Runoff and Streamgage

The daily mean discharge data was obtained from USGS for 14 of the 15 streamgages in Gwinnett County, Georgia. The Wildcat Creek streamgage was excluded, since its recorded data (1953 – 1982) lies outside of the period scope of study (1985 -present) and the control watershed was not included. Streamgage data are the observed waterflow at the outlet of a watershed, normally given by the USGS as daily values.  

The raw data file for each streamgage from USGS contains the date, corresponding mean discharge in cubic feet per second (ft3/s), and a date-value qualification value. The qualification codes include A (approved for publication), e (value has been estimated), R (records were revised), and P (provisional data subject to revision). The compiled data disregarded the provisional data and only retained the approved data. The days without a discharge value were also disregarded. Additionally, years with incomplete data, either: (a) not having a complete year (year with less than 360 days of data), (b) having no data at all, were also disregarded. 

The daily discharge data was converted into runoff (mm/day) by dividing it by the drainage area of the watersheds. This will allow the streamgage data to be comparable to the gridded water balance and precipitation data. These were further converted into annual mean discharge, annual total runoff, and annual peak daily runoff by streamgage by year. The annual mean discharge is the average daily mean discharge value by year, annual total runoff is the sum of the daily runoff depths by year, and annual peak daily discharge is the largest recorded daily runoff depth in a year. 

Trendlines were fitted to the annual mean discharge values to determine if there is an increasing or decreasing trend for discharge per gage. The resulting trendlines are relatively flat, with low coefficient of determination (R²) values, ranging from 0.00 to 0.12. This means that yearly variability outweighs long-term changes based on observed discharge. However, the inconsistent availability of data among gage types for some watersheds (e.g., Yellow River near Snellville with a 16-year gap and other gages having complete records only from 2002), may limit the detection of long-term trends. This can be supported by seeing that Suwanee Creek, with continuous data from 1985 to 2023, showed one of the largest increases in annual mean discharge over time. Thus, the streamgage data should be interpreted with precipitation data to determine if the discharge has changed outside of wet or dry years.

#figure(
  caption: [Annual Mean Discharge for 14 Streamgages in Gwinnett County, GA],
  image("figures/gage_figures.png", width: 90%),
  placement: top,
  scope: "parent",
  )

Processing the stream average daily discharge (cfs)  into an average runoff amount per square mile per day per year  (mm/year) facilitates comparison to the water balance dataset.  The  gridded water balance daily dataset was also processed into an average value per day per year per watershed.  In comparing the two datasets, it is clear the gage data has significantly more variability between the gages than the water balance dataset as shown in the figure below.  

#figure(
  caption: [Standard Deviation of Runoff across Watersheds],
  image("figures/stdev.png", width: 100%),
)

The water balance dataset incorporates the spatial variability of the rainfall as well as the variability in infiltration capacity of just the underlying soils but does not incorporate land use variability or other hydrologic factors such as storage ponds within the watershed.  So it is expected that the real-world data would exhibit more variability than the modeled data.  One notable difference is higher variability in the mid 2010s in the water balance datasets. This could indicate these years is one where there was more spatial variability in the rainfall datasets across the 15 watersheds. 

In addition to providing a comparison of data, it is important to have confidence that the datasets can be evaluated jointly as part of the predictive modeling.  The figure below compares the estimated annual daily runoff for gage 02207120 for both the gage data and the water balance data. 

#figure(
  caption: [Comparison of Annual Runoff, Stream Gage versus Water Balance],
  image("figures/AnnualGagevsWaterBalance.png", width: 100%),
)

From the figure it is clear they generally follow a similar underlying pattern suggesting the water balance dataset is reasonably estimating runoff.  This is a similar pattern that can be seen in the other watersheds evaluated.  

In addition to annual data, the project developed daily summaries for each of the watersheds.  In the figure below, runoff is summarized for the same gage watershed.

#figure(
  caption: [Comparison of Daily Runoff, Stream Gage versus Water Balance],
  image("figures/DailyGagevsWaterBalance.png", width: 100%),
)

As expected, the gage data runoff peaks approximately a day after the water balance data does because of the travel time between the location of the rainfall and the stream gage.  However, the overall volumes do not align; in most cases, the water balance model predicts more runoff than was actually measured at the stream gage.  This could indicate the water balance dataset is poorly incorporating the full set of factors that contribute to the final runoff amount.  

== Precipitation

The GridMET precipitation variable is used in the Daily Water Balance model and is therefore explored further. @mean-daily-precip shows the annual mean daily precipitation from 1985 to 2024 to correspond with the general temporal data availability for other datasets used in this project. The annual mean daily precipitation is calculated by aggregating the daily precipitation over GridMET 4-km grids that have centroids within a watershed. If no grid centroids are located within a watershed (such as smaller watersheds), the grids closest to a watershed are allocated to that watershed. This approach is also used for other variables from the GridMet dataset. The bold line is the average across the 15 watersheds. The thin grey lines are the individual basins and track each other closely. The shaded band spans one standard deviation above and below the trend line of the annual data scattered about the trend line. The band is included to assess whether an apparent trend is larger than ordinary year-to-year variation, in comparing the total rise against one standard deviation. 

For annual mean daily precipitation, the rise across the data record is smaller than one standard deviation of the scatter, so no trend can be distinguished from the noise, even though the fitted line does slope upward.  

#figure(
  caption: [Mean Daily Precipitation Trends for 15 Watersheds in Gwinnett County, GA],
  image("figures/Mean_Daily_Precip.png", width: 100%),
  ) <mean-daily-precip>

@max-daily-precip shows the annual maximum daily rainfall, where the increasing trend is more visible. The annual maximum rainfall rises by approximately 7.7 mm per decade. The total precipitation is therefore roughly unchanged while the heaviest precipitation events become more intense. Because peak flows and runoff response depend on rainfall intensity rather than annual depth, this distinction is relevant to the runoff modeling.

#figure(
  caption: [Annual Maximum Daily Rainfall for 15 Watersheds in Gwinnett County, GA],
  image("figures/Max_Daily_Precip.png", width: 100%),
  ) <max-daily-precip>

/*The MACA dataset simulates daily precipitation spatially between the years 1950 to 2099. The period between 1950-2006 is considered a historic dataset and the remaining years are reflective of different climate scenarios (RCP45/ RCP85) and different models.  Due to the amount of data available (two climate scenarios, multiple models), the daily data for MACA was only pulled for one model, CNRM-CM5 for both climate scenarios.  This model was selected as the sample model to use because it more closely replicates extreme precipitation cycles in the #link("https://journals.ametsoc.org/view/journals/clim/33/22/jcliD190757.xml#:~:text=Simulation%20of%20Northeast%20U.S.%20Extreme%20Precipitation%20and,Observed%20extreme%20precipitation.%20Reanalysis%20geopotential%20height%20patterns.")[Northeast United States], which typically sees common weather patterns similar to the southeast and Georgia. Typically with climate data, it is valuable to also consider an ensemble of multiple climate models to fully understand the uncertainty in the data. Since only one model was used, it is important to verify that it is not exhibiting any trends that are not apparent in the ensemble dataset.   

In @ensemble-comparison we compare the ensemble annual rainfall in mm which is available at county-level at Climate Explorer. Climate Explorer reports the weighted mean, maximum and minimum value of the ensemble.  From this comparison of the ensemble results to the values aggregated as part of this project for CNRM-CM5, it is apparent that the data does not show any noticeable trends outside of the ensemble results. The single model predicts more variability year over year than the ensemble (mean).  

#figure(
  caption: [Annual Rainfall Comparison between CNRM-CM5 and Climate Explorer Ensemble for Gwinnett County, GA],
  image("figures/ensemble_vs_CNRM-CM5.png", width: 100%),
  ) <ensemble-comparison>

The evaluation of precipitation across three datasets, requires confirmation that the datasets correlate year to year.  @precip-ensemble-comparison compares the three datasets,  MACA (precipitation), GridMET (precipitation) and the Water Balance Data (rainfall) for a sample watershed (02207120). For each dataset, the gridded data was processed into a mean daily value per watershed and then into a mean annual value (in mm). The comparisons confirm the GridMET and Water Balance datasets align.  Since the water balance dataset the precipitation is a combination of snowfall (not stored) and rainfall (the variable plotted below), the water balance dataset is expected to constantly have slightly lower values. The other critical item of note is that for the MACA dataset, while it does have a historical component, does not attempt to recreate the actual historical data but was instead validated based on overall #link("https://www.climatologylab.org/maca.html")[trends]. Therefore the MACA data should only be used as part of this project in a similar fashion, in larger 10-30 year time blocks.  

#figure(
  caption: [AnnualPrecipitation Comparison across the Various Datasets for Watershed "02207120"],
  image("figures/PrecipRain_ensemble_CNRM_WB_gridmet.png", width: 100%),
  ) <precip-ensemble-comparison>
*/
== Temperature

Unlike precipitation, both temperature variables show a larger rise (@max-temp-trend and @min-temp-trend) compared to their respective 1 standard deviation noise bands. Minimum temperature increases at 0.374 degrees Celsius per decade and maximum temperature at 0.268 degree Celsius per decade, amounting to approximately 1.5 degrees Celsius and 1.0 degree Celsius respectively across the data record. Relative to the annual scatter, the minimum temperature trend is more pronounced compared to the maximum temperature trend, as it rises roughly two and a half times one standard deviation, compared to about 1.3 times for maximum temperature. 

#figure(
  caption: [Annual Maximum Temperature Comparison across the Various Datasets],
  image("figures/Max_temp_trend.png", width: 100%),
  ) <max-temp-trend>

#figure(
  caption: [Annual Minimum Temperature Comparison across the Various Datasets],
  image("figures/Min_temp_trend.png", width: 100%),
  ) <min-temp-trend>

In comparing mean fractional impervious area and minimum temperature, it is seen that both variables increase over the temporal domain, as shown in @Tmmn_vs_ImpFrac, though not at a constant rate. Mean fractional impervious area appears to increase at a greater rate roughly until 2005, after which it slows substantially. Minimum temperature rises unevenly, with most of the increase showing up around 2004. Both variables are overall increasing across the period as a whole, so there is reason to suspect they may confound each other. This is directly relevant to the project's central question of how much runoff change is attributable to climate versus land use changes. The differing shapes of the two trends, in particular the period after 2005, where impervious area plateaus while temperature continues to rise, may offer a means of distinguishing them. Methods to do so will be explored further. 

#figure(
  caption: [Fractional Impervious Area and Annual Minimum Temperature Comparison across the Various Datasets for Watershed "02207120"],
  image("figures/Tmmn_vs_ImpFrac.png", width: 100%),
  ) <Tmmn_vs_ImpFrac>

== Infiltration Capacity

For nearly all watersheds in Gwinnett County, the NLCD data shows a rapid increase in fractional impervious areas between 1985 and the early 2000s, followed by a slower rate of growth after 2010 (see @fctimpgraph). Percentages of developed land cover follow a similar trend as fractional impervious area (see @medintdevgraph). This trend is mirrored by declines in deciduous forest land cover that plummet until the early 2000s and decrease more gradually decreased after (see @decforestgraph). These patterns \indicate a surge in urbanization, including land development and deforestation, through the early 2000s and steady urbanization from the early 2000s to the present.

Rather than tracking all land cover classes over time, the Soil Conservation Service (SCS) Curve Number may be used to capture the totality of land use changes across all land use types and relate them to runoff and infiltration. According to NRCS' Technical Release 55 (TR-55) @tr55, runoff may be modeled as a function of precipitation and watershed characteristics using the SCS Curve Number method, which states:

$ Q &= frac(\(P-I_a\)^2, \(P-I_a\)+S) \
  I_a &= 0.2S \
  S &= frac(1000, "CN") - 10 $

where $Q$ is runoff, $P$ is rainfall, $S$ is potential maximum retention after runoff begins, $I_a$ is initial abstraction, with all units in inches. CN is the curve number, a dimensionless integer between 0 and 100 that represents the potential for rainfall to run off rather than infiltrate. Given the importance of the CN in modeling runoff, a raster of CN values was created in this project from the NLCD and SSURGO rasters. 

The US Army Corps of Engineers (USACE) provides a lookup table for CN values based on NLCD land cover classes and hydrologic soil group (HSG) @USACEtable. The lookup table is shown in @cn_table.

#figure(
    caption: [Curve Number Lookup Table],
    table(
      columns: (25%,auto, 10%, 10%, 10%, 10%,),
      align: (center+horizon, left+horizon, center+horizon, center+horizon, center+horizon, center+horizon),
      table.header(
        table.cell(rowspan:2)[*Land Cover Value*],
        table.cell(rowspan:2)[*Land Cover Class*], 
        table.cell(colspan:4)[*Hydrologic Soil Group*], 
        [*A*], [*B*], [*C*], [*D*]),
      "11", "Open Water", "98", "98", "98", "98",
      "12", "Perennial Ice/Snow", "98", "98", "98", "98",
      "21", "Developed, Open Space", "49", "69", "79", "84",
      "22", "Developed, Low Intensity", "57", "72", "81", "86",
      "23", "Developed, Medium Intensity", "61", "75", "83", "87",
      "24", "Developed, High Intensity", "81", "88", "91", "93",
      "31", "Barren Land (Rock/Sand/Clay)", "78", "86", "91", "93",
      "41", "Deciduous Forest", "45", "66", "77", "83",
      "42", "Evergreen Forest", "25", "55", "70", "77",
      "43", "Mixed Forest", "36", "60", "73", "79",
      "52", "Shrub/Scrub", "55", "72", "81", "86",
      "71", "Grassland/Herbaceous","50", "69", "79", "84",
      "81", "Pasture/Hay", "49", "69", "79", "84",
      "82", "Cultivated Crops", "67", "78", "85", "89",
      "90", "Woody Wetlands", "30", "58", "71", "78",
      "95", "Emergent Herbaceous Wetlands","30", "58", "71", "78"
    ),
  ) <cn_table>

  The SSURGO dataset provides the dominant HSG(s) for each 10-meter grid cell in the raster. The raster was aggregated to 30-meter grid cells to share the same spatial domain as the NLCD land cover dataset. Aggregation was accomplished by averaging HSGs and rounding ties up, i.e. to the HSG that yields a higher CN. For example, the average of “A” and “B” is “B”, the average of “A” and “C” is “B”, and the average of “A” and “D” is “C”. Each 30-meter grid cell was assigned a CN using its land cover class, its HSG, and the USACE lookup table. The CNs were then summarized for each watershed using the averaging technique described above, as well as by extracting minimum, maximum, and median values.
  
 Overall, the watersheds have steadily trended toward higher average CNs (see @cngraph), which predict lower rates of infiltration and higher rates of runoff during rainfall events. For some watersheds, the average CN has been stable for the past one or two decades, which is consistent with lessened changes in fractional impervious area, developed land cover, and forest cover in the time frame.
  
  #figure(
  caption: [Mean Fractional Impervious Area by Watershed in Gwinnett County, GA],
  image("figures/land-cover/FctImp_meanByWatershed.png", height: 100%),
) <fctimpgraph>

#figure(
  caption: [Percentage of Medium Intensity Developed Land Cover by Watershed in Gwinnett County, GA],
  image("figures/land-cover/DevelopedMediumIntensity_percentByWatershed.png", height: 100%),
) <medintdevgraph>

#figure(
  caption: [Percentage of Deciduous Forest Land Cover by Watershed in Gwinnett County, GA],
  image("figures/land-cover/DeciduousForest_percentByWatershed.png", height: 100%),
) <decforestgraph>

#figure(
  caption: [Mean Curve Number by Watershed in Gwinnett County, GA],
  image("figures/land-cover/CN_meanByWatershed.png", height: 100%),
) <cngraph>

Likewise, heatmaps reveal stark differences in fractional impervious area between 1985 and 2024, as well as the spatial distribution of urbanization.

#figure(
  stack(
    dir: ttb,
    spacing: 0.8em,
    image("figures/land-cover/FctImp1985.png", width: 100%),
    image("figures/land-cover/FctImp2024.png", width: 100%),
  ),
  caption: [Fractional Impervious Area in Gwinnett County, GA in 1985 vs 2024],
) <fig-fctimp>
/*
#figure(
  image("figures/land-cover/FctImp1985.png", width: 100%),
)

#figure(
  caption: [Fractional Impervious Area in Gwinnett County, GA in 1985 vs 2024],
  image("figures/land-cover/FctImp2024.png", width: 100%),
)
*/
 In addition to land use and impervious area, the other factor which determines infiltration capacity for an area is the soil type. The SSURGO data are the only input in determining the maximum potential storage of rainwater within the water balance dataset. It is derived from the available water storage variable (AWS) variable within the SSURGO dataset and estimates the amount of water that can be stored within the soil that is available to plants. While the maximum AWS used for the water balance dataset is not provided, in general it is possible to estimate the value used by taking the maximum value over time for each grid cell.  By visual comparison on a sample watershed for USGS gage 02207120, the datasets do generally align as shown below.  However it should be noted that differences will exist because reprojection methods when developing the water- balance datasets are not publicly available.  In general, it appears the maximum soilwater value is higher than the value this project estimated from the SSURGO data, indicating that the maximum soilwater would be an appropriate way to estimate the maximum soil bucket input value if needed to recreate the water balance process. 

#figure(
  caption: [SSURGO Available Water Storage (left), Daily Water Balance Maximum Soilwater (right)],
  image("figures/SSURGOvsSoilwater.png", width: 100%),
) 
The Curve Number (CN) was used to quantify the increase in urbanization in Gwinnett County. The average CN per year per watershed (site location) was used to represent urbanization and was plotted against time with the average mean discharge for each watershed. While the CN is seen to increase over time, the average mean discharge is seen to be controlled by the wet and dry periods, indicated by the lack of visually increasing or decreasing trends over time.

 = Predictive Modeling 
 == Multiple Linear Regression with the Water Balance Spatial Dataset
 The water balance model is a physically based model that transforms the precipitation by first dividing it into rainfall and snowfall.  The runoff is then estimated as the available water that cannot be infiltrated or evapotranspirated as shown in the below figure.

 #figure(
  caption: [Schematic of Water Balance Model Variables],
  image("figures/WaterBalanceProcess.png", width: 100%),
)<fig-waterbalance>
The infiltration/evapotranspiration is often simplified in hydrologic modeling by assuming a constant loss rate based on the type of soils.  The rates typically range between 0 and 0.45 in/hr or approximately 0 to 274 mm/day.  For the watersheds in this study, based on the Hydrologic Soil Group of the soils, the typical range to expect would be 30 to 180 mm/day.  

In the water balance model, the maximum evapotranspiration in a day for any of the watersheds evaluated was approximately 6 mm/day and the maximum infiltration was 80 mm per day.  The mean infiltration on days with rain was approximately 3 mm/day, indicating that the water balance model is typically underestimating the infiltration capacity of the watersheds.   

Therefore, this project incorporated a combination of the water balance estimate of runoff with extra spatial weights to represent the extra infiltration and with a linear intercept which could be used to represent base flow.   

Another complication with using the water balance results to estimate streamflow at a gage is the travel time from the location within the watershed where the runoff occurs to the gaged location.  In traditional watershed modeling, this is modeled using a time of concentration or lag time to reflect the travel time for rainfall from the farthest part of the watershed to the downstream most point in the watershed and the rainfall hyetograph is translated by the time length. In this model, the travel time was reflected by estimating the gage discharge at time t by the runoff estimated by the modified water balance model at time t, t-1, t-2, etc. reflecting the overall translation of the spatially gridded runoff to the final gaged streamflow point.   

These additional variables and weights are documented in the updated figure below. 

#figure(
  caption: [Schematic of Water Balance Model Variables Used to Develop Gaged Runoff Estimate],
  image("figures/WaterBalanceModelModified.png", width: 100%),
)<fig-waterbalancemodified>


Within the model, weights were estimated for each 1 square kilometer grid cell.  For example, the Suwanee Creek gage (USGS Gage No 02334885) covers 112 cells.  Therefore, in the linear regression model  there are 112 weights, one for each grid cell at time t.  In the model that incorporates both time t and t-1, there are twice as many weights, 224.  As part of the process, the project evaluated three different methods to estimate the weights on each grid cell using the Machine Learning in Julia (MLJ) and MLJLinearModels packages. 

Linear Regressor.  The linear regressor applies the standard linear regression function by minimizing the difference between a weighted X matrix and Y. 
Ridge Regressor.  The ridge regressor applies a penalty term, $lambda$, to the square of the weights.  While we should expect a higher overall error when applying ridge regression because it adds an extra term to the error equation, it should result in more consistent and lower weights across the spatial domain.  While it will introduce more error, these weights are more likely to be the more physically realistic option.  
Lasso Regressor.  The lasso regressor similarly applies a penalty term but multiplies it singularly by the absolute value of the weight instead of the square of the weights. Lasso regression should result in more zeroed weights.  While in many cases this may not be physically representative of the watershed (that a location has zero impact on the overall downstream discharge), it could represent locations where there is a local reservoir that controls or regulates the flow so it does not impact the final gaged discharge.    
Similar to the other methods evaluated, the project looked at these approaches with two gages, Suwanee Creek at Suwanee (02334885) and the Chattahoochee River at Helen (02330450).  This will allow evaluation of both an urbanizing watershed and one with a very low level of development.  A summary of the R-Squared of the various scenarios with different time ranges, model, and lambdas is included in the tables below.   In these models the models were trained and tested across the full datasets.  Because in this case we trained over the full time period, there was no noticeable degradation of model results due to urbanization.  

#figure(
    caption: [Suwanee Creek at Suwanee (02334885) R-Squared for Various Model Scenarios],
    table(
  columns: 7,
  inset: 6pt,
  align: ((center+horizon,) * 7),

  table.header(
    [*Day Range*], [*0*], [*0-1*], [*0-2*], [*0-3*], [*0-4*], [*0-5*],
  ),

  [*Linear*],            [0.11], [0.48], [0.50], [0.51], [0.51],  [0.52],
  [*Ridge $lambda = 0.001$*], [0.11], [0.48], [0.49], [0.50], [0.51],  [0.51],
  [*Ridge $lambda = 0.01$*],  [0.11], [0.47], [0.48], [0.49], [0.49],  [0.50],
  [*Ridge $lambda = 0.1$*],   [0.11], [0.46], [0.47], [0.48], [0.48],  [0.48],
  [*Lasso $lambda = 0.001$*], [0.11], [0.47], [0.49], [0.49], [0.50], [0.50],
  [*Lasso $lambda = 0.01$*],  [0.10], [0.46], [0.47], [0.47], [0.47],  [0.47],
  [*Lasso $lambda = 0.1$*],   [0.08], [0.43], [0.44], [0.44], [0.44],  [0.44],
)
  ) <suwanee_r2_table>

#figure(
    caption: [Chattahoochee River at Helen (02330450) R-Squared for Various Model Scenarios],
    table(
  columns: 7,
  inset: 6pt,
  align: ((center+horizon,) * 7),

  table.header(
    [*Day Range*], [*0*], [*0-1*], [*0-2*], [*0-3*], [*0-4*], [*0-5*],
  ),

  [*Linear*],                 [0.16], [0.35], [0.40], [0.43], [0.45],  [0.47],
  [*Ridge $lambda = 0.001$*], [0.16], [0.35], [0.39], [0.43], [0.44],  [0.46],
  [*Ridge $lambda = 0.01$*],  [0.16], [0.34], [0.38], [0.41], [0.43],  [0.44],
  [*Ridge $lambda = 0.1$*],   [0.15], [0.33], [0.37], [0.40], [0.41],  [0.43],
  [*Lasso $lambda = 0.001$*], [0.16], [0.35], [0.39], [0.42], [0.43], [0.45],
  [*Lasso $lambda = 0.01$*],  [0.15], [0.33], [0.37], [0.39], [0.41],  [0.42],
  [*Lasso $lambda = 0.1$*],   [0.14], [0.31], [0.34], [0.37], [0.38],  [0.39],
)
  ) <chattahoochee_r2_table>

As expected, the linear regressor produced the highest r-squared value although none of the models produced consistently strong results.  In general, the model produced significantly better results once the second day (i.e. the water balance runoff from the day before) was added to the estimate.  There was typically minimal improvement in the model as more days were added beyond two days.  This was true for both gages.  It is expected that the length of time to include would change based on the watershed size as the overall travel time within the watershed will change.  In this case both gages have a similar watershed size and therefore produce similar results with respect to time.   

The weights were also evaluated spatially.  Below are some sample plots of the beta values for the linear regressor at Suwanee Creek.  In this example, weights for the flow at time t were developed across t through t-5 so the bottom right graph shows the weights used on the spatially estimated runoff at time t, then t-1, etc.  Each was then summed to estimate the final runoff at the gaged location. 

#figure(
  caption: [Example of Beta Weights for Suwanee Creek at Suwanee (02334885) for Linear Regressor with Time t through t-5
  ],
  image("figures/SampleBetaGrids.png", width: 100%),
)<fig-betasuwaneecreekd>

As shown in the above figures, stronger weights are in the southwest of the watershed, which is where the gage is located.  This logically makes sense as this location would have a more direct impact on the flow at the gage.  In addition, the higher weights occur on the spatially estimated runoff at day t-1, confirming the expected behavior that there is a delay between the rainfall and the runoff expected at the gage.  The other item of note from these figures is the known issue with a linear regressor in a spatial context: it produces strong swings between cells physically next to each other due to overfitting to the training data.   

The differences between the modeling results on specific rainfall events can also be evaluated by looking at the final runoff estimate over time between the various models, as shown in the figure below developed from predictions of a rainfall occurring during September 2009.   

#figure(
  caption: [Example of Sample Hydrographs for Suwanee Creek at Suwanee (02334885) for Linear Regressor with Time t through t-5
  ],
  image("figures/ModelResults_WaterBalance.png", width: 100%),
)<fig-samplehydrographs>

The figure documents several impacts of the modeling approach.  First, it confirms the concern that the pure water balance results were overestimating the runoff.  It also documents the value of incorporating the extra t values to better reflect runoff occurring after the initial rainfall event.  This is especially noticeable on September 19th, where the water balance model spikes, but the gage does not reflect the rainfall until the 20th. 

 Overall while adding the weights, specifically the weights on two or more days, improved the accuracy of the model in predicting flow, it still does not result in a well-calibrated model reflecting that additional work is needed to reflect the complicated hydrologic system upstream of a gage.   
 == Multiple Linear Regression Model with a Gabor Transform 
 == Multiple Linear Regression Model with Principal Component Analysis

The model was developed for the Suwanee Creek at Suwanee gage (USGS Gage No. 02334885). The dependent variable is daily runoff depth in millimeters (mm), calculated from daily mean discharge and the watershed drainage area. The record extends from January 3, 1985, to June 10, 2024, and contains 14,404 consecutive days with no missing values. 

For this model, four independent variables were used: (1) one-day precipitation, (2) two-day precipitation, (3) three-day precipitation, and (4) fractional impervious area. One-day precipitation represents watershed-average daily precipitation and was taken from the gridded water balance dataset. The two- and three-day precipitation show the sum of the current day's precipitation and the precipitation from one or two days prior. Meanwhile, the fractional impervious area is the mean fractional impervious area, taken from the land cover dataset.

A principal component analysis (PCA) was applied to transform the independent variables into uncorrelated components before fitting the regression. Every fourth year of the record (1988, 1992, and so on through 2024) was withheld for testing, and the model was trained on the remaining years. This resulted in 10,948 days of training data and 3,456 days of testing data. Withholding every third and fifth year of record was also tested to determine if this sampling methodology is sensitive to the interval chosen. However, this did not significantly improve the regression results, so the middle value was chosen. 

Whole years were withheld instead of random days, since streamflow has a more gradual daily change than a random fluctuation. Streamflow is highly dependent on precipitation and on the rate of drainage through the drainage network within the watershed, which causes flow from a single storm event to extend over several days. Randomly selecting a day may place data from the same storm event in both training and testing data and may cause the model to overperform. Each variable was then normalized to a mean of zero and a standard deviation of one using the normalization function from the lecture. 

The PCA was performed by applying a singular value decomposition to the normalized training data. The loadings of the resulting principal components, which indicate the contribution of each independent variable to each component, are summarized in the table below.

#figure(
  table(
    columns: (2fr, 1fr, 1fr, 1fr),
    align: (left, center, center, center),
    table.header([*Variable*], [*PC1*], [*PC2*], [*PC3*]),
    [One-day precipitation], [−0.55], [0.02], [−0.78],
    [Two-day precipitation], [−0.61], [0.02], [0.13],
    [Three-day precipitation], [−0.57], [0.01], [0.61],
    [Fractional impervious area], [−0.03], [−1.00], [−0.01],
  ),
  caption: [Principal component loadings for the Suwanee Creek watershed],
) <pca-loadings>

The loadings show how much each variable contributes to a component, where a value closer to 1 (or -1) indicates a large contribution and a value closer to 0 indicates a small contribution. The first principal component is weighted almost equally on the three precipitation variables and represents the overall amount of recent rainfall. The second component consists almost entirely of the fractional impervious area. The third component contrasts the one-day precipitation with the three-day precipitation and therefore represents the timing of the rainfall, that is, whether the rain fell on the same day or on the preceding days. Each component is a direction through the data, so its sign only indicates which way that direction points and is assigned arbitrarily by the PCA; therefore, this does not affect the results. 

Two models were then fitted to the training data by least squares for comparison. The first uses the four normalized independent variables directly, and the second uses the three retained principal components:

#v(0.6em)
#align(center)[
  #set par(justify: false)
  #set text(hyphenate: false)
  Runoff = β#sub[1] (One-day precipitation) + β#sub[2] (Two-day precipitation) + β#sub[3] (Three-day precipitation) + β#sub[4] (Fractional impervious area)
]
#v(0.6em)
#align(center)[
  Runoff = β#sub[1] (PC1) + β#sub[2] (PC2) + β#sub[3] (PC3)
]
#v(0.6em)

The coefficient of determination for each model, calculated for both the training and testing data, is summarized in the table below.

#figure(
  table(
    columns: (2fr, 1fr, 1fr),
    align: (left, center, center),
    table.header([*Model*], [*Daily $R^2$ (train)*], [*Daily $R^2$ (test)*]),
    [All four variables], [0.56], [0.59],
    [PCA, three components], [0.52], [0.53],
  ),
  caption: [Coefficients of determination for the Suwanee Creek regression models],
) <pca-r2>

#figure(
  image("figures/suwanee_regression_daily_all.png", width: 100%),
  caption: [Predicted vs. Observed Daily Runoff for Suwanee Creek using All Four Variables],
) <pca-daily-all>

#figure(
  image("figures/suwanee_regression_daily_pca.png", width: 100%),
  caption: [Predicted vs. Observed Daily Runoff for Suwanee Creek using Three Principal Components],
) <pca-daily-pca>

The $R^2$ values from the two models range from 0.52 to 0.59 for daily runoff. The values for the testing data are similar to those for the training data, which indicates that the models are not overfitted to the training years. This is consistent with the water balance regression described above, in which including the previous day produced the largest improvement in the model. In the PCA regression, the timing component (PC3) has the largest coefficient (0.58), followed by the rainfall amount component (PC1, −0.40), which confirms that the delay between rainfall and streamflow is the most important feature captured by the aggregated precipitation variables. 

The PCA regression has a slightly lower $R^2$ for daily runoff than the regression on all four variables (0.53 compared to 0.59 for the testing data), since it uses one fewer input variable. 

#figure(
  image("figures/suwanee_pca_sept2009.png", width: 100%),
  caption: [Observed and predicted daily runoff for Suwanee Creek during September 2009],
) <pca-sept2009>

The figure above compares observed and predicted daily runoff for the September 2009 storm, which is the same storm shown in the water balance regression section. This period falls within the training years, so the models are expected to perform well in predicting the data. The two models closely follow the smaller rises in runoff before and after the main storm. However, the observed runoff peaked at approximately 66 mm on September 21, whereas the predicted peaks were approximately 24 mm for the regression on all four variables and 21 mm for the PCA regression, and both occurred one day later.

Two limitations can be identified: (1) days with low runoff tend to be overpredicted for both models, and (2) days with the highest runoff are underpredicted, as shown by the points falling below the line at high observed runoff, by the points falling above the line at low observed runoff, and by the comparison for the September 2009 storm. Additionally, the coefficient of the fractional impervious area component (PC2) is close to zero (−0.03), which indicates that the linear model does not detect an effect of urbanization on daily runoff at Suwanee Creek, even though the fractional impervious area increased substantially over the period of record. A linear model can only add a fixed amount of runoff for a given level of imperviousness, whereas imperviousness is expected to increase the runoff produced by each unit of rainfall.

/*This project will predict and compare the impacts of climate change versus urbanization on surface runoff and stream flows using the datasets discussed above. Specifically, the project will use singular value decomposition (SVD) and principal component analysis (PCA) to understand the dominant variables determining runoff and stream flows, the degree to which they explain variations in flows (via the singular values), and the relative loadings of climate-related variables compared to urbanization-related variables. Each observation of the data matrix will contain the summarized variables for all watersheds at one point in time, with the total number of observations as a product of the temporal range and the (daily or annual) sample rate. Climate variables may include precipitation, temperature, and number of days with extreme temperatures or precipitation, and urbanization variables may include fractional impervious area and the SCS curve number.
Multivariate regression will also be used to analyze the strength and confidence of correlations between the climate and the urbanization metrics as independent variables and runoff or stream flow as the dependent variable. The regression optimization model will assume linear relationships for all variables except where theory, industry standards, or analysis results establish a clear nonlinear relationship, such as the relationship between CN and runoff in the SCS equation.
The above models will then be used to predict runoff under four cases: 
1.	historical land cover with historical climate (baseline)
2.	future land cover with historical climate
3.	historical land cover with projected RCP 4.5 and RCP 8.5 climate
4.	future land cover with projected RCP 4.5 and RCP 8.5 climate
Future land cover may be extrapolated from annual NLCD trends. Comparing these results with the future water balance projections will show the influence of urbanization versus climate on future runoff.

In comparing mean fractional impervious area and minimum temperature, it is seen that both variables increase over the temporal domain, as shown in Figure I-1, though not at a constant rate. Mean fractional impervious area appears to increase at a greater rate roughly until 2005, after which it slows substantially. Minimum temperature rises unevenly, with most of the increase showing up around 2004. Because both variables are net-increasing across the period as a whole there is cause to suspect they may confound each other. This is directly relevant to the project's central question of how much runoff change is attributable to climate versus land use. The differing shapes of the two trends, in particular the period after 2005, where impervious area plateaus while temperature continues to rise, may offer a means of distinguishing them. Methods to do so will be explored further.
*/