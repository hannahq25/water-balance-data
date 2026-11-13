### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ abfe2d6a-d614-11f1-8620-49cff9915e07
using PlutoUI, HTTP, Rasters, NCDatasets, ArchGDAL, Dates, Statistics
#this code originated from the python code on https://github.com/nationalparkservice/Water-Balance/ but was modified and simplified for use with this project

# ╔═╡ 5dcf2f5d-da81-46c0-b57f-876e8b19d1b1
using Proj, GeoInterface, DimensionalData.Lookups

# ╔═╡ 6108da4c-269b-4236-88b0-eb07079a5496
begin
import GeoJSON
using GeoJSON
"load GeoJSON"
end

# ╔═╡ d9d5a237-935c-4cab-8284-c573d17eb46b
function make_latitude(temp_nc)
    #temp_nc ="/Users/amy/Documents/CEE492/DIY WaterBalance/NASA/v_1_5_1980_gridmet_historical_accumswe.nc4"
    
    daymet_txt = ArchGDAL.importWKT(""" 
        PROJCS["Lambert_Conformal_Conic",
        GEOGCS["WGS 84",
        DATUM["WGS_1984",
        SPHEROID["WGS 84", 6378137, 298.257223563]],
        PRIMEM["Greenwich", 0],
        UNIT["degree", 0.0174532925199433]],
        PROJECTION["Lambert_Conformal_Conic_2SP"],
        PARAMETER["standard_parallel_1", 25],
        PARAMETER["standard_parallel_2", 60],
        PARAMETER["latitude_of_origin", 42.5],
        -PARAMETER["central_meridian", -100],
        -PARAMETER["false_easting", 0],
        -PARAMETER["false_northing", 0],
        UNIT["metre", 1]]
        """)
        
    daymet_wkt = ArchGDAL.toWKT(daymet_txt)
    daymet_crs = WellKnownText(GeoFormatTypes.CRS(), daymet_wkt)
    
    ras = Raster(NCDataset(temp_nc)["lat"], lazy=true)
    X_vals = X(dims(ras, X).val)
    Y_vals = Y(dims(ras, Y).val)  
    data = Array(NCDataset(temp_nc)["lat"])
    ras_lat = Raster(data, (X_vals, Y_vals))
    ras_lat = setcrs(ras_lat, daymet_crs)

end

# ╔═╡ 9c341829-14bb-4617-88f2-3f3bf5afcf37
function CALC_F_RAIN_SNOW(d_rasters)
    messageTime = now()
    #@info "Creating MELT, RAIN, SNOW $messageTime"

    #assume all snow if below 0 degrees celcius, all rain if above 6 degrees, and factored if between the two
    #Equation 1
    test_zero = d_rasters["Tₐ"] .<= 0
    d_rasters["F"][test_zero] .= 0

    #Equation 2
    test_frac = (d_rasters["Tₐ"] .> 0) .& (d_rasters["Tₐ"] .< 6.0)
    d_rasters["F"][test_frac] .=  d_rasters["Tₐ"][test_frac] ./ 6

    #Equation 3
    test_one  = d_rasters["Tₐ"] .>= 6   
    d_rasters["F"][test_one]  .= 1
        
    #Equation 4
    d_rasters["RAIN"] .= d_rasters["F"] .* d_rasters["P"]  
    d_rasters["RAIN"][d_rasters["RAIN"] .<0] .= 0

    #Equation 5
    d_rasters["SNOW"] .= d_rasters["P"] .- d_rasters["RAIN"]

    return d_rasters
end

# ╔═╡ 3e587fe0-6ca2-4ff0-b345-7b8205042ee6
#Function Derives the Snow Melt, Snow Pack and Monthly Water Input - Equations 6-8 Dilts et. al. Biogeography 2015 Appendix S1)
function CALC_MELT_PACK_W(d_rasters, t)
    Fₜ = d_rasters["F"][Ti = At([t])]
    PACKₜ₋₁ = d_rasters["PACK"][Ti = At(t-Day(1))]   #note want to drop the time
    SNOWₜ = d_rasters["SNOW"][Ti = At([t])]
    Pₜ = d_rasters["P"][Ti = At([t])]

    #Equations 6
     d_rasters["MELT"][Ti = At([t])] .=   Fₜ .*(SNOWₜ .+ PACKₜ₋₁)
    
    #Equation 7
    d_rasters["PACK"][Ti = At([t])] .= (1 .- Fₜ).^2 .* Pₜ + 
                                                         (1 .- Fₜ).* PACKₜ₋₁
    #can just reset for full timeperiod
    d_rasters["PACK"][d_rasters["PACK"] .< 0] .= 0 

    #Equation 8
    d_rasters["W"][Ti = At([t])] .= d_rasters["RAIN"][Ti = At([t])]  .+
                                                    d_rasters["MELT"][Ti = At([t])]
    
    messageTime = now()
    #@info "Derived PACK, MELT, W - $messageTime"

    return d_rasters
end

# ╔═╡ fbbafc2f-4dbf-4002-83a7-5c047fb3df2a
function clip_indices(nc, var, r)
	vals = nc[var][:]	
	first = vals[1]
	last = vals[end]
	step = vals[2] - vals[1]
	if step > 0 
	return range(start= ceil(Int, (minimum(r) - first)/step),
				 stop= ceil(Int, (maximum(r) - first)/step)+1)
	else
	return range(start=-1*trunc(Int, (first - maximum(r))/step)+1,
				 stop=ceil(Int, (first-minimum(r))/-step)+1)
		#trunc(Int, (maximum(range)-first)/-step)-1:ceil(Int, (range[2]-first)/step)+1#: ceil(Int, (range[1] - last)/step)
	end
end

# ╔═╡ 130eaf56-954e-462c-8561-2deee792fc29
function get_ncs(var, nc_path)
	paths = [nc_path *"/" for f in readdir(nc_path)]
	full_paths = paths.* readdir(nc_path)
	#don't include files that have CREATED_ bc they were created by this script
	filter!(f -> !contains(f, "CREATED_"), full_paths)
	#don't include files that are not netcdf files
	filter!(f -> contains(f, Regex(var, "i")), full_paths)
	return full_paths
end

# ╔═╡ dc84935f-3609-4a4c-9a14-baf7f37c6d4a
function daymet()
    
project_string = "+proj=lcc +lat_1=25 +lat_2=60 +lat_0=42.5 +lon_0=-100 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs"

spatial_reference_object = ArchGDAL.importPROJ4(project_string)
wkt_str = ArchGDAL.toWKT(spatial_reference_object)
crs = WellKnownText(GeoFormatTypes.CRS(), wkt_str)
    
#=    wkt_str = """
    PROJCS["Lambert_Conformal_Conic",
        GEOGCS["WGS 84",
            DATUM["WGS_1984",
                SPHEROID["WGS 84", 6378137, 298.257223563]],
            PRIMEM["Greenwich", 0],
            UNIT["degree", 0.0174532925199433]],
        PROJECTION["Lambert_Conformal_Conic_2SP"],
        PARAMETER["standard_parallel_1", 25],
        PARAMETER["standard_parallel_2", 60],
        PARAMETER["latitude_of_origin", 42.5],
        PARAMETER["central_meridian", -100],
        PARAMETER["false_easting", 0],
        PARAMETER["false_northing", 0],
        UNIT["metre", 1]]
    """
    
    spatial_ref = ArchGDAL.importWKT(strip(wkt_str))
    daymet_wkt  = ArchGDAL.toWKT(spatial_ref)
=#    
    return (
        crs = crs,
        wkt_Str = wkt_str,
        sro = spatial_reference_object,
        prj_string = project_string
    )
end

# ╔═╡ 28694193-3a8c-4369-88d8-cf5f91518eca
function dayYearMidMonth(month)
    try
        d_midmonthday = Dict(
                    "01" => 15,
                    "02" => 46,
                    "03" => 74,
                    "04" => 105,
                    "05" => 135,
                    "06" => 166,
                    "07" => 196,
                    "08" => 227,
                    "09" => 258,
                    "10" => 288,
                    "11" => 319,
                    "12" => 349)
        return d_midmonthday[month]


    catch e
        messageTime = timeFun()
        scriptMsg = "Error - " * messageTime
        @info "Error JulianDayMidMonth Function -  $month"
        exit()
    end
end


# ╔═╡ c5e23dd3-529d-40a1-bb5d-199e95507ea7
#Monthly Solar Declination 15th Day of the month (needed for equation 11 - Day Length) Out put is Degrees - Not sure if Radian's or Degree's is desired? - KRS 20150824

function solarDeclination(month)
    try       #Get Julian Day
        dayMid = Int(dayYearMidMonth(month))
        #dayofyear(dt) would be more efficient maybe
        
        #equation = (math.sin(((360.0/365.0)*(dayMid - 81))) * (math.sin(23.45)))  #Equation in One Calculation
       
        #δ = 23.45 * sind(360/365*(284+ dayMid))

        δ = asind(sind((360.0 / 365.0) * (dayMid - 81)) * sind(23.45))

        @info "Solar Delination Angle for month - $month is: $δ"
        return δ

    catch e
        messageTime = timeFun()
        scriptMsg = "Error - $e" * messageTime
        @info "Error MsolarDeclination Function -  $month"
        exit()
    end
end

# ╔═╡ 55294331-d57f-471d-af67-56d4e3dc66f0
function regularize_dim(r::Raster, d::Symbol)
	d_ext = getproperty(extent(r), d)
	d_min, d_max = d_ext[1], d_ext[2]
	d_step = (d_max-d_min)/(size(r,d)-1)
	d_range = d_min:d_step:d_max

	ord = d_step > 0 ? ForwardOrdered() : ReverseOrdered()

	return Sampled(
        d_range;
        order = ord,
        span  = Regular(abs(d_step))
    )
end

# ╔═╡ df18ebdf-55ac-4660-a62a-982ef06a35ee
function regularize_dim(nc::NCDataset, d::Symbol)
	d_begin, d_end = nc[d][1], nc[d][end]
	d_step = (d_end-d_begin)/(nc.dim[d]-1)
	#d_range = d_min:d_step:d_max
	d_length = length(nc[d])

	d_range = range(d_begin, stop=d_end, length=d_length)
	ord = d_step > 0 ? ForwardOrdered() : ReverseOrdered()
    #d_range = d_step > 0 ? d_min:d_step:d_max : 
	
	return Sampled(
        d_range;
        order = ord,
        span  = Regular(d_step)
    )
	
end

# ╔═╡ e2405c1f-4639-44bf-8af0-59bcd0fe1ee1
function crop_nasa_ras(f, var, crs, ext)
#temp_nc ="/Users/amy/Documents/CEE492/Water_Balance/NASA_Data/WaterBalance_Daily_Historical_GRIDMET_1.5-20260918_184221/v_1_5_1980_gridmet_historical_accumswe.nc4"
nc = NCDataset(f)
x_indices = clip_indices(nc, "x", ext.X)
y_indices = clip_indices(nc, "y", ext.Y)
data = nc[var][x_indices, y_indices, :]

x_dim = regularize_dim(nc, :x)[x_indices]
y_dim = regularize_dim(nc, :y)[y_indices]

  
    
#fix dates so they are not datetime
st_date = Date(nc["time"][1])
end_date = Date(nc["time"][end])

dates = st_date:Day(1):end_date

t_dim = Sampled(dates; order = ForwardOrdered(), 
                  span  = Regular(Day(1)),
                  sampling = Points())

ras = Raster(data, (X(x_dim), Y(y_dim), Ti(t_dim));
                missingval = -9999,
                crs = crs) 
return ras
end


# ╔═╡ 740c4c2f-6868-40d5-bb54-c434773d3e95
function clip_and_return_at_t(var, ext, nc, crs, t)
	clipped_raster = crop_nasa_ras(nc, lowercase(var), crs, ext)
	return clipped_raster[Ti = At([t])] 
end

# ╔═╡ 0bf1b6fe-b889-4b7f-b3fb-42eb150d8066
function merge_ncs2ras(files, var, crs, ext)
	cat_collection = []
	for f in files
		push!(cat_collection, crop_nasa_ras(f, lowercase(var), crs, ext))
	end
	combined_nc = cat(sort(cat_collection, by = r -> first(dims(r, Ti)))...; dims=Ti)
end

# ╔═╡ fc2a3658-8686-48bf-8be9-3a11818cc618
function clip_and_merge(var, ext, nasa_path, crs)
	files = get_ncs(var, nasa_path)
	merged_ras = merge_ncs2ras(files, var, crs, ext)
	return merged_ras
end

# ╔═╡ 525b6d1e-2ff7-42f0-a8d6-098d14906d26
function clip_and_maximize(var, ext, nasa_path, crs)
	files = get_ncs(var, nasa_path)
	merged_ras = merge_ncs2ras(files, var, crs, ext)
	return dropdims(maximum(merged_ras, dims = Ti), dims = Ti)
end

# ╔═╡ 16e44723-c84d-4f12-880e-d247652c2727
function get_ds_subset(v_short::String, v_long::String, ext::Extent)
    
    source = 
        #"http://thredds.northwestknowledge.net:8080/thredds/
        #catalog/MET/$variable/catalog.html?dataset=REACCHDatasetScan_
        #$variable/$(variable)_$year.nc" 
    "http://thredds.northwestknowledge.net:8080/thredds/dodsC/agg_met_$(v_short)_1979_CurrentYear_CONUS.nc"
    #"http://thredds.northwestknowledge.net:8080/thredds/catalog/MET/tmmn/catalog.html?dataset=REACCHDatasetScan_tmmn/tmmn_2026.nc"
    #"http://thredds.northwestknowledge.net:8080/thredds/catalog/MET/tmmx/catalog.html?dataset=REACCHDatasetScan_tmmx/tmmx_2026.nc"

    ds = NCDataset(source)

    @info "$source"

    #get steps so we make sure we contain full area with pull
    lat_step = step(regularize_dim(ds, :lat))
    lon_step = step(regularize_dim(ds, :lon))
    
    #longitude vals, note for MACA data lon is 0-360 versus gage is in -180 to 180
    lon_min = ext[1][1] - lon_step
    lon_max = ext[1][2] + lon_step
    
    # range of latitude
    lat_min = ext[2][1] - lat_step
    lat_max = ext[2][2] + lat_step

    ds_subset = NCDatasets.@select(ds[v_long],
    $lon_min <= lon <= $lon_max && $lat_min <= lat <= $lat_max)
    
    ras = Raster(ds_subset[v_long][:], 
    (X(ds_subset["lon"][:]), 
     Y(ds_subset["lat"][:]), 
     Ti(ds_subset["day"][:])); 
    name = Symbol(v_long),
    missingval = ds_subset[v_long].attrib["_FillValue"]
)
    return ras
    
    
    #return ds_subset

end

# ╔═╡ 9fc9bce9-2bc4-4fde-bc49-ee6c7765a724
function regularize_grid(r::Raster, crs)

	x_min, x_max = extent(r)[1][1], extent(r)[1][2]
	y_min, y_max = extent(r)[2][1], extent(r)[2][2]
	t_min, t_max = extent(r)[3][1], extent(r)[3][2]

	x_step = (x_max-x_min)/(size(r,X)-1)
	y_step = (y_max-y_min)/(size(r,Y)-1)
	t_step = (t_max-t_min)/(size(r,Ti)-1)
	
	
	x_range = x_min:x_step:x_max #need to get it back to negative 80ish
	y_range = y_min:y_step:y_max
	t_range = t_min:t_step:t_max

	ras_regular = Raster(
    	parent(r), 
        (
			X(x_range; crs = crs, sampling = Points()), 
	        Y(y_range; crs = crs, sampling = Points()),
			Ti(t_range)
		);
    	missingval = missingval(r),
    	crs = crs
	)
	return ras_regular
end

# ╔═╡ ea8fdf7b-a9ae-4978-9fcd-aacb69207467
function buffer_extent(buffer, ext)
	buffered_ext = Extent(X = (ext.X[1] - buffer, ext.X[2] + buffer),
						      Y = (ext.Y[1] - buffer, ext.Y[2] + buffer))
end

# ╔═╡ b5567c07-e317-4986-b6d6-25d40a109b71
function add_time(ras2d, date)
data3d = reshape(parent(ras2d), size(ras2d)..., 1)
ras3d = Raster(data3d,
               (dims(ras2d)..., Ti([date]));
               crs = crs(ras2d),
               missingval = missingval(ras2d)
              )
return ras3d
end

# ╔═╡ b0b1c319-ed96-44e2-82c8-c4489abe2882
function CALC_SOIL_AET_RUNOFF(d_rasters, t, SOILₘₐₓ)
    Wₜ = d_rasters["W"][Ti = At([t])]
    PETₜ = d_rasters["PET"][Ti = At([t])]
    
    SOILₜ₋₁ = d_rasters["SOIL"][Ti = At(t - Day(1))]
    
    #Δₛₒᵢₗ,ₜ= zero(d_rasters["SOIL"][Ti = At(t)] )

    #equation 12 when Wt>PETt otherwise equation 13 
    W_fills_PET  = Wₜ .> PETₜ
    SOILₜ = ifelse.(W_fills_PET, 
                     min.(add_time(SOILₘₐₓ, t), Wₜ .- PETₜ .+ SOILₜ₋₁),
                     SOILₜ₋₁ .- SOILₜ₋₁ .*(1 .- exp.(-(PETₜ .- Wₜ)./SOILₘₐₓ)))

    Δₛₒᵢₗ = SOILₜ .- SOILₜ₋₁

    AETₜ = ifelse.(W_fills_PET, PETₜ, Wₜ .- Δₛₒᵢₗ)

    RUNOFFₜ = Wₜ .- Δₛₒᵢₗ .- AETₜ
    RUNOFFₜ .= max.(RUNOFFₜ, zero(RUNOFFₜ)) #was coming up with some rounding errors below zero

    d_rasters["SOIL"][Ti = At(t)] = SOILₜ
    d_rasters["RUNOFF"][Ti = At(t)] = RUNOFFₜ
    d_rasters["AET"][Ti = At(t)] = AETₜ    
    
    messageTime = now()
    #@info "Derived SOIL, Δₛₒᵢₗ, AET, RUNOFF - $messageTime"
    return d_rasters

 
end

# ╔═╡ e76fccba-1519-494a-838a-e7bc89d70976
function project((x,y), source_string, target_string, always_xy)
	Proj.Transformation(source_string, target_string; always_xy=always_xy)(x,y)
end

# ╔═╡ 1eaf7164-e3f1-4bb1-8e00-6eedc9928b51
function get_projected_gage_basin(g, crs_string, crs)
    url = "https://api.water.usgs.gov/nldi/linked-data/nwissite/USGS-$g/basin?f=json"
    res = HTTP.get(url) 
	g_geom = GeoJSON.read(res.body).features[1].geometry[1]

	s_str = "EPSG:4326"
	t_str = crs_string
	projected_xys = [project((x,y), s_str, t_str, true) for (x, y) in g_geom]
	polygon = GeoInterface.Polygon([projected_xys], crs=crs)
	ext = GeoInterface.extent(polygon)	
	return (polygon = polygon, ext = ext)
end

# ╔═╡ 7fce0c85-096e-444b-9f38-d9e0b11fb1f5
begin
	#02334885 Suwanee Creek at Suwanee, Ga. (47.09) - urbanization ongoing
	#02330450 Chattahoochee River at Helen, GA (44.8) - no urbanization going
	USGS_Gages = ["02334885", "02330450"]
	projected_exts = []
	geo_exts = []
	for g in USGS_Gages
		push!(projected_exts, 
			  get_projected_gage_basin(g, daymet().prj_string, daymet().crs).ext)
		push!(geo_exts, 
			 get_projected_gage_basin(g, "EPSG:4326", EPSG(4326)).ext)
	end
	proj_extent = GeoInterface.Extents.union(projected_exts...)
	geo_extent = GeoInterface.Extents.union(geo_exts...)
	"Get Extents to Use for Clipping and USGS Gages"
end

# ╔═╡ e7b3bd41-a327-47ac-9dfb-3863f6a8dc59
begin
    nasa_path = "/Users/amy/Documents/CEE492/DIY WaterBalance/NASA"
    outDir = "/Users/amy/Documents/CEE492/DIY WaterBalance/OUTPUT"
    
    PETs_path = outDir*"/PET.nc"
    SOILₘₐₓ_path = outDir*"/SOILMAX.nc"

    if isfile(PETs_path)
        PETs = Raster(PETs_path)
        PETs = setcrs(PETs, daymet().crs) 
        @info "loaded $PETs_path"        
    else
        PETs = clip_and_merge("pet", proj_extent, nasa_path, daymet().crs)
        write(PETs_path, PETs; name = :pet) 
        @info "created $PETs_path"
    end
    
    if isfile(SOILₘₐₓ_path)
        SOILₘₐₓ = Raster(SOILₘₐₓ_path)
        setcrs(SOILₘₐₓ, daymet().crs)
        @info "loaded $SOILₘₐₓ_path"
    else
        SOILₘₐₓ = clip_and_maximize("soilwater", proj_extent, nasa_path, daymet().crs)
	    write(SOILₘₐₓ_path, SOILₘₐₓ; name = :soilmax)
        @info "created $SOILₘₐₓ_path"
    end

"create or load PETs, SOILMAX"
end

# ╔═╡ 228e3f02-a9cd-4561-bb4e-8d40f919e007
Date(maximum(dims(PETs, Ti)))

# ╔═╡ 284ccf74-82c1-4dcf-985d-005453a7b553
#Function derives the average day length raster for the 15th day of the month - equation 11 Dilts et. al. Biogeography 2015 Appendix S1)
#Equation for DayLength Calulcation is incorrect as of 20170211 and has not been migrated from ArcPY
function dayLengthRas(latitude, δₘ, month)
    try
        ω = 0.2618   
        #Default angular velocity of the Earth's rotation in (radian hr-1)
        
        DLₘ = 2 .* acos.(-tand.(δₘ) .* tand.(Λ)) ./ω
        outDLₘ = "$outDir/DayLengthHours_$(string(year))_$month.tif"
        write(outDLₘ, DLₘ)

        messageTime = timeFun()
        @info "Completed Day Length Caluclation for - $month $outDLₘ $messageTime"

        return DLₘ

    catch e
        messageTime = timeFun()
        scriptMsg = "Error - $e"
        @info "Error dalylengthras Function -  $month"
        exit()
    end
end

# ╔═╡ 12c42c71-3653-4ce0-8096-b53bb2d3cede
#Function calculates the Folded Aspect - Equation 14 Dilts Et. al. 2015 = aspFold = Abs(180 - (Abs((aspectRas) - 225))))
#Note monthlyTempMean list is being used for spatial reference of output Folder Aspect
function aspectFolded(aspectRas, monthlyTempMean)
    try
        aspFold = abs.(180 .- abs.(aspectRas .- 225))
        aspFold[aspFold < 0] = NaN

        #Export Aspect Folder Array to Raster
        outAspFold = "$outDir/Folded_Aspect.tif"
        write(outAspFold, aspFold)

 

        messageTime = timeFun()
        @info "Folded Aspect Derived - $outAspFold $messageTime"

        return aspFold

    catch e
        messageTime = timeFun()
        scriptMsg = "Error - $e"
        @info "Error aspedFolded Function -  $month"
        exit()
    end
end        

# ╔═╡ a482fd86-1b68-4802-a756-f7a6ef75c8ae
#Function calculates the Heat Load Index - Equation 15 Dilts Et. al. 2015
function heatLoadIndexFun(aspFoldedRas, slopeRas, latitude, outArraySize)
    try
        outheatLoad = "$outDir/HeatLoadIndex.tif"
        #outslopeRasRad = "$outDir/Slope_Radians.tif"
        HL = 	0.339 .+ 0.808 .* (cosd.(latitude) .* cosd.(slopeRas)) .- 
                             0.196 .* (sind.(latitude) .* sind.(slopeRas)) .- 
                           0.482 .* (cosd.(aspFoldedRas) .* sind.(slopeRas))
        write(outheatLoad, HL)

 

        messageTime = timeFun()
        @info "Heat Load Index Created - $outheatLoad $messageTime"

        return HL

    catch e
        messageTime = timeFun()
        scriptMsg = "Error - $e"
        @info "Error heatLoadIndexFun Function -  $month"
        exit()
    end
end   

# ╔═╡ 5f3a2a4c-4832-496f-b4c1-2bca8d6886a4
# ╠═╡ skip_as_script = true
#=╠═╡
begin 
	#have to buffer the GridMET so the bilinear interpolation works
	buffered_wgs_extent = buffer_extent(0.1, geo_extent)

	pr_path = outDir*"/P.nc"
	tmmn_path = outDir*"/Tmin.nc"
	tmmx_path = outDir*"/Tmax.nc"

    if isfile(pr_path)
		pr = Raster(pr_path, lazy=true)
		pr = setcrs(pr, daymet().crs)	
	    @info "loaded $pr_path"
	else
		pr = get_ds_subset("pr", "precipitation_amount",buffered_wgs_extent) 
		pr = regularize_grid(pr, EPSG(4326))
		pr = resample(pr; to = PETs[Ti = 1], method = :bilinear)	
		write(pr_path, pr; 
			  name = :P)
	    @info "created $pr_path from gridmet data"		
	end

    if isfile(tmmn_path)
		tmmn = Raster(tmmn_path, lazy=true)
		tmmn = setcrs(tmmn, daymet().crs)	
	    @info "loaded $tmmn_path"
	else
		tmmn = get_ds_subset("tmmn", "daily_minimum_temperature",buffered_wgs_extent) 
		tmmn = regularize_grid(tmmn, EPSG(4326))
		tmmn = resample(tmmn; to = PETs[Ti = 1], method = :bilinear)	
		write(tmmn_path, tmmn; 
			  name = :Tmin)
	    @info "created $tmmn_path from gridmet data"		
	end

    if isfile(tmmx_path)
		tmmx = Raster(tmmx_path, lazy=true)
		tmmx = setcrs(tmmx, daymet().crs)	
	    @info "loaded $tmmx_path"
	else
		tmmx = get_ds_subset("tmmx", "daily_maximum_temperature",buffered_wgs_extent) 
		tmmx = regularize_grid(tmmx, EPSG(4326))
		tmmx = resample(tmmx; to = PETs[Ti = 1], method = :bilinear)	
		write(tmmx_path, tmmx; 
			  name = :Tmax)
	    @info "created $tmmx_path from gridmet data"		
	end
	"create or load Precip, Tmin, Tmax fro GridMET"
end
  ╠═╡ =#

# ╔═╡ eeb4f528-87bd-4bb9-9ba5-c66c666863d5
#=╠═╡
function initialize_rasters(st_date, end_date)
    d_rasters = Dict()
    d_rasters["P"] = pr[Ti = Between(st_date, end_date)]
    #average and convert from kelvin to celcius
    d_rasters["Tₐ"] = (tmmn[Ti = Between(st_date, end_date)] .+ 
                                tmmx[Ti = Between(st_date, end_date)]) ./ 2 .-273.15
    d_rasters["PET"] = PETs[Ti = Between(st_date, end_date)]
    keys = ["F", "RAIN", "SNOW", "PACK", "MELT", "W", "SOIL", "RUNOFF", "AET"]
    for k in keys
        d_rasters[k] = zero(d_rasters["P"])
    end
    #d_rasters["Δₛₒᵢₗ"] = zero(d_rasters["P"])   
    return d_rasters
end
  ╠═╡ =#

# ╔═╡ c0b1c13e-8f70-4120-9b47-0fe26aa43fae
#=╠═╡

#combined_nc = cat(sort(cat_collection, by = r -> first(dims(r, Ti)))...; dims=Ti)


begin    
    dt_range = Date(minimum(dims(PETs, Ti))):Date(maximum(dims(PETs, Ti)))
    #initialize one day before start so we can set cumulative rasters
    d_rasters = Dict()
    d_rasters = initialize_rasters(dt_range[1]- Day(1), dt_range[end]) 
    
    #calculate daily melt factor, rain, snow
    d_rasters = CALC_F_RAIN_SNOW(d_rasters)
    @info "created melt factor, rain, snow"
    
    #calculate raster that ARE dependent upon calculated raster
    for date in dt_range
        date_str = Dates.format(date, "yyyy-mm-dd")
        #@info "starting $date_str"

        global d_rasters = CALC_MELT_PACK_W(d_rasters, date)
        global d_rasters = CALC_SOIL_AET_RUNOFF(d_rasters, date, SOILₘₐₓ)
    end   
    #check that values are reasonable
    for k in keys(d_rasters)
          max = maximum(d_rasters[k])
          min = minimum(d_rasters[k])
          avg = mean(d_rasters[k])
          @info "$k: max:$max, min:$min, avg:$avg"
    end
end
  ╠═╡ =#

# ╔═╡ 73b234f4-2224-4e06-877c-1f4a0c425131
#=╠═╡
begin 
	#because some of the rasters start a day before PET, need to fix this range when saveing named tuple
	dates = Ti(Between(dt_range[1], dt_range[end]))
	nt = NamedTuple(Symbol(k) => v[dates] for (k, v) in d_rasters)
	full_stack = RasterStack(nt)
	write(outDir*"/Output.nc", full_stack, force=true) 
	@info "created $(outDir*"/Output.nc")"
	"export rasters"
end
  ╠═╡ =#

# ╔═╡ 6899d54e-8701-4468-b4e1-490d351d9a45
buffer_extent(0.1, geo_extent).Y

# ╔═╡ 9ae179b5-bb64-4598-af9b-ff05529fcf07
geo_extent.Y

# ╔═╡ b8001e10-2687-4f86-9358-20cc8e52d190
ext1 = get_projected_gage_basin("02334885", daymet().prj_string, daymet().crs).ext

# ╔═╡ 95f24927-75a6-4632-8835-77064af29c97
ext2 = get_projected_gage_basin("02330450", daymet().prj_string, daymet().crs).ext

# ╔═╡ 5e09e286-e852-492c-8b84-af3b903ebc70
GeoInterface.Extents.union([ext1, ext2]...)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
ArchGDAL = "c9ce4bd3-c3d5-55b8-8973-c0e20141b8c3"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
DimensionalData = "0703355e-b756-11e9-17c0-8b28908087d0"
GeoInterface = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
GeoJSON = "61d90e0f-e114-555e-ac52-39dfb47a3ef9"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
NCDatasets = "85f8d34a-cbdd-5861-8df4-14fed0d494ab"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Proj = "c94c279d-25a6-4763-9509-64d165bea63e"
Rasters = "a3a2b9e3-a471-40c9-b274-f788e487c689"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
ArchGDAL = "~0.10.12"
DimensionalData = "~0.30.2"
GeoInterface = "~1.6.2"
GeoJSON = "~0.8.4"
HTTP = "~2.6.7"
NCDatasets = "~0.14.15"
PlutoUI = "~0.7.83"
Proj = "~1.9.0"
Rasters = "~0.15.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.7"
manifest_format = "2.0"
project_hash = "65f882bea4c9e847cf6260606109e982f3532349"

[[deps.AbstractPlutoDingetjes]]
git-tree-sha1 = "e71ee7b4aa06b045259a7d6101e1cb45ad140bce"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.4.1"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "dee8388a9bec89c8713ad176f96960ae2f98598a"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.7.4"

    [deps.Adapt.extensions]
    AdaptSparseArraysExt = "SparseArrays"
    AdaptStaticArraysExt = "StaticArrays"

    [deps.Adapt.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.ArchGDAL]]
deps = ["CEnum", "ColorTypes", "Dates", "DiskArrays", "Extents", "GDAL", "GeoFormatTypes", "GeoInterface", "ImageCore", "Tables"]
git-tree-sha1 = "d77f9c3d7bc0df0c7d197bc68a78a39664f1523d"
uuid = "c9ce4bd3-c3d5-55b8-8973-c0e20141b8c3"
version = "0.10.12"

    [deps.ArchGDAL.extensions]
    ArchGDALJLD2Ext = "JLD2"
    ArchGDALMakieExt = "Makie"
    ArchGDALRecipesBaseExt = "RecipesBase"

    [deps.ArchGDAL.weakdeps]
    JLD2 = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Arrow_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Lz4_jll", "Thrift_jll", "Zlib_jll", "Zstd_jll", "boost_jll", "brotli_jll", "rapidjson_jll", "snappy_jll"]
git-tree-sha1 = "776ed1d3fe0cff2166d0cb731fda3fce1cf6ce37"
uuid = "8ce61222-c28f-5041-a97a-c2198fb817bf"
version = "24.0.0+0"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.Blosc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Lz4_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "535c80f1c0847a4c967ea945fca21becc9de1522"
uuid = "0b7ba130-8d10-5ba8-a3d6-c5182647fed9"
version = "1.21.7+0"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1b96ea4a01afe0ea4090c5c8039690672dd13f2e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.9+0"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CFTime]]
deps = ["Dates", "Printf"]
git-tree-sha1 = "fad2f199d1f1ae0c8e820ab68f81f6dbf62e60b2"
uuid = "179af706-886a-5703-950a-314cd64e0468"
version = "0.2.10"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "970758a3d591a2a5c2a907c53f2e2f8c1b1d3537"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.9"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "a7cf827a79b378a381e31e5c7feca853ec19cb94"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.4"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "8b3b6f87ce8f65a2b4f857528fd8d70086cd72b1"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.11.0"

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

    [deps.ColorVectorSpace.weakdeps]
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Reexport"]
git-tree-sha1 = "a633156e74096f90b3b5e833529292b651b5671a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.3"

[[deps.CommonDataModel]]
deps = ["CFTime", "DataStructures", "Dates", "DiskArrays", "Preferences", "Printf", "Statistics"]
git-tree-sha1 = "54d50f8a0a68ff4160564dfa09fc5de32465cfca"
uuid = "1fbeeb36-5f17-413c-809b-666fb144f157"
version = "0.4.4"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.1+2"

[[deps.ConstructionBase]]
git-tree-sha1 = "b4b092499347b18a015186eae3042f72267106cb"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.6.0"
weakdeps = ["IntervalSets", "LinearAlgebra", "StaticArrays"]

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

[[deps.CoordinateTransformations]]
deps = ["LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "a692f5e257d332de1e554e4566a4e5a8a72de2b2"
uuid = "150eb455-5306-5404-9cee-2592286d6298"
version = "0.6.4"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["OrderedCollections"]
git-tree-sha1 = "b0bc6d2cad1fed8b7fd59a1551a991cb3d2809e6"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.19.6"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DimensionalData]]
deps = ["ConstructionBase", "DataAPI", "Dates", "Extents", "Interfaces", "IntervalSets", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "PrecompileTools", "Random", "Statistics", "TableTraits", "Tables"]
git-tree-sha1 = "3e5b58039d35b98f425446c099577d67633a7237"
uuid = "0703355e-b756-11e9-17c0-8b28908087d0"
version = "0.30.2"

    [deps.DimensionalData.extensions]
    DimensionalDataAbstractFFTsExt = "AbstractFFTs"
    DimensionalDataAdaptExt = "Adapt"
    DimensionalDataAlgebraOfGraphicsExt = "AlgebraOfGraphics"
    DimensionalDataArrayInterfaceExt = "ArrayInterface"
    DimensionalDataCategoricalArraysExt = "CategoricalArrays"
    DimensionalDataChainRulesCoreExt = "ChainRulesCore"
    DimensionalDataDiskArraysExt = "DiskArrays"
    DimensionalDataMakieExt = "Makie"
    DimensionalDataNearestNeighborsExt = "NearestNeighbors"
    DimensionalDataPythonCallExt = "PythonCall"
    DimensionalDataRecipesBaseExt = "RecipesBase"
    DimensionalDataSparseArraysExt = "SparseArrays"
    DimensionalDataStatsBaseExt = "StatsBase"

    [deps.DimensionalData.weakdeps]
    AbstractFFTs = "621f4979-c628-5d54-868e-fcf4e3e8185c"
    Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
    AlgebraOfGraphics = "cbdf2221-f076-402e-a563-3d30da359d67"
    ArrayInterface = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
    CategoricalArrays = "324d7699-5711-5eae-9e2f-1d82baa6b597"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DiskArrays = "3c3547ce-8d99-4f5e-a174-61eb10b00ae3"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    NearestNeighbors = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
    PythonCall = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"

[[deps.DiskArrays]]
deps = ["ConstructionBase", "LRUCache", "Mmap", "OffsetArrays"]
git-tree-sha1 = "9903195c34a488c5265d9a105f39718b7a2b3568"
uuid = "3c3547ce-8d99-4f5e-a174-61eb10b00ae3"
version = "0.4.22"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.EnumX]]
git-tree-sha1 = "c49898e8438c828577f04b92fc9368c388ac783c"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.7"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d0f666deaf8099a7d7ac229a74402ada88898be1"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.9.0+0"

[[deps.Extents]]
git-tree-sha1 = "b309b36a9e02fe7be71270dd8c0fd873625332b4"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.6"

[[deps.FieldMetadata]]
git-tree-sha1 = "c279c6eab9767a3f62685e5276c850512e0a1afd"
uuid = "bf96fef3-21d2-5d20-8afa-0e7d4c32a885"
version = "0.3.1"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FillArrays]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "417289ac840d201005d9ed16789a46defccbe36d"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.18.1"

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStaticArraysExt = "StaticArrays"
    FillArraysStatisticsExt = "Statistics"

    [deps.FillArrays.weakdeps]
    PDMats = "90014a1f-27ba-587c-ab20-58faa44d9150"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.FixedPointNumbers]]
deps = ["Random", "Statistics"]
git-tree-sha1 = "59af96b98217c6ef4ae0dfe065ac7c20831d1a84"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.6"

[[deps.Flatten]]
deps = ["ConstructionBase", "FieldMetadata"]
git-tree-sha1 = "d3541c658c7e452fefba6c933c43842282cdfd3e"
uuid = "4c728ea3-d9ee-5c9a-9642-b6f7d7dc04fa"
version = "0.4.3"

[[deps.Fmt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "38ac3c197b18d75111a531bf7faa83519cdfff02"
uuid = "5dc1e892-f187-50dd-85f3-7dff85c47fc5"
version = "11.1.1+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.GDAL]]
deps = ["CEnum", "GDAL_jll", "NetworkOptions", "PROJ_jll"]
git-tree-sha1 = "020bb41d1b52ef795cc02253209a994c83262fbb"
uuid = "add2ef01-049f-52c4-9ee2-e494f65e021a"
version = "1.13.0"

[[deps.GDAL_jll]]
deps = ["Arrow_jll", "Artifacts", "Blosc_jll", "CompilerSupportLibraries_jll", "Expat_jll", "GEOS_jll", "HDF4_jll", "HDF5_jll", "JLLWrappers", "LERC_jll", "LibCURL_jll", "LibPQ_jll", "Libdl", "Libtiff_jll", "Lz4_jll", "MPIABI_jll", "MPICH_jll", "MPIPreferences", "MPItrampoline_jll", "MicrosoftMPI_jll", "NetCDF_jll", "OpenJpeg_jll", "OpenMPI_jll", "PCRE2_jll", "PROJ_jll", "Qhull_jll", "SQLite_jll", "TOML", "XML2_jll", "XZ_jll", "Zlib_jll", "Zstd_jll", "grok_jll", "libgeotiff_jll", "libpng_jll", "libwebp_jll", "muparser_jll"]
git-tree-sha1 = "53545c56f90636f09e8dcee93259b7e26c9174fa"
uuid = "a7073274-a066-55f0-b90d-d619367d196c"
version = "305.1300.301+0"

[[deps.GEOS_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fdaf62d2354bb398652ee612d487eb19d74468a6"
uuid = "d604d12d-fa86-5845-992e-78dc15976526"
version = "3.14.1+0"

[[deps.GeoFormatTypes]]
git-tree-sha1 = "7528a7956248c723d01a0a9b0447bf254bf4da52"
uuid = "68eda718-8dee-11e9-39e7-89f7f65f511f"
version = "0.4.5"

[[deps.GeoInterface]]
deps = ["DataAPI", "Extents", "GeoFormatTypes"]
git-tree-sha1 = "20f6b13b28c6304104968374f38c24ef71a8ea16"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "1.6.2"

    [deps.GeoInterface.extensions]
    GeoInterfaceMakieExt = ["Makie", "GeometryBasics"]
    GeoInterfaceRecipesBaseExt = "RecipesBase"

    [deps.GeoInterface.weakdeps]
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"

[[deps.GeoJSON]]
deps = ["Extents", "GeoFormatTypes", "GeoInterface", "JSON3", "StructTypes", "Tables"]
git-tree-sha1 = "ce64817b826c36b30493b31be2ce53c55a277835"
uuid = "61d90e0f-e114-555e-ac52-39dfb47a3ef9"
version = "0.8.4"

    [deps.GeoJSON.extensions]
    GeoJSONMakieExt = "Makie"
    GeoJSONRecipesBaseExt = "RecipesBase"

    [deps.GeoJSON.weakdeps]
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"

[[deps.GeometryOpsCore]]
deps = ["DataAPI", "GeoInterface", "StableTasks", "Tables"]
git-tree-sha1 = "8f32a94cf3d80a716cae6025af6cbc4e68421da5"
uuid = "05efe853-fabf-41c8-927e-7063c8b9f013"
version = "0.1.12"

[[deps.Giflib_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a3efbbc027441271444dcd0c0a46f2d119dc4329"
uuid = "59f7168a-df46-5410-90c8-f2779963d0ec"
version = "6.1.3+0"

[[deps.HDF4_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Zlib_jll", "libaec_jll"]
git-tree-sha1 = "ea9eff9cfef5f45b771096e5c2de3de0eab937c3"
uuid = "818ab7a1-5177-5f44-ba99-6e845030c6cb"
version = "4.3.2+0"

[[deps.HDF5_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LibCURL_jll", "Libdl", "MPIABI_jll", "MPICH_jll", "MPIPreferences", "MPItrampoline_jll", "MicrosoftMPI_jll", "OpenMPI_jll", "OpenSSL_jll", "TOML", "Zlib_jll", "aws_c_s3_jll", "dlfcn_win32_jll", "libaec_jll", "mpif_jll"]
git-tree-sha1 = "8dd4e7d13617134fccede29e5b576380ab5d9199"
uuid = "0234f1f7-429e-5d53-9886-15a909be8d59"
version = "2.2.1+0"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "Dates", "EnumX", "PrecompileTools", "Random", "Reseau", "SHA", "URIs", "UUIDs", "Zlib_jll"]
git-tree-sha1 = "b0ff6627f1308bc1691528aac3b70ac3abd1d598"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "2.6.7"

[[deps.Hwloc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XML2_jll", "Xorg_libpciaccess_jll"]
git-tree-sha1 = "c35847ca5b4997fc8418836354a56c459bcf48d8"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.14.0+0"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "d1a86724f81bcd184a38fd284ce183ec067d71a0"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "1.0.0"

[[deps.ICU_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b3d8be712fbf9237935bde0ce9b5a736ae38fc34"
uuid = "a51ab1cf-af8e-5615-a023-bc2c838bba6b"
version = "76.2.0+0"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

[[deps.ImageCore]]
deps = ["ColorVectorSpace", "Colors", "FixedPointNumbers", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "PrecompileTools", "Reexport"]
git-tree-sha1 = "8c193230235bbcee22c8066b0374f63b5683c2d3"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.10.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.Interfaces]]
git-tree-sha1 = "331ff37738aea1a3cf841ddf085442f31b84324f"
uuid = "85a1e053-f937-4924-92a5-1367d23b7b87"
version = "0.3.2"

[[deps.IntervalSets]]
git-tree-sha1 = "79d6bd28c8d9bccc2229784f1bd637689b256377"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.14"
weakdeps = ["Random", "RecipesBase", "Statistics"]

    [deps.IntervalSets.extensions]
    IntervalSetsRandomExt = "Random"
    IntervalSetsRecipesBaseExt = "RecipesBase"
    IntervalSetsStatisticsExt = "Statistics"

[[deps.InvertedIndices]]
git-tree-sha1 = "6da3c4316095de0f5ee2ebd875df8721e7e0bdbe"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.1"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7204148362dafe5fe6a273f855b8ccbe4df8173e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.8.0"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "PrecompileTools", "StructTypes", "UUIDs"]
git-tree-sha1 = "411eccfe8aba0814ffa0fdf4860913ed09c34975"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.14.3"

    [deps.JSON3.extensions]
    JSON3ArrowExt = ["ArrowTypes"]

    [deps.JSON3.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "037babc10853eeb8e585418922246cb97b8e5b74"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.2.0+1"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.Kerberos_krb5_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0f2899fdadaab4b8f57db558ba21bdb4fb52f1f0"
uuid = "b39eb1a6-c29a-53d7-8c32-632cd16f18da"
version = "1.21.3+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "39bca05343661c347aae0bca57a5994a0bf4f08d"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.2.0+0"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e5b100780d4d30d63b4618d7930d48af409c1772"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "23.1.1+0"

[[deps.LRUCache]]
git-tree-sha1 = "5519b95a490ff5fe629c4a7aa3b3dfc9160498b3"
uuid = "8ac3fa9e-de4c-5943-b1dc-09c6b5f20637"
version = "1.6.2"
weakdeps = ["Serialization"]

    [deps.LRUCache.extensions]
    SerializationExt = ["Serialization"]

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"
version = "1.11.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.15.0+0"

[[deps.LibGit2]]
deps = ["LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.9.0+0"

[[deps.LibPQ_jll]]
deps = ["Artifacts", "ICU_jll", "JLLWrappers", "Kerberos_krb5_jll", "Libdl", "OpenSSL_jll", "Zstd_jll"]
git-tree-sha1 = "c692057e05ba6da348bc45d5dab8c7a2c88da518"
uuid = "08be9ffa-1c94-5ee5-a977-46a84ec9b350"
version = "16.14.0+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "OpenSSL_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.3+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "d36c21b9e7c172a44a10484125024495e2625ac0"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.7.1+1"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "aebd334d06cee9f24cea70bd19a39749daf73881"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.3+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.LittleCMS_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll"]
git-tree-sha1 = "38928f7999753af13d4e13966ae15958ff3a917a"
uuid = "d3a379c0-f9a3-5b72-a4c0-6bf4d2e8af0f"
version = "2.19.1+0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.Lz4_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "191686b1ac1ea9c89fc52e996ad15d1d241d1e33"
uuid = "5ced341a-0733-55b8-9ab6-a4889d929147"
version = "1.10.1+0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MPIABI_jll]]
deps = ["Artifacts", "Hwloc_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIPreferences", "TOML"]
git-tree-sha1 = "c0ab44a826d1a8219715078f79c265a11292db86"
uuid = "b5ada748-db0f-5fc0-8972-9331c762740c"
version = "1.0.0+0"

[[deps.MPICH_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "Libdl", "MPIPreferences", "TOML"]
git-tree-sha1 = "07dbec8aab01696edc0151a401a6cdfe95b9b885"
uuid = "7cb0a576-ebde-5e09-9194-50597f1243b4"
version = "5.0.1+0"

[[deps.MPIPreferences]]
deps = ["Libdl", "Preferences"]
git-tree-sha1 = "8e98d5d80b87403c311fd51e8455d4546ba7a5f8"
uuid = "3da0fdf6-3ccc-4f1b-acd9-58baa6c99267"
version = "0.1.12"

[[deps.MPItrampoline_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIPreferences", "TOML"]
git-tree-sha1 = "675df097f8eeb28998b2cfe3b25655af73d5f7df"
uuid = "f1f71cc9-e9ae-5b93-9b94-4fe0e1ad3748"
version = "5.5.6+0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.MappedArrays]]
git-tree-sha1 = "0ee4497a4e80dbd29c058fcee6493f5219556f40"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.3"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MicrosoftMPI_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bc95bf4149bf535c09602e3acdf950d9b4376227"
uuid = "9237b28f-5490-5468-be7b-bb81f5f5e6cf"
version = "10.1.4+3"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2025.11.4"

[[deps.NCDatasets]]
deps = ["CFTime", "CommonDataModel", "DataStructures", "Dates", "DiskArrays", "NetCDF_jll", "NetworkOptions", "Printf"]
git-tree-sha1 = "5eb7747d10437f5acb2675c1f865ffa0353f3f9c"
uuid = "85f8d34a-cbdd-5861-8df4-14fed0d494ab"
version = "0.14.15"

    [deps.NCDatasets.extensions]
    NCDatasetsMPIExt = "MPI"

    [deps.NCDatasets.weakdeps]
    MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"

[[deps.NetCDF_jll]]
deps = ["Artifacts", "Blosc_jll", "Bzip2_jll", "HDF5_jll", "JLLWrappers", "LazyArtifacts", "LibCURL_jll", "Libdl", "MPIABI_jll", "MPICH_jll", "MPIPreferences", "MPItrampoline_jll", "MicrosoftMPI_jll", "OpenMPI_jll", "TOML", "XML2_jll", "Zlib_jll", "Zstd_jll", "libaec_jll", "libzip_jll"]
git-tree-sha1 = "bbd7ae15594503021b388a1090cca6ea431e0a8f"
uuid = "7243133f-43d8-5620-bbf4-c2c921802cf3"
version = "401.1000.101+0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.OffsetArrays]]
git-tree-sha1 = "117432e406b5c023f665fa73dc26e79ec3630151"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.17.0"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenJpeg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libtiff_jll", "LittleCMS_jll", "libpng_jll"]
git-tree-sha1 = "215a6666fee6d6b3a6e75f2cc22cb767e2dd393a"
uuid = "643b3616-a352-519d-856d-80112ee9badc"
version = "2.5.5+0"

[[deps.OpenMPI_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIPreferences", "TOML", "Zlib_jll"]
git-tree-sha1 = "6d6c0ca4824268c1a7dca1f4721c535ac63d9074"
uuid = "fe0851c0-eecd-5654-98d4-656369965a5c"
version = "5.0.11+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.6+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "b079a6affebde167dad8ffe0d670b53917fbcb68"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "2.0.3"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.44.0+1"

[[deps.PROJ_jll]]
deps = ["Artifacts", "JLLWrappers", "LibCURL_jll", "Libdl", "Libtiff_jll", "SQLite_jll"]
git-tree-sha1 = "fbfbc14815c5f5375abc971321aa5f468e715a38"
uuid = "58948b4f-47e0-5654-a9ad-f609743f8632"
version = "902.800.100+0"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "0fac6313486baae819364c52b4f483450a9d793f"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.12"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "ba0dc8a8a67cacac4842631f960c046e4e563675"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.8"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.12.1"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "e189d0623e7ce9c37389bac17e80aac3b0302e75"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.83"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "edbeefc7a4889f528644251bdb5fc9ab5348bc2c"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.3.4"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "5005266de4bfe50e53ff44a5cb5c540b6e47a254"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.6.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "fbb92c6c56b34e1a2c4c36058f68f332bec840e7"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.11.0"

[[deps.Proj]]
deps = ["CEnum", "CoordinateTransformations", "GeoFormatTypes", "GeoInterface", "NetworkOptions", "PROJ_jll"]
git-tree-sha1 = "61188669db4f5b400173e4ec60da8bcb72d6e749"
uuid = "c94c279d-25a6-4763-9509-64d165bea63e"
version = "1.9.0"

[[deps.Qhull_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c69da20496799bbdd56c15ecf5d80a5e6cbcc904"
uuid = "784f63db-0788-585a-bace-daefebcd302b"
version = "10008.0.1004+0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Rasters]]
deps = ["Adapt", "ColorTypes", "CommonDataModel", "ConstructionBase", "Dates", "DimensionalData", "DiskArrays", "Extents", "FillArrays", "Flatten", "GeoFormatTypes", "GeoInterface", "GeometryOpsCore", "LinearAlgebra", "Missings", "Mmap", "OffsetArrays", "ProgressMeter", "RecipesBase", "Reexport", "Setfield", "Statistics"]
git-tree-sha1 = "8e300b3139f30c7dafc085f10c1fa8c13efc5673"
uuid = "a3a2b9e3-a471-40c9-b274-f788e487c689"
version = "0.15.0"

    [deps.Rasters.extensions]
    RastersArchGDALExt = "ArchGDAL"
    RastersCoordinateTransformationsExt = "CoordinateTransformations"
    RastersGRIBDatasetsExt = "GRIBDatasets"
    RastersMakieExt = "Makie"
    RastersNCDatasetsExt = "NCDatasets"
    RastersProjExt = "Proj"
    RastersRasterDataSourcesExt = "RasterDataSources"
    RastersStatsBaseExt = "StatsBase"
    RastersZarrDatasetsExt = "ZarrDatasets"

    [deps.Rasters.weakdeps]
    ArchGDAL = "c9ce4bd3-c3d5-55b8-8973-c0e20141b8c3"
    CoordinateTransformations = "150eb455-5306-5404-9cee-2592286d6298"
    GRIBDatasets = "82be9cdb-ee19-4151-bdb3-b400788d9abc"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    NCDatasets = "85f8d34a-cbdd-5861-8df4-14fed0d494ab"
    Proj = "c94c279d-25a6-4763-9509-64d165bea63e"
    RasterDataSources = "3cb90ccd-e1b6-4867-9617-4276c8b2ca36"
    StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
    ZarrDatasets = "519a4cdf-1362-424a-9ea1-b1d782dbb24b"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "0c0dcffc464cda2ff33fc8ffc1dd1bdd53cd98be"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.4.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.Reseau]]
deps = ["NetworkOptions", "OpenSSL_jll", "PrecompileTools", "Random", "SHA"]
git-tree-sha1 = "aaee74fab545e9af4b21d10c2203c93c636c4ae0"
uuid = "802f3686-a58f-41ce-bb0c-3c43c75bba36"
version = "1.4.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SQLite_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll", "dlfcn_win32_jll"]
git-tree-sha1 = "324744e40b84e6dc2cfaa4122ce969a083c40a6f"
uuid = "76ed43ae-9a5d-5a62-8c75-30186b810ce8"
version = "3.53.2+0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "c5391c6ace3bc430ca630251d02ea9687169ca68"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.2"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.StableTasks]]
git-tree-sha1 = "c4f6610f85cb965bee5bfafa64cbeeda55a4e0b2"
uuid = "91464d47-22a1-43fe-8b7f-2d57ee82463f"
version = "0.1.7"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "be1cf4eb0ac528d96f5115b4ed80c26a8d8ae621"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.2"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "de349d5585559b692f518b6d3fc7c179d64b2364"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.23"

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

    [deps.StaticArrays.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6ab403037779dae8c514bad259f32a447262455a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.4"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "e2b53ce13a53367e96601081e33d34746b571bad"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.5"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "159331b30e94d7b11379037feeb9b690950cace8"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.11.0"

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
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "a94d9bdda1b7bed0046cea645639ab3f62196fac"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.14.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.Thrift_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "boost_jll"]
git-tree-sha1 = "4d16a4b4eab80099c19342b10d0bdb252c39bea6"
uuid = "e0b8ae26-5307-5830-91fd-398402328850"
version = "0.21.1+0"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.URIs]]
git-tree-sha1 = "908fec9df6c5de98548ead82a468c95ccf6cd263"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.7.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "80d3930c6347cfce7ccf96bd3bafdf079d9c0390"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.9+0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e52eca002a11c30a858185efdfb15311e1c7a6bf"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.8.4+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "ce91b54a5f90c4f27df6950706234b34e49cf79e"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.14+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aa1261ebbac3ccc8d16558ae6799524c450ed16b"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.13+0"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "52858d64353db33a56e13c341d7bf44cd0d7b309"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.6+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "1a4a26870bf1e5d26cd585e38038d399d7e65706"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.8+0"

[[deps.Xorg_libpciaccess_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "58972370b81423fc546c56a60ed1a009450177c3"
uuid = "a65dc6b1-eb27-53a1-bb3e-dea574b5389e"
version = "0.19.0+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXau_jll", "Xorg_libXdmcp_jll"]
git-tree-sha1 = "bfcaf7ec088eaba362093393fe11aa141fa15422"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.1+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a63799ff68005991f9d9491b6e95bd3478d783cb"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.6.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.3.1+2"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "446b23e73536f84e8037f5dce465e92275f6a308"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.7+1"

[[deps.aws_c_auth_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_cal_jll", "aws_c_http_jll", "aws_c_sdkutils_jll"]
git-tree-sha1 = "8cab83c96af80a1be968251ce1a0548a7545484d"
uuid = "2b3700d1-4306-52e2-a478-c162f0c514be"
version = "0.9.6+0"

[[deps.aws_c_cal_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_common_jll"]
git-tree-sha1 = "22c0f42f4a1f0dc5dcfa8fd267c4ac407c455e7a"
uuid = "70f11efc-bab2-57f1-b0f3-22aad4e67c4b"
version = "0.9.13+0"

[[deps.aws_c_common_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a759cb9bf456ad792cc7898a81ae333cce9ef02a"
uuid = "73048d1d-b8c4-5092-a58d-866c5e8d1e50"
version = "0.12.6+0"

[[deps.aws_c_compression_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_common_jll"]
git-tree-sha1 = "7910c72f45f44afd297c39fe43b99c56d5ed22ec"
uuid = "73a04cd5-f3d7-5bac-9290-e8adb709f224"
version = "0.3.2+0"

[[deps.aws_c_http_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_compression_jll", "aws_c_io_jll"]
git-tree-sha1 = "3fb8685778068de502c72fec5dd8075e037cee15"
uuid = "3254fc65-9028-534d-aa9d-d76d128babc6"
version = "0.10.15+0"

[[deps.aws_c_io_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_cal_jll", "aws_c_common_jll", "s2n_tls_jll"]
git-tree-sha1 = "7e481d474b2087ee8bbf55b81bf9119f21e396d9"
uuid = "13c41daa-f319-5298-b5eb-5754e0170d52"
version = "0.26.3+0"

[[deps.aws_c_s3_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_auth_jll", "aws_c_common_jll", "aws_c_http_jll", "aws_checksums_jll", "s2n_tls_jll"]
git-tree-sha1 = "3e9917ab25114feba657e71be41cad068b9f6595"
uuid = "bd1f34fb-993f-5903-a121-aaf302eed6d4"
version = "0.11.5+0"

[[deps.aws_c_sdkutils_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_common_jll"]
git-tree-sha1 = "c43dfba2c1ab9ea9f02f2c80e86fa16f6460244e"
uuid = "1282aa60-004d-510b-9f52-12498d409daa"
version = "0.2.4+1"

[[deps.aws_checksums_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "aws_c_common_jll"]
git-tree-sha1 = "2570c8e23f4771a087b12a47edcaaa670ac05a01"
uuid = "b2a88e68-78e7-5e94-8c20-c02986ec140e"
version = "0.2.10+0"

[[deps.boost_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "25fb6ecbb784a45f8ea74584fa631a9e85393dd0"
uuid = "28df3c45-c428-5900-9ff8-a3135698ca75"
version = "1.87.0+0"

[[deps.brotli_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "46fda47f4215c957bc92fd5fbb5ad04fee1e3743"
uuid = "4611771a-a7d2-5e23-8d00-b1becdba1aae"
version = "1.2.0+0"

[[deps.dlfcn_win32_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e141d67ffe550eadfb5af1bdbdaf138031e4805f"
uuid = "c4b69c83-5512-53e3-94e6-de98773c479f"
version = "1.4.2+0"

[[deps.grok_jll]]
deps = ["Artifacts", "Fmt_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "LittleCMS_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "cd143eb1444b3512c2a0757fab41461808f5ae2a"
uuid = "0cd81ddb-c824-5a44-8fef-56db1943f23c"
version = "20.3.7+0"

[[deps.libaec_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "60f4792734488db6f42e2c7699f1d4594780bd03"
uuid = "477f73a3-ac25-53e9-8cc3-50b2fa2566f0"
version = "1.1.7+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.libgeotiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LibCURL_jll", "Libdl", "Libtiff_jll", "PROJ_jll", "Zlib_jll"]
git-tree-sha1 = "cbdbc9ae1127f81cb653a4f7545d89f8db2a17a7"
uuid = "06c338fa-64ff-565b-ac2f-249532af990e"
version = "100.702.400+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "1fcd6cf05d23adab0b5ffc496d020537215751dc"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.59+1"

[[deps.libwebp_jll]]
deps = ["Artifacts", "Giflib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libglvnd_jll", "Libtiff_jll", "libpng_jll"]
git-tree-sha1 = "52d3b9475133c3bc8c0a7f90f18bfc8cdb5a443a"
uuid = "c5f90fcd-3b7e-5836-afba-fc50a0988cb2"
version = "1.6.1+0"

[[deps.libzip_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "OpenSSL_jll", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "363a1c43b8cb92e7b3ff7f504ef9a0a83c548e97"
uuid = "337d8026-41b4-5cde-a456-74a10e5b31d1"
version = "1.11.4+0"

[[deps.mpif_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIABI_jll", "MPICH_jll", "MPIPreferences", "MPItrampoline_jll", "MicrosoftMPI_jll", "OpenMPI_jll", "TOML"]
git-tree-sha1 = "a06fcd368cfe6fe2c0eb7b63320d4d27ddcd010d"
uuid = "9aeb927a-4695-514f-a259-621a69f20ec0"
version = "1.0.0+0"

[[deps.muparser_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "70ee0f42a44ef6e16298e5bfc8b6e311d08e49bb"
uuid = "888e69b1-873b-5047-a2fc-24c07cbe9dc8"
version = "2.3.5+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.64.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.7.0+0"

[[deps.rapidjson_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ea9bafbf42a1adba0ae73aa972bd42bce38578b5"
uuid = "17fc61dc-9d6f-534d-91bb-5213c1b476d9"
version = "1.1.1+0"

[[deps.s2n_tls_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f3a7831c8a44767ff9e36d41bb1f7b576bbce81c"
uuid = "cddc5d3d-934d-5d3a-9747-62fc12ea3f48"
version = "1.7.8+0"

[[deps.snappy_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ca88363dd41d2547f52118287dd34dbbc14f3eb7"
uuid = "fe1e1685-f7be-5f59-ac9f-4ca204017dfd"
version = "1.2.3+0"
"""

# ╔═╡ Cell order:
# ╠═abfe2d6a-d614-11f1-8620-49cff9915e07
# ╠═5dcf2f5d-da81-46c0-b57f-876e8b19d1b1
# ╟─6108da4c-269b-4236-88b0-eb07079a5496
# ╟─7fce0c85-096e-444b-9f38-d9e0b11fb1f5
# ╟─d9d5a237-935c-4cab-8284-c573d17eb46b
# ╟─e7b3bd41-a327-47ac-9dfb-3863f6a8dc59
# ╠═228e3f02-a9cd-4561-bb4e-8d40f919e007
# ╟─5f3a2a4c-4832-496f-b4c1-2bca8d6886a4
# ╠═6899d54e-8701-4468-b4e1-490d351d9a45
# ╠═9ae179b5-bb64-4598-af9b-ff05529fcf07
# ╟─eeb4f528-87bd-4bb9-9ba5-c66c666863d5
# ╠═c0b1c13e-8f70-4120-9b47-0fe26aa43fae
# ╟─73b234f4-2224-4e06-877c-1f4a0c425131
# ╟─9c341829-14bb-4617-88f2-3f3bf5afcf37
# ╟─3e587fe0-6ca2-4ff0-b345-7b8205042ee6
# ╟─b0b1c319-ed96-44e2-82c8-c4489abe2882
# ╟─fc2a3658-8686-48bf-8be9-3a11818cc618
# ╟─525b6d1e-2ff7-42f0-a8d6-098d14906d26
# ╟─740c4c2f-6868-40d5-bb54-c434773d3e95
# ╟─0bf1b6fe-b889-4b7f-b3fb-42eb150d8066
# ╟─fbbafc2f-4dbf-4002-83a7-5c047fb3df2a
# ╟─130eaf56-954e-462c-8561-2deee792fc29
# ╟─dc84935f-3609-4a4c-9a14-baf7f37c6d4a
# ╟─e2405c1f-4639-44bf-8af0-59bcd0fe1ee1
# ╟─c5e23dd3-529d-40a1-bb5d-199e95507ea7
# ╟─28694193-3a8c-4369-88d8-cf5f91518eca
# ╟─284ccf74-82c1-4dcf-985d-005453a7b553
# ╟─12c42c71-3653-4ce0-8096-b53bb2d3cede
# ╟─a482fd86-1b68-4802-a756-f7a6ef75c8ae
# ╟─16e44723-c84d-4f12-880e-d247652c2727
# ╟─55294331-d57f-471d-af67-56d4e3dc66f0
# ╟─df18ebdf-55ac-4660-a62a-982ef06a35ee
# ╠═1eaf7164-e3f1-4bb1-8e00-6eedc9928b51
# ╠═5e09e286-e852-492c-8b84-af3b903ebc70
# ╠═b8001e10-2687-4f86-9358-20cc8e52d190
# ╠═95f24927-75a6-4632-8835-77064af29c97
# ╟─9fc9bce9-2bc4-4fde-bc49-ee6c7765a724
# ╟─ea8fdf7b-a9ae-4978-9fcd-aacb69207467
# ╟─b5567c07-e317-4986-b6d6-25d40a109b71
# ╟─e76fccba-1519-494a-838a-e7bc89d70976
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
