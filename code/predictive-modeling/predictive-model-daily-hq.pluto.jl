### A Pluto.jl notebook ###
# v0.20.0

using Markdown
using InteractiveUtils

# ╔═╡ 88673022-d964-4aca-afe6-c91e555fd264
begin
    using CSV, DataFrames
    using Plots, Plots.Measures, StatsPlots, CairoMakie
    using Statistics, Distributions, GLM, FFTW, ContinuousWavelets
    using Dates
end

# ╔═╡ e9467fe4-4fe9-431b-a891-86c4738b2f9c
using StatsBase, Random

# ╔═╡ 19d1b4b6-1cea-4d99-9823-98d9a6163e0c
using LaTeXStrings

# ╔═╡ d359d20f-daac-438e-b029-cff97ff00108
#VSCODE-MARKDOWN
md"""
# Load and Combine Data
"""

# ╔═╡ fd2a45ce-a756-4be7-8b7d-773663e511c3
begin
    df_climate_daily = CSV.read("../climate-dataset-work/gridmet_watershed_daily_part1.csv", DataFrame)
    df_climate_daily2 = CSV.read("../climate-dataset-work/gridmet_watershed_daily_part2.csv", DataFrame)
    append!(df_climate_daily, df_climate_daily2)
    rename!(df_climate_daily, :usgs_gage => :gage)
end

# ╔═╡ 662e5785-5618-4927-8581-e09a1f4ad7a7
names(df_climate_daily)

# ╔═╡ 514f50bf-576f-4599-a71c-a24d52868789
begin
    df_water_bal_daily1 = CSV.read("../water-balance-dataset-work/water_balance_daily_part1.csv", DataFrame)
    df_water_bal_daily2 = CSV.read("../water-balance-dataset-work/water_balance_daily_part2.csv", DataFrame)
    df_water_bal_daily = innerjoin(df_water_bal_daily1, df_water_bal_daily2, 
        on=[:Ti, :gage, :rain_avg, :rain_med, :rain_max, :rain_min])
    transform!(df_water_bal_daily, :Ti => ByRow(Date) => :date)
end

# ╔═╡ ba3aa8c3-b5eb-4913-bece-a9520c49fe48
names(df_water_bal_daily)

# ╔═╡ 2ce64f42-a540-45a1-afd9-433b265bf89e
begin
    df_land_cover = CSV.read("../land-cover-dataset-work/land_cover_annual_with_CN.csv", DataFrame)
    df_land_cover = df_land_cover[df_land_cover.gage .== 2334885, [:year, :gage, :FctImp_mean]]
end

# ╔═╡ a003ef2c-0b87-4a8e-9d07-913b4666d017
function interpolate_fctimp(date)
    year = Dates.year(date)
    day = Dates.value(date - Date(year, 1, 1))

    fctimp0 = df_land_cover.FctImp_mean[year - df_land_cover.year[1] + 1]
    fctimp1 = df_land_cover.FctImp_mean[year - df_land_cover.year[1] + 2]

    return fctimp0 + (fctimp1 - fctimp0) / daysinyear(year) * day
end

# ╔═╡ 41a19507-903e-4f93-9e8b-82cd91bda8fd
df_gage_daily = CSV.read("../gage-usgs/gage_daily.csv", DataFrame)

# ╔═╡ 7a28d218-e661-4626-85e6-9f47f72f6744
function addprevdays(x, days)
    if days <= 0
        x
    else
        [zeros(days); x[1:(end-days)]] .+ addprevdays(x, days-1)
    end
end

# ╔═╡ 2d9fca60-9d9f-4af2-b892-d69e71f0c9fd
begin
    df_gage_daily_suwanee = df_gage_daily[df_gage_daily.watershed .== "Suwanee Creek", :]
    df_daily_suwanee = innerjoin(df_climate_daily, df_water_bal_daily, df_gage_daily_suwanee, on=[:date, :gage])
   
    transform!(df_daily_suwanee, :date => ByRow(interpolate_fctimp) => :fct_imp,
        :date => (d -> Dates.value.(d .- df_daily_suwanee.date[1])) => :days,
        :pr_mean => (x -> addprevdays(x, 1)) => :pr_agg1,
        :pr_mean => (x -> addprevdays(x, 2)) => :pr_agg2,
        :pr_mean => (x -> addprevdays(x, 3)) => :pr_agg3)

    select!(df_daily_suwanee, [:date, :days, :gage, :pr_agg1, :pr_agg2, :pr_agg3, :pr_mean], :)
end

# ╔═╡ 45995b8e-0e0c-44b6-8459-c61209972027
begin
    df_climate_helen = CSV.read("../../Datasets/gridmet_watershed_daily_Ch_Helen.csv", DataFrame)
    rename!(df_climate_helen, :usgs_gage => :gage)

    df_land_cover_helen = CSV.read("../../Datasets/fctimp_annual_ch_helen.csv", DataFrame)

    function interpolate_fctimp_helen(date)
        year = Dates.year(date)
        day = Dates.value(date - Date(year, 1, 1))

        fctimp0 = df_land_cover_helen.FctImp_mean[year - df_land_cover_helen.year[1] + 1]
        fctimp1 = df_land_cover_helen.FctImp_mean[year - df_land_cover_helen.year[1] + 2]

        return fctimp0 + (fctimp1 - fctimp0) / daysinyear(year) * day
    end
    
    df_gage_helen = CSV.read("../../Datasets/discharge_daily_helen.csv", DataFrame)

    df_daily_helen = innerjoin(df_climate_helen, df_gage_helen, on=[:date, :gage])
   
    transform!(df_daily_helen, :date => ByRow(interpolate_fctimp_helen) => :fct_imp,
        :date => (d -> Dates.value.(d .- df_daily_helen.date[1])) => :days,
        :pr_mean => (x -> addprevdays(x, 1)) => :pr_agg1)

    select!(df_daily_helen, [:date, :days, :gage, :pr_agg1, :pr_mean], :)
end


# ╔═╡ 80abbe13-cb1a-4766-9c76-941828a9ad3f
#VSCODE-MARKDOWN
md"""
# Visualize and Analyze Data
"""

# ╔═╡ a1e8749f-24c4-456e-8e6b-e8551de4638a
function normalize(df)
    transform(df, names(df, Number) .=> (x -> (x .- mean(x)) ./ std(x)), renamecols=false)
end

# ╔═╡ 6189e3e7-5e54-4a72-a6be-c463ea78d85c
begin
    @df df_daily_suwanee Plots.plot(:date, :runoff, label="USGS gage runoff", size=(1000,300), title="Suwanee Creek")
    savefig("../../hq-figures/SuwaneeGage.png")
end

# ╔═╡ af3f1f15-a3a2-417d-815a-92b4777f0027
begin
    Plots.plot(df_land_cover.year, 
		df_land_cover[df_land_cover.gage .== 02334885, :FctImp_mean], 
		label="Suwanee Creek", ylabel="Mean Fractional Impervious Area (%)",
		ylabelfontsize=9, xtickfontsize=8, ytickfontsize=8, size=(400,300))
	Plots.plot!(df_land_cover_helen.year, df_land_cover_helen.FctImp_mean, 
		label="Chattahoochee River at Helen")
	savefig("../../figures/land-cover/FctImp_meanSuwaneeHelen.png")
end

# ╔═╡ 381e952c-acd2-471d-a626-51f57d99e6b9
begin
    @df df_daily_suwanee[1:365*5,:] Plots.plot(:date, :runoff, label="USGS gage runoff", size=(1000,300), title="Suwanee Creek")
    savefig("../../hq-figures/SuwaneeGage5Year.png")
end

# ╔═╡ ad5c2f44-6c05-4cd7-99d1-5bdc74a4f409
begin
    df_daily_norm = normalize(df_daily_suwanee)
    
    @df df_daily_norm[1:365,:] Plots.plot(:date, :runoff, label="Normalized USGS gage runoff", size=(1000,300), title="Suwanee Creek")
    @df df_daily_norm[1:365,:] Plots.plot!(:date, :pr_mean, label="Normalized precipitation", size=(1000,300))
    savefig("../../hq-figures/Suwanee1YearGageVsPrecip.png")
end

# ╔═╡ d90890d1-e5d3-46f4-9613-6b8c77ffc69f
begin    
    normplots = []
    push!(normplots, @df df_daily_norm Plots.plot(:date, :runoff, label="", 
        title="Normalized Stream Flow", xticks=false))
    push!(normplots, @df df_daily_norm Plots.plot(:date, :pr_agg1, label="", 
        title="Normalized Two-Day Precipitation", xticks=false))
    push!(normplots, @df df_daily_norm Plots.plot(:date, :tmmn_mean, label="", 
        title="Normalized Minimum Temperature"))

    df_daily_norm_helen = normalize(df_daily_helen)
    
    normplots_helen = []
    push!(normplots_helen, @df df_daily_norm_helen Plots.plot(:date, :runoff, 
        label="", title="Normalized Stream Flow", xticks=false, color=:green))
    push!(normplots_helen, @df df_daily_norm_helen Plots.plot(:date, :pr_agg1, label="", 
        title="Normalized Two-Day Precipitation", xticks=false, color=:green))
    push!(normplots_helen, @df df_daily_norm_helen Plots.plot(:date, :tmmn_mean, label="", 
        title="Normalized Minimum Temperature", color=:green))
    
    for i in 1:length(normplots)
        ylim_s = ylims(normplots[i])
        ylim_h = ylims(normplots_helen[i])
        y_lim = (minimum([ylim_s[1], ylim_h[1]]), maximum([ylim_s[2], ylim_h[2]]))
        normplots[i] = Plots.plot(normplots[i], ylims=y_lim)
        normplots_helen[i] = Plots.plot(normplots_helen[i], ylims=y_lim)
    end

    Plots.plot(normplots..., layout=(3,1), size=(500,400), titlefontsize=9, 
        right_margin=4mm, top_margin=-2mm)
    savefig("../../figures/gabor-transform/Suwanee-Norm-Gage-Precip-Temp.png")

    Plots.plot(normplots_helen..., layout=(3,1), size=(500,400), titlefontsize=9, 
        right_margin=4mm, top_margin=-2mm)
    savefig("../../figures/gabor-transform/Helen-Norm-Gage-Precip-Temp.png")

end

# ╔═╡ 5f525f7d-2eb2-4055-8122-aac357e596e3
begin
    @df df_daily_norm corrplot([:pr_mean :aet_avg :soilwater_avg :tmmn_mean :tmmx_mean :srad_mean :vpd_mean :fct_imp :runoff], size=(1000,1000))
	savefig("../../hq-figures/CorrelationPlotDaily.png")
end

# ╔═╡ 5c62c5c1-d1e9-41a1-97df-9b3e6822cdfa
#VSCODE-MARKDOWN
md"""
## Fourier Transform and Spectrogram
"""

# ╔═╡ 62549229-5535-4a8d-9ffc-b4db51ee4cb7
begin
	samplerate = 365 #samples per year

	function calc_fft(a::AbstractVector, samplerate)
		norm_amps = abs.(fft(a)) / length(a) * 2 
		freqs = fftfreq(length(a), samplerate)
		return freqs[freqs .> 0], norm_amps[freqs .> 0] 
	end
	
	function gaussian_window(a::AbstractVector, μ::Number, σ::Number)
		[a[i] * pdf(Normal(µ, σ), i) * √(2 * pi * σ^2) for i in 1:length(a)]
	end

	function fft_window(a::AbstractVector, samplerate, μ, σ)
		calc_fft(gaussian_window(a, μ, σ), samplerate)[2]
	end

	function gabor_transform(a::AbstractVector, samplerate, σ)
		stack([fft_window(a, samplerate, μ, σ) for μ in 1:length(a)], dims=1)
	end
end

# ╔═╡ 30d5d0bc-acdd-4425-90d3-85c6dbe83463
begin
    #Suwanee Creek
    freqs, amps = @df df_daily_norm calc_fft(:runoff, samplerate)
    freqs_pr, amps_pr = @df df_daily_norm calc_fft(:pr_agg1, samplerate)
    freqs_tm, amps_tm = @df df_daily_norm calc_fft(:tmmn_mean, samplerate)
    
    powerspectra = []
    push!(powerspectra, Plots.plot(freqs, amps, label="", title="Stream Flow", xticks=false))
    push!(powerspectra, Plots.plot(freqs_pr, amps_pr, label="", title="Two-Day Precipitation", xticks=false, ylabel="Amplitude"))
    push!(powerspectra, Plots.plot(freqs_tm, amps_tm, label="", title="Minimum Temperature", xlabel="Frequency (1/year)"))
    
    #Chattahoochee Creek at Helen
    freqs_h, amps_h = @df df_daily_norm_helen calc_fft(:runoff, samplerate)
    freqs_prh, amps_prh = @df df_daily_norm_helen calc_fft(:pr_agg1, samplerate)
    freqs_tmh, amps_tmh = @df df_daily_norm_helen calc_fft(:tmmn_mean, samplerate)
    
    powerspectra_h = []
    push!(powerspectra_h, Plots.plot(freqs_h, amps_h, label="", 
        title="Stream Flow", xticks=false, color=:green))
    push!(powerspectra_h, Plots.plot(freqs_prh, amps_prh, label="", 
        title="Two-Day Precipitation", xticks=false, ylabel="Amplitude", 
        color=:green))
    push!(powerspectra_h, Plots.plot(freqs_tmh, amps_tmh, label="", 
        title="Minimum Temperature", xlabel="Frequency (year)", color=:green))
    
    for i in 1:length(powerspectra)
        ylim_s = ylims(powerspectra[i])
        ylim_h = ylims(powerspectra_h[i])
        y_lim = (minimum([ylim_s[1], ylim_h[1]]), maximum([ylim_s[2], ylim_h[2]]))
        powerspectra[i] = Plots.plot(powerspectra[i], ylims=y_lim)
        powerspectra_h[i] = Plots.plot(powerspectra_h[i], ylims=y_lim)
    end

    Plots.plot(powerspectra..., layout=(3,1), size=(500,400), titlefontsize=9, 
        top_margin=-2mm, xlabelfontsize=9, ylabelfontsize=9)
    savefig("../../figures/gabor-transform/SuwaneePowerSpectra.png")

    Plots.plot(powerspectra_h..., layout=(3,1), size=(500,400), titlefontsize=9, 
        top_margin=-2mm, xlabelfontsize=9, ylabelfontsize=9)
    savefig("../../figures/gabor-transform/HelenPowerSpectra.png")
end

# ╔═╡ fb8f0802-d018-401e-b630-9914a2ae76d8
begin 
    df_fft = DataFrame(:index => 1:length(freqs), :frequency => freqs, :amplitude => amps)
    sort(df_fft, :amplitude, rev=true)
end

# ╔═╡ 2f59a5b8-3e4d-4bbb-ae52-ba94ff2add1a
begin 
    df_fft_pr = DataFrame(:index => 1:length(freqs), :frequency => freqs_pr, :amplitude => amps_pr)
    sort(df_fft_pr, :amplitude, rev=true)
end

# ╔═╡ c8227a21-a168-4a76-8fe6-abdd9ae6b393
begin 
    df_fft_tm = DataFrame(:index => 1:length(freqs_tm), :frequency => freqs_tm, :amplitude => amps_tm)
    sort(df_fft_tm, :amplitude, rev=true)
end

# ╔═╡ 43ddd1ee-f2e7-4cbe-9545-a7eac887d891
begin 
    df_fft_h = DataFrame(:index => 1:length(freqs_h), :frequency => freqs_h, :amplitude => amps_h)
    sort(df_fft_h, :amplitude, rev=true)
end

# ╔═╡ e0c4bb63-bd13-4b78-a52f-ffad86889b0d
begin
    gabormatrix = gabor_transform(df_daily_suwanee.runoff, samplerate, 10)
    gabormatrix_pr = gabor_transform(df_daily_suwanee.pr_agg1, samplerate, 10)
    gabormatrix_tm = gabor_transform(df_daily_suwanee.tmmn_mean, samplerate, 10)
end

# ╔═╡ b5e7f965-7e1b-4ffc-b958-efe9c7e1d1b8
begin
	# Plots.heatmap(df_daily_suwanee.date, freqs, gabormatrix',
	# 	xlabel="Date", ylabel="Frequency (1/year)")
	# savefig("../../hq-figures/Spectrogram.png")
end

# ╔═╡ b540ae48-ff04-4ca1-8b2e-44e42275cdea
begin
    gabormatrix_r_helen = gabor_transform(df_daily_helen.runoff, samplerate, 10)
    gabormatrix_pr_helen = gabor_transform(df_daily_helen.pr_agg1, samplerate, 10)
    gabormatrix_tm_helen = gabor_transform(df_daily_helen.tmmn_mean, samplerate, 10)
end

# ╔═╡ 0ad260a1-b66f-471c-9336-3038da19b809
begin
    gaborplots = []
    push!(gaborplots, Plots.plot(df_daily_suwanee.date, gabormatrix[:,39], 
        label="", title="Stream Flow", xticks=false, ylabel="Amplitude"))
    push!(gaborplots, Plots.plot(df_daily_suwanee.date, gabormatrix_pr[:,39], 
        label="", title="Two-Day Precipitation", xticks=false, ylabel="Amplitude"))
    push!(gaborplots, Plots.plot(df_daily_suwanee.date, gabormatrix_tm[:,39], 
        label="", title="Minimum Temperature", xticks=false, ylabel="Amplitude"))
    push!(gaborplots, Plots.plot(df_daily_suwanee.date, df_daily_suwanee.fct_imp,
        label="", title="Mean Fractional Impervious Area", ylabel="Percentage"))

    gaborplots_helen = []
    push!(gaborplots_helen, Plots.plot(df_daily_helen.date, gabormatrix_r_helen[:,39], 
        label="", title="Stream Flow", xticks=false, ylabel="Amplitude", color=:green))
    push!(gaborplots_helen, Plots.plot(df_daily_helen.date, gabormatrix_pr_helen[:,39], 
        label="", title="Two-Day Precipitation", xticks=false, ylabel="Amplitude", color=:green))
    push!(gaborplots_helen, Plots.plot(df_daily_helen.date, gabormatrix_tm_helen[:,39], 
        label="", title="Minimum Temperature", xticks=false, ylabel="Amplitude", color=:green))
    push!(gaborplots_helen, Plots.plot(df_daily_helen.date, df_daily_helen.fct_imp,
        label="", title="Mean Fractional Impervious Area", ylabel="Percentage", color=:green))

    for i in 1:length(gaborplots)
        ylim_s = ylims(gaborplots[i])
        ylim_h = ylims(gaborplots_helen[i])
        println(ylim_s, ", ", ylim_h)
        y_lim = (minimum([ylim_s[1], ylim_h[1]]), maximum([ylim_s[2], ylim_h[2]]))
        println(y_lim)
        println()
        gaborplots[i] = Plots.plot(gaborplots[i], ylims=y_lim)
        gaborplots_helen[i] = Plots.plot(gaborplots_helen[i], ylims=y_lim)
    end

    Plots.plot(gaborplots...,layout=(4,1), size=(500,500), titlefontsize=9, 
        top_margin=-2mm, xlabelfontsize=9, ylabelfontsize=9)
    savefig("../../figures/gabor-transform/SuwaneeGaborMatrixAnnualFreq.png")

    Plots.plot(gaborplots_helen...,layout=(4,1), size=(500,500), titlefontsize=9, 
        top_margin=-2mm, xlabelfontsize=9, ylabelfontsize=9)
    savefig("../../figures/gabor-transform/HelenGaborMatrixAnnualFreq.png")
end

# ╔═╡ 21277483-4bb0-43d7-9bd2-205c47250e9e
#VSCODE-MARKDOWN
md"""
## Wavelet Transform and Spectrogram
"""

# ╔═╡ 24d24938-7bc2-43d9-ab0e-30330fb508cc
begin
    wav = wavelet(Morlet(π), averagingType=NoAve(), β=2)
    waveletfreqs = getMeanFreq(computeWavelets(length(df_daily_suwanee.runoff), wav)[1], samplerate)
end

# ╔═╡ 192e308d-3e20-4c74-96ab-4c4a160b93b8
function calc_wavelet(a::AbstractVector)
	abs.(cwt(a, wav))
end

# ╔═╡ 17b68d87-8463-48d0-9c75-075ec90ce6f8
begin
    waveletamps = calc_wavelet(df_daily_suwanee.runoff)
    # Plots.heatmap(df_daily_suwanee.date, waveletfreqs, waveletamps',
    #     xlabel="Date", ylabel="Frequency (1/year)")
	# savefig("../../hq-figures/WaveletSpectrogram.png")
end

# ╔═╡ 503f3722-40c0-4929-a19d-275aa938d49c
begin
	max_amp_idx = argmax(waveletamps)
	waveletfreqs[max_amp_idx[2]]
end

# ╔═╡ 9bda8e2a-0f1d-48a7-91c3-9f6f5cb572e9
df_daily_suwanee.date[max_amp_idx[1]]

# ╔═╡ f0f87a81-056a-471c-befe-457617e6fbf1
#VSCODE-MARKDOWN
md"""
## Regression Models
"""

# ╔═╡ 7db32f4d-ca1a-4499-acab-729bedbccf32
#VSCODE-MARKDOWN
md"""
### Functions
"""

# ╔═╡ 1f3ae5e5-a9af-495a-91eb-6401e6f6c241
function rmse(y, ŷ)
    return sqrt(mean((y .- ŷ) .^ 2))
end

# ╔═╡ df5561f1-1f0c-4871-9c6f-75fa3a7b9208
function mape(y, ŷ)
    return mean(abs.((y .- ŷ) ./ y)) * 100
end

# ╔═╡ 84442a1d-9fbd-4d42-8009-25715185247c
function lm_train_80(df, gabormatrix_runoff, gabormatrix_pr, gabormatrix_tm)
    df_fft = insertcols(df, 
        :runoff_annual_amplitude => gabormatrix_runoff[:,39],
        :pr_agg1_annual_amplitude => gabormatrix_pr[:,39],
        :tmmn_annual_amplitude => gabormatrix_tm[:,39])

    rng = Xoshiro(42)
    idx = sample(rng, axes(df_fft, 1), round(Int, 0.2 * nrow(df_fft)), 
        replace=false, ordered=true)
    df_test = df_fft[idx,:]
    df_train = df_fft[Not(idx),:]
    
    amp_lm = lm(
        @formula(runoff_annual_amplitude ~ pr_agg1_annual_amplitude + tmmn_annual_amplitude + fct_imp),
        df_train)
    
    return amp_lm, df_train, df_test
end

# ╔═╡ 79ee79c6-23f0-423c-88d2-b2da250ab523
function lm_train_by_year(df, gabormatrix_runoff, gabormatrix_pr, gabormatrix_tm, year)
    df_fft = insertcols(df, 
        :runoff_annual_amplitude => gabormatrix_runoff[:,39],
        :pr_agg1_annual_amplitude => gabormatrix_pr[:,39],
        :tmmn_annual_amplitude => gabormatrix_tm[:,39])

    idx_pre = Dates.year.(df_fft.date) .< year
    df_post = df_fft[Not(idx_pre),:]
    df_pre = df_fft[idx_pre,:]
    
    pre_lm = lm(
        @formula(runoff_annual_amplitude ~ pr_agg1_annual_amplitude + tmmn_annual_amplitude + fct_imp),
        df_pre)

    return pre_lm, df_pre, df_post
end

# ╔═╡ 4d64bfcd-2e6e-4b5e-a6da-7f235a15ff36
function performance_metrics(lm, df_train, df_test)
    pred_train = predict(lm, df_train)
    pred_test = predict(lm, df_test)

    println("R2: ", r2(lm))
    println("RMSE on training data: ", rmse(df_train.runoff_annual_amplitude, pred_train))
    println("MAPE on training data: ", mape(df_train.runoff_annual_amplitude, pred_train))
    println("RMSE on testing data: ", rmse(df_test.runoff_annual_amplitude, pred_test))
    println("MAPE on testing data: ", mape(df_test.runoff_annual_amplitude, pred_test))
end

# ╔═╡ 2b5f3778-7629-4777-9794-f7897637a6eb
function plot_predictions(lm, df_test, filename, color=:auto)
    pred_test = predict(lm, df_test)
    Plots.plot(df_test.date, df_test.runoff_annual_amplitude, label="Test Data", 
        color=color)
    Plots.plot!(df_test.date, pred_test, label="Prediction", size=(800,350), 
        ylabel="Gabor-Transformed Amplitude", 
        ylabelfontsize=10, xtickfontsize=10, ytickfontsize=10, 
        legendfontsize=10, left_margin=4mm)
    savefig(filename)
end

# ╔═╡ 0c8c449a-9706-48a5-93cd-af8cc8690247
#VSCODE-MARKDOWN
md"""
### Regression on Suwanee Raw Data (Baseline)
"""

# ╔═╡ 43cd9f42-821d-4bb4-b856-da40f76da4b9
runoff_lm = lm(@formula(runoff ~ pr_agg1 + tmmn_mean + fct_imp), df_daily_norm)

# ╔═╡ cbddc721-7f75-4d87-b6b3-a54047d96b1b
r2(runoff_lm)

# ╔═╡ a107d37f-7140-4dae-8603-8f68138d9db3
#VSCODE-MARKDOWN
md"""
### Training on 80% of Data, Testing on 20%
#### Suwanee Creek
"""

# ╔═╡ b47a4bfe-49b6-49d2-8748-a32d6ac10891
begin
    amp_lm, df_train, df_test = lm_train_80(df_daily_norm, gabormatrix, 
        gabormatrix_pr, gabormatrix_tm)
    amp_lm
end

# ╔═╡ 13329577-990d-4ed0-b4f7-4916a5e26053
begin
    plot_predictions(amp_lm, df_test, 
        "../../figures/gabor-transform/SuwaneeLMPrediction.png")
    performance_metrics(amp_lm, df_train, df_test)
end

# ╔═╡ d93d4e63-2687-4bce-ac1d-0e7c7e07d8a7
#VSCODE-MARKDOWN
md"""
#### Chattahoochee River at Helen
"""

# ╔═╡ 678da96b-5a79-4574-97a7-b4b7e6cb4e94
begin
    amp_lm_h, df_train_h, df_test_h = lm_train_80(df_daily_norm_helen, 
        gabormatrix_r_helen, gabormatrix_pr_helen, gabormatrix_tm_helen)
    amp_lm_h
end

# ╔═╡ 854e019b-9129-451c-a16e-ce184a575d67
performance_metrics(amp_lm_h, df_train_h, df_test_h)

# ╔═╡ debb5d38-711b-4f45-bab5-fbab3aab7364
plot_predictions(amp_lm_h, df_test_h, 
    "../../figures/gabor-transform/HelenLMPrediction.png", :darkgreen)

# ╔═╡ 17d9332e-53a9-466f-966f-505d4001be7a
#VSCODE-MARKDOWN
md"""
### Training on Pre-2010 Data, Testing on 2010-2024
#### Suwanee Creek
"""

# ╔═╡ 060e6d4d-5ce8-4125-ab43-0f083f6e2555
begin
    amp_pre2010_lm, df_pre2010, df_post2010 = lm_train_by_year(df_daily_norm, 
        gabormatrix, gabormatrix_pr, gabormatrix_tm, 2010)
    amp_pre2010_lm
end

# ╔═╡ 224bfcaa-89be-478b-9c51-4a903cfde308
performance_metrics(amp_pre2010_lm, df_pre2010, df_post2010)

# ╔═╡ 16fc9208-3d9c-449d-a9a1-251c3c922967
plot_predictions(amp_pre2010_lm, df_post2010, 
    "../../figures/gabor-transform/SuwaneeLMPredictionPost2010.png")

# ╔═╡ 6042f61f-9e9c-4a8f-af11-ab15af9c1a80
#VSCODE-MARKDOWN
md"""
#### Chattahoochee River at Helen
"""

# ╔═╡ e2ee7f82-d17e-4021-86d4-da0c11018868
begin
    amp_pre2010_lm_h, df_pre2010_h, df_post2010_h = lm_train_by_year(
        df_daily_norm_helen, gabormatrix_r_helen, gabormatrix_pr_helen, 
        gabormatrix_tm_helen, 2010)
    amp_pre2010_lm_h
end

# ╔═╡ 4f9ca63c-1252-49ed-9178-99a159225e63
performance_metrics(amp_pre2010_lm_h, df_pre2010_h, df_post2010_h)

# ╔═╡ a6ebe723-40b5-4fb7-8e14-085f248d5097
plot_predictions(amp_pre2010_lm_h, df_post2010_h, 
    "../../figures/gabor-transform/HelenLMPredictionPost2010.png", :darkgreen)

# ╔═╡ 02c79083-ffa0-4a83-ae1a-17014eaca075
#VSCODE-MARKDOWN
md"""
### Runoff Exceedances
"""

# ╔═╡ 7a5e2c8b-97df-4dac-a3e4-a080380d2ed1
begin
    df_daily_suwanee.year = Dates.year.(df_daily_suwanee.date)
    df_extremes = combine(groupby(df_daily_suwanee, :year),
        :runoff => (x -> sum(x .> 10)) => :rExceed10,
        :runoff => (x -> sum(x .> 20)) => :rExceed20)
    @df df_extremes Plots.scatter(:year, :rExceed10, label="Days exceeding 10 mm runoff (r2 = .18)", smooth=true)
    @df df_extremes Plots.scatter!(:year, :rExceed20, label="Days exceeding 20 mm runoff (r2 = .05)", smooth=true)
end

# ╔═╡ cff7898f-db3b-4509-aadd-689a0a322d1e
rE10_lm = lm(@formula(rExceed10 ~ year), df_extremes)

# ╔═╡ 98faef1d-6d4b-41ce-87fc-9d7fa83b182b
r2(rE10_lm)

# ╔═╡ 73d257cf-f7af-477e-a808-8710c5b79674
rE20_lm = lm(@formula(rExceed20 ~ year), df_extremes)

# ╔═╡ e218d7b3-e654-41fa-a58b-437817d22503
r2(rE20_lm)

# ╔═╡ Cell order:
# ╠═88673022-d964-4aca-afe6-c91e555fd264
# ╠═e9467fe4-4fe9-431b-a891-86c4738b2f9c
# ╠═19d1b4b6-1cea-4d99-9823-98d9a6163e0c
# ╠═d359d20f-daac-438e-b029-cff97ff00108
# ╠═fd2a45ce-a756-4be7-8b7d-773663e511c3
# ╠═662e5785-5618-4927-8581-e09a1f4ad7a7
# ╠═514f50bf-576f-4599-a71c-a24d52868789
# ╠═ba3aa8c3-b5eb-4913-bece-a9520c49fe48
# ╠═2ce64f42-a540-45a1-afd9-433b265bf89e
# ╠═a003ef2c-0b87-4a8e-9d07-913b4666d017
# ╠═41a19507-903e-4f93-9e8b-82cd91bda8fd
# ╠═7a28d218-e661-4626-85e6-9f47f72f6744
# ╠═2d9fca60-9d9f-4af2-b892-d69e71f0c9fd
# ╠═45995b8e-0e0c-44b6-8459-c61209972027
# ╠═80abbe13-cb1a-4766-9c76-941828a9ad3f
# ╠═a1e8749f-24c4-456e-8e6b-e8551de4638a
# ╠═6189e3e7-5e54-4a72-a6be-c463ea78d85c
# ╠═af3f1f15-a3a2-417d-815a-92b4777f0027
# ╠═381e952c-acd2-471d-a626-51f57d99e6b9
# ╠═ad5c2f44-6c05-4cd7-99d1-5bdc74a4f409
# ╠═d90890d1-e5d3-46f4-9613-6b8c77ffc69f
# ╠═5f525f7d-2eb2-4055-8122-aac357e596e3
# ╠═5c62c5c1-d1e9-41a1-97df-9b3e6822cdfa
# ╠═62549229-5535-4a8d-9ffc-b4db51ee4cb7
# ╠═30d5d0bc-acdd-4425-90d3-85c6dbe83463
# ╠═fb8f0802-d018-401e-b630-9914a2ae76d8
# ╠═2f59a5b8-3e4d-4bbb-ae52-ba94ff2add1a
# ╠═c8227a21-a168-4a76-8fe6-abdd9ae6b393
# ╠═43ddd1ee-f2e7-4cbe-9545-a7eac887d891
# ╠═e0c4bb63-bd13-4b78-a52f-ffad86889b0d
# ╠═b5e7f965-7e1b-4ffc-b958-efe9c7e1d1b8
# ╠═b540ae48-ff04-4ca1-8b2e-44e42275cdea
# ╠═0ad260a1-b66f-471c-9336-3038da19b809
# ╠═21277483-4bb0-43d7-9bd2-205c47250e9e
# ╠═24d24938-7bc2-43d9-ab0e-30330fb508cc
# ╠═192e308d-3e20-4c74-96ab-4c4a160b93b8
# ╠═17b68d87-8463-48d0-9c75-075ec90ce6f8
# ╠═503f3722-40c0-4929-a19d-275aa938d49c
# ╠═9bda8e2a-0f1d-48a7-91c3-9f6f5cb572e9
# ╠═f0f87a81-056a-471c-befe-457617e6fbf1
# ╠═7db32f4d-ca1a-4499-acab-729bedbccf32
# ╠═1f3ae5e5-a9af-495a-91eb-6401e6f6c241
# ╠═df5561f1-1f0c-4871-9c6f-75fa3a7b9208
# ╠═84442a1d-9fbd-4d42-8009-25715185247c
# ╠═79ee79c6-23f0-423c-88d2-b2da250ab523
# ╠═4d64bfcd-2e6e-4b5e-a6da-7f235a15ff36
# ╠═2b5f3778-7629-4777-9794-f7897637a6eb
# ╠═0c8c449a-9706-48a5-93cd-af8cc8690247
# ╠═43cd9f42-821d-4bb4-b856-da40f76da4b9
# ╠═cbddc721-7f75-4d87-b6b3-a54047d96b1b
# ╠═a107d37f-7140-4dae-8603-8f68138d9db3
# ╠═b47a4bfe-49b6-49d2-8748-a32d6ac10891
# ╠═13329577-990d-4ed0-b4f7-4916a5e26053
# ╠═d93d4e63-2687-4bce-ac1d-0e7c7e07d8a7
# ╠═678da96b-5a79-4574-97a7-b4b7e6cb4e94
# ╠═854e019b-9129-451c-a16e-ce184a575d67
# ╠═debb5d38-711b-4f45-bab5-fbab3aab7364
# ╠═17d9332e-53a9-466f-966f-505d4001be7a
# ╠═060e6d4d-5ce8-4125-ab43-0f083f6e2555
# ╠═224bfcaa-89be-478b-9c51-4a903cfde308
# ╠═16fc9208-3d9c-449d-a9a1-251c3c922967
# ╠═6042f61f-9e9c-4a8f-af11-ab15af9c1a80
# ╠═e2ee7f82-d17e-4021-86d4-da0c11018868
# ╠═4f9ca63c-1252-49ed-9178-99a159225e63
# ╠═a6ebe723-40b5-4fb7-8e14-085f248d5097
# ╠═02c79083-ffa0-4a83-ae1a-17014eaca075
# ╠═7a5e2c8b-97df-4dac-a3e4-a080380d2ed1
# ╠═cff7898f-db3b-4509-aadd-689a0a322d1e
# ╠═98faef1d-6d4b-41ce-87fc-9d7fa83b182b
# ╠═73d257cf-f7af-477e-a808-8710c5b79674
# ╠═e218d7b3-e654-41fa-a58b-437817d22503
