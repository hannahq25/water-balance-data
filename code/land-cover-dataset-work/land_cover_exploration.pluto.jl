### A Pluto.jl notebook ###
# v0.20.0

using Markdown
using InteractiveUtils

# ╔═╡ e481b52e-43d2-4d81-a479-2c8ab50be103
#VSCODE-MARKDOWN
md"""
# Exploratory Data Analysis on Land Cover Data
"""

# ╔═╡ a609ad42-48ad-4c37-9e24-ccbf58bf7717
using CSV, DataFrames, Plots, StatsPlots, Measures

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
    plots = []
	
	### Square plots
	# for df in dfg
    #    push!(plots, plot(df.year, df[!, variable], 
	#    	title=get(gage_names, df.gage[1], ""), titlefontsize=8, label=:none))
    # end

    # plot(plots..., plot_title="$variableName by Watershed", 
	# 	layout=(4,4), size=(800,800))

	### Tall plots
    for df in dfg
        push!(plots, plot(df.year, df[!, variable], label=:none,
	   		title=get(gage_names, "0" * string(df.gage[1]), ""), 
			titlefontsize=12, tickfontsize=10, 
			left_margin=15mm, right_margin=10mm))
    end

	l = @layout [a{0.05h}; grid(8, 2)]
	p_title = plot(title = "$variableName by Watershed", framestyle = nothing, 
               showaxis = false, xticks = false, yticks = false, bottom_margin = -30mm)
	plot(p_title, plots..., layout=l, size=(800, 2400))
end

# ╔═╡ 3010385e-60b9-459f-a652-7a2430d127ed
function plotVariableByWatershedSave(variable, variableName)
    plotVariableByWatershed(variable, variableName)
	var_filename = replace("$(variable)", "/" => "")
    savefig("../../figures/$(var_filename)ByWatershed.png")
end

# ╔═╡ 245fe526-b4de-43d6-b6e4-88620c86ab25
plotVariableByWatershedSave(:FctImp_mean, "Mean Fractional Impervious Area")

# ╔═╡ 6b2b6b64-0b15-44c4-bb9f-5727d96ab37d
plotVariableByWatershedSave(:CN_mean, "Mean Curve Number")

# ╔═╡ c582a8a9-b39b-42d0-8614-d23862e2500b
plotVariableByWatershedSave(:DeciduousForest_percent, "Percentage of Deciduous Forest Land Cover")

# ╔═╡ 13a582d8-2ab7-4194-99c2-734ec29188d5
plotVariableByWatershedSave(:OpenWater_percent, "Percentage of Open Water")

# ╔═╡ ba569976-d716-4863-a5d2-6cdafdc66f02
plotVariableByWatershedSave(Symbol("Grassland/Herbaceous_percent"), "Percentage of Grassland/Herbaceous")

# ╔═╡ 8da0c6aa-78f0-4034-966e-047de6591cd7
plotVariableByWatershedSave(:DevelopedLowIntensity_percent, "Percentage of Low Intensity Developed Land")

# ╔═╡ c6a11ad2-a06b-47f0-bd9f-a696a7f3b166
plotVariableByWatershedSave(:DevelopedMediumIntensity_percent, "Percentage of Medium Intensity Developed Land")

# ╔═╡ ccc16025-a4d3-43c2-b5ac-a158b1b9b9ea
plotVariableByWatershedSave(:DevelopedHighIntensity_percent, "Percentage of High Intensity Developed Land")

# ╔═╡ 0c1b8bfa-865e-45ca-adc9-077e1390ce79
plotVariableByWatershedSave(:BarrenLand_percent, "Percentage of Barren Land")

# ╔═╡ 91f8b834-3a19-4157-b38a-67b616c968fe
begin
    difference(v) = v[end] - v[begin]
    diffs = combine(dfg, [:FctImp_mean, :CN_mean, valuecols(dfg)[10:25]...] .=> difference)
end

# ╔═╡ Cell order:
# ╠═e481b52e-43d2-4d81-a479-2c8ab50be103
# ╠═a609ad42-48ad-4c37-9e24-ccbf58bf7717
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
# ╠═91f8b834-3a19-4157-b38a-67b616c968fe
