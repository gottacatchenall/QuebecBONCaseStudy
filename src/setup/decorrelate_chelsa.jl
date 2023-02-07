function decorrelate_chelsa(bounds)
    layers = preallocate_layers(bounds)
    load_masked_chelsa_layers!(CHELSA_YEARS[begin], SSPs[begin], bounds,layers)

    Is = common_Is(layers)
    matrix = zeros(length(layers), length(Is))

    get_matrix_form!(layers, Is, matrix)
    matrix = convert.(Float32, matrix)
    w = fit_whitening(matrix)

    apply_and_write_decorrelated_chelsa(w, layers, matrix, bounds)
end

function apply_and_write_decorrelated_chelsa(w, layers, matrix, bounds)

    tmp = similar(layers[begin])

    for y in CHELSA_YEARS
        run(`mkdir -p $(joinpath(datadir(), CHELSA_DECORRELATED_DIR, y))`)
        for s in SSPs
            run(`mkdir -p $(joinpath(datadir(), CHELSA_DECORRELATED_DIR, y,s))`)
            load_masked_chelsa_layers!(y, s, bounds, layers)
            Is = common_Is(layers)
            get_matrix_form!(layers, Is, matrix)
            
            decorrelated_matrix = MultivariateStats.transform(w, matrix)
            
            tmp.grid .= nothing
            for l in 1:length(layers)
                tmp.grid[Is] .= decorrelated_matrix[l,:]

                path = decorrelated_chelsa_path(y,s,l)
                geotiff(path, tmp)
            end
        end 
    end
end

decorrelated_chelsa_path(y,s,l) = joinpath(datadir(), CHELSA_DECORRELATED_DIR, y,s, string("$l.tif"))

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