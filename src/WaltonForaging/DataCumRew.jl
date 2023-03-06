include("AverageRewardDF.jl")
baseline = check
average_rew_rate = df0
sav_dir = "/Users/dariosarra/Documents/Lab/Oxford/Walton/Presentations/Lab_meeting/Lab_meeting20230222/"
RichnessColor = Dict("poor" => :lightgreen, "medium" => :green, "rich" => :darkgreen)
##

baseline[!,:Color] = [get(RichnessColor, r, 4) for r in baseline.Richness]
@df baseline scatter(:CumForage, :CumReward .+ [get(Rich_shift,x,0) for x in :Richness],
    group = :Richness, color = :Color,
    markersize = 2, markeralpha = 0.8, markerstrokewidth = 0,
    ylabel = "Rewards obtained",
    xlabel = "Forage time in trial")
savefig(joinpath(output_dir,"Energy_intake.pdf"))

##
average_rew_rate[!,:Color] = [get(RichnessColor, r, 4) for r in average_rew_rate.Richness]
fit_df = combine(groupby(average_rew_rate,[:Richness])) do dd
    gain_fit = curve_fit(GainModel, dd.BinCumForage, dd.CumReward, [0.1, 0.1, 0.1])
    exp_fit = curve_fit(ExpGains, dd.BinCumForage, dd.CumReward, [0.1, 0.1])
    (BinCumForage = collect(0:20), 
    Gain_fit = GainModel(0:20, coef(gain_fit)), 
    Exp_fit = ExpGains(0:20, coef(exp_fit)))
end
fit_df[!,:Color] = [get(RichnessColor, r, 4) for r in fit_df.Richness]
##
plt = @df average_rew_rate scatter(:BinCumForage,:CumReward, group = :Richness,
    markersize = 2, markeralpha = 1, markerstrokewidth = 0, color = :Color,
    ylabel = "Average rewards obtained",
    xlabel = "Forage time in trial", legend = false)
savefig(joinpath(output_dir,"Mean_Energy_intake.pdf"))
@df fit_df plot!(:BinCumForage, :Gain_fit, group = :Richness,
    linewidth = 2, linestyle = :dash,  color = :Color)
savefig(joinpath(output_dir,"Fit_Energy_intake.pdf"))
##
for (r,c) in zip(eachrow(df2),[1,2,3])
    span = range(r.Extremes..., step = 0.1)
    plot!(plt,span, r.Polyfit.(span), color = c, legend = false)
end
savefig(joinpath(output_dir,"Fit_Mean_Energy_intake.pdf"))
display(plt)