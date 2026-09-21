#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Analysis of Daily Historical Water Balance Products for the Continental US],
  abstract: [
    This is where you put your abstract. Abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract abstract.
  ],
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

= Background

This project will evaluate a gridded water balance dataset originally developed using funding by the National Park Service Inventory and Monitoring Program and the National Park Service Climate Change Response Program. Version 1.5, which is the version currently available online, was developed from daily meteorological data available from GridMET (#link("http://thredds.northwestknowledge.net:8080/thredds/reacch_climate_MET_catalog.html")).  

Inputs:
-Daily minimum and maximum temperature (from GridMET)
-Daily precipitation (from GridMET)

Output: 
-Daily rainwater (rain) in mmper 1km square grid cell.  This is a daily value.
-Accumulated snow water equivalent(accumswe).  Any precip not captured as rain is accumulated in this variable in units of mm per 1 km square grid cell until temperature results in the snow melting. The decision on whether precipitation is rain or snow is based on the temperature data (maybe add more details here).  This an accumulated value over time.
-The amount of water in the soil (soilwater).  The model treats the soil as a "bucket" and assumes a maximum capacitybased on the SSURGO soil database.  This is the amount, in mm, in the bucket at a specific time. Water is added from the rain variable and removed by evaporation and transpiration (the AET variable discussed below).  This value is accumulated over time.
-The amount of rainwater that is cannot be captured in the soil bucket and is therefore lost as runoff (runoff). This variable like the others is captured in mm per 1 km square grid cell.  Similar to rainfall, this is a daily value and there is no accumulation of this variable over time
-Potential evaporation and transpiration (pet).  This is the maximum amount of evaporation and transpiration that would occur if soilwater variable was unlimited.  This variable is driven by temperature, wind, solar radiation and cloudiness and a variety of other factors affect PET (would be good to add more details on this one).  Captured in mm per 1 km square per day.  This is a daily value.
-Actual evaporation and transpiration (aet). Actual evaporation and transpiration is the amount of water that is actually removed from the soilwater bucket and is the minimum of the pet and soilwater variables.  Captured in mm per 1 km square per day.  This is a daily value. 
- Deficit (deficit).  This is the difference between the pet and aet variables and is captured in mm per 1 km square per day.  So if the vegetation and climatic parameters could support more evaporation and transpiration, this would be greater than zero.  Otherwise the value is 0.  Captured in mm per 1 km square per day. This is a daily value.

All of the data is stored in daily time steps in the time variable.  The data is projected into a lambert conformal conic (lcc) projection (similar to the daymet data) and each cell has a lcc  x and y as well as a lat and lon variable. The dataset is gridded over the entire continental US. 


Note many references cite a thredds server for the water balance data, however that server is no longer valid.  

== Historic Water Balance Data (1980-2024)
 Version 1.5 of the Daily Historic Data (1980-2024) on NASA's Earthdata Database #link("https://search.earthdata.nasa.gov/search?q=C2674700048-LPCLOUD") or an Amazon S3 bucket #link("https://npwbanalres.s3.us-west-2.amazonaws.com/index.html")

== Future Conditions (2040-2069 and 2070-2099)
  Future conditions are availalble in 30-year averages (2040-2069 and 2070-2099for both RCP 4.5 and RCP 8.5 scenarios) from #link("https://screenedcleanedsummaries.s3.us-west-2.amazonaws.com/index.html").  Results from an assortment of climate models are available in this future conditions folder under both emissions scenarios. 
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
