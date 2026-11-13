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

# ╔═╡ f96dd454-46b6-404d-8936-809acc726736
using STFT

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
    pr = @df df_daily_norm Plots.plot(:date, :runoff, label="", title="Normalized Stream Flow", xticks=false)
    pp = @df df_daily_norm Plots.plot(:date, :pr_agg1, label="", title="Normalized Two-Day Precipitation", xticks=false)
    pt = @df df_daily_norm Plots.plot(:date, :tmmn_mean, label="", title="Normalized Minimum Temperature")
    Plots.plot(pr, pp, pt, layout=(3,1), size=(500,500), titlefontsize=9, right_margin=4mm, top_margin=-2mm)
    savefig("../../figures/gabor-transform/Suwanee-Norm-Gage-Precip-Temp.png")
end

# ╔═╡ f0df732c-8647-42b0-8658-0409a1762360
begin
    min_months = []
    for y in sort(unique(Dates.year.(df_daily_suwanee.date)))
        df_y = df_daily_suwanee[Dates.year.(df_daily_suwanee.date) .== y,:]
        push!(min_months, Dates.month(df_y.date[argmin(df_y.runoff)]))
    end
    histogram(min_months, size=(300,300))
end

# ╔═╡ 7f6b7c15-c517-4930-a835-904b09a3b863
begin
    max_months = []
    for y in sort(unique(Dates.year.(df_daily_suwanee.date)))
        df_y = df_daily_suwanee[Dates.year.(df_daily_suwanee.date) .== y,:]
        push!(max_months, Dates.month(df_y.date[argmax(df_y.runoff)]))
    end
    histogram(max_months, bins=collect(1:12), xticks=1:1:12, size=(300,300))
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
    freqs, amps = @df df_daily_suwanee calc_fft(:runoff, samplerate)
    freqs_pr, amps_pr = @df df_daily_suwanee calc_fft(:pr_agg1, samplerate)
    freqs_tm, amps_tm = @df df_daily_suwanee calc_fft(:tmmn_mean, samplerate)
    
    powerspectra = []
    push!(powerspectra, Plots.plot(freqs, amps, label="", title="Stream Flow", xticks=false))
    push!(powerspectra, Plots.plot(freqs_pr, amps_pr, label="", title="Two-Day Precipitation", xticks=false, ylabel="Amplitude"))
    push!(powerspectra, Plots.plot(freqs_tm, amps_tm, label="", title="Minimum Temperature", xlabel="Frequency (1/year)"))
    Plots.plot(powerspectra..., layout=(3,1), size=(500,400), titlefontsize=9, 
        top_margin=-2mm, xlabelfontsize=9, ylabelfontsize=9)
    savefig("../../figures/gabor-transform/SuwaneePowerSpectra.png")
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

# ╔═╡ e0c4bb63-bd13-4b78-a52f-ffad86889b0d
gabormatrix = gabor_transform(df_daily_suwanee.runoff, samplerate, 10)

# ╔═╡ f7b87b08-c022-45c4-bbc1-48245780800b
gabormatrix_pr = gabor_transform(df_daily_suwanee.pr_agg1, samplerate, 10)

# ╔═╡ 764873c1-a7f7-4056-ad1b-effd0a1f2d8f
gabormatrix_tm = gabor_transform(df_daily_suwanee.tmmn_mean, samplerate, 10)

# ╔═╡ 687c5f73-b4f1-449a-83cf-46469bcac077
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
    Plots.plot(gaborplots...,layout=(4,1), size=(500,600), titlefontsize=9, 
        top_margin=-2mm, xlabelfontsize=9, ylabelfontsize=9)
    savefig("../../figures/gabor-transform/SuwaneeGaborMatrixAnnualFreq.png")
end

# ╔═╡ b5e7f965-7e1b-4ffc-b958-efe9c7e1d1b8
begin
	# Plots.heatmap(df_daily_suwanee.date, freqs, gabormatrix',
	# 	xlabel="Date", ylabel="Frequency (1/year)")
	# savefig("../../hq-figures/Spectrogram.png")
end

# ╔═╡ 63ebde27-e4f8-4bd0-8fe6-31b53fee6c87
begin
    W = 700                                 # Window length
    w = gaussian_window(ones(W), W/2, 10)   # Rectangular analysis window
    H = 1                                   # Hop
    L = W - H                               # Overlap

    freqs2 = fftfreq(W+4, 365)
    freqs2 = freqs2[freqs2 .> 0]

    X = stft(df_daily_suwanee.runoff, w, L) # Analysis
    s = abs2.(X)                            # Compute spectrogram
    Plots.heatmap(df_daily_suwanee.date[1:end-L], freqs2, s, 
        ylabel="Frequency (1/y)")           # Display spectrogram
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

# ╔═╡ 1f3ae5e5-a9af-495a-91eb-6401e6f6c241
function rmse(y, ŷ)
    return sqrt(mean((y .- ŷ) .^ 2))
end

# ╔═╡ df5561f1-1f0c-4871-9c6f-75fa3a7b9208
function mape(y, ŷ)
    return mean(abs.((y .- ŷ) ./ y)) * 100
end

# ╔═╡ 43cd9f42-821d-4bb4-b856-da40f76da4b9
runoff_lm = lm(@formula(runoff ~ pr_agg1 + tmmn_mean + fct_imp), df_daily_norm)

# ╔═╡ cbddc721-7f75-4d87-b6b3-a54047d96b1b
r2(runoff_lm)

# ╔═╡ b47a4bfe-49b6-49d2-8748-a32d6ac10891
begin
    df_daily_norm_fft = insertcols(df_daily_norm, 
        :runoff_annual_amplitude => gabormatrix[:,39],
        :pr_agg1_annual_amplitude => gabormatrix_pr[:,39],
        :tmmn_annual_amplitude => gabormatrix_tm[:,39])

    rng = Xoshiro(42) # seeded random number generator
    idx = sample(rng, axes(df_daily_norm_fft, 1), 
        round(Int, 0.2 * nrow(df_daily_norm_fft)), replace=false,
        ordered=true)
    df_test = df_daily_norm_fft[idx,:]
    df_train = df_daily_norm_fft[Not(idx),:]
    
    amp_lm = lm(
        @formula(runoff_annual_amplitude ~ pr_agg1_annual_amplitude + tmmn_annual_amplitude + fct_imp),
        df_train)
end

# ╔═╡ d6423238-cceb-4f89-a065-94387f74e760
r2(amp_lm)

# ╔═╡ 13329577-990d-4ed0-b4f7-4916a5e26053
begin
    pred_train = predict(amp_lm, df_train)
    rmse(df_train.runoff_annual_amplitude, pred_train)
end

# ╔═╡ 2f6c4616-d1e4-4c3a-9f52-8dc9666039a1
mape(df_train.runoff_annual_amplitude, pred_train)

# ╔═╡ 51086343-a1ae-4bb4-8f3a-8f6f5afb9fca
begin
    pred = predict(amp_lm, df_test)
    Plots.plot(df_test.date, df_test.runoff_annual_amplitude, label="Test Data")
    Plots.plot!(df_test.date, pred, label="Prediction", size=(800,350), 
        ylabel="Gabor-Transformed Amplitude", 
        ylabelfontsize=10, xtickfontsize=10, ytickfontsize=10, 
        legendfontsize=10, left_margin=4mm)
    savefig("../../figures/gabor-transform/SuwaneeLMPrediction.png")
end

# ╔═╡ fbc32996-341e-4947-8f53-9f2b465fad75
rmse(df_test.runoff_annual_amplitude, pred)

# ╔═╡ d05fa934-1405-4409-8cde-3b6281777cab
mape(df_test.runoff_annual_amplitude, pred)

# ╔═╡ 060e6d4d-5ce8-4125-ab43-0f083f6e2555
begin
    idx_pre2020 = Dates.year.(df_daily_norm_fft.date) .< 2020
    df_post2020 = df_daily_norm_fft[Not(idx_pre2020),:]
    df_pre2020 = df_daily_norm_fft[idx_pre2020,:]
    
    amp_pre2020_lm = lm(
        @formula(runoff_annual_amplitude ~ pr_agg1_annual_amplitude + tmmn_annual_amplitude + fct_imp),
        df_pre2020)
end

# ╔═╡ 224bfcaa-89be-478b-9c51-4a903cfde308
r2(amp_pre2020_lm)

# ╔═╡ 16fc9208-3d9c-449d-a9a1-251c3c922967
begin
    pred_post2020 = predict(amp_pre2020_lm, df_post2020)
    Plots.plot(df_post2020.date, df_post2020.runoff_annual_amplitude, label="Test Data")
    Plots.plot!(df_post2020.date, pred_post2020, label="Prediction", size=(800,350), 
        ylabel="Gabor-Transformed Amplitude", 
        ylabelfontsize=10, xtickfontsize=10, ytickfontsize=10, 
        legendfontsize=10, left_margin=4mm)
    savefig("../../figures/gabor-transform/SuwaneeLMPredictionPost2024.png")
end

# ╔═╡ dbd0f849-3665-4b5a-b3cf-c7244d4a2878
rmse(df_post2020.runoff_annual_amplitude, pred_post2020)

# ╔═╡ 5aab7e7a-9230-47de-acf5-31a8bcdb5b41
mape(df_post2020.runoff_annual_amplitude, pred_post2020)

# ╔═╡ a331950d-38d9-4c8f-8f85-db22124e9c39
begin
    pred_pre2020 = predict(amp_pre2020_lm, df_pre2020)
    Plots.plot(df_pre2020.date, df_pre2020.runoff_annual_amplitude, label="Training Data")
    Plots.plot!(df_pre2020.date, pred_pre2020, label="Prediction", size=(800,350), 
        ylabel="Gabor-Transformed Amplitude", 
        ylabelfontsize=10, xtickfontsize=10, ytickfontsize=10, 
        legendfontsize=10, left_margin=4mm)
    # savefig("../../figures/gabor-transform/SuwaneeLMPrediction.png")
end

# ╔═╡ 4718bc44-c46f-4752-a89a-482ff2048ae1
rmse(df_pre2020.runoff_annual_amplitude, pred_pre2020)

# ╔═╡ 36f10422-ad66-4366-9a98-42adbbbf7ea0
mape(df_pre2020.runoff_annual_amplitude, pred_pre2020)

# ╔═╡ 8615b627-5658-4e93-ac60-913b3d95622c
amp_v_time = lm(@formula(runoff_annual_amplitude ~ days), df_daily_norm_fft)

# ╔═╡ 14cdc109-2d70-4b1d-9541-dfe0922acfbc
r2(amp_v_time)

# ╔═╡ cff7898f-db3b-4509-aadd-689a0a322d1e
rE10_lm = lm(@formula(rExceed10 ~ year), df_extremes)

# ╔═╡ 98faef1d-6d4b-41ce-87fc-9d7fa83b182b
r2(rE10_lm)

# ╔═╡ 7a5e2c8b-97df-4dac-a3e4-a080380d2ed1
begin
    df_daily_suwanee.year = Dates.year.(df_daily_suwanee.date)
    df_extremes = combine(groupby(df_daily_suwanee, :year),
        :runoff => (x -> sum(x .> 10)) => :rExceed10,
        :runoff => (x -> sum(x .> 20)) => :rExceed20)
    @df df_extremes Plots.scatter(:year, :rExceed10, label="Days exceeding 10 mm runoff (r2 = .18)", smooth=true)
    @df df_extremes Plots.scatter!(:year, :rExceed20, label="Days exceeding 20 mm runoff (r2 = .05)", smooth=true)
end

# ╔═╡ 73d257cf-f7af-477e-a808-8710c5b79674
rE20_lm = lm(@formula(rExceed20 ~ year), df_extremes)

# ╔═╡ e218d7b3-e654-41fa-a58b-437817d22503
r2(rE20_lm)

# ╔═╡ Cell order:
# ╠═88673022-d964-4aca-afe6-c91e555fd264
# ╠═e9467fe4-4fe9-431b-a891-86c4738b2f9c
# ╠═f96dd454-46b6-404d-8936-809acc726736
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
# ╠═80abbe13-cb1a-4766-9c76-941828a9ad3f
# ╠═a1e8749f-24c4-456e-8e6b-e8551de4638a
# ╠═6189e3e7-5e54-4a72-a6be-c463ea78d85c
# ╠═381e952c-acd2-471d-a626-51f57d99e6b9
# ╠═ad5c2f44-6c05-4cd7-99d1-5bdc74a4f409
# ╠═d90890d1-e5d3-46f4-9613-6b8c77ffc69f
# ╠═f0df732c-8647-42b0-8658-0409a1762360
# ╠═7f6b7c15-c517-4930-a835-904b09a3b863
# ╠═5f525f7d-2eb2-4055-8122-aac357e596e3
# ╠═5c62c5c1-d1e9-41a1-97df-9b3e6822cdfa
# ╠═62549229-5535-4a8d-9ffc-b4db51ee4cb7
# ╠═30d5d0bc-acdd-4425-90d3-85c6dbe83463
# ╠═fb8f0802-d018-401e-b630-9914a2ae76d8
# ╠═2f59a5b8-3e4d-4bbb-ae52-ba94ff2add1a
# ╠═c8227a21-a168-4a76-8fe6-abdd9ae6b393
# ╠═e0c4bb63-bd13-4b78-a52f-ffad86889b0d
# ╠═f7b87b08-c022-45c4-bbc1-48245780800b
# ╠═764873c1-a7f7-4056-ad1b-effd0a1f2d8f
# ╠═687c5f73-b4f1-449a-83cf-46469bcac077
# ╠═b5e7f965-7e1b-4ffc-b958-efe9c7e1d1b8
# ╠═63ebde27-e4f8-4bd0-8fe6-31b53fee6c87
# ╠═21277483-4bb0-43d7-9bd2-205c47250e9e
# ╠═24d24938-7bc2-43d9-ab0e-30330fb508cc
# ╠═192e308d-3e20-4c74-96ab-4c4a160b93b8
# ╠═17b68d87-8463-48d0-9c75-075ec90ce6f8
# ╠═503f3722-40c0-4929-a19d-275aa938d49c
# ╠═9bda8e2a-0f1d-48a7-91c3-9f6f5cb572e9
# ╠═f0f87a81-056a-471c-befe-457617e6fbf1
# ╠═1f3ae5e5-a9af-495a-91eb-6401e6f6c241
# ╠═df5561f1-1f0c-4871-9c6f-75fa3a7b9208
# ╠═43cd9f42-821d-4bb4-b856-da40f76da4b9
# ╠═cbddc721-7f75-4d87-b6b3-a54047d96b1b
# ╠═b47a4bfe-49b6-49d2-8748-a32d6ac10891
# ╠═d6423238-cceb-4f89-a065-94387f74e760
# ╠═13329577-990d-4ed0-b4f7-4916a5e26053
# ╠═2f6c4616-d1e4-4c3a-9f52-8dc9666039a1
# ╠═51086343-a1ae-4bb4-8f3a-8f6f5afb9fca
# ╠═fbc32996-341e-4947-8f53-9f2b465fad75
# ╠═d05fa934-1405-4409-8cde-3b6281777cab
# ╠═060e6d4d-5ce8-4125-ab43-0f083f6e2555
# ╠═224bfcaa-89be-478b-9c51-4a903cfde308
# ╠═16fc9208-3d9c-449d-a9a1-251c3c922967
# ╠═dbd0f849-3665-4b5a-b3cf-c7244d4a2878
# ╠═5aab7e7a-9230-47de-acf5-31a8bcdb5b41
# ╠═a331950d-38d9-4c8f-8f85-db22124e9c39
# ╠═4718bc44-c46f-4752-a89a-482ff2048ae1
# ╠═36f10422-ad66-4366-9a98-42adbbbf7ea0
# ╠═8615b627-5658-4e93-ac60-913b3d95622c
# ╠═14cdc109-2d70-4b1d-9541-dfe0922acfbc
# ╠═cff7898f-db3b-4509-aadd-689a0a322d1e
# ╠═98faef1d-6d4b-41ce-87fc-9d7fa83b182b
# ╠═7a5e2c8b-97df-4dac-a3e4-a080380d2ed1
# ╠═73d257cf-f7af-477e-a808-8710c5b79674
# ╠═e218d7b3-e654-41fa-a58b-437817d22503
