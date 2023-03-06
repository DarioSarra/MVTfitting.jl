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
@df check scatter(:CumForage, :CumReward .+ [get(Rich_shift,x,0) for x in :Richness]
    , group = :Richness,
    markersize = 2, markeralpha = 0.4, markerstrokewidth = 0,
    ylabel = "Rewards obtained",
    xlabel = "Forage time in trial")
savefig(joinpath(output_dir,"Energy_intake.pdf"))
##
extremes = combine(groupby(check,[:Richness]), 
    :CumForage => (x -> [extrema(x)]) => [:Min, :Max],
    :CumReward => maximum => :MaxRew)

fitdf = check[:,[:Richness,:Travel,:CumForage,:CumReward]]
prov = DataFrame()
for r in eachrow(extremes)
    for t in ["short", "long"]
        mindf = DataFrame(CumForage = collect(0:0.002:r.Min))
        mindf[!,:Richness] .= r.Richness
        mindf[!,:Travel] .= t
        mindf[!,:CumReward] .= 0
        append!(prov,mindf)
        maxdf = DataFrame(CumForage = collect(r.Max:0.5:22))
        maxdf[!,:Richness] .= r.Richness
        maxdf[!,:Travel] .= t
        maxdf[!,:CumReward] .= r.MaxRew
        append!(prov,maxdf)
    end
end
prov
open_html_table(prov)
append!(fitdf,prov)
##
@. sigmoid_f(x, θ) = θ[1]/(1 + exp(-θ[2]*x))
@. atan_f(x,p) = p[1] + p[2]*atan(x)
@. tan_f(x,p) = p[1] + p[2]*tan(x)
@. log_f(x,p) = p[1] + p[2]*log(x)
@. exp_f(x,p) = p[1] + p[2]*exp(x)
function curvefit_info(f,x,y,p)
    res = curve_fit(f, x, y, [0.1, 0.1])
    return (coef(res), margin_error(res))
end
fit_intake = combine(groupby(fitdf,[:Richness]),
    [:CumForage, :CumReward] => 
    ((x,y) -> [coef(curve_fit(exp_f, x, y, [0.1, 0.1]))]) =>
    :Exp,
    [:CumForage, :CumReward] => 
    ((x,y) -> [coef(curve_fit(log_f, x, y, [0.1, 0.1]))]) =>
    :Log,
    [:CumForage, :CumReward] => 
    ((x,y) -> [coef(curve_fit(sigmoid_f, x, y, [1.0, 1.0]))]) =>
    :Sigmoid,
    [:CumForage, :CumReward] => 
    ((x,y) -> [coef(curve_fit(atan_f, x, y, [1.0, 1.0]))]) =>
    :ArcTan,
    [:CumForage, :CumReward] => 
    ((x,y) ->fit(x, y,3)) =>
    :Polyfit,
)
open_html_table(fit_intake)
##
p = @df check scatter(:CumForage, :CumReward .+ [get(Rich_shift,x,0) for x in :Richness],
    group = :Richness,
    markersize = 2, markeralpha = 0.4, markerstrokewidth = 0,
    ylabel = "Rewards obtained",
    xlabel = "Forage time in trial")
for r in eachrow(fit_intake)
    # plot!(p,x-> exp_f(x,r.Exp), 0:20)
    # plot!(p,x-> log_f(x,r.Log), 0:20)
    # plot!(x-> r.Polyfit(x), 1:20)
    plot!(x-> sigmoid_f(x,r.Sigmoid), 0:20, title = "Sigmoid")
    # plot!(x-> atan_f(x,r.ArcTan), 0:20, title = "Arctangent")
end
p
##
p = plot();
for (r,c) in zip(eachrow(fit_intake), 1:3)
    # plot!(p,x-> r.Intercept + r.Scale*log(x), 1:20)
    # plot!(x-> r.Polyfit(x), 1:20)
    plot!(x-> atan_f(x,r.ArcTan), 0:20, color = c)
end
p
##
open_html_table
poor_fit = curve_fit(model, dd.CumForag, ydata, p0)
param = fit.param
log(Complex(-1,30))

sort!(check,[:CumForage,:Richness])
filter(r-> r.Richness == "poor", check)
# calculates intake rate
testb.Richness[1]
testb.CumReward
 
##
df0 = filter(r->r.Rewarded, testb) 
df1 = combine(groupby(testb,[:SubjectID,:BoutInTrial,:Travel, :Richness,:Treatment]),
   :CumForage => mean => :CumForage)
df2 = combine(groupby(df1,[:Treatment,:Travel, :Richness,:BoutInTrial]),
    :CumForage .=> [mean, sem])
filter!(r -> !isnan(r.CumForage_sem), df2)
transform!(df2,[:BoutInTrial, :CumForage_mean] => 
    ByRow((r,t) -> r/t) => :IntakeRate)
open_html_table(df2)
df3 = filter(r -> r.Treatment == "Baseline", df2)
scatter(df3.CumForage_mean, df3.IntakeRate, group = df3.Richness .* df3.Travel)
##
df4 = combine(groupby(df3, [:Richness, :Travel]),
    [:CumForage_mean, :IntakeRate] => ((x,y) -> Polynomials.fit(x,y)) => :Intake_f)
df4[1,:Intake_f]
##
transform!(testb, [:CumReward, :CumForage] => 
    ByRow((r,t) -> r/t) => :IntakeRate)
testb.CumForage
extrema(testb.CumForage)
i = findfirst(x-> x > 869,testb.CumForage)
open_html_table(testb[i-50:i+2,:])
intake_f = combine(groupby(testb, [:Richness, :Travel, :Treatment]),
    [:CumForage, :IntakeRate] => ((x,y) -> Polynomials.fit(x,y,20)) => :Intake_f,
    :CumForage => extrema => :Bounds)
plot(intake_f[1,:Intake_f],intake_f[1,:Bounds]...)

open_html_table(intake_f)
##
check = filter(r-> r.SubjectID == "RP03" &&
    r.StartDate	== "2021/04/01 14:53:40",
    pokes)
open_html_table(check)
##
 open_html_table(testb[1:100,:])
 df0 = combine(groupby(testb,[:Treatment,:Travel, :Richness,:BoutInTrial]),
    :IntakeRate .=> [mean, sem])
    filter!(r -> !isnan(r.IntakeRate_sem), df0)
open_html_table(df0)
filter(r -> r.Treatment == "Baseline", df0)
##
