
function make_template_layer(bounds)    
    dirpath = joinpath(DATA_DIR, CHELSA_MASKED_DIR, "templates")

    watercover_path = joinpath(dirpath, "watercover.tif")  
    
    water = convert(Float32, geotiff(SimpleSDMPredictor, watercover_path; bounds...))

    tmp = convert(Float32, load_chelsa_layer(CHELSA_YEARS[begin], SSPs[begin], 1, bounds))


    Iwater = findall(x->x==100., water.grid)

    I = CartesianIndices(size(water.grid))
    #Iland = filter(i-> i ∉ Iwater, I)


    template = similar(tmp)
    template.grid .= 1
    template.grid[Iwater] .= nothing

    template_path = get_template_path()

    geotiff(template_path, template)
end

get_template_path() = joinpath(DATA_DIR, CHELSA_MASKED_DIR, "templates", "template.tif")




