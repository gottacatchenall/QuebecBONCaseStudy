function mask_chelsa(bounds)
    watermask = get_template_path()


    #CHELSA_processed

    for y in CHELSA_YEARS
        run(`mkdir -p $(joinpath(datadir(), CHELSA_MASKED_DIR, y))`)
        for s in SSPs
            run(`mkdir -p $(joinpath(datadir(), CHELSA_MASKED_DIR, y, s))`)
            for l in 1:19
                layer = load_chelsa_layer(y,s,l,bounds)
                geotiff(masked_layer_path(y,s,l), convert(Float32, mask(geotiff(SimpleSDMPredictor, watermask; bounds...),layer)))
            end 
        end
    end

end

masked_layer_path(y,s,l) = joinpath(datadir(), CHELSA_MASKED_DIR, y, s, "layer_$l.tif")


function load_masked_chelsa_layer!(y,s,l,bounds,layer)
    path = masked_layer_path(y,s,l)
    r = geotiff(SimpleSDMPredictor, path; bounds...)
    layer.grid .= r.grid
end 

function load_masked_chelsa_layers!(y,s, bounds, layers)
    for i in 1:length(layers)
        load_masked_chelsa_layer!(y,s,i,bounds,layers[i])
    end    
end


