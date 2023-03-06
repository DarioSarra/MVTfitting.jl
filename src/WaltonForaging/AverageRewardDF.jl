using DataFrames, CategoricalArrays, CSV, StatsBase
using Plots, StatsPlots, BrowseTables
using Optim, Polynomials, Distributions, Roots
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
    #create a cumulative trial forage time
    :SummedForage => cumsum => :CumForage,
    :ElapsedForage => cumsum => :CumElapsedForage,
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
df0 = combine(groupby(check,[:BinCumForage,:Richness]), :CumReward => mean => :CumReward)