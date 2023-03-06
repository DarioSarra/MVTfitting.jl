ExpGains(x,p) = @. (1 - exp(-p[1]*x)) * p[2]
leaving_tan(x,m,q) = @. m*x + q

function MVTtangent(coef, P)
    # P is the point where the line pass through
    # cumulative to be tangential to
    c(x) = @. (1 - exp(-coef[1]*x))*coef[2]
    #derivative of the cum, equal to the slope
    d(x) = @. coef[1] * exp(-coef[1]*x) *coef[2]
    #solve using slope-intercept form of the line
    # y-y0 = m(x-x0)
    # x0 has to be a point on the curve so express it in this way
    # y-c(x0) = d(x0)(x-x0)
    # solve passing for the point P
    # yp -c(x0) = d(x0)(xp-x0)
    # yp -c(x0) - d(x0)(xp-x0) = 0
    # f(x) = P[2] - (1 - exp(-coef[1]*x))*coef[2] - (coef[1] * exp(-coef[1]*x))*coef[2]*(P[1]-x)
    f(x) = P[2] - c(x) - d(x)*(P[1]-x)
    x0 = Roots.find_zero(f,0) # search x0 in a reasonable range of trial time
    #find inercept using P and m = d(x0)
    # y = mx +q
    # P[2] = d(x0)*P[1] + q
    # q = -d(x0)*P[1] - P[2]
    q = -d(x0)*P[1] - P[2]
    # sol(x) = @. x * d(x0) + q
    # return DataFrame(OptLeave = x0, Slope = d(x0), Intercept = q)
    return (x0,d(x0),q)
end

function MVTpoint(coef, m)
    # P is the point where the line pass through
    # cumulative to be tangential to
    c(x) = @. (1 - exp(-coef[1]*x))*coef[2]
    #derivative of the cum, equal to the slope
    d(x) = @. coef[1] * exp(-coef[1]*x) *coef[2]
    #solve using slope-intercept form of the line
    # y-y0 = m(x-x0)
    # x0 has to be a point on the curve so express it in this way
    # y-c(x0) = d(x0)(x-x0)
    # solve passing for the point P
    # yp -c(x0) = d(x0)(xp-x0)
    # yp -c(x0) - d(x0)(xp-x0) = 0
    # f(x) = P[2] - (1 - exp(-coef[1]*x))*coef[2] - (coef[1] * exp(-coef[1]*x))*coef[2]*(P[1]-x)
    # f(x) = P[2] - c(x) - d(x)*(P[1]-x)
    f(x) = d(x) - m
    x0 = Roots.find_zero(f,0) # search x0 in a reasonable range of trial time
    #find inercept using P and m = d(x0)
    y0 = c(x0)
    # y = mx + q
    q =  y0 - m*x0
    # sol(x) = @. x * d(x0) + q
    # return DataFrame(OptLeave = x0, Slope = d(x0), Intercept = q)
    return (x0,y0,q)
end

