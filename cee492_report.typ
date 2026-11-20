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
= Introduction <introduction>
Accurate runoff prediction underpins a wide variety of decisions made within civil infrastructure.  Typically, industry has developed specified solutions depending upon the question being asked.  For example, when determining where to locate buildings, regulations are based on estimating a peak annual flow recurrence interval.  This approach often requires complex statistical evaluations at a regional level of stationary gage datasets.  When evaluating sizing for raw water distribution systems, understanding mean daily flow and low flow statistics is more critical.  Or if determining when to close bridges or evacuate citizens, communities often rely on predictive gages that National Oceanic and Atmospheric Administration is constantly manually updating and modifying during flood events to calibrate to observed conditions.   

These approaches often rely upon a variety of hydrologic datasets and are either manually intensive, highly subjective, or reliant on stationary datasets that are difficult to obtain in urbanizing communities or increasingly complex to simulate under changing climate conditions.   

This project evaluated whether machine learning methods could be used to simplify the runoff prediction process and develop a model that can be used by civil engineers for a variety of uses.  The project evaluated the success of various machine learning approaches in two extremes: one watershed that experienced both significant urbanization as well as another watershed whose land use did not change during the time period.  Both watersheds were impacted by any change in climatic conditions during the study period.  

Our expectation was that urbanization would have the biggest impact on our ability to predict stream flow in the selected watershed in north-metro Atlanta.  This hypothesis was based on past research, which often focuses on land cover as a primary impact in runoff.   

For example, the USGS has developed peak flow regression equations at a regional level. These flows are used to develop development requirements, size bridges among a variety of other uses.   In Georgia, there are two primary current reports for estimating peak streamflow: one for urban streams @feaster2023 and another for rural streams @feaster2014.  Both reports determine an applicability boundary at an impervious area percentage of 10 (urban at an impervious percentage greater than 10% and rural if impervious area is less than 10%).   Although impervious area is a big factor in the resulting estimated peak flow, neither report specifically evaluates the impact of climate change (either temperature or precipitation) when estimating a predictive flow.  Instead, datasets are screened for nonstationarity using methods such as the Mann-Kendall approach.  Nonstationary datasets typically cannot be used when developing U.S. Geological Survey (USGS) regression equations. 

= Data Formats and Contents
To evaluate our hypothesis, we incorporated the following datasets.

== GridMET
 The primary climate dataset used was Climatology Lab's GridMET dataset@abatzoglou2013 @GridMETwebsite. GridMET is a 4-km gridded daily time series dataset from 1979 through the present for continental U.S. (CONUS). It blends the spatial detail of Parameter-elevation Regressions on Independent Slopes Model (PRISM) climate data with the daily timing of National Land Data Assimilation System Phase 2 (NLDAS-2) reanalysis. While the focus and calibration of the dataset is on climate variables such as precipitation and temperature, Climatology Lab also stores terrain data on a similar grid and spatial domain that can be used for modeling purposes. 
The GridMET data are available as Network Common Data Form (NetCDF) files, usually one file per variable per year, on a regular latitude–longitude grid in geographic coordinate system World Geodetic System 1984 (WGS84). The GridMET dataset spans the years 1979 to the present.

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
== Daily Historical Water Balance Dataset (Daily Water Balance)
 A previously-created dataset used as part of this project is a gridded daily historical water balance dataset covering the CONUS @Tercek2023. The dataset was originally developed under the National Park Service Inventory and Monitoring Program and the National Park Service Climate Change Response Program. Version 1.5, the version currently available through the National Aeronautics and Space Administration (NASA), provides daily historic data (1980–2024) on #link("https://search.earthdata.nasa.gov/search?q=C2674700048-LPCLOUD")[NASA's Earthdata database] or an #link("https://npwbanalres.s3.us-west-2.amazonaws.com/index.html")[Amazon S3 bucket]. @HistBalanceData

 The daily water balance data are available in the NetCDF format. NetCDF files contain variables distributed across common dimensions, and attributes of each variable, which allow a single file to store variables across both spatial and time dimensions.   

The data are gridded over the entire continental U.S. in 1 kilometer (km) cells, stored in daily time steps (`time` variable). This is projected in a Lambert Conformal Conic (LCC) projection, and each cell has an LCC `x` and `y` coordinate.  The degree latitude/longitude is also stored as variables across the `x`/`y` dimensions. 

Version 1.5 of the water balance dataset, used in this project, was developed from daily meteorological data from GridMET: daily minimum and maximum temperature, and daily precipitation. The model treats the soil as a "bucket" with a maximum capacity based on the Soil Survey Geographic Database (SSURGO) soil database Available Water Storage (AWS) parameter. Precipitation is classified as rain or snow based on temperature, adjusted for relative humidity @jennings2018. Potential evapotranspiration is calculated with the Oudin method, which uses temperature and latitude-based solar radiation @oudin2005. 

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

== SSURGO <ssurgo-intro>
Runoff is impacted not only by climate, but also by soil conditions. Data on soil properties across CONUS are available through the Natural Resources Conservation Service's (NRCS) Soil Survey Geographic Database (SSURGO).  While the dataset has been updated over the years, there is no time dimension to the data, unlike the other datasets discussed above.  The dataset categorizes areas spatially by soil type and provides tables detailing the properties of each soil type. The two primary variables used as part of this project are the Hydrologic Soil Group (HSG) and the AWS.  Together, they capture both the rate at which water enters the ground and the total volume the soil can retain before generating runoff.  HSG expresses the soil type as either A, B, C, or D, with A being the most permeable and D being the least permeable.  AWS expresses the amount of water that can be stored for use by plants up to a certain depth in the soil and stores the value in millimeters (mm), typically ranging between 0 and 250 mm.  SSURGO data are available in statewide datasets from the NRCS website @SSURGO. 

The SSURGO dataset, accessed as a statewide database for Georgia as part of this project, is available in two parts:
(1) a GeoTIFF file defining the soil type using a map unit key (`mukey`) for each grid cell, and 
(2) the tabular data describing the various soil properties for each `mukey`. Each table for the state of Georgia was included in a geopackage (gpkg) database file. For this project, the key table is the Map Unit Aggregated Attribute (`muaggatt`) table, which stores the hydrologic soil group per map unit (`hydgrpdcd`) and the AWS capacity (`aws150`). Both of these variables are used to calculate the infiltration capacity of the soil. 

The GeoTIFF used for this project was in a 10m resolution in the European Petroleum Survey Group (EPSG) projection number 5070, also known as the NAD83 / Conus Albers projection. 

== Annual National Land Cover Database Collection 1.2  (NLCD)
 While not utilized in the Daily Water Balance, the other major variable typically used when evaluating infiltration capacity is land use.  Land use data predicts infiltration capacity by identifying: (a) impervious surfaces, where no infiltration is possible, (b) barren land, which has moderate infiltration capacity, and (c) different types of vegetative cover, which have greater capacities to intercept and absorb rainfall. The USGS has classified land cover and surface change characteristics across CONUS by applying geospatial deep learning algorithms to the Landsat satellite imagery record @NLCDUserGuide. The resulting data are available in the Annual NLCD Collection 1.2 on an annual basis, beginning in 1985. The Land Cover Classification and Fractional Impervious Surface products in the dataset are used in this project. The data are available to view and download through multiple platforms, including the Multi-Resolution Land Characteristics (MRLC) Web Viewer @MRLCViewer.

The NLCD data are provided as Cloud-Optimized GeoTIFF (COG) files. Each GeoTIFF image corresponds to a year and a land cover variable. @nlcd-legend shows the legend for Land Cover values according to the Annual NLCD Collection 1 Science Product User Guide @NLCDUserGuide.

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
) <nlcd-legend>

The data values for Fractional Impervious Area range from 0-100, representing the percentage of a 30-meter pixel that is covered with impervious surfaces. 

== USGS Water Data for the Nation (USGS Gage Data)
While the Daily Water Balance dataset estimates runoff, it is critical to validate the model results against observed runoff.  Observed runoff can be estimated from stream gages.  The USGS collects and distributes stream gage data for gages across CONUS.  Each gage has a unique site number and varying period of record and data collected.  For this project, the daily mean discharge was incorporated as the best dataset to validate the Daily Water Balance runoff estimates.  The USGS maintains a website for each gage and users can obtain data directly through the website or other Application Programming Interfaces (APIs).  

For each gage, the USGS also maintains its spatial watershed boundary in GeoJSON format, which can be accessed through its API @USGSAPI.
The Water Data for the Nation dataset is a tabular time series, downloadable as CSV, tab-delimited text, or JSON. This can be obtained from the Water Data for the Nation website or programmatically with the USGS `dataretrieval` Python package. The dataset provides point data measured at one gage location as a daily time series, with many gages having records going back decades. 

Each gage has a site number and metadata including location and drainage area. Data are organized by parameter code: discharge is `00060`, in cubic feet per second, and daily mean values use statistic code `00003`. Each value carries a qualification code: `A` (approved, reviewed by USGS), `P` (provisional, may be revised), or `e` (estimated). Recent data are often still provisional, so we will only incorporate approved values. 

= Selecting a Study Area and Time Period <domain-selection>
Gwinnett County, GA was chosen as the focus area due to its rapid urbanization within the past several decades. For consistency and simplicity, all gridded variables were summarized by watershed for 15 gaged watersheds within Gwinnett County as shown in @locationmap.  Stream gage data was only evaluated for 14 of the 15 watersheds because there was limited data available during the time period considered with this project.
#figure(
  image("figures/LocationMap.png", width: 80%),
  caption: [Location of the 15 gaged watersheds evaluated in this report],
) <locationmap>
Aulenbach et al. @alenbauch evaluated the overall impact of urbanization on runoff within the original 15 watershed within  Gwinnett County, although they did not evaluate the impacts of a changing climate or changing impervious over time on runoff.  The paper focused on runoff statistics such as runoff-ratio and baseflow between the different watersheds.  It confirmed percent imperviousness impacted runoff statistics within the watersheds.

In addition, because of the intense urbanization in all of the Gwinnett Watersheds, a sixteenth watershed was selected nearby without urbanization over the study period.  The gage, Chattahoochee River at Helen, GA (USGS Gage 02330450) was selected as a control watershed to compare the results of the Gwinnett County watersheds to a watershed that has not been impacted by urbanization.  

Analyzing runoff and stream flow requires the precision of daily data. However, urbanization trends are best observed at annual or decadal intervals. Therefore, for each watershed and time period, the data was  summarized by the daily average, median, maximum, and minimum if available, and each statistical parameter was also estimated on an annual basis.

Although data span a variety of time periods, most of the data are only available between 1985 to 2024 for historical datasets.  Therefore this project will focus on this time period.  Most of the gage streamflow datasets do not begin until the mid-2000s, so the predictive modeling will focus on gages with a full record (02330450 and 02334885).

= Exploratory Data Analysis

== Runoff and Streamgage

The daily mean discharge data was obtained from USGS for 14 of the 15 streamgages in Gwinnett County, Georgia. The Wildcat Creek streamgage was excluded, since its recorded data (1953 – 1982) lies outside of the period scope of study (1985 -present) and the control watershed was not included. Streamgage data are the observed waterflow at the outlet of a watershed, normally given by the USGS as daily values.  

The raw data file for each streamgage from USGS contains the date, corresponding mean discharge in cubic feet per second (ft3/s), and a date-value qualification value. The qualification codes include A (approved for publication), e (value has been estimated), R (records were revised), and P (provisional data subject to revision). The compiled data disregarded the provisional data and only retained the approved data. The days without a discharge value were also disregarded. Additionally, years with incomplete data, either: (a) not having a complete year (year with less than 360 days of data), (b) having no data at all, were also disregarded. 

The daily discharge data was converted into runoff (mm/day) by dividing it by the drainage area of the watersheds. This will allow the streamgage data to be comparable to the gridded water balance and precipitation data. These were further converted into annual mean discharge, annual total runoff, and annual peak daily runoff by streamgage by year. The annual mean discharge is the average daily mean discharge value by year, annual total runoff is the sum of the daily runoff depths by year, and annual peak daily discharge is the largest recorded daily runoff depth in a year. 

Trendlines were fitted to the annual mean discharge values to determine if there is an increasing or decreasing trend for discharge per gage. The resulting trendlines are relatively flat, with low coefficient of determination (R²) values, ranging from 0.00 to 0.12. This means that yearly variability outweighs long-term changes based on observed discharge. However, the inconsistent availability of data among gage types for some watersheds (e.g., Yellow River near Snellville with a 16-year gap and other gages having complete records only from 2002), may limit the detection of long-term trends. This can be supported by seeing that Suwanee Creek, with continuous data from 1985 to 2023, showed one of the largest increases in annual mean discharge over time. Thus, the streamgage data should be interpreted with precipitation data to determine if the discharge has changed outside of wet or dry years.

#figure(
  caption: [Annual Mean Discharge for Available Streamgages],
  image("figures/gage_figures.png", width: 90%),
  placement: top,
  scope: "parent",
  )<annualdischarge>

Processing the stream average daily discharge (cfs)  into an average runoff amount per square mile per day per year  (mm/year) facilitates comparison to the water balance dataset.  The  gridded water balance daily dataset was also processed into an average value per day per year per watershed.  In comparing the two datasets, it is clear the gage data has significantly more variability between the gages than the water balance dataset as shown in @standard-deviation.  

#figure(
  caption: [Standard Deviation of Runoff across Watersheds],
  image("figures/stdev.png", width: 100%),
)<standard-deviation>

The water balance dataset incorporates the spatial variability of the rainfall as well as the variability in infiltration capacity of just the underlying soils but does not incorporate land use variability or other hydrologic factors such as storage ponds within the watershed.  So it is expected that the real-world data would exhibit more variability than the modeled data.  One notable difference is higher variability in the mid 2010s in the water balance datasets. This could indicate these years is one where there was more spatial variability in the rainfall datasets across the 15 watersheds. 

In addition to providing a comparison of data, it is important to have confidence that the datasets can be evaluated jointly as part of the predictive modeling.  In @annual-gage-vs-waterbalance, we compare the estimated annual daily runoff for gage 02207120 for both the gage data and the water balance data. 

#figure(
  caption: [Comparison of Annual Runoff, Stream Gage versus Water Balance],
  image("figures/AnnualGagevsWaterBalance.png", width: 100%),
) <annual-gage-vs-waterbalance>

From the figure it is clear they generally follow a similar underlying pattern suggesting the water balance dataset is reasonably estimating runoff.  This is a similar pattern that can be seen in the other watersheds evaluated.  

In addition to annual data, the project developed daily summaries for each of the watersheds.  In @daily-gage-vs-waterbalance, runoff is summarized for the same gage watershed.

#figure(
  caption: [Comparison of Daily Runoff, Stream Gage versus Water Balance],
  image("figures/DailyGagevsWaterBalance.png", width: 100%),
)<daily-gage-vs-waterbalance>

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

== Infiltration Capacity <infiltration-capacity>

For nearly all watersheds in Gwinnett County, the NLCD data shows a rapid increase in fractional impervious area between 1985 and the early 2000s, followed by a slower rate of growth after 2010 (see @fctimpgraph). Percentages of developed land cover follow a similar trend as fractional impervious area (see @medintdevgraph). This trend is mirrored by declines in deciduous forest land cover that fall sharply until the early 2000s and decline more gradually afterward (see @decforestgraph). These patterns indicate a surge in urbanization, including land development and deforestation, through the early 2000s and steady urbanization from the early 2000s to the present.

Rather than tracking all land cover classes over time, the Soil Conservation Service (SCS) Curve Number may be used to capture the totality of land use changes across all land use types and relate them to runoff and infiltration. According to NRCS' Technical Release 55 (TR-55) @tr55, runoff may be modeled as a function of precipitation and watershed characteristics using the SCS Curve Number method, which states:

$ Q &= frac(\(P-I_a\)^2, \(P-I_a\)+S) \
  I_a &= 0.2S \
  S &= frac(1000, "CN") - 10 $

where $Q$ is runoff, $P$ is rainfall, $S$ is potential maximum retention after runoff begins, $I_a$ is initial abstraction, with all units in inches. CN is the curve number, a dimensionless integer between 0 and 100 that represents the potential for rainfall to run off rather than infiltrate. Given the importance of the CN in modeling runoff, a raster of CN values was created in this project from the NLCD and SSURGO rasters. 

The U.S. Army Corps of Engineers (USACE) provides a lookup table for CN values based on NLCD land cover classes and HSG @USACEtable. The lookup table is shown in @cn_table.

#figure(
    caption: [Curve Number Lookup Table],
    table(
      columns: (20%,auto, 10%, 10%, 10%, 10%,),
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
  image("figures/land-cover/FctImp_meanByWatershed.png", width: 100%),
) <fctimpgraph>

#figure(
  caption: [Percentage of Medium Intensity Developed Land Cover by Watershed in Gwinnett County, GA],
  image("figures/land-cover/DevelopedMediumIntensity_percentByWatershed.png", width: 100%),
) <medintdevgraph>

#figure(
  caption: [Percentage of Deciduous Forest Land Cover by Watershed in Gwinnett County, GA],
  image("figures/land-cover/DeciduousForest_percentByWatershed.png", width: 100%),
) <decforestgraph>

#figure(
  caption: [Mean Curve Number by Watershed in Gwinnett County, GA],
  image("figures/land-cover/CN_meanByWatershed.png", width: 100%),
) <cngraph>

Likewise, heatmaps in @fig-fctimp reveal stark differences in fractional impervious area between 1985 and 2024, as well as the spatial distribution of urbanization.

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
 In addition to land use and impervious area, the other factor which determines infiltration capacity for an area is the soil type. The SSURGO data are the only input in determining the maximum potential storage of rainwater within the water balance dataset. It is derived from the AWS variable within the SSURGO dataset and estimates the amount of water that can be stored within the soil that is available to plants. While the maximum AWS used for the water balance dataset is not provided, in general it is possible to estimate the value used by taking the maximum value over time for each grid cell.  By visual comparison on a sample watershed for USGS gage 02207120, the datasets do generally align as shown in @soilwater-comparison.  In general, it appears the maximum soilwater value is higher than the value this project estimated from the SSURGO data.  Therefore we maximized the soilwater data instead of attempting to use the SSURGO data directly.  The differences between the two results are likely due do complications and assumptions made when converting the data between projections and cell sizes. 

#figure(
  caption: [SSURGO Available Water Storage (left), Daily Water Balance Maximum Soilwater (right)],
  image("figures/SSURGOvsSoilwater.png", width: 100%),
) <soilwater-comparison>
The Curve Number (CN) was used to quantify the increase in urbanization in Gwinnett County. The average CN per year per watershed (site location) was used to represent urbanization and was plotted against time with the average mean discharge for each watershed. While the CN is seen to increase over time, the average mean discharge is seen to be controlled by the wet and dry periods, indicated by the lack of visually increasing or decreasing trends over time.

 = Predictive Modeling 
 == Multiple Linear Regression with the Water Balance Spatial Dataset
 The water balance model is a physically based model that transforms the precipitation by first dividing it into rainfall and snowfall.  The runoff is then estimated as the available water that cannot be infiltrated or evapotranspirated as shown in @fig-waterbalance.

 #figure(
  caption: [Schematic of Water Balance Model Variables],
  image("figures/WaterBalanceProcess.png", width: 100%),
)<fig-waterbalance>
The infiltration/evapotranspiration is often simplified in hydrologic modeling by assuming a constant loss rate based on the type of soils.  The rates typically range between 0 and 0.45 in/hr or approximately 0 to 274 mm/day.  For the watersheds in this study, based on the HSG of the soils, the typical range to expect would be 30 to 180 mm/day during a rainfall event.  

Instead, in the water balance model, the maximum evapotranspiration in a day for any of the watersheds evaluated was approximately 6 mm/day and the maximum infiltration was 80 mm per day.  The mean infiltration on days with rain was approximately 3 mm/day, indicating that the water balance model typically underestimates soil storage and infiltration capacity compared with more typical hydrologic modeling approaches.   

Therefore, this project incorporated a combination of the water balance estimate of runoff with extra spatial weights to represent the extra infiltration and with a linear intercept which could be used to represent base flow.   

Another complication with using the water balance results to estimate streamflow at a gage is the travel time from the location within the watershed where the runoff occurs to the gaged location.  In traditional watershed modeling, this is modeled using a time of concentration or lag time to reflect the travel time for rainfall from the farthest part of the watershed to the downstream most point in the watershed and the rainfall hyetograph is translated by the time length. In this model, the travel time was reflected by estimating the gage discharge at time t by the runoff estimated by the modified water balance model at time t, t-1, t-2, etc. reflecting the overall translation of the spatially gridded runoff to the final gaged streamflow point.   

These additional variables and weights are documented in @fig-waterbalancemodified. 

#figure(
  caption: [Schematic of Water Balance Model Variables Used to Develop Gaged Runoff Estimate],
  image("figures/WaterBalanceModelModified.png", width: 100%),
)<fig-waterbalancemodified>


Within the model, weights were estimated for each 1 square kilometer grid cell.  For example, the Suwanee Creek gage (USGS Gage No 02334885) covers 112 cells.  Therefore, in the linear regression model  there are 112 weights, one for each grid cell at time t.  In the model that incorporates both time t and t-1, there are twice as many weights, 224.  As part of the process, the project evaluated three different methods to estimate the weights on each grid cell using the Machine Learning in Julia (MLJ) and MLJLinearModels packages: linear regressor, ridge regressor, and lasso regressor.
 
Similar to the other methods evaluated, the project looked at these approaches with two gages, Suwanee Creek at Suwanee (02334885) and the Chattahoochee River at Helen (02330450).  This will allow evaluation of both an urbanizing watershed and one with a very low level of development.  A summary of the R-Squared of the various scenarios with different time ranges, model, and lambdas is included in the tables below.   In these models the models were trained on data between October 1984 and September 2016 and tested across data between October 2016 and September 2024.  

#figure(
    caption: [Suwanee Creek at Suwanee (02334885) R-Squared for Various Model Scenarios Including Time t through t-5],
    table(
  columns: 7,
  inset: 6pt,
  align: ((center+horizon,) * 7),

  table.header(
    [*Day Range*], [*0*], [*0-1*], [*0-2*], [*0-3*], [*0-4*], [*0-5*],
  ),



  [*Linear*],            [-0.06], [0.28], [0.25], [0.22], [0.2], [0.19],
  [*Ridge $lambda = 0.001$*], [-0.024], [0.33], [0.33], [0.32], [0.32], [0.31],
  [*Ridge $lambda = 0.01$*],  [0.00065], [0.37], [0.37], [0.38], [0.38], [0.37],
  [*Ridge $lambda = 0.1$*],   [0.017], [0.4], [0.41], [0.41], [0.41], [0.41],
  [*Lasso $lambda = 0.001$*], [-0.014], [0.35], [0.35], [0.35], [0.35], [0.35],
  [*Lasso $lambda = 0.01$*],  [0.019], [0.4], [0.41], [0.41], [0.41], [0.41],
  [*Lasso $lambda = 0.1$*],   [0.017], [0.39], [0.4], [0.41], [0.41], [0.41],
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

  [*Linear*],                 [-0.21], [-0.22], [-0.48], [-0.61], [-0.89], [-1.1],
  [*Ridge $lambda = 0.001$*], [-0.029], [0.1], [0.067], [0.065], [0.056], [0.059],
  [*Ridge $lambda = 0.01$*],  [0.007], [0.16], [0.16], [0.17], [0.18], [0.18],
  [*Ridge $lambda = 0.1$*],   [0.018], [0.19], [0.22], [0.23], [0.24], [0.25],
  [*Lasso $lambda = 0.001$*], [-0.0055], [0.13], [0.12], [0.12], [0.13],[0.14],
  [*Lasso $lambda = 0.01$*],  [0.0088], [0.19], [0.22], [0.24], [0.25], [0.26],
  [*Lasso $lambda = 0.1$*],   [0.03], [0.2], [0.23], [0.24], [0.26], [0.27],
)

  ) <chattahoochee_r2_table>

None of the models produced consistently strong results.  In general, the model produced significantly better results once the second day (i.e. the water balance runoff from the day before) was added to the estimate.  There was typically minimal improvement in the model as more days were added beyond two days.  This was true for both gages.  It is expected that the length of time to include would change based on the watershed size as the overall travel time within the watershed will change.  In this case both gages have a similar watershed size and therefore produce similar results with respect to time. It was unexpected that the model would have more difficulty fitting the Chattahoochee River gage since the watershed did not experience any change in land use over the time period evaluated.  One potential explanation is that the Chattahoochee River gage is located in a more orographically extreme location.  Therefore the rainfall data, spatially downscaled from a 4 kilometer grid, may not be accurately reflecting the rainfall within the watershed.  

The weights were also evaluated spatially.  @fig-betasuwaneecreekd are some sample plots of the beta values for the ridge regressor at Suwanee Creek with a $lambda = 0.01$  In this example, weights for the flow at time t were developed across t through t-5 so the bottom right graph shows the weights used on the spatially estimated runoff at time t, then t-1, etc.  Each was then summed to estimate the final runoff at the gaged location. 

#figure(
  caption: [Example of Beta Weights for Suwanee Creek at Suwanee (02334885) for Ridge Regressor with Time t through t-5
  ],
  image("figures/SampleBetaGrids.png", width: 100%),
)<fig-betasuwaneecreekd>

Stronger weights are in the southwest which is where the gage is located.  This logically makes sense as this location would have a more direct impact on the flow at the gage.  In addition, the higher weights occur on the spatially estimated runoff at day t=0 and t-1, confirming the expected behavior that there is a delay between the rainfall and the runoff expected at the gage.  Compared with the linear regression results, the ridge regression generally produced lower weights and fewer adjacent extremes especially at the higher lambda values.  The ridge regression penalty term, lambda, penalizes large coefficients and would be expected to produce a more generalized result.  

The differences between the modeling results on specific rainfall events can also be evaluated by looking at the final runoff estimate over time between the various models, as shown in @fig-samplehydrographs developed from predictions of a rainfall occurring during September 2009.   

#figure(
  caption: [Example of Sample Hydrographs for Suwanee Creek at Suwanee (02334885) for Linear Regressor with Time t through t-5
  ],
  image("figures/ModelResults_WaterBalance.png", width: 100%),
)<fig-samplehydrographs>

The figure documents several impacts of the modeling approach.  First, it confirms the concern that the pure water balance results were overestimating the runoff.  It also documents the value of incorporating the extra t values to better reflect runoff occurring after the initial rainfall event.  This is especially noticeable on September 19th, where the water balance model spikes, but the gage does not reflect the rainfall until the 20th. 

 Overall while adding the weights, specifically the weights on two or more days, improved the accuracy of the model in predicting flow, it still does not result in a well-calibrated model reflecting that additional work is needed to reflect the complicated hydrologic system upstream of a gage.  

 == Multiple Linear Regression Model with a Gabor Transform
 As seen in @annualdischarge, stream flow is highly oscillatory. At the same time, it is cyclic, with visible seasonal fluctuations. Stream flow is the sum of base flow, which originates from groundwater seepage, and runoff, which is directly related to precipitation. Therefore, much of the variability in stream flow is due to the oscillatory and cyclic nature of precipitation. To reduce noise and focus on periodic flows, the stream flow, precipitation, and temperature data were transformed using a Gabor transform. This transform was applied only to the Suwanee Creek and the Chattahoochee River at Helen watersheds but may be generalized to other watersheds. 
 
 First, the stream flow, precipitation, and temperature variables were analyzed for their dominant frequencies. @normtimeseries shows time series plots of the normalized raw data for each watershed.  @powerspectra shows frequency-domain graphs of the three variables produced by a Fast Fourier Transform (FFT). Two-day precipitation represents each day's precipitation plus the previous day's precipitation to account for an observed 1-day lag between peak precipitation and peak stream flow.

 The frequency with the greatest amplitude for both stream flow and minimum temperature is 1 year#super[-1]. This aligns with the physical reality that precipitation and temperature are seasonal, or yearly periodic. While precipitation itself is more random, stream flow typically captures a smoother trend in precipitation-induced runoff due to the buffering effect of the stream's watershed. 

Then, a Gabor matrix was calculated for each variable. A relatively large standard deviation of 10 days (i.e. 10 samples) was used for the moving Gaussian window to favor frequency resolution over temporal resolution. For each matrix, the column representing amplitudes at a frequency of 1 year#super[-1] was extracted. This frequency column, referred to hereon as the Gabor-transformed data, tracks yearly periodic data over time. The Gabor-transformed data for each variable is depicted in @gaboramplitudes. 

In addition, fractional impervious area was selected as a variable that quantifies urbanization over time, in order to compare the effects of urbanization and climate variables on Gabor-transformed runoff. In @infiltration-capacity, CN was introduced as an aggregate metric of infiltration capacity in a watershed. A linear regression between the annual CNs and fractional impervious areas of all watersheds from 1985-2025 yields an R#super[2] of 0.93, indicating that CN and fractional impervious area are confounded and only one should be used in a regression model. Since calculating one CN value for a watershed involves more rounding error than calculating the mean fractional impervious area, the latter was selected and is shown in @gaboramplitudes. Note that fractional impervious area increases over time for both  watersheds, but its magnitude is negligible in Chattahoochee River at Helen compared to Suwanee Creek.

The Gabor-transformed variables, plus fractional impervious area, were passed into a multiple linear regression model of the form:

$ S_"Gabor" = a_0 + a_1 P_"Gabor" + a_2 T_"Gabor" + a_3 F $

Where $S_"Gabor"$ is Gabor-transformed streamflow, $P_"Gabor"$ is Gabor-transformed precipitation, $T_"Gabor"$ is Gabor-transformed temperature, $F$ is mean fractional impervious area, and $a_0$ through $a_3$ are constant coefficients.

=== Training on 80% of Data

For each watershed, 20% of the data was withheld for testing using a Xoshiro random number generator with a seed of 42 from the Random Julia package. The regression model was trained on the other 80% of the data, utilizing the GLM Julia package.

The models yielded the coefficients in @gabor-coeff-80. The linear models were then used to predict stream flow for the testing data, as shown in @gabor-predictions. Performance metrics are summarized in @gabor-error-80, where MAPE is Mean Absolute Percentage Error and RMSE is Root Mean Square Error.

#figure(
  caption: [Gabor Linear Model Coefficients, Trained on 80% of Data],
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto,),
    align: (center+horizon, center+horizon, center+horizon,),
    table.header(
      table.cell(rowspan:2)[*Variable*],
      table.cell(colspan:3)[*Suwanee Creek Watershed*],
      table.cell(colspan:3)[*Chattahoochee River at Helen Watershed*],
      [*Coeff.*], [*t-score*], [*Pr(>|t|)*],
      [*Coeff.*], [*t-score*], [*Pr(>|t|)*]),
    "Intercept", "8.761e-4", "17.48", "<1e-66",     "4.124e-3", "38.66", "<1e-99", 
      $P_"Gabor"$, "2.296e-1", "157.34", "<1e-99",   "2.192e-1", "94.79", "<1e-99",
      $T_"Gabor"$, "-4.594e-2", "-61.00", "<1e-99",  "-8.030e-2", "-43.98", "<1e-99",
      $F$, "3.834e-4", "21.07", "<1e-95",            "5.034e-4", "13.44", "<1e-40"
  ),
) <gabor-coeff-80>

#figure(
  caption: [Gabor Linear Model Metrics, Trained on 80% of Data],
  table(
    columns: (35mm, auto, auto,),
    align: (center+horizon, center+horizon, center+horizon,),
    table.header(
      table.cell()[*Variable*],
      table.cell[*Suwanee Creek Watershed*],
      table.cell[*Chattahoochee River at Helen Watershed*],),
    $R^2$, "0.72", "0.51",
    [MAPE on Training Data], "44.17%", "42.91%",
    "MAPE on Testing Data", "45.96%", "43.98%",
    [RMSE on Training Data], "1.946e-3","4.003e-3",
    "RMSE on Testing Data", "1.985e-3", "4.067e-3",
  ),
) <gabor-error-80>

=== Training on Pre-2010 Data

For each watershed, the linear model was also trained on data before 2010 and tested on data from 2010-2024, resulting in the coefficients in @gabor-coeff-2010 and performance metrics in @gabor-error-2010.

The models trained on pre-2010 data had greater error in predicting their testing data than in predicting the post-2010 training data, most likely due to greater extremes in weather and streamflow patterns in the pre-2010 years.

#pagebreak()
#figure(
  placement: top,
  scope: "parent",
  stack(
    dir: ttb,
    spacing: 0.8em,

    [#figure(
      grid(
        columns: (1fr, 1fr),
        gutter: 1em,
        image("figures/gabor-transform/Suwanee-Norm-Gage-Precip-Temp.png", width: 95%),
        image("figures/gabor-transform/Helen-Norm-Gage-Precip-Temp.png", width: 95%),
      ),
      caption: [Normalized Daily Data, Suwanee Creek Watershed (left) and Chattahoochee River at Helen Watershed (right)],
    )<normtimeseries>],

    [#figure(
      grid(
        columns: (1fr, 1fr),
        gutter: 1em,
        image("figures/gabor-transform/SuwaneePowerSpectra.png", width: 95%),
        image("figures/gabor-transform/HelenPowerSpectra.png", width: 95%),
      ),
      caption: [Frequency-Domain Graphs, Suwanee Creek Watershed (left) and Chattahoochee River at Helen Watershed (right)],
    )<powerspectra>],

    [#figure(
      grid(
        columns: (1fr, 1fr),
        gutter: 1em,
        image("figures/gabor-transform/SuwaneeGaborMatrixAnnualFreq.png", width: 95%),
        image("figures/gabor-transform/HelenGaborMatrixAnnualFreq.png", width: 95%),
      ),
      caption: [Amplitudes of Gabor-Transformed Data at 1 year#super[-1] Frequency and Fractional Impervious Area, Suwanee Creek Watershed (left) and Chattahoochee River at Helen Watershed (right)],
    )<gaboramplitudes>],
  )
)
#pagebreak()

#figure(
    caption: [Gabor Linear Model Coefficients, Trained on Pre-2010 Data],
    table(
      columns: (auto, auto, auto, auto, auto, auto, auto,),
      align: (center+horizon, center+horizon, center+horizon,),
      table.header(
        table.cell(rowspan:2)[*Variable*],
        table.cell(colspan:3)[*Suwanee Creek Watershed*],
      table.cell(colspan:3)[*Chattahoochee River at Helen Watershed*],
        [*Coeff.*], [*t-score*], [*Pr(>|t|)*],
        [*Coeff.*], [*t-score*], [*Pr(>|t|)*]),
      "Intercept", "9.202e-4", "14.81", "<1e-48",     "4.241e-3", "37.73", "<1e-99", 
       $P_"Gabor"$, "2.257e-1", "125.91", "<1e-99",   "2.046e-1", "84.11", "<1e-99",
       $T_"Gabor"$, "-4.309e-2", "-46.90", "<1e-99",  "-7.953e-2", "-41.63", "<1e-99",
       $F$, "4.099-4", "14.52", "<1e-46",             "1.134e-4", "2.29", "0.0219"
    ),
  ) <gabor-coeff-2010>

#figure(
    caption: [Gabor Linear Model Metrics, Trained on Pre-2010 Data],
    table(
      columns: (35mm, auto, auto, ),
      align: (center+horizon, center+horizon, center+horizon,),
      table.header(
        table.cell()[*Variable*],
        table.cell[*Suwanee Creek Watershed*],
        table.cell[*Chattahoochee River at Helen Watershed*],),
      $R^2$, "0.67", "0.50",
      [MAPE on Training Data], "52.07%", "42.91%",
      "MAPE on Testing Data", "30.98%", "38.94%",
      [RSME on Training Data], "2.098e-3","3.688e-3",
      "RSME on Testing Data", "1.682e-3", "4.646e-3",
    ),
  ) <gabor-error-2010>


#place(
  top + center,
  scope: "parent",
  float: true,
  clearance: 0.5em,
  stack(
    dir: ttb,
    spacing: 0.5em,

    [#figure(
      grid(
        columns: (1fr, 1fr),
        gutter: 1em,
        image("figures/gabor-transform/SuwaneeLMPrediction.png", width: 100%),
        image("figures/gabor-transform/HelenLMPrediction.png", width: 100%),
      ),
      caption: [Linear Model Predictions for Amplitude of Gabor-Transformed Stream Flow at 1 year#super[-1] Frequency, Tested on 20% of Data, Suwanee Creek Watershed (left) and Chattahoochee River at Helen Watershed (right)],
    )<gabor-predictions>],
  )
)

#place(
  top + center,
  scope: "parent",
  float: true,
  clearance: 1em,
  stack(
    dir: ttb,
    spacing: 1em,
    [#figure(
      grid(
        columns: (1fr, 1fr),
        gutter: 1em,
        image("figures/gabor-transform/SuwaneeLMPredictionPost2010.png", width: 100%),
        image("figures/gabor-transform/HelenLMPredictionPost2010.png", width: 100%),
      ),
      caption: [Linear Model Predictions for Amplitude of Gabor-Transformed Stream Flow at 1 year#super[-1] Frequency, Tested on 2010-2024 Data, Suwanee Creek Watershed (left) and Chattahoochee River at Helen Watershed (right)],
    )],
  )
)

== Multiple Linear Regression Model with Principal Component Analysis

The model was developed for the Suwanee Creek at Suwanee gage (USGS Gage No. 02334885) and the Chattahoochee River at Helen gage (USGS Gage No. 02330450). The dependent variable is daily runoff depth in millimeters (mm), calculated from daily mean discharge and the watershed drainage area. The record extends from January 3, 1985, to June 10, 2024, and contains 14,404 consecutive days with no missing values for both gages.

Four independent variables were used: (1) one-day precipitation, (2) two-day precipitation, (3) three-day precipitation, and (4) fractional impervious area. One-day precipitation represents watershed-average daily precipitation. These data were taken from the gridded water balance dataset for Suwanee Creek and from the GridMET dataset for Helen. The two- and three-day precipitation are the sum of the current day's precipitation and the precipitation from one or two days prior. The fractional impervious area is the annual mean fractional impervious area of the watershed, taken from the land cover dataset.

Every fourth year of the record (1988, 1992, and so on through 2024) was withheld for testing, which resulted in 10,948 days of training data and 3,456 days of testing data at each gage. Withholding every third year and every fifth year resulted in relatively similar regression results, so the four-year interval was retained. Whole years were withheld instead of random days, since flow from a single storm event extends over several days. The selection of random days may place data from the same storm event in both the training and testing data, and may cause the testing results to look better than they actually are. Each variable was standardized to a mean of zero and a standard deviation of one, separately for the training and testing data.

A principal component analysis (PCA) was performed by applying a singular value decomposition to the standardized training data. The loadings of the first three components are summarized in @pca-loadings.

#figure(
  placement: auto,
  scope: "parent",
  table(
    columns: (2.2fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, center, center, center, center, center, center),
    table.header(
      table.cell(rowspan: 2)[*Variable*],
      table.cell(colspan: 3)[*Suwanee Creek Watershed*],
      table.cell(colspan: 3)[*Chattahoochee River at Helen Watershed*],
      [*PC1*], [*PC2*], [*PC3*], [*PC1*], [*PC2*], [*PC3*]),
    [One-day precipitation], [−0.55], [−0.02], [0.78], [−0.55], [−0.02], [0.78],
    [Two-day precipitation], [−0.61], [−0.02], [−0.13], [−0.61], [−0.02], [−0.12],
    [Three-day precipitation], [−0.57], [−0.01], [−0.61], [−0.57], [−0.01], [−0.62],
    [Fractional impervious area], [−0.03], [1.00], [0.01], [−0.03], [1.00], [0.01],
  ),
  caption: [Principal Component Loadings],
) <pca-loadings>

A loading closer to 1 (or −1) indicates a larger contribution of a variable to a component, while a loading closer to 0 indicates a smaller contribution. The first component is weighted almost equally on the three precipitation variables and is interpreted as the overall amount of recent rainfall. The second component mostly consists of the fractional impervious area. Lastly, the third component consists mainly of one-day precipitation and three-day precipitation with opposite signs, which can be interpreted as the timing of the rainfall.

Two models were fitted to the training data of each gage using least squares. The four standardized independent variables are used in the first equation, while the three retained principal components are used in the second equation:

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

The coefficients of determination are summarized in @pca-r2 and the fitted coefficients in @pca-coeff. The variables were standardized in order for the coefficients to be comparable with one another.

#figure(
  placement: auto,
  table(
    columns: (1.5fr, 2.2fr, 1fr, 1fr),
    align: (left, left, center, center),
    table.header([*Gage*], [*Model*], [*$R^2$ (train)*], [*$R^2$ (test)*]),
    [Suwanee Creek], [All four variables], [0.56], [0.59],
    [Suwanee Creek], [PCA, three components], [0.52], [0.53],
    [Helen], [All four variables], [0.39], [0.43],
    [Helen], [PCA, three components], [0.39], [0.42],
  ),
  caption: [Coefficients of Determination for Daily Runoff, PCA Regression Models],
) <pca-r2>

#figure(
  placement: auto,
  table(
    columns: (2.2fr, 1fr, 1fr),
    align: (left, center, center),
    table.header([*Term*], [*Suwanee Creek*], [*Helen*]),
    table.cell(colspan: 3)[_Regression on all four variables_],
    [One-day precipitation], [−0.41], [−0.16],
    [Two-day precipitation], [0.77], [0.34],
    [Three-day precipitation], [0.26], [0.41],
    [Fractional impervious area], [0.04], [0.08],
    table.cell(colspan: 3)[_PCA regression_],
    [PC1 (rainfall amount)], [−0.40], [−0.36],
    [PC2 (fractional impervious area)], [0.03], [0.07],
    [PC3 (rainfall timing)], [−0.57], [−0.42],
  ),
  caption: [Regression Coefficients for the Standardized Variables and Principal Components],
) <pca-coeff>

The $R^2$ values range from 0.52 to 0.59 at Suwanee Creek and from 0.39 to 0.43 at Helen. The values for the testing data are similar to those for the training data, indicating that the models are not overfitted to the training years. The $R^2$ of the PCA regression is equal to or slightly lower than that of the regression on all four variables at both watersheds, since one fewer input variable is used.

In the regression on all four variables, the largest coefficient is from the two-day precipitation at Suwanee Creek and the three-day precipitation at Helen, which indicates that runoff responds to rainfall more slowly at Helen. In the PCA regression, the negative coefficient of PC3, together with its positive loading on one-day precipitation and negative loading on three-day precipitation, means that runoff is higher when the rain fell on the preceding days than when it fell on the same day. This is consistent with the water balance regression, in which the largest improvement was seen by including the previous day.

The coefficient of the fractional impervious area component (PC2) is 0.03 at Suwanee Creek and 0.07 at Helen. An effect of urbanization on daily runoff was therefore not detected at Suwanee Creek, even though the fractional impervious area increased substantially. Additionally, the coefficient is seen to be larger at Helen, where the fractional impervious area barely changed over time, so it cannot be attributed to urbanization. The lack of a detected effect may be due to the form of a linear model, in which a given level of imperviousness can only add a fixed amount of runoff, whereas imperviousness is expected to increase the runoff produced per unit of rainfall.

#figure(
  placement: auto,
  scope: "parent",
  grid(
    columns: (1fr, 1fr),
    gutter: 1em,
    image("figures/suwanee_regression_daily_all.png", width: 100%),
    image("figures/helen_regression_daily_all.png", width: 100%),
  ),
  caption: [Predicted vs. Observed Daily Runoff using All Four Variables, Suwanee Creek Watershed (left) and Chattahoochee River at Helen Watershed (right)],
) <pca-daily-all>

#figure(
  placement: auto,
  scope: "parent",
  grid(
    columns: (1fr, 1fr),
    gutter: 1em,
    image("figures/suwanee_regression_daily_pca.png", width: 100%),
    image("figures/helen_regression_daily_pca.png", width: 100%),
  ),
  caption: [Predicted vs. Observed Daily Runoff using Three Principal Components, Suwanee Creek Watershed (left) and Chattahoochee River at Helen Watershed (right)],
) <pca-daily-pca>

The observed and predicted daily runoff for the September 2009 storm are shown in @pca-sept2009. This is the same storm shown in the water balance regression section, and it falls within the training years. The observed runoff at Suwanee Creek peaked at approximately 66 mm on September 21, whereas the predicted peaks were approximately 24 mm for the regression on all four variables and 21 mm for the PCA regression, one day later. At Helen, the observed peak of approximately 21 mm on September 21 was predicted as approximately 18 mm on the same day, although the runoff in the days before the storm was overpredicted.

#figure(
  placement: auto,
  scope: "parent",
  grid(
    columns: (1fr, 1fr),
    gutter: 1em,
    image("figures/suwanee_pca_sept2009.png", width: 100%),
    image("figures/helen_pca_sept2009.png", width: 100%),
  ),
  caption: [Observed and Predicted Daily Runoff during September 2009, Suwanee Creek Watershed (left) and Chattahoochee River at Helen Watershed (right)],
) <pca-sept2009>

Two limitations can be identified: (1) days with low runoff tend to be overpredicted at both gages, and (2) days with the highest runoff are underpredicted, as shown by the points falling below the line at high observed runoff and above the line at low observed runoff in @pca-daily-all and @pca-daily-pca, and by the comparison for the September 2009 storm.

==  Decision Tree with Feature Selection and Cross Validation

Two basins were considered for this evaluation: Suwanee Creek (USGS 02334885) and the Chattahoochee River at Helen (USGS 02330450) in the state of Georgia. They are similar in size but differ in land cover and rainfall (@basin-char). Suwanee Creek basin urbanized rapidly from 1985 to 2023, with impervious cover rising from 5.6% to 30%. The Chattahoochee River at Helen basin stayed largely forested, with impervious cover below 1% throughout. Helen is also much wetter, receiving about 1,880 mm of rain a year compared to 1,360 mm/year at Suwanee. The annual rainfall in both basins (calculated as the average of pr_mean (mm/day) over all grid cells in each basin and aggregated annually) move closely together (correlation 0.88), as seen in @1dt_annual_rainfall_correlation.

#figure(
  table(
    columns: (2fr, 1fr, 1.5fr),
    align: (left, center, center),
    table.header([*Basin Characteristic*], [*Suwanee Creek*], [*Chattahoochee at Helen*]),
    [Drainage area (sq.mi.)], [47.1], [44.7],
    [Impervious cover % (1985-2023)], [5.6 to 30], [$<1$],
    [Annual mean rainfall (mm)], [1,360], [1,880],
  ),
  caption: [Selected Basin Characteristics],
) <basin-char>

#figure(
  image("figures/Figure1dt_annual_rainfall_correlation.png", width: 100%),
  caption: [Annual Rainfall of Suwanee and Chattahoochee River at Helen Basins (1985-2023)],
) <1dt_annual_rainfall_correlation>

=== Feature Selection 

Initial features explored for analysis included daily GridMET climate variables averaged over each basin:  

• precipitation ('pr_mean', 'pr_max', 'pr_min', 'pr_median')

• minimum and maximum temperature ('tmmn_mean', 'tmmx_mean') 

• solar radiation ('srad_mean') 

• vapor pressure deficit ('vpd_mean') 

• rainfall totals over the previous 2, 7 and 30 days ('rain_2day', 'rain_7day', 'rain_30day') 

• flags for more than 1 inch (25.4 mm) of rain on the day or over 2 days ('heavy_rain_daily', 'heavy_rain_2day') 

• the day of the year ('day_of_year') 

• annual fraction impervious ('impervious_pct')


Many of these features overlap, so Spearman correlations were plotted (@1dt_spearman_correlation) to remove the features most similar to each other.  

#figure(
  image("figures/Figure2dt_feature_correlation.png", width: 90%),
  caption: [Spearman Correlations between Initial Features for Feature Selection],
  placement: auto,
  scope: "parent",
) <1dt_spearman_correlation>

On reviewing the feature correlations, only nine features were selected for further analysis including pr_mean, rain_2day, rain_7day, rain_30day, tmmx_mean, srad_mean, vpd_mean, day_of_year and impervious_pct. Only pr_mean was kept due to high correlations with similar variables. A similar logic was used to keep only tmmx_mean. Features including flags for heavy rain were dropped because the decision tree will find its own cut points. 

=== Model Development

The DecisionTree Julia package was used to develop a decision tree for each basin. The data were separated into training (80%) and testing (20%) sets using a seeded random sample (seed 42) per basin.  

A separate decision tree was developed for each basin using the remaining features, with the target of predicting high-discharge events. Discharge (cfs) is calculated using gage depth (mm/day) and basin area (sq mm). High-discharge events are defined as days when discharge exceeds the 90th percentile of the training data. These thresholds were calculated independently for each watershed (129 cfs at Suwanee and 244 cfs at Helen) because rainfall and flow differ greatly between the two basins.  

A decision tree repeatedly splits the days into two groups using a yes/no question about one feature. Each split is chosen to make the groups as pure as possible, measured by the Gini index (Gini = 1 − Σ pₖ²). A Gini index of 0 means all days in the group are the same kind. Figure @3dt shows an example for ‘rain_2day’. At Suwanee, splitting at about ‘rain2day’ = 24 mm brings the weighted Gini index to about 0.12. At Chattahoochee at Helen, the best ‘rain_2day’ split brings its index to about 0.15.

The number of levels in the tree was decided based on the 5-fold cross-validated F1 score (described under Model Performance) for depths of 1 to 10 (@3dt). Suwanee scores almost as well with a single split (F1 = 0.62) as at its best depth (F1 = 0.63 at four levels), while Helen improves steadily up to about six levels. Four levels were chosen as a balance between the two basins.

The decision trees for Suwanee basin and Chattahoochee at Helen basin are shown in @4dt and @5dt respectively. The predictions for both basins depend mostly on the rain variables. ‘impervious_pct’ shows little to negligible predictive importance for both watersheds, as well as ‘tmmx_mean’, ‘srad_mean’, ‘vpd_mean’ and ‘pr_mean’. This is because land use change is available only on an annual basis, so daily changes in runoff cannot be explained. Additional examination of the impact of land use may include reviewing yearly runoff ratio (annual runoff depth divided by annual rainfall), analyzing stream flashiness, or looking at other basins.

#figure(
  placement: top,
  image("figures/Figure3dt_gini_split_and_tree_depth.png", width: 100%),
  caption: [(a) Weighted Gini Example and (b) Cross-Validated F1 by Maximum Tree Depth],
  scope: "parent",
) <3dt>

#figure(
  placement: auto,
  image("figures/Figure4dt_decision_tree_suwanee.png", width: 95%),
  caption: [Decision tree for Suwanee basin],
  scope: "parent"
) <4dt>

#figure(
  placement: auto,
  image("figures/Figure5dt_decision_tree_helen.png", width: 95%),
  caption: [Decision tree for Chattahoochee by Helen basin],
  scope: "parent"
) <5dt>

=== Model Performance

To evaluate how well the decision trees predict, four metrics were used: 

• Accuracy, which is the share of all test days predicted correctly. Because only 10% of days are high flow, always predicting "normal" already scores about 90% (the baseline), so accuracy isn’t the best metric to assess performance in this case. 

• Precision, which is ratio of true high flow days to the days predicted as high flow. Low precision indicates a lot of false negatives. 

• Recall, which is ratio of true high flow days to the days that are actually high flow. Low recall indicates a lot of missed events. 

• F1, which is a single score that balances precision and recall (calculated by their harmonic mean); it is high only when both are high. For this study, the F1 score is likely a better performance indicator than accuracy due to the relative rarity of high flow events. 

The performance metrics are listed below.
 
#figure(
  placement: auto,
  table(
    columns: (2fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, center, center, center, center),
    table.header([*Basin*], [*Accuracy*], [*Precision*], [*Recall*], [*F1*]),
    [Suwanee Creek], [92.8%], [71%], [57%], [0.63],
    [Chattahoochee at Helen], [92.9%], [66%], [47%], [0.55],
  ),
  caption: [Decision Tree Performance on Test Set],
  scope: "parent"
) <basin-characteristics>

The decision tree models do only moderately better than guessing. They give relatively few false alarms (71% and 66% precisions) but miss a large number of high flow days (57% and 47% recall), especially at Chattahoochee at Helen. The decision tree model does somewhat better on the Suwanee basin than on the Chattahoochee at Helen basin (0.63 vs 0.55 F1s). 

== Comparison of Modeling Approaches
Comparing the models, similar findings were found for the following: rainfall timing and time lag, effect of urbanization at the daily scale, and high-flow prediction.

The timing of the rainfall is found to be the most important predictor of streamflow. The water balance regression improved the most when the previous day was included; the Gabor transform regression used a two-day precipitation total to account for the one-day lag; the timing component had the largest coefficient in the PCA regression; and the decision trees depended mostly on the rainfall variables. Additionally, considering the runoff from the previous day(s) produced large improvements in the predictions. This is consistent with the observation that the runoff occurs approximately one day after the precipitation due to the time needed for the rainfall to reach the streamgages. 

The effect of urbanization on a daily scale is difficult to detect since land cover data change annually, while runoff data change daily. The coefficient of the fractional impervious area component in the PCA regression was close to zero, and the annual impervious cover data cannot explain daily runoff in the decision trees. However, the Gabor transform regression produced a small positive coefficient for fractional impervious area, due to the effect of impervious surfaces increasing runoff. 

Lastly, high flows are difficult to predict and are largely underpredicted. The water balance and PCA regressions underpredicted the highest runoff days, including the September 2009 storm, and the decision trees missed a large number of high-flow days. In contrast, the model that predicts the smoothed seasonal signal had the highest coefficient of determination, which indicates that the models perform better as the predicted quantity becomes less variable.

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