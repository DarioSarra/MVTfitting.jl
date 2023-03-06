time_to_rew(rew_num,initial_dur) = initial_dur *1.3^(rew_num-1)
rew_at_time(time,initial_dur) = 1 + (log(time) - log(initial_dur))/log(1.3)

#= this function defines how much time it takes to get the next reward.
    It is a function of the first reward forage time (1s poor, 0.5 medium, 0.227s rich)
    and the reward number. For each consecutive reward the time is increase by 1.3. 
    This determine the nth reward forage time. The actual time is sampled on 
    an exponential distribution with mean equal to the nth reward forage time
    =#
    function update_time(rew_num, initial)
        M = initial*(1.3^(rew_num-1))
        EXP = Exponential(M)
        CIlow = quantile(EXP,0.025)
        CIhigh =  quantile(EXP,0.925)
        return M, CIlow, CIhigh
    end
    
    function update_time(initial; n_rewards = 15)
        df = DataFrame(Mean = Float64[],CI_L = Float64[], CI_H = Float64[], Rew = Float64[])
        prev = 0
        for i in 1:n_rewards
            m, cil, cih = update_time(i,initial)
            push!(df,(Mean = m+prev,CI_L = cil+prev, CI_H = cih+prev, Rew = i))
            prev +=m
        end
        return df
    end

#function to simulate cumulative foraging gains 
GainModel(x,p) = @. (1 - exp(-p[1]*x)) *p[2] + p[3]