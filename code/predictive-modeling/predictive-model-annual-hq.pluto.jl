### A Pluto.jl notebook ###
# v0.20.0

using Markdown
using InteractiveUtils

# ╔═╡ 83e462e4-9e7c-4783-bd71-ccf2f36b5bbe
using CSV, DataFrames, Plots, Plots.Measures, StatsPlots, Statistics, Distributions

# ╔═╡ 99e0782c-3f66-4226-8047-2680e7e9f6a4
#VSCODE-MARKDOWN
md"""
# Load and Combine Data
## Helper Functions
"""

# ╔═╡ 2d26399d-a0da-47e3-9bfd-067794d9dc55
function normalize(df)
    transform(df, names(df, Number) .=> (x -> (x .- mean(x)) ./ std(x)), renamecols=false)
end

# ╔═╡ 80a6c02d-bfae-48e5-9054-6ba02b92f914
#VSCODE-MARKDOWN
md"""
## Annual Data
"""

# ╔═╡ e1847a91-5ef8-4e52-a43c-73d7415df1eb
begin
    df_climate_annual = CSV.read("../climate-dataset-work/gridmet_watershed_annual.csv", DataFrame)
    rename!(df_climate_annual, :usgs_gage => :gage)
end

# ╔═╡ 7daff94b-1cb8-4c01-9428-8f9c20441ff6
 df_land_cover = CSV.read("../land-cover-dataset-work/land_cover_annual_with_CN.csv", DataFrame)

# ╔═╡ 60180d48-a325-4790-a4af-ed5e851411b4
df_water_bal_annual = CSV.read("../water-balance-dataset-work/water_balance_annual.csv", DataFrame)

# ╔═╡ d8955e06-2131-45ed-9b22-ffc7f52d416b
df_gage_annual = CSV.read("../gage-usgs/gage_annual.csv", DataFrame)

# ╔═╡ 7a62fe8d-b0fc-4fcf-b895-eae973246174
df_annual = innerjoin(df_climate_annual, df_land_cover, df_water_bal_annual, df_gage_annual, on = [:year, :gage])

# ╔═╡ d0b351cd-7472-482c-8cf1-4032b36a9409
begin
    colnames_max = [:year, :gage, :pr_max, :tmmx_max, :FctImp_maximum, 
    :CN_maximum, :runoff_max, :max_discharge, :peak_runoff]

    df_annual_maxs_by_year = combine(
        groupby(select(df_annual, colnames_max), :year), 
        colnames_max[3:end] .=> mean, 
        renamecols=false)
end

# ╔═╡ 921f6652-ef6e-4493-87e6-5e4983a8b1fc
begin
    @df normalize(df_annual_maxs_by_year) corrplot(cols(2:5), size=(600,600))
    savefig("../../hq-figures/CorrelationPlotMaxes.png")
end

# ╔═╡ 7ca5d69e-ebfc-4865-8dcb-acd81d4c2cf8
begin
    colnames_mean = [:year, :gage, :pr_mean, :tmmx_mean, :FctImp_mean, :CN_mean, 
    :runoff_avg, :mean_discharge, :total_runoff]
    
    df_annual_means_by_year = combine(
        groupby(select(df_annual, colnames_mean), :year), 
        colnames_mean[3:end] .=> mean, 
        renamecols=false)
end

# ╔═╡ 9016192f-02ca-4c90-a4b3-ad331af5b3c6
begin
    @df normalize(df_annual_means_by_year) corrplot(cols(2:5), size=(600,600))
    savefig("../../hq-figures/CorrelationPlotMeans.png")
end

# ╔═╡ 1d6f33a1-2e53-4f51-8157-1c1623975721
@df df_annual_means_by_year plot(:year, :total_runoff)

# ╔═╡ Cell order:
# ╠═83e462e4-9e7c-4783-bd71-ccf2f36b5bbe
# ╠═99e0782c-3f66-4226-8047-2680e7e9f6a4
# ╠═2d26399d-a0da-47e3-9bfd-067794d9dc55
# ╠═80a6c02d-bfae-48e5-9054-6ba02b92f914
# ╠═e1847a91-5ef8-4e52-a43c-73d7415df1eb
# ╠═7daff94b-1cb8-4c01-9428-8f9c20441ff6
# ╠═60180d48-a325-4790-a4af-ed5e851411b4
# ╠═d8955e06-2131-45ed-9b22-ffc7f52d416b
# ╠═7a62fe8d-b0fc-4fcf-b895-eae973246174
# ╠═d0b351cd-7472-482c-8cf1-4032b36a9409
# ╠═921f6652-ef6e-4493-87e6-5e4983a8b1fc
# ╠═7ca5d69e-ebfc-4865-8dcb-acd81d4c2cf8
# ╠═9016192f-02ca-4c90-a4b3-ad331af5b3c6
# ╠═1d6f33a1-2e53-4f51-8157-1c1623975721
