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
