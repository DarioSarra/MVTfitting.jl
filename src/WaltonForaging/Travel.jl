include("AverageRewardDF.jl")
baseline = check
average_rew_rate = df0
sav_dir = "/Users/dariosarra/Documents/Lab/Oxford/Walton/Presentations/Lab_meeting/Lab_meeting20230222/"
RichnessColor = Dict("poor" => :lightgreen, "medium" => :green, "rich" => :darkgreen)

##
pre_trav = combine(groupby(baseline, [:Travel, :SubjectID]),
    :CumForage => mean => :CumForage,
    :CumElapsedForage => mean => :CumElapsedForage
)
mean_trav = combine(groupby(pre_trav, :Travel),
    :CumForage .=> [mean,std] .=> [:M, :SD]
)
mean_trav[!,:Type] .= "Summed forage poking"
mean_trav2 = combine(groupby(pre_trav, :Travel),
    :CumElapsedForage .=> [mean,std] .=> [:M, :SD]
)
mean_trav2[!,:Type] .= "Elapsed time"
append!(mean_trav,mean_trav2)
mean_trav
##
@df mean_trav groupedbar(:Type,:M, group = :Travel, yerror = :SD, legend = :topleft)
savefig(joinpath(output_dir,"Travel.pdf"))
