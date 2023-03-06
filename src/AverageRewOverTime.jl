using DataFrames, CategoricalArrays, CSV, StatsBase
using Plots, StatsPlots, BrowseTables
using Optim, Polynomials, Distributions
import Statistics: mean, sem, median, std

xs = range(0, 10, length=10)
ys = @. exp(-xs)
f = fit(xs, ys) # degree = length(xs) - 1
f2 = fit(xs, ys, 2) # degree = 2

scatter(xs, ys, markerstrokewidth=0, label="Data")
plot!(f, extrema(xs)..., label="Fit")
plot!(f2, extrema(xs)..., label="Quadratic Fit")

##
output_dir = "/Users/dariosarra/Documents/Lab/Oxford/Walton/Presentations/Lab_meeting/Lab_meeting20230222/figures"
if ispath("/home/beatriz/Documents/Datasets/WaltonForaging")
    main_path ="/home/beatriz/Documents/Datasets/WaltonForaging"
elseif ispath("/Users/dariosarra/Documents/Lab/Oxford/Walton/WaltonForaging")
        main_path = "/Users/dariosarra/Documents/Lab/Oxford/Walton/WaltonForaging"
elseif ispath(joinpath("C:\\Users","dario","OneDrive","Documents","Lab","Walton","WaltonForaging"))
        main_path = joinpath("C:\\Users","dario","OneDrive","Documents","Lab","Walton","WaltonForaging")
end
Exp = "5HTPharma"
pokes = CSV.read(joinpath(main_path,"data",Exp,"Processed","PokesTable.csv"), DataFrame)
bouts = CSV.read(joinpath(main_path,"data",Exp,"Processed","BoutsTable.csv"), DataFrame)
for dd in [pokes, bouts]
    for (c,l) in zip([:Richness, :Travel],[["poor", "medium", "rich"], ["short", "long"]])
        dd[!,c] = categorical(dd[:,c], ordered = true)
        dd[!,c] = levels!(dd[:,c], l)
    end
end
## Adjust bouts DF
testb = dropmissing(bouts,[:SummedForage,:ElapsedForage, :Travel])
forage_lim = quantile(testb.SummedForage, 0.95)
filter!(r-> r.SummedForage < forage_lim, testb)
@df testb density(:SummedForage)
transform!(testb, [:SummedForage,:SummedTravel,:ElapsedForage,:ElapsedTravel] .=>
    ByRow(x-> x/1000) .=> [:SummedForage,:SummedTravel,:ElapsedForage,:ElapsedTravel])
## Calculation cumulative variable over trials
transform!(groupby(testb,[:SubjectID,:StartDate,:Trial]),
    #count bout in trial
    :Bout => (x-> collect(1:length(x))) => :BoutInTrial,
    #create a cumulative elapsed forage time
    :SummedForage => cumsum => :CumForage,
    #counts reward obtained during a trial 
    :Rewarded => cumsum => :CumReward)
## shift cumulative reward by travel and richness for visualization purposes
Rich_shift = Dict(c=>v for (c,v) in zip(levels(testb.Richness), [0.0,0.2,0.4]))
## Calculate assimilated energy corrected per cost of searching
check = filter(r-> r.Treatment == "Baseline", testb)
@df check scatter(:CumForage, :CumReward .+ [get(Rich_shift,x,0) for x in :Richness],
    group = :Richness,
    markersize = 2, markeralpha = 0.4, markerstrokewidth = 0,
    ylabel = "Rewards obtained",
    xlabel = "Forage time in trial")
savefig(joinpath(output_dir,"Energy_intake.pdf"))

##
check[!,:BinCumForage] = round.(check.CumForage, digits = 1)
df0 = combine(groupby(check,[ :BinCumForage,:Richness]), :CumReward => mean => :CumReward)
df1 = combine(groupby(df0,:Richness)) do dd
    min, max = extrema(dd.BinCumForage)
    println(min," ",max)
    max_rew = maximum(dd.:CumReward)
    pre_bins = collect(0:0.1:min)[1:end-1]
    pre_rew = zeros(length(pre_bins))
    post_bins = collect(max:0.1:20.5)[2:end]
    post_rew = repeat([max_rew], length(post_bins))
    richness = repeat([dd[1,:Richness]], length(pre_bins) + length(post_bins))
    return (Richness = richness, 
        CumReward = vcat(pre_rew,post_rew),
        BinCumForage = vcat(pre_bins,post_bins)
        )
end
# open_html_table(sort(df0, :BinCumForage))
df2 = combine(groupby(df0,:Richness)) do dd
    (Polyfit = Polynomials.fit(dd.BinCumForage, dd.CumReward,4),
     Extremes = extrema(dd.BinCumForage))
end
df3 = combine(groupby(df0,[:Richness])) do dd
    gain_fit = curve_fit(GainModel, dd.BinCumForage, dd.CumReward, [0.1, 0.1, 0.1])
    (BinCumForage = collect(0:20), Gain_fit = GainModel(0:20, coef(gain_fit)))
end
##
plt = @df df0 scatter(:BinCumForage,:CumReward, group = :Richness,
    markersize = 2, markeralpha = 1, markerstrokewidth = 0,
    ylabel = "Average rewards obtained",
    xlabel = "Forage time in trial", legend = false)
savefig(joinpath(output_dir,"Mean_Energy_intake.pdf"))

@df df3 plot!(:BinCumForage, :Gain_fit, linewidth = 2, linestyle = :dash, group = :Richness)

for (r,c) in zip(eachrow(df2),[1,2,3])
    span = range(r.Extremes..., step = 0.1)
    plot!(plt,span, r.Polyfit.(span), color = c, legend = false)
end
savefig(joinpath(output_dir,"Fit_Mean_Energy_intake.pdf"))
display(plt)
##
poor = update_time(1)
medium = update_time(0.5)
rich = update_time(0.227)

@df poor plot!(:Mean, :Rew, fillalpha = 0.2,label = "poor",
    xlims = (0,20), ylims = (-0.5,15), color = 1)
@df medium plot!(:Mean, :Rew, fillalpha = 0.2, label = "medium")
@df rich plot!(:Mean, :Rew, fillalpha = 0.2, label = "high",
     legend = :topleft, xlims = (0,15), ylims=(0,18),xticks = 0:1:15,yticks = 0:1:18)