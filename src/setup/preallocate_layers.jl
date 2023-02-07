function preallocate_layers(bounds, n=19)
    templatepath = joinpath(datadir(), "CHELSA", "templates", "template.tif")
    
    template = geotiff(templatepath; bounds...)

    layers = []
    for l in 1:n
        thislayer = similar(template)
        thislayer.grid .= template.grid
        push!(layers, thislayer)
    end
    layers
end
