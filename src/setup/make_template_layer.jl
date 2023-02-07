
function make_template_layer(bounds)    
    dirpath = joinpath(datadir(), "CHELSA_processed", "templates")

    watercover_path = joinpath(dirpath, "watercover.tif")    
    water = convert(Float32, geotiff(SimpleSDMPredictor, watercover_path; bounds...))

    Iwater = findall(x->x==100., water.grid)

    I = CartesianIndices(size(water.grid))
    Iland = filter(i-> i ∉ Iwater, I)


    template = similar(water)
    template.grid .= nothing
    template.grid[Iland] .= 1
    template_path = get_template_path()

    geotiff(template_path, template)
end

get_template_path() = joinpath(datadir(), "CHELSA_processed", "templates", "template.tif")




