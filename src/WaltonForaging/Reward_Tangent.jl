include("AverageRewardDF.jl")
averge_rew_rate = df0
sav_dir = "/Users/dariosarra/Documents/Lab/Oxford/Walton/Presentations/Lab_meeting/Lab_meeting20230222/"
RichnessColor = Dict("poor" => :lightgreen, "medium" => :green, "rich" => :darkgreen)

## calculate intake at 3 richness
df1 = combine(groupby(averge_rew_rate, :Richness)) do dd
    gain_fit = curve_fit(ExpGains, dd.BinCumForage, dd.CumReward, [0.1, 0.1])
    c = coef(gain_fit)
    (ExpP1 = c[1], ExpP2 = c[2])
end
df1[!, :ExpP] = [[p1,p2] for (p1,p2) in zip(df1.ExpP1,df1.ExpP2)]
df2 = combine(groupby(df1, :Richness)) do dd
    (BinCumForage = collect(0:20), Gain_fit = ExpGains(0:20,[dd.ExpP1,dd.ExpP2]))
end
df2[!, :Color] =  [get(RichnessColor, r, 4) for r in df2.Richness]
@df df2 plot(:BinCumForage, :Gain_fit, group = :Richness, color = :Color)
## Calculate tangent from Slope 0.7
df3  = combine(groupby(df1,:Richness)) do dd
    m = 0.7
    x,y,q = MVTpoint(dd[1,:ExpP], m)
    (OptLeave = x, Intake = y, Intercept = q, Slope = m)
end
df4 = combine(groupby(df3, :Richness)) do dd
    span = collect(-10:20)
    res = leaving_tan(span, dd.Slope, dd.Intercept)
    (BinCumForage = span, Tan_fit = res, Net_intake = res .- dd[1,:Intercept])
end
df4[!, :Color] =  [get(RichnessColor, r, 4) for r in df4.Richness]
## Calculate tangent from Slope 0.5
df5  = combine(groupby(df1,:Richness)) do dd
    m = 0.5
    x,y,q = MVTpoint(dd[1,:ExpP], m)
    (OptLeave = x, Intake = y, Intercept = q, Slope = m)
end
df6 = combine(groupby(df5, :Richness)) do dd
    span = collect(-10:20)
    res = leaving_tan(span, dd.Slope, dd.Intercept)
    (BinCumForage = span, Tan_fit = res, Net_intake = res .- dd[1,:Intercept])
end
df6[!, :Color] =  [get(RichnessColor, r, 4) for r in df6.Richness]
##
quality = "medium"
@df filter(r->r.Richness == quality, df2) plot(:BinCumForage, :Gain_fit, framestyle=:origin, 
    xlims = (-5,20), ylims = (-0.5,20), legend = :top,xticks = -5:5:20,
    label = "Marginal intake curve", ylabel = "Cumulative gains", xlabel = "Time", color  = :black)
savefig(joinpath(sav_dir, "MVT1.pdf"))
@df filter(r->r.Richness == quality, df4) plot!(:BinCumForage, :Net_intake, 
    labels = "Net energy intake", color  = :black, linestyle = :solid)
    # annotate = (15, 15, text("Travel time", :right, 10, rotation = 44)))
savefig(joinpath(sav_dir, "MVT2.pdf"))
lim = filter(r->r.Richness == quality, df3)[1,:OptLeave]
@df filter(r->r.Richness == quality && lim - 3 < r.BinCumForage < lim+3 , df4) plot!(:BinCumForage, :Tan_fit, 
    labels = "", color  = :black, linestyle = :dash)
savefig(joinpath(sav_dir, "MVT3.pdf"))
@df filter(r->r.Richness == quality, df3) scatter!(:OptLeave, [0], markersize = 6, 
    label = "", markercolor = :black)
savefig(joinpath(sav_dir, "MVT4.pdf"))
##
quality = "rich"
@df filter(r->r.Richness == quality, df2) plot!(:BinCumForage, :Gain_fit,
    label = "Increased marginal intake", color  = :blue)
lim = filter(r->r.Richness == quality, df3)[1,:OptLeave]
@df filter(r->r.Richness == quality && lim - 3 < r.BinCumForage < lim+3 , df4) plot!(:BinCumForage, :Tan_fit, 
        labels = "", linestyle = :dash, color = :blue)
@df filter(r->r.Richness == quality, df3) scatter!(:OptLeave, [0], markersize = 6, 
        label = "", markercolor = :blue)
savefig(joinpath(sav_dir, "MVT5.pdf"))
##
quality = "medium"
@df filter(r->r.Richness == quality, df6) plot!(:BinCumForage, :Net_intake, 
    labels = "Reduced average intake", color  = :red, linestyle = :solid)
lim = filter(r->r.Richness == quality, df5)[1,:OptLeave]
@df filter(r->r.Richness == quality && lim - 3 < r.BinCumForage < lim+3 , df6) plot!(:BinCumForage, :Tan_fit, 
    labels = "", color  = :red, linestyle = :dash)
@df filter(r->r.Richness == quality, df5) scatter!(:OptLeave, [0], markersize = 6, 
    label = "", markercolor = :red)
savefig(joinpath(sav_dir, "MVT6.pdf"))
####
@df df2 plot(:BinCumForage, :Gain_fit, group = :Richness, framestyle=:origin, 
    xlims = (-5,20), ylims = (0,15), legend = :top, color  = :Color,)