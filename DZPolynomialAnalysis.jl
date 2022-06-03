module DZPolynomialAnalysis

export to_wolfram, has_real_root, is_positive_definite,
    has_unbounded_projection, integer_projection

using DZPolynomials
using MathLink

################################################################################

const WOLFRAM_VARIABLES = Dict(
    k => MathLink.WSymbol.(v)
    for (k, v) in DZPolynomials.CANONICAL_VARIABLES
)

function to_wolfram(p::Polynomial{T, N, I}) where {T, N, I}
    vars = WOLFRAM_VARIABLES[N]
    terms = Any[]
    for (m, c) in p
        factors = Any[]
        if !isone(c)
            push!(factors, Int(c))
        end
        for (i, n) in enumerate(m)
            if isone(n)
                push!(factors, vars[i])
            elseif !iszero(n)
                push!(factors, W"Power"(vars[i], Int(n)))
            end
        end
        if isempty(factors)
            push!(terms, 1)
        elseif length(factors) == 1
            push!(terms, factors[1])
        else
            push!(terms, W"Times"(factors...))
        end
    end
    if isempty(terms)
        return 0
    elseif length(terms) == 1
        return terms[1]
    else
        return W"Plus"(terms...)
    end
end

################################################################################

function has_real_root(p::Polynomial{T, N, I}) where {T, N, I}
    result = weval(W"Reduce"(
        W"Exists"(WOLFRAM_VARIABLES[N], W"Equal"(to_wolfram(p), 0)),
        W"Reals"
    ))
    if result == W"True"
        return true
    elseif result == W"False"
        return false
    else
        error()
    end
end

function is_positive_definite(p::Polynomial{T, N, I}) where {T, N, I}
    result = weval(W"Reduce"(
        W"ForAll"(WOLFRAM_VARIABLES[N], W"Greater"(to_wolfram(p), 0)),
        W"Reals"
    ))
    if result == W"True"
        return true
    elseif result == W"False"
        return false
    else
        error()
    end
end

function has_unbounded_projection(p::Polynomial{T, N, I},
                                  i::Int) where {T, N, I}
    vars = WOLFRAM_VARIABLES[N]
    stmt = W"ForAll"(W"T", W"Exists"(vars, W"And"(
        W"Equal"(to_wolfram(p), 0),
        W"Greater"(W"Power"(vars[i], 2), W"T")
    )))
    result = weval(W"Resolve"(stmt, W"Reals"))
    if result == W"True"
        return true
    elseif result == W"False"
        return false
    else
        error()
    end
end

function has_unbounded_projection(p::Polynomial{T, N, I}) where {T, N, I}
    for i = 1 : N
        if !has_unbounded_projection(p, i)
            return false
        end
    end
    return true
end

function integer_projection(p::Polynomial{T, N, I}, i::Int) where {T, N, I}
    vars = WOLFRAM_VARIABLES[N]
    result = weval(W"Reduce"(
        W"Resolve"(
            W"Exists"(deleteat!(copy(vars), i), W"Equal"(to_wolfram(p), 0)),
            W"Reals"
        ),
        vars[i],
        W"Integers"
    ))
    if result == W"False"
        return Int[]
    elseif (result.head == W"Equal" &&
            length(result.args) == 2 &&
            result.args[1] == vars[i])
        return Int[result.args[2]]
    elseif result.head == W"Or"
        @assert all(term.head == W"Equal" &&
                    length(term.args) == 2 &&
                    term.args[1] == vars[i]
                    for term in result.args)
        return Int[term.args[2] for term in result.args]
    else
        error()
    end
end

################################################################################

end # module DZPolynomialAnalysis
