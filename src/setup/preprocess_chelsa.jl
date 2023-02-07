function mask_chelsa(bounds)
    watermask = get_template_path()


    #CHELSA_processed

    for y in CHELSA_YEARS
        run(`mkdir -p $(joinpath(datadir(), "CHELSA_processed", y))`)
        for s in SSPs
            run(`mkdir -p $(joinpath(datadir(), "CHELSA_processed", y, s))`)
            for l in 1:19
                layer = load_chelsa_layer(y,s,l,bounds)
                geotiff(processed_layer_path(y,s,l), mask(geotiff(SimpleSDMPredictor, watermask; bounds...),layer))
            end 
        end
    end

end

processed_layer_path(y,s,l) = joinpath(datadir(), "CHELSA_processed", y, s, "layer_$l.tif")
