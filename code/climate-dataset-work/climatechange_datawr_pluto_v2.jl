### A Pluto.jl notebook ###
# v1.0.4

using Markdown
using InteractiveUtils

# ╔═╡ cd582571-0783-4cdf-a01b-f351d8b7b184
### A Pluto.jl notebook ###
# v0.20.0

using Markdown

# ╔═╡ c7cfa807-129f-4ea3-9142-618b97f772e8
using InteractiveUtils

# ╔═╡ fb727659-eb73-48c1-9307-5139bb732c26
using HTTP, JSON3, NCDatasets, DataFrames, CSV, Statistics, Dates

# ╔═╡ c0c86bff-f443-4ad3-b1dd-f182d6fba28f
#VSCODE-MARKDOWN
md"""
# GRIDMET Watershed Summaries

This notebook reads yearly GRIDMET Climate files and calculates **daily** and **yearly** statistics (max, min, mean and median) for 15 USGS watersheds in Gwinnett County, Georgia.

"""

# ╔═╡ 4d44f743-d88c-4820-bf04-3cfdbb25b28b
#VSCODE-MARKDOWN
md"""
### Step 0: Packages

"""

# ╔═╡ 4c5ba86e-4640-4e78-a37c-04afaeab3545
#VSCODE-MARKDOWN
md"""
### Step 1: Settings
"""

# ╔═╡ 7ae81455-4a62-442d-9e56-b2580af8d373
begin
    INPUT_DIR = "/Users/vasudhabhogineni/Documents/Documents/Continued Learning/UIUC Env Systems Cert 2026-27/UIUC CEE 492 Data Science/Course Project/Climate Change Data/GritMET_orig/NetCDF_GridMET_Orig"

    # @__DIR__ means the folder that contains this notebook.
    OUTPUT_DIR = @__DIR__

    GAGES = [
        "02205000",   # Wildcat Creek near Lawrenceville, Ga.
        "02205865",   # Sweetwater Creek at Club Drive near Lilburn, Ga.
        "02206500",   # Yellow River near Snellville, Ga.
        "02207120",   # Yellow River at Ga 124, near Lithonia, Ga.
        "02207185",   # No Business Creek at Lee Road
        "02207385",   # Big Haynes Creek at Lenora Road
        "02207400",   # Brushy Fork Creek at Beaver Road
        "02208150",   # Alcovy River at New Hope Road
        "02217274",   # Wheeler Creek at Bill Cheek Road
        "02218565",   # Apalachee River at Fence Road
        "02334480",   # Richland Creek at Suwanee Dam Road
        "02334578",   # Level Creek at Suwanee Dam Road
        "02334885",   # Suwanee Creek at Suwanee, Ga.
        "02335350",   # Crooked Creek near Norcross, Ga.
        "02336030",   # North Fork Peachtree Creek at Graves Rd
    ]

    # The five GRIDMET variables, in the order they appear in the output tables
    VARIABLES = ["pr", "tmmn", "tmmx", "srad", "vpd"]

    # The four statistics calculated for each variable
    STATS = ["max", "min", "mean", "median"]

    # How far (in degrees) to extend the box around the watersheds when cutting out the grid. This is used to correctly link GRIDMET grids to watershed polygons when no grid centroids are located in a polygon.
    BASIN_PAD = 0.05

    # If true (which is the case for this data), temperatures given in Kelvin are converted to degrees Celsius
    KELVIN_TO_C = true
end

# ╔═╡ ffea16a6-e5a3-4f9c-8080-8b0caf71d4e0
#VSCODE-MARKDOWN
md"""
### Step 2: Download the watershed boundaries

The USGS NLDI service returns each watershed as a **polygon**: a closed outline of points that goes around the edge of the watershed. Each point is stored as `[longitude, latitude]` to match `[x, y]`.

This notebook assumes every watershed is one polygon: a single outline with no gaps inside it and no separate pieces. If the download returns anything else, the notebook stops with an error.
"""

# ╔═╡ 3d7894c4-f6f6-47fd-860f-8d0a22f84432
# Convert the outline of one watershed into a list of (longitude, latitude) points.
# The download stores each point as [longitude, latitude] lists.
# Julia uses (longitude, latitude) tuples, so each point is converted here.
function parse_polygon(coordinates)
    points = Tuple{Float64,Float64}[]          # start with an empty list
    for point in coordinates
        longitude = Float64(point[1])
        latitude = Float64(point[2])
        push!(points, (longitude, latitude))   
    end
    return points
end

# ╔═╡ 94f8b1ad-8466-4a37-957e-bd2d4c78839f
# Download the watershed for one gage and return its polygon as a list of points.
function fetch_basin(gage)
    url = "https://api.water.usgs.gov/nldi/linked-data/nwissite/USGS-$(gage)/basin?f=json"
    response = HTTP.get(url)                             # send the request
    data = JSON3.read(String(response.body))             # read the text as JSON

    geometry = data.features[1].geometry
    if geometry.type != "Polygon"
        error("Expected a single Polygon for USGS-$gage, but got $(geometry.type)")
    end

    # The download wraps the outline in an extra list.
    # Item 1 of that list is the outline we want.
    outline = geometry.coordinates[1]
    return parse_polygon(outline)
end

# ╔═╡ 62d99be5-feef-4d23-944f-b01f343c7ead
#VSCODE-MARKDOWN
md"""
### Step 2b: Download all 15 watersheds and find the bounding box
"""

# ╔═╡ 70863e00-8cb5-444f-a844-fb44dde57211
begin
    # Download the watershed for every gage.
    # basins["02205000"] gives the polygon for that gage.
    basins = Dict(gage => fetch_basin(gage) for gage in GAGES)
    
    # Gather the points from all 15 watersheds into one list
    all_points = Tuple{Float64,Float64}[]
    for gage in GAGES
        append!(all_points, basins[gage])
    end
    
    # The smallest and largest longitude and latitude across all watersheds
    BBOX_LON = (minimum(first.(all_points)), maximum(first.(all_points)))
    BBOX_LAT = (minimum(last.(all_points)), maximum(last.(all_points)))
    
    bbox_text = "Bounding box of the $(length(GAGES)) watersheds (WGS84): " *
                "lon $(round(BBOX_LON[1], digits=5)) to $(round(BBOX_LON[2], digits=5)), " *
                "lat $(round(BBOX_LAT[1], digits=5)) to $(round(BBOX_LAT[2], digits=5))"
end

# ╔═╡ 1b0dcc9b-8bfc-41d8-b7b1-0a48abfdbec8
#VSCODE-MARKDOWN
md"""
### Step 3: Which grid cells are inside each watershed?

gridMET is a grid of small squares (about 4 km each). A square belongs to a watershed when its centre point is inside the watershed polygon.
"""

# ╔═╡ 79bf59da-feea-4172-a5c9-87cdad44c29c
# Is the point (x, y) inside the polygon?
# Method: draw a line from the point straight to the right.
# Count how many edges of the polygon that line crosses.
# An odd count means the point is inside.
function point_in_polygon(x, y, polygon)
    crossings = 0
    n = length(polygon)
    for i in 1:n
        # Each edge joins point j to point i, where point j is the point just before i.
        # For the first point, the point before it is the last point,
        # so the outline closes back on itself.
        j = i == 1 ? n : i - 1
        xi, yi = polygon[i]
        xj, yj = polygon[j]

        # Does this edge cross the height of the point point?
        crosses_height = (yi > y) != (yj > y)
        if crosses_height
            # Where does the edge cross that height, horizontally?
            x_of_crossing = (xj - xi) * (y - yi) / (yj - yi) + xi
            # Is the crossing to the right of the point?
            if x < x_of_crossing
                crossings += 1
            end
        end
    end
    return isodd(crossings)
end

# ╔═╡ 3b2b2cb7-8ff8-4fd6-ab9a-0dfc72a2de51
# For every gage, identify which grid cells belong to its watershed.
# Returns:
#   lon_range, lat_range : which columns and rows of the grid being checked
#   masks : for each gage, a table of true/false, one value per grid cell
#   methods : for each gage, how the grids were associated with it. Only for information, not output.
function watershed_masks(lon, lat)
    # Keep only the grid columns and rows inside the bounding box, plus a little padding
    lon_low = BBOX_LON[1] - BASIN_PAD
    lon_high = BBOX_LON[2] + BASIN_PAD
    lat_low = BBOX_LAT[1] - BASIN_PAD
    lat_high = BBOX_LAT[2] + BASIN_PAD

    lon_index = findall(value -> lon_low <= value <= lon_high, lon)
    lat_index = findall(value -> lat_low <= value <= lat_high, lat)
    lon_range = first(lon_index):last(lon_index)
    lat_range = first(lat_index):last(lat_index)
    lon_window = lon[lon_range]
    lat_window = lat[lat_range]

    masks = Dict{String,BitMatrix}()
    methods = Dict{String,String}()

    for gage in GAGES
        # mask[i, j] is true when grid cell (i, j) is inside this watershed
        mask = falses(length(lon_window), length(lat_window))
        for j in eachindex(lat_window), i in eachindex(lon_window)
            mask[i, j] = point_in_polygon(lon_window[i], lat_window[j], basins[gage])
        end

        if any(mask)
            methods[gage] = "cell_centres_inside"
        else
            # A very small watershed may have no grid centre inside it.
            # In that case, use the grid cell closest to the middle of the watershed.
            center_lon = mean(first.(basins[gage]))
            center_lat = mean(last.(basins[gage]))

            # Squared distance from the middle of the watershed to every grid cell
            distance_squared = [
                (lon_window[i] - center_lon)^2 + (lat_window[j] - center_lat)^2
                for i in eachindex(lon_window), j in eachindex(lat_window)
            ]
            nearest_cell = argmin(distance_squared)   # the position of the smallest distance
            mask[nearest_cell] = true
            methods[gage] = "nearest_to_centroid"
        end

        masks[gage] = mask
    end

    return lon_range, lat_range, masks #, methods
end

# ╔═╡ 2a661928-fe6b-4645-a647-37a8a9f210d7
#VSCODE-MARKDOWN
md"""
### Step 4: Summarize one file

Each gridMET file holds one variable for one year. This step calculates the max, min, mean and median of the grid cells inside a watershed for each day.
"""

# ╔═╡ 43b2afa8-c4ed-45f6-a586-127565213e3b
# Round a number to 4 decimal places, to keep the CSV files tidy
function round4(x)
    return round(x, digits=4)
end

# ╔═╡ 55854dea-ea04-470e-9318-7a7f29fa7872
# Summarize one gridMET file (one variable, one year) for every gage.
# Returns a table with one row per gage per day.
function summarize_file(path)
    file_name = basename(path)

    # Read the variable name from the file name, e.g. "tmmx_2020.nc" gives "tmmx"
    match_result = match(r"^(pr|tmmn|tmmx|srad|vpd)_(\d{4})\.nc$", file_name)
    if match_result === nothing
        error("Unexpected file name: $file_name")
    end
    variable = match_result.captures[1]

    dataset = NCDataset(path)
    try
        # Some files call the time axis "day" and others call it "time"
        time_name = haskey(dataset, "day") ? "day" : "time"
        lon = Float64.(dataset["lon"][:])
        lat = Float64.(dataset["lat"][:])
        dates = Date.(dataset[time_name][:])

        # Find the data variable: the one that has lon, lat and time dimensions
        data_name = ""
        for name in keys(dataset)
            dims = NCDatasets.dimnames(dataset[name])
            if length(dims) == 3 && "lon" in dims && "lat" in dims
                data_name = name
                break
            end
        end
        if data_name == ""
            error("No data variable found in $file_name")
        end

        data = dataset[data_name]
        dims = NCDatasets.dimnames(data)
        if !(dims[1] == "lon" && dims[2] == "lat")
            error("Unexpected dimension order in $file_name: $dims")
        end

        # The units tell us whether the values are in Kelvin
        units = try
            string(data.attrib["units"])
        catch
            ""
        end
        if units == "K" && KELVIN_TO_C
            offset = -273.15       # adding this converts Kelvin to Celsius
        else
            offset = 0.0           # no change
        end

        lon_range, lat_range, masks, _ = watershed_masks(lon, lat)

        rows = NamedTuple[]
        for (day_number, date) in enumerate(dates)
            # Read the grid cells for this one day.
            # Missing values come back as `missing`.
            day_block = data[lon_range, lat_range, day_number]

            for gage in GAGES
                # Keep only the values inside this watershed that are not missing
                cell_values = collect(skipmissing(day_block[masks[gage]])) .+ offset
                if isempty(cell_values)
                    continue
                end

                push!(rows, (date = date,
                             year = Dates.year(date),
                             variable = variable,
                             usgs_gage = parse(Int, gage),
                             daily_max = round4(maximum(cell_values)),
                             daily_min = round4(minimum(cell_values)),
                             daily_mean = round4(mean(cell_values)),
                             daily_median = round4(median(cell_values))))
            end
        end
        return DataFrame(rows)
    finally
        close(dataset)    # always close the file, even if something went wrong
    end
end

# ╔═╡ d8cc9078-691c-4783-b5ba-8a495e532af3
#VSCODE-MARKDOWN
md"""
### Step 5: Find the gridMET files

This step looks in the input folder for files named like `pr_2020.nc`, `tmmn_2020.nc`, and so on.
"""

# ╔═╡ 259d796b-6398-4e02-818f-8854518843a2
input_files = begin
    all_files = readdir(INPUT_DIR; join = true)
    matching = filter(f -> occursin(r"^(pr|tmmn|tmmx|srad|vpd)_\d{4}\.nc$", basename(f)), all_files)
    if isempty(matching)
        error("No pr, tmmn, tmmx, srad or vpd files found in $INPUT_DIR")
    end
    sort(matching)
end

# ╔═╡ 0d20eea4-9c5d-4a9e-b611-e451948c45e7
#VSCODE-MARKDOWN
md"""
### Step 6: Build the tables

The tables are built in two shapes:

* **Long shape:** one row for each variable, gage and day. This is easy to calculate with.
* **Wide shape:** one row for each gage and day, with four columns (max, min, mean, median) for each variable. This is the shape the CSV files use.

The helper below turns the long shape into the wide shape.
"""

# ╔═╡ ba8fca0a-5ba8-4e66-965c-8139d250d587
# Turn a long table into a wide table with one column per variable and statistic.
# Example column names: pr_max, pr_min, pr_mean, pr_median, tmmn_max, ...
#   long_table   : the long table to reshape
#   key_columns  : the columns that identify each row, e.g. [:date, :usgs_gage]
#   prefix       : the start of the statistic column names, "daily" or "annual"
function make_wide_table(long_table, key_columns, prefix)
    pieces = DataFrame[]

    # Make one small table for each statistic, with one column per variable
    for stat in STATS
        piece = unstack(long_table, key_columns, :variable, Symbol("$(prefix)_$(stat)"))
        for variable in VARIABLES
            if hasproperty(piece, Symbol(variable))
                rename!(piece, Symbol(variable) => Symbol("$(variable)_$(stat)"))
            end
        end
        push!(pieces, piece)
    end

    # Join the four small tables side by side, matching on the key columns
    joined = reduce((left, right) -> outerjoin(left, right, on = key_columns), pieces)

    # Put the columns in order: key columns first, then pr_max, pr_min, ... tmmn_max, ...
    ordered_names = [Symbol("$(variable)_$(stat)") for variable in VARIABLES for stat in STATS]
    return select(joined, vcat(key_columns, ordered_names))
end

# ╔═╡ 36e268a9-99da-44cf-be01-66e62dd8289b
#VSCODE-MARKDOWN
md"""
### Step 6b: Daily table

Summarize every file, then build the daily table. The last line shows the first five rows as a preview.
"""

# ╔═╡ 84029279-7844-4bb1-a430-43af68f1017d
begin
	# Long table: one row per variable, gage and day
	daily_long = reduce(vcat, [summarize_file(f) for f in input_files])
	sort!(daily_long, [:variable, :usgs_gage, :date])
	
	# Wide table: one row per gage and day
	daily = make_wide_table(daily_long, [:date, :usgs_gage], "daily")
	sort!(daily, [:date, :usgs_gage])
	
	first(daily, 5)     # preview the first five rows
end

# ╔═╡ 5fa737b8-25b7-499e-94cf-59fd1902df9b
#VSCODE-MARKDOWN
md"""
### Step 6c: Annual table

For each variable, gage and year, this step summarizes the daily values:

* **max** is the largest of the daily maximums
* **min** is the smallest of the daily minimums
* **mean** is the average of the daily means
* **median** is the median of the daily medians
"""

# ╔═╡ aefad77d-39b4-456a-9349-1627e1c9426a
begin
    # Long table: one row per variable, gage and year
    annual_long = combine(
        groupby(daily_long, [:variable, :usgs_gage, :year]),
        :daily_max => maximum => :annual_max,
        :daily_min => minimum => :annual_min,
        :daily_mean => mean => :annual_mean,
        :daily_median => median => :annual_median,
    )
    
    # Wide table: one row per gage and year
    annual = make_wide_table(annual_long, [:year, :usgs_gage], "annual")
    sort!(annual, [:year, :usgs_gage])
    
    first(annual, 5)    # preview the first five rows
end

# ╔═╡ d3b2ad01-73f3-4ed3-94f3-242f1499107a
#VSCODE-MARKDOWN
md"""
### Step 7: Save the CSV files
"""

# ╔═╡ 6d3fad81-51ec-4b36-91e3-d9bbfd4b97db
begin
	daily_path = joinpath(OUTPUT_DIR, "gridmet_watershed_daily.csv")
	annual_path = joinpath(OUTPUT_DIR, "gridmet_watershed_annual.csv")
	
	CSV.write(daily_path, daily; quotestrings = false)
	CSV.write(annual_path, annual; quotestrings = false)
	
	"$bbox_text. Wrote $(nrow(daily)) daily rows to $daily_path and $(nrow(annual)) annual rows to $annual_path"
	
	# Cell order:
	# ╠═9051d41b-40bb-412b-85b8-875405b35757
	# ╠═2cd8845b-2938-4d4e-bdaa-ea36861ed961
	# ╠═4b2b8eba-99fc-4d91-a30a-f4af4f18f524
	# ╠═fab3fb28-0e6f-4929-ad9b-230e89c23c0d
	# ╠═b5567e3c-c34d-4d09-849a-44fd029dbf8d
	# ╠═dee744ee-bed0-4a28-aa9f-9094b22e2492
	# ╠═7f654880-fa36-4acf-9ac6-b3a57926d21a
	# ╠═63fe5b5e-75a8-4ed6-9621-670663a37c47
	# ╠═acad991e-d53f-4fe5-bb25-6f65b1818c6d
	# ╠═608fc63c-5b14-42b6-a231-8e4ffa010605
	# ╠═6f342f93-2efd-4354-9eac-b3d8f1704e6a
	# ╠═6754a36e-1c2e-469e-bf90-c6ba66fa6a4a
	# ╠═1dee0c87-8de3-4408-bb4d-489a05f07b32
	# ╠═2abafe8a-61d5-43d9-adc4-18ac99f9d545
	# ╠═21aaa272-fefc-4fa2-9644-e02fd871285e
	# ╠═fea00a7c-7baa-4c83-8660-05f8641592de
	# ╠═acc9bed1-b2d1-401f-907e-d3da9a98eaae
	# ╠═9a1f3278-1035-42fa-bba9-221ffe666e63
	# ╠═9d1c60f4-6cf4-481c-be82-446b44f20a42
	# ╠═94250561-cdfc-4288-b747-60a20bee6eb2
	# ╠═5f1aaace-1998-46d0-8e76-51a30d0767dd
	# ╠═442b5722-61be-4dc6-bf9d-4ce1e1eb7df0
	# ╠═c5f3be66-b7ee-4364-93cc-889bade98bb3
	# ╠═d454bf2e-a74a-41c2-a63b-44e137652aad
	# ╠═0d05ec4a-509b-4684-b2e7-9f7300b777e8
	# ╠═964a3ecc-5cdb-46be-8607-d18069306792
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
InteractiveUtils = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
JSON3 = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
NCDatasets = "85f8d34a-cbdd-5861-8df4-14fed0d494ab"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
CSV = "~0.10.17"
DataFrames = "~1.8.2"
HTTP = "~2.11.0"
JSON3 = "~1.14.3"
NCDatasets = "~0.14.15"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.13.2"
manifest_format = "2.1"
project_hash = "1ad7b784ad18d90753b1fb068a11660d725c0af6"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.Blosc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Lz4_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "535c80f1c0847a4c967ea945fca21becc9de1522"
registries = "General"
uuid = "0b7ba130-8d10-5ba8-a3d6-c5182647fed9"
version = "1.21.7+0"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1b96ea4a01afe0ea4090c5c8039690672dd13f2e"
registries = "General"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.9+0"

[[deps.CFTime]]
deps = ["Dates", "Printf"]
git-tree-sha1 = "fad2f199d1f1ae0c8e820ab68f81f6dbf62e60b2"
registries = "General"
uuid = "179af706-886a-5703-950a-314cd64e0468"
version = "0.2.10"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "PrecompileTools", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "abed1e735dd4152f48c90cf0767e1790e25f332f"
registries = "General"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.17"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "970758a3d591a2a5c2a907c53f2e2f8c1b1d3537"
registries = "General"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.9"

[[deps.CommonDataModel]]
deps = ["CFTime", "DataStructures", "Dates", "DiskArrays", "Preferences", "Printf", "Statistics"]
git-tree-sha1 = "54d50f8a0a68ff4160564dfa09fc5de32465cfca"
registries = "General"
uuid = "1fbeeb36-5f17-413c-809b-666fb144f157"
version = "0.4.4"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "9d8a54ce4b17aa5bdce0ea5c34bc5e7c340d16ad"
registries = "General"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.18.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.5.5+2"

[[deps.ConstructionBase]]
git-tree-sha1 = "b4b092499347b18a015186eae3042f72267106cb"
registries = "General"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.6.0"

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.Crayons]]
git-tree-sha1 = "54b76cbb40d9a0f5368c880725b2f141da77c94f"
registries = "General"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.2.0"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
registries = "General"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "5fab31e2e01e70ad66e3e24c968c264d1cf166d6"
registries = "General"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.8.2"

[[deps.DataStructures]]
deps = ["OrderedCollections"]
git-tree-sha1 = "b0bc6d2cad1fed8b7fd59a1551a991cb3d2809e6"
registries = "General"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.19.6"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
registries = "General"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DiskArrays]]
deps = ["ConstructionBase", "LRUCache", "Mmap", "OffsetArrays"]
git-tree-sha1 = "49bd7d5b2c773a078b076f0d491c9c30b4715586"
registries = "General"
uuid = "3c3547ce-8d99-4f5e-a174-61eb10b00ae3"
version = "0.4.25"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.EnumX]]
git-tree-sha1 = "c49898e8438c828577f04b92fc9368c388ac783c"
registries = "General"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.7"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates"]
git-tree-sha1 = "3bab2c5aa25e7840a4b065805c0cdfc01f3068d2"
registries = "General"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.24"

    [deps.FilePathsBase.extensions]
    FilePathsBaseMmapExt = "Mmap"
    FilePathsBaseTestExt = "Test"

    [deps.FilePathsBase.weakdeps]
    Mmap = "a63ad114-7e13-5084-954f-fe012c677804"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.HDF5_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LibCURL_jll", "Libdl", "MPIABI_jll", "MPICH_jll", "MPIPreferences", "MPItrampoline_jll", "MicrosoftMPI_jll", "OpenMPI_jll", "OpenSSL_jll", "TOML", "Zlib_jll", "aws_c_s3_jll", "dlfcn_win32_jll", "libaec_jll", "mpif_jll"]
git-tree-sha1 = "58d79d3a61d2fdeda667fead57546ae22a20b27a"
registries = "General"
uuid = "0234f1f7-429e-5d53-9886-15a909be8d59"
version = "2.2.3+0"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "Dates", "EnumX", "Logging", "PrecompileTools", "Random", "Reseau", "SHA", "URIs", "UUIDs", "Zlib_jll"]
git-tree-sha1 = "58ad5af017e97735ce6eab23c72b7af1b1762555"
registries = "General"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "2.11.0"

[[deps.Hwloc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XML2_jll", "Xorg_libpciaccess_jll"]
git-tree-sha1 = "c35847ca5b4997fc8418836354a56c459bcf48d8"
registries = "General"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.14.0+0"

[[deps.InlineStrings]]
git-tree-sha1 = "06b65886c7577a3784d616e29f1302c2e36e389d"
registries = "General"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.6"

    [deps.InlineStrings.extensions]
    ArrowTypesExt = "ArrowTypes"
    ParsersExt = "Parsers"

    [deps.InlineStrings.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"
    Parsers = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.InvertedIndices]]
git-tree-sha1 = "6da3c4316095de0f5ee2ebd875df8721e7e0bdbe"
registries = "General"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.1"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
registries = "General"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7204148362dafe5fe6a273f855b8ccbe4df8173e"
registries = "General"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.8.0"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "PrecompileTools", "StructTypes", "UUIDs"]
git-tree-sha1 = "411eccfe8aba0814ffa0fdf4860913ed09c34975"
registries = "General"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.14.3"

    [deps.JSON3.extensions]
    JSON3ArrowExt = ["ArrowTypes"]

    [deps.JSON3.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.LRUCache]]
git-tree-sha1 = "5519b95a490ff5fe629c4a7aa3b3dfc9160498b3"
registries = "General"
uuid = "8ac3fa9e-de4c-5943-b1dc-09c6b5f20637"
version = "1.6.2"
weakdeps = ["Serialization"]

    [deps.LRUCache.extensions]
    SerializationExt = ["Serialization"]

[[deps.LaTeXStrings]]
git-tree-sha1 = "f88f3ccef05a6a72a0cf0ed417c8fd68530f4ab2"
registries = "General"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.1"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"
version = "1.11.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "1.0.0"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "Zlib_jll", "Zstd_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.22.0+0"

[[deps.LibGit2]]
deps = ["LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "PCRE2_jll", "Zlib_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.9.7+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl", "OpenSSL_jll", "Zlib_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.104+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
registries = "General"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.13.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.Lz4_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "191686b1ac1ea9c89fc52e996ad15d1d241d1e33"
registries = "General"
uuid = "5ced341a-0733-55b8-9ab6-a4889d929147"
version = "1.10.1+0"

[[deps.MPIABI_jll]]
deps = ["Artifacts", "Hwloc_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIPreferences", "TOML"]
git-tree-sha1 = "42e2cada9f35500b4d227106ce2b60e85d9f15bc"
registries = "General"
uuid = "b5ada748-db0f-5fc0-8972-9331c762740c"
version = "1.0.1+0"

[[deps.MPICH_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "Libdl", "MPIPreferences", "TOML"]
git-tree-sha1 = "08cb47f95a2f1b795e43a9e4f9783e68ecdc1ca6"
registries = "General"
uuid = "7cb0a576-ebde-5e09-9194-50597f1243b4"
version = "5.0.3+0"

[[deps.MPIPreferences]]
deps = ["Libdl", "Preferences"]
git-tree-sha1 = "8e98d5d80b87403c311fd51e8455d4546ba7a5f8"
registries = "General"
uuid = "3da0fdf6-3ccc-4f1b-acd9-58baa6c99267"
version = "0.1.12"

[[deps.MPItrampoline_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIPreferences", "TOML"]
git-tree-sha1 = "09a99227205419c00e734f413ee98c18bc1b02e4"
registries = "General"
uuid = "f1f71cc9-e9ae-5b93-9b94-4fe0e1ad3748"
version = "5.5.7+0"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MicrosoftMPI_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bc95bf4149bf535c09602e3acdf950d9b4376227"
registries = "General"
uuid = "9237b28f-5490-5468-be7b-bb81f5f5e6cf"
version = "10.1.4+3"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
registries = "General"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2026.8.13"

[[deps.NCDatasets]]
deps = ["CFTime", "CommonDataModel", "DataStructures", "Dates", "DiskArrays", "NetCDF_jll", "NetworkOptions", "Printf"]
git-tree-sha1 = "5eb7747d10437f5acb2675c1f865ffa0353f3f9c"
registries = "General"
uuid = "85f8d34a-cbdd-5861-8df4-14fed0d494ab"
version = "0.14.15"

    [deps.NCDatasets.extensions]
    NCDatasetsMPIExt = "MPI"

    [deps.NCDatasets.weakdeps]
    MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"

[[deps.NetCDF_jll]]
deps = ["Artifacts", "Blosc_jll", "Bzip2_jll", "HDF5_jll", "JLLWrappers", "LazyArtifacts", "LibCURL_jll", "Libdl", "MPIABI_jll", "MPICH_jll", "MPIPreferences", "MPItrampoline_jll", "MicrosoftMPI_jll", "OpenMPI_jll", "TOML", "XML2_jll", "Zlib_jll", "Zstd_jll", "libaec_jll", "libzip_jll"]
git-tree-sha1 = "bbd7ae15594503021b388a1090cca6ea431e0a8f"
registries = "General"
uuid = "7243133f-43d8-5620-bbf4-c2c921802cf3"
version = "401.1000.101+0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.OffsetArrays]]
git-tree-sha1 = "117432e406b5c023f665fa73dc26e79ec3630151"
registries = "General"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.17.0"

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

    [deps.OffsetArrays.weakdeps]
    Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.30+0"

[[deps.OpenMPI_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIPreferences", "TOML", "Zlib_jll"]
git-tree-sha1 = "0dba69ef957d790d41484ca7c20212c5ac806738"
registries = "General"
uuid = "fe0851c0-eecd-5654-98d4-656369965a5c"
version = "5.0.14+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.8+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "b079a6affebde167dad8ffe0d670b53917fbcb68"
registries = "General"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "2.0.3"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.46.0+0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "ba0dc8a8a67cacac4842631f960c046e4e563675"
registries = "General"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.8"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "Zstd_jll", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.13.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
registries = "General"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "edbeefc7a4889f528644251bdb5fc9ab5348bc2c"
registries = "General"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.3.4"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "aef1987d90dcc2e2cbd919ad10b2d25bcce4f418"
registries = "General"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.6.1"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "REPL", "Reexport", "StringManipulation", "StyledStrings", "Tables"]
git-tree-sha1 = "99fd8f32ab6728ff205cddd24e2d9ea6cbb498d3"
registries = "General"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "3.5.0"

    [deps.PrettyTables.extensions]
    PrettyTablesExcelExt = "XLSX"
    PrettyTablesTypstryExt = "Typstry"
    PrettyTablesWriteDocxExt = "WriteDocx"

    [deps.PrettyTables.weakdeps]
    Typstry = "f0ed7684-a786-439e-b1e3-3b82803b501e"
    WriteDocx = "d049ceea-54ee-41d7-a26f-ba29db3b6599"
    XLSX = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.REPL]]
deps = ["Base64", "Dates", "FileWatching", "InteractiveUtils", "JuliaSyntaxHighlighting", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
registries = "General"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Reseau]]
deps = ["NetworkOptions", "OpenSSL_jll", "PrecompileTools", "Random", "SHA"]
git-tree-sha1 = "3c8cb8ecab28eec47a02d56a44d4929b85fbab55"
registries = "General"
uuid = "802f3686-a58f-41ce-bb0c-3c43c75bba36"
version = "1.6.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "1.0.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "084c47c7c5ce5cfecefa0a98dff69eb3646b5a80"
registries = "General"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.10"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "13cd91cc9be159e3f4d95b857fa2aa383b53772a"
registries = "General"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.3"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "e2b53ce13a53367e96601081e33d34746b571bad"
registries = "General"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.5"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StringManipulation]]
deps = ["PrecompileTools", "StyledStrings"]
git-tree-sha1 = "9e3a02d73a8f0a9be04e677dbef758aab40f8bea"
registries = "General"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.6.1"

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "fd6a55e88450cb4256e49103a5a243f065c7b781"
registries = "General"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.11.1"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
registries = "General"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "a94d9bdda1b7bed0046cea645639ab3f62196fac"
registries = "General"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.14.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
registries = "General"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.URIs]]
deps = ["Serialization"]
git-tree-sha1 = "0392e5e3c5327b90a487b0ff3e818c4aecd3660b"
registries = "General"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.7.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "0716e01c3b40413de5dedbc9c5c69f27cddfddfc"
registries = "General"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.3"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
registries = "General"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "80d3930c6347cfce7ccf96bd3bafdf079d9c0390"
registries = "General"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.9+0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e52eca002a11c30a858185efdfb15311e1c7a6bf"
registries = "General"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.8.4+0"

[[deps.Xorg_libpciaccess_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "58972370b81423fc546c56a60ed1a009450177c3"
registries = "General"
uuid = "a65dc6b1-eb27-53a1-bb3e-dea574b5389e"
version = "0.19.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.3.2+0"

[[deps.Zstd_jll]]
deps = ["CompilerSupportLibraries_jll", "Libdl"]
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.7+1"

[[deps.aws_c_auth_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_cal_jll", "aws_c_http_jll", "aws_c_sdkutils_jll"]
git-tree-sha1 = "8cab83c96af80a1be968251ce1a0548a7545484d"
registries = "General"
uuid = "2b3700d1-4306-52e2-a478-c162f0c514be"
version = "0.9.6+0"

[[deps.aws_c_cal_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_common_jll"]
git-tree-sha1 = "22c0f42f4a1f0dc5dcfa8fd267c4ac407c455e7a"
registries = "General"
uuid = "70f11efc-bab2-57f1-b0f3-22aad4e67c4b"
version = "0.9.13+0"

[[deps.aws_c_common_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a759cb9bf456ad792cc7898a81ae333cce9ef02a"
registries = "General"
uuid = "73048d1d-b8c4-5092-a58d-866c5e8d1e50"
version = "0.12.6+0"

[[deps.aws_c_compression_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_common_jll"]
git-tree-sha1 = "7910c72f45f44afd297c39fe43b99c56d5ed22ec"
registries = "General"
uuid = "73a04cd5-f3d7-5bac-9290-e8adb709f224"
version = "0.3.2+0"

[[deps.aws_c_http_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_compression_jll", "aws_c_io_jll"]
git-tree-sha1 = "3fb8685778068de502c72fec5dd8075e037cee15"
registries = "General"
uuid = "3254fc65-9028-534d-aa9d-d76d128babc6"
version = "0.10.15+0"

[[deps.aws_c_io_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_cal_jll", "aws_c_common_jll", "s2n_tls_jll"]
git-tree-sha1 = "7e481d474b2087ee8bbf55b81bf9119f21e396d9"
registries = "General"
uuid = "13c41daa-f319-5298-b5eb-5754e0170d52"
version = "0.26.3+0"

[[deps.aws_c_s3_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_auth_jll", "aws_c_common_jll", "aws_c_http_jll", "aws_checksums_jll", "s2n_tls_jll"]
git-tree-sha1 = "3e9917ab25114feba657e71be41cad068b9f6595"
registries = "General"
uuid = "bd1f34fb-993f-5903-a121-aaf302eed6d4"
version = "0.11.5+0"

[[deps.aws_c_sdkutils_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_common_jll"]
git-tree-sha1 = "c43dfba2c1ab9ea9f02f2c80e86fa16f6460244e"
registries = "General"
uuid = "1282aa60-004d-510b-9f52-12498d409daa"
version = "0.2.4+1"

[[deps.aws_checksums_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_common_jll"]
git-tree-sha1 = "2570c8e23f4771a087b12a47edcaaa670ac05a01"
registries = "General"
uuid = "b2a88e68-78e7-5e94-8c20-c02986ec140e"
version = "0.2.10+0"

[[deps.dlfcn_win32_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e141d67ffe550eadfb5af1bdbdaf138031e4805f"
registries = "General"
uuid = "c4b69c83-5512-53e3-94e6-de98773c479f"
version = "1.4.2+0"

[[deps.libaec_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "60f4792734488db6f42e2c7699f1d4594780bd03"
registries = "General"
uuid = "477f73a3-ac25-53e9-8cc3-50b2fa2566f0"
version = "1.1.7+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.libzip_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "OpenSSL_jll", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "363a1c43b8cb92e7b3ff7f504ef9a0a83c548e97"
registries = "General"
uuid = "337d8026-41b4-5cde-a456-74a10e5b31d1"
version = "1.11.4+0"

[[deps.mpif_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIABI_jll", "MPICH_jll", "MPIPreferences", "MPItrampoline_jll", "MicrosoftMPI_jll", "OpenMPI_jll", "TOML"]
git-tree-sha1 = "a06fcd368cfe6fe2c0eb7b63320d4d27ddcd010d"
registries = "General"
uuid = "9aeb927a-4695-514f-a259-621a69f20ec0"
version = "1.0.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.70.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.8.3+0"

[[deps.s2n_tls_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d6cfe0874f96962fe4b20ed8bdb71c467e09c2c6"
registries = "General"
uuid = "cddc5d3d-934d-5d3a-9747-62fc12ea3f48"
version = "1.7.11+0"

[registries.General]
url = "https://github.com/JuliaRegistries/General.git"
uuid = "23338594-aafe-5451-b93e-139f81909106"
"""

# ╔═╡ Cell order:
# ╠═cd582571-0783-4cdf-a01b-f351d8b7b184
# ╠═c7cfa807-129f-4ea3-9142-618b97f772e8
# ╠═c0c86bff-f443-4ad3-b1dd-f182d6fba28f
# ╟─4d44f743-d88c-4820-bf04-3cfdbb25b28b
# ╠═fb727659-eb73-48c1-9307-5139bb732c26
# ╠═4c5ba86e-4640-4e78-a37c-04afaeab3545
# ╠═7ae81455-4a62-442d-9e56-b2580af8d373
# ╟─ffea16a6-e5a3-4f9c-8080-8b0caf71d4e0
# ╠═3d7894c4-f6f6-47fd-860f-8d0a22f84432
# ╠═94f8b1ad-8466-4a37-957e-bd2d4c78839f
# ╠═62d99be5-feef-4d23-944f-b01f343c7ead
# ╠═70863e00-8cb5-444f-a844-fb44dde57211
# ╠═1b0dcc9b-8bfc-41d8-b7b1-0a48abfdbec8
# ╠═79bf59da-feea-4172-a5c9-87cdad44c29c
# ╠═3b2b2cb7-8ff8-4fd6-ab9a-0dfc72a2de51
# ╠═2a661928-fe6b-4645-a647-37a8a9f210d7
# ╠═43b2afa8-c4ed-45f6-a586-127565213e3b
# ╠═55854dea-ea04-470e-9318-7a7f29fa7872
# ╠═d8cc9078-691c-4783-b5ba-8a495e532af3
# ╠═259d796b-6398-4e02-818f-8854518843a2
# ╠═0d20eea4-9c5d-4a9e-b611-e451948c45e7
# ╠═ba8fca0a-5ba8-4e66-965c-8139d250d587
# ╠═36e268a9-99da-44cf-be01-66e62dd8289b
# ╠═84029279-7844-4bb1-a430-43af68f1017d
# ╠═5fa737b8-25b7-499e-94cf-59fd1902df9b
# ╠═aefad77d-39b4-456a-9349-1627e1c9426a
# ╠═d3b2ad01-73f3-4ed3-94f3-242f1499107a
# ╠═6d3fad81-51ec-4b36-91e3-d9bbfd4b97db
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
