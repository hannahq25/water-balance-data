### A Pluto.jl notebook ###
# v0.20.0

using Markdown
using InteractiveUtils

# ╔═╡ d1feafff-c32b-455e-b777-222e2ad0eff8
#VSCODE-MARKDOWN
md"""
# Land Cover Data Wrangling

This code will:

* Take a list of USGS Gage Numbers and for each gage pull the watershed

* Take a given folder with NLCD land cover and fractional impervious area TIFF files, crop them, and summarize data by watershed
"""

# ╔═╡ c9c3235d-ece2-4fbe-9621-2a454eaa8685
#VSCODE-MARKDOWN
md"""
### 1.0 Get Bounding Box from OpenStreetMap
"""

# ╔═╡ 200dcd95-aea7-434c-876e-9d631c019343
using HTTP, Proj, GeoInterface, PlutoUI, HypertextLiteral

# ╔═╡ 97c7b647-bd18-4122-86fd-9999beb565ea
begin
import GeoJSON
using GeoJSON
end

# ╔═╡ 5cfeddb3-6382-44d7-8a6a-c3e58cccf720
USGS_Gages = ["02205000", #Wildcat Creek near Lawrenceville, Ga. (1.29 SQMI)
			"02205865", #Sweetwater Creek at Club Drive near Lilburn, Ga. (20.98)
			"02206500", #Yellow River near Snellville, Ga. (136.06)
			"02207120", #Yellow River at Ga 124, near Lithonia, Ga. (161.41)
			"02207185", #No Business Creek at Lee Road (10.06)
			"02207385", #Big Haynes Creek at Lenora Road, (17.26)
			"02207400", #Brushy Fork Creek at Beaver Road (8.18)
			"02208150", #"Alcovy River at New Hope Road (30.8)
			"02217274", #Wheeler Creek at Bill Cheek Road (1.31)
			"02218565", #Apalachee River at Fence Road (5.65)
			"02334480", #Richland Creek at Suwanee Dam Road (9.37)
			"02334578", #Level Creek at Suwanee Dam Road (5.06)
			"02334885", #Suwanee Creek at Suwanee, Ga. (47.09)
			"02335350", #Crooked Creek near Norcross, Ga. (8.87)
			"02336030"] #North Fork Peachtree Creek at Graves Rd (1.53)

# ╔═╡ 50240bdf-d969-4fee-944c-56e5c923a5dd
#Define Info about Input Files
begin
x = "x"
y = "y"
stp = 30 #cell size of input netcdf
    
nlcd_wkt= """
    PROJCS["AEA        WGS84",
    GEOGCS["WGS 84",
    DATUM["WGS_1984",
    SPHEROID["WGS 84",6378137,298.257223563, AUTHORITY["EPSG","7030"]], AUTHORITY["EPSG","6326"]],
    PRIMEM["Greenwich",0],
    UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]],
    PROJECTION["Albers_Conic_Equal_Area"],
    PARAMETER["latitude_of_center",23],
    PARAMETER["longitude_of_center",-96],
    PARAMETER["standard_parallel_1",29.5],
    PARAMETER["standard_parallel_2",45.5],
    PARAMETER["false_easting",0],PARAMETER["false_northing",0],
    UNIT["metre",1,AUTHORITY["EPSG","9001"]],
    AXIS["Easting",EAST],
    AXIS["Northing",NORTH]]
    """
nlcd_crs = WellKnownText(GeoFormatTypes.CRS(), nlcd_wkt)

#converts from wgs to the input files projection
wgs_2_nlcdproj = Proj.Transformation("EPSG:4326", nlcd_wkt, always_xy=true) 
end

# ╔═╡ 0430f618-31f9-4272-b5f5-6db55be469ac
function pull_watershed(gage_no::String)
    #sleep(1.0)
    url = "https://api.water.usgs.gov/nldi/linked-data/nwissite/USGS-"*
        gage_no*
        "/basin?f=json"
    res = HTTP.get(url)
#    data = JSON3.read(res.body)    
    return res.body#(lat = parse(Float64, data[1].lat), lon = parse(Float64, data[1].lon))
end

# ╔═╡ a978e8b0-cbcc-4c9f-aeb4-7d4f8cdb6055
#get watersheds, also want to track the max and min values so we know what to clip with
begin
	#start with bounding box of entire water balance dataset
	ext = Extent(x=(0, 0), y=(0, 0))
	#min_x, max_x, min_y, max_y = -2.06025f6, 2.63875f6, -1.915f6, 1.384f6
	gage_basins = Dict{}()
	for g in USGS_Gages
		g_geom = GeoJSON.read(pull_watershed(g)).features[1].geometry[1]
		projected_xys = [wgs_2_nlcdproj(x,y) for (x, y) in g_geom]
		gage_basins[g] = GeoInterface.Polygon([projected_xys], crs=nlcd_crs)
		global ext = GeoInterface.Extents.union(
			ext, GeoInterface.extent(gage_basins[g]))
	end
end

# ╔═╡ a2624ecf-c294-45cf-bd78-3c1fecb3a443
#VSCODE-MARKDOWN
md"""
### 2.0 Get Files to Process
Will give us the variables within the land cover datasets
"""

# ╔═╡ 50583f67-1431-4dc3-b8c4-268034c8ddf8
using Rasters, ArchGDAL

# ╔═╡ 100aadda-6e45-469c-bd67-6cb54e6e2e2c
begin
    sample_path = "../../hq-data/NLCD/Annual_NLCD_FctImp_1985_CU_C1V2_ef5fc425-51d8-47d2-a7d5-30b0a408bf51.tiff"
	sample_tiff = Raster(sample_path, lazy=true)
end

# ╔═╡ 9f534853-0087-47ab-a4e4-8e9ff90521be
begin
	clipped_ras = crop(sample_tiff; to=ext)
	maras= mask(clipped_ras; with=boolmask(gage_basins["02207120"], to=clipped_ras))
end

# ╔═╡ 490a764e-cc02-44ea-9a82-41947eac5f4a
function check_match(sample_ras, new_ras)
#because we are going to combine multipel datasets at the end of this script, we have to check that all of them can be combined (so have the same projection and extent
	sample_stats = (crs(sample_ras), sample_ras.dims, extent(sample_ras))
	new_stats = (crs(new_ras), new_ras.dims, extent(new_ras))
	return sample_stats == new_stats
end

# ╔═╡ e545bf96-a175-407d-88bf-43f398f0e3f0
#VSCODE-MARKDOWN
md"""
### 3.0 Process into one dataset per variable
Each will be clipped to county bounding box
"""

# ╔═╡ 0f2455aa-0bbe-4454-9542-34ec8e527a72
function get_raster(v, y)
	link = "../../hq-data/NLCD/Annual_NLCD_$(v)_$(y)_CU_C1V2_ef5fc425-51d8-47d2-a7d5-30b0a408bf51.tiff" 
	ras = Raster(link, lazy=true)
	return ras
end

# ╔═╡ 6e9c79e8-b0ce-4b7d-a20e-c032f3d95205
using DataFrames, Statistics, CSV

# ╔═╡ cbc703aa-12bc-4b35-8af7-43391613ac9e
#VSCODE-MARKDOWN
md"""
#### 3.1 Fractional Impervious Area
The data is provided and will be stored as percentage (0-100) of impervious area 
"""

# ╔═╡ 0fab2640-4e85-445f-bc77-dd55e0d5552c
begin
	years = collect(1985:2025)
	
	fctimp_data = DataFrame(
		variable  = String[],
		year = Int16[],
		gage = String[],
		FctImp_mean = Float16[],
		FctImp_maximum = Float16[],
		FctImp_minimum = Float16[],
		FctImp_median = Float16[])
	
    #get a sample raster to compare stats to to make sure everything matches before clipping/combining
	sample_ras_fctimp = get_raster("FctImp", years[1])
	
	for y in years
		ras = get_raster("FctImp", y)
		if check_match(sample_ras_fctimp, ras)
			clipped_ras = crop(ras; to=ext)
			for g in USGS_Gages
				masked_ras = mask(clipped_ras; 
								  with=boolmask(gage_basins[g], to=clipped_ras))
				new_row = (variable = "FctImp",
						   year = y,
						   gage = g,
						   FctImp_mean = mean(skipmissing(masked_ras)),
						   FctImp_maximum = maximum(skipmissing(masked_ras)),
						   FctImp_minimum = minimum(skipmissing(masked_ras)),
						   FctImp_median = median(skipmissing(masked_ras)))
				push!(fctimp_data, new_row)
			end
		else
			println("didn't match the specs so didn't use for the following:
					variable = $v, year = $y")
		end
	end
end

# ╔═╡ 28dc13f1-edc7-44cc-960a-b963f8712975
fctimp_working = copy(fctimp_data)

# ╔═╡ 82f0a45e-252a-4538-847f-4fc7bd391e21
#VSCODE-MARKDOWN
md"""
#### 3.2 Land Cover Class
The data is categorical and will be summarized as percentage (0-100) of each watershed covered by each land cover class
"""

# ╔═╡ adc68b46-8d07-4790-b9b9-46e175648ed6
begin
	lc_dict = Dict(11 => "OpenWater", 12 => "PerennialIce/Snow",
		21 => "DevelopedOpenSpace", 22 => "DevelopedLowIntensity", 
		23 => "DevelopedMediumIntensity", 24 => "DevelopedHighIntensity",
		31 => "BarrenLand", 41 => "DeciduousForest", 
		42 => "EvergreenForest", 43 => "MixedForest",
		52 => "Shrub/Scrub", 71 => "Grassland/Herbaceous",
		81 => "Pasture/Hay", 82 => "CultivatedCrops",
		90 => "WoodyWetlands", 95 => "EmergentHerbacousWetlands")
	
	lndcov_data = DataFrame(
		variable  = String[],
		year = Int16[],
		gage = String[],
		percent = Float16[])
	
    #get a sample raster to compare stats to to make sure everything matches before clipping/combining
	sample_ras_lndcov = get_raster("LndCov", years[1])
	
	for y in years
		ras = get_raster("LndCov", y)
		if check_match(sample_ras_lndcov, ras)
			clipped_ras = crop(ras; to=ext)
			for g in USGS_Gages
				masked_ras = mask(clipped_ras; 
								  with=boolmask(gage_basins[g], to=clipped_ras))
				for (lckey, lcvalue) in lc_dict
					new_row = (
						variable = lcvalue,
						year = y,
						gage = g,
						percent = 100 * count(x -> x == lckey,
						skipmissing(masked_ras)) / count(!ismissing, masked_ras))
					push!(lndcov_data, new_row)
				end
			end
		else
			println("didn't match the specs so didn't use for the following:
					land cover class = $lckey, year = $y")
		end
	end 
end

# ╔═╡ 4d563163-4bb0-4b01-a747-cd65db5bbd8e
lndcov_working = copy(lndcov_data)

# ╔═╡ f90cbd93-6846-48cd-9c6d-69447c6d5e2c
lndcov_gb = groupby(lndcov_data, :variable)

# ╔═╡ bee0f37a-5f2d-468c-ac53-d1cc68f23a84
begin
	dfs = []
	push!(dfs, select(fctimp_working, Not(:variable)))
	for v in unique(lndcov_working.variable)
		df_single = copy(lndcov_gb[(v,)])
		col_nm = v*"_percent"
		df_single[!, col_nm] .= df_single[!,"percent"]
		select!(df_single, Not(:variable, :percent))
		push!(dfs, df_single)
	end
end

# ╔═╡ 521f2dc1-0305-4727-8a1c-c90695a23d23
df_cleaned = outerjoin(dfs..., on = [:year, :gage])

# ╔═╡ e36b7805-0a70-4636-9c8d-39fa202649b8
begin
	out_future = "land_cover_annual.csv"
	CSV.write(out_future, df_cleaned)
end

# ╔═╡ Cell order:
# ╠═d1feafff-c32b-455e-b777-222e2ad0eff8
# ╠═c9c3235d-ece2-4fbe-9621-2a454eaa8685
# ╠═200dcd95-aea7-434c-876e-9d631c019343
# ╠═97c7b647-bd18-4122-86fd-9999beb565ea
# ╠═5cfeddb3-6382-44d7-8a6a-c3e58cccf720
# ╠═50240bdf-d969-4fee-944c-56e5c923a5dd
# ╠═0430f618-31f9-4272-b5f5-6db55be469ac
# ╠═a978e8b0-cbcc-4c9f-aeb4-7d4f8cdb6055
# ╠═a2624ecf-c294-45cf-bd78-3c1fecb3a443
# ╠═50583f67-1431-4dc3-b8c4-268034c8ddf8
# ╠═100aadda-6e45-469c-bd67-6cb54e6e2e2c
# ╠═9f534853-0087-47ab-a4e4-8e9ff90521be
# ╠═490a764e-cc02-44ea-9a82-41947eac5f4a
# ╠═e545bf96-a175-407d-88bf-43f398f0e3f0
# ╠═0f2455aa-0bbe-4454-9542-34ec8e527a72
# ╠═6e9c79e8-b0ce-4b7d-a20e-c032f3d95205
# ╠═cbc703aa-12bc-4b35-8af7-43391613ac9e
# ╠═0fab2640-4e85-445f-bc77-dd55e0d5552c
# ╠═28dc13f1-edc7-44cc-960a-b963f8712975
# ╠═82f0a45e-252a-4538-847f-4fc7bd391e21
# ╠═adc68b46-8d07-4790-b9b9-46e175648ed6
# ╠═4d563163-4bb0-4b01-a747-cd65db5bbd8e
# ╠═f90cbd93-6846-48cd-9c6d-69447c6d5e2c
# ╠═bee0f37a-5f2d-468c-ac53-d1cc68f23a84
# ╠═521f2dc1-0305-4727-8a1c-c90695a23d23
# ╠═e36b7805-0a70-4636-9c8d-39fa202649b8
