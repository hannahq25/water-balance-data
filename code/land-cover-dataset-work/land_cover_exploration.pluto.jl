### A Pluto.jl notebook ###
# v0.20.0

using Markdown
using InteractiveUtils

# ╔═╡ e481b52e-43d2-4d81-a479-2c8ab50be103
#VSCODE-MARKDOWN
md"""
# Exploratory Data Analysis on Land Cover Data
"""

# ╔═╡ 88a6380c-378e-4608-876a-36a9a80be835
begin
    #change this to true to resave figures
    savefigures = true
end

# ╔═╡ a609ad42-48ad-4c37-9e24-ccbf58bf7717
using CSV, DataFrames, Plots, StatsPlots, Measures

# ╔═╡ e5494703-d48f-43c5-a8e6-1b4dda9992df
using StatsBase

# ╔═╡ 84d3d0c7-e28b-4fa6-bed9-b7aefba00d51
df_lc = CSV.read("land_cover_annual_with_CN.csv", DataFrame)

# ╔═╡ 91b47aad-d213-45f8-8eec-86c7c604c0cf
dfg = groupby(df_lc, :gage)

# ╔═╡ 8730dbf3-b041-4994-b94a-3ab230006da1
function plotVariableByWatershed(variable, variableName)
    gage_names = Dict("02205000" => "Wildcat Creek",
			"02205865" => "Sweetwater Creek",
			"02206500" => "Yellow River near Snellville",
			"02207120" => "Yellow River near Lithonia",
			"02207185" => "No Business Creek",
			"02207385" => "Big Haynes Creek",
			"02207400" => "Brushy Fork Creek",
			"02208150" => "Alcovy River",
			"02217274" => "Wheeler Creek",
			"02218565" => "Apalachee River",
			"02334480" => "Richland Creek",
			"02334578" => "Level Creek",
			"02334885" => "Suwanee Creek",
			"02335350" => "Crooked Creek",
			"02336030" => "North Fork Peachtree Creek")
    # plots = []
    # for df in dfg
    #     push!(plots, plot(df.year, df[!, variable], label=:none,
	#    		title=get(gage_names, "0" * string(df.gage[1]), ""), 
	# 		titlefontsize=12, tickfontsize=10, 
	# 		left_margin=15mm, right_margin=10mm))
    # end

	# l = @layout [a{0.05h}; grid(8, 2)]
	# p_title = plot(title = "$variableName Across Watersheds", framestyle = nothing, 
    #            showaxis = false, xticks = false, yticks = false, bottom_margin = -30mm)
	# plot(p_title, plots..., layout=l, size=(800, 2400))

	p1 = plot()
	basin_data = []
	for df in dfg
		push!(basin_data, df[!, variable])
        plot!(df.year, df[!, variable], color=:gray, label=:none)
			# legend=:outerright,
    end
	plot!([], [], color=:gray, label="Individual basins")
	plot!(dfg[1].year, mean(basin_data), linewidth=3,
		label="Mean of 15 basins", 
		ylabel=variableName, ylabelfontsize=9,
		xtickfontsize=8, ytickfontsize=8, size=(400,300))
end

# ╔═╡ 3010385e-60b9-459f-a652-7a2430d127ed
function plotVariableByWatershedSave(variable, variableName)
    plotVariableByWatershed(variable, variableName)
	if savefigures
        var_filename = replace("$(variable)", "/" => "")
        savefig("../../figures/land-cover/$(var_filename)ByWatershed.png")
    end
end

# ╔═╡ 245fe526-b4de-43d6-b6e4-88620c86ab25
plotVariableByWatershedSave(:FctImp_mean, "Mean Fractional Impervious Area")


# ╔═╡ 6b2b6b64-0b15-44c4-bb9f-5727d96ab37d
plotVariableByWatershedSave(:CN_mean, "Mean Curve Number")

# ╔═╡ c582a8a9-b39b-42d0-8614-d23862e2500b
plotVariableByWatershedSave(:DeciduousForest_percent, "% Deciduous Forest Land Cover")

# ╔═╡ 13a582d8-2ab7-4194-99c2-734ec29188d5
plotVariableByWatershedSave(:OpenWater_percent, "% Open Water")

# ╔═╡ ba569976-d716-4863-a5d2-6cdafdc66f02
plotVariableByWatershedSave(Symbol("Grassland/Herbaceous_percent"), "% Grassland/Herbaceous")

# ╔═╡ 8da0c6aa-78f0-4034-966e-047de6591cd7
plotVariableByWatershedSave(:DevelopedLowIntensity_percent, "% Low Intensity Developed Land")

# ╔═╡ c6a11ad2-a06b-47f0-bd9f-a696a7f3b166
plotVariableByWatershedSave(:DevelopedMediumIntensity_percent, "% Medium Intensity Developed Land")

# ╔═╡ ccc16025-a4d3-43c2-b5ac-a158b1b9b9ea
plotVariableByWatershedSave(:DevelopedHighIntensity_percent, "% High Intensity Developed Land")

# ╔═╡ 0c1b8bfa-865e-45ca-adc9-077e1390ce79
plotVariableByWatershedSave(:BarrenLand_percent, "% Barren Land")

# ╔═╡ Cell order:
# ╠═e481b52e-43d2-4d81-a479-2c8ab50be103
# ╠═88a6380c-378e-4608-876a-36a9a80be835
# ╠═a609ad42-48ad-4c37-9e24-ccbf58bf7717
# ╠═e5494703-d48f-43c5-a8e6-1b4dda9992df
# ╠═84d3d0c7-e28b-4fa6-bed9-b7aefba00d51
# ╠═91b47aad-d213-45f8-8eec-86c7c604c0cf
# ╠═8730dbf3-b041-4994-b94a-3ab230006da1
# ╠═3010385e-60b9-459f-a652-7a2430d127ed
# ╠═245fe526-b4de-43d6-b6e4-88620c86ab25
# ╠═6b2b6b64-0b15-44c4-bb9f-5727d96ab37d
# ╠═c582a8a9-b39b-42d0-8614-d23862e2500b
# ╠═13a582d8-2ab7-4194-99c2-734ec29188d5
# ╠═ba569976-d716-4863-a5d2-6cdafdc66f02
# ╠═8da0c6aa-78f0-4034-966e-047de6591cd7
# ╠═c6a11ad2-a06b-47f0-bd9f-a696a7f3b166
# ╠═ccc16025-a4d3-43c2-b5ac-a158b1b9b9ea
# ╠═0c1b8bfa-865e-45ca-adc9-077e1390ce79
