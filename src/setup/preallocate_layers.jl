function preallocate_layers(bounds, n=19)
    templatepath = joinpath(DATA_DIR, CHELSA_MASKED_DIR, "templates", "template.tif")
    template = geotiff(SimpleSDMPredictor,templatepath; bounds...)

    layers = []
    for l in 1:n
        thislayer = similar(template)
        thislayer.grid .= template.grid
        push!(layers, thislayer)
    end
    layers
end
