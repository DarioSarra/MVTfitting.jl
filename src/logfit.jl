"Fits a straight line through a set of points, `y = a₁ + a₂ * x`"
function linear_fit(x, y)

    
    sx = sum(x)
    sy = sum(y)

    m = length(x)

    sx2 = zero(sx.*sx)
    sy2 = zero(sy.*sy)
    sxy = zero(sx*sy)

    for i = 1:m
        sx2 += x[i]*x[i]
        sy2 += y[i]*y[i]
        sxy += x[i]*y[i]
    end

    a0 = (sx2*sy - sxy*sx) / ( m*sx2 - sx*sx )
    a1 = (m*sxy - sx*sy) / (m*sx2 - sx*sx)

    return (a0, a1)
end

"Fits a log function through a set of points: `y = a₁+ a₂*log(x)`"
log_fit(x, y) = linear_fit(log.(x), y)