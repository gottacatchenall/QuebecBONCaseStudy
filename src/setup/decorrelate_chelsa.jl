function decorrelate_chelsa(bounds)
    layers = preallocate_layers(bounds)
    load_masked_chelsa_layers!(CHELSA_YEARS[begin], SSPs[begin], bounds,layers)

    Is = common_Is(layers)
    matrix = zeros(19, length(Is))

    get_matrix_form!(layers, Is, matrix)
    matrix = convert.(Float32, matrix)
    w = fit_whitening(matrix)

    

end

function fit_whitening(matrix)
    w = MultivariateStats.fit(Whitening, matrix)
end

function common_Is(layers)
    Is = []
    for l in layers
        push!(Is, findall(x -> !isnothing(x) && !isnan(x), l.grid))
    end
    Is = unique(intersect(unique(Is)...))
end 

function get_matrix_form!(layers, I, matrix)
    for l in 1:length(layers)
        for (ct,i) in enumerate(I)
            if isnothing(layers[l].grid[i]) || isnan(layers[l].grid[i])
                @info "fails, l:$l, i: $i, ct:$ct"
                return 
            else
                matrix[l,ct] = layers[l].grid[i]
            end
        end
    end 
    return matrix
end 