function fit_and_project_sdms()
    run(`mkdir -p $(joinpath(datadir(), SDMS_DIR))`)

    groups = get_species_groups()
    speciessets = get_species.(groups)
    qc = geotiff(SimpleSDMPredictor, joinpath(datadir(), "qc_mask_fixed.tif"))
    climate_layers = load_fit_layers()
    I = common_Is(climate_layers)


    qc_mask = mask(qc, climate_layers[begin])

    qc_mask = clip(qc_mask; QCbounds...)
    #Imask = findall(isnothing, qc.grid) 

    for (i,species) in enumerate(speciessets)
        @info "\tGroup: $(groups[i])"
        for sp in species
            @info "\t\tSpecies: $sp"
            fit_and_project(groups[i], sp, qc_mask, climate_layers, I)
        end
    end
end

function fit_and_project(group,species, qc, climate_layers, I)
    
    occ_layer = get_presences(group, species, climate_layers[begin])
    pres, abs = get_pres_and_abs(occ_layer)
    model, xy, y, xy_pres, pres = fit_sdm(pres, abs, climate_layers)
    
    run(`mkdir -p $(joinpath(datadir(), SDMS_DIR, group))`)
    run(`mkdir -p $(joinpath(datadir(), SDMS_DIR, group, species))`)


    prediction, uncertainty = predict_sdm(climate_layers, model,I)
    dict = compute_fit_stats_and_cutoff(prediction, xy, y)

    write_stats(dict, joinpath(datadir(), SDMS_DIR, group, species, "fit.json"))


    bson_path = joinpath(datadir(), SDMS_DIR, group, species, "model.bson")
    @save bson_path model

    for y in CHELSA_YEARS
        run(`mkdir -p $(joinpath(datadir(),SDMS_DIR, group, species, y))`)
        run(`mkdir -p $(joinpath(plotsdir(),SDMS_DIR, group, species, y))`)

        for s in SSPs
            run(`mkdir -p $(joinpath(datadir(),SDMS_DIR, group, species, y, s))`)
            run(`mkdir -p $(joinpath(plotsdir(),SDMS_DIR, group, species, y, s))`)

            theselayers = [geotiff(SimpleSDMPredictor, decorrelated_chelsa_path(y,s,l)) for l in 1:19]
            prediction, uncertainty = predict_sdm(theselayers, model,I)

    
            f_prediction, f_uncert = make_map(prediction, species), make_map(uncertainty, species, :viridis)

            predict_path = joinpath(plotsdir(),SDMS_DIR, group, species, y, s, "sdm.png")
            uncert_path = joinpath(plotsdir(),SDMS_DIR, group, species, y, s, "uncertainty.png")

            save(predict_path, f_prediction)
            save(uncert_path, f_uncert)

            #qc_mask = clip(qc, prediction)

            prediction = mask(qc,prediction)
            uncertainty = mask(qc,uncertainty)

            geotiff(joinpath(datadir(), SDMS_DIR, group, species, y, s, "prediction.tif"), prediction)
            geotiff(joinpath(datadir(), SDMS_DIR, group, species, y, s, "uncertainty.tif"), uncertainty)
        end
    end
end

function get_presences(group, species, template)
    df = CSV.read(joinpath(datadir(), OCCURRENCE_DATA_DIR, "$group.csv"), DataFrame)
    thisdf = filter(r->r.species == species, df)

    thissp = similar(template)

   # thissp.grid[findall(isnothing, thissp.grid)] .= nothing
   # I = findall(!isnothing, thissp.grid)
    thissp.grid .= false

    thissp = convert(Bool, thissp)
    for r in eachrow(thisdf)
        lat, long = Float32.([r.latitude, r.longitude])
        if check_inbounds(thissp, lat,long)
            i = SimpleSDMLayers._point_to_cartesian(thissp, Point(long,lat))
            thissp.grid[i] = 1
        end
    end
    thissp
end 


function get_pres_and_abs(presences)
    absences = rand(SurfaceRangeEnvelope, presences)
    presences, absences 
end 

function fit_sdm(presences, absences, climate_layers)
    presences = mask(presences, climate_layers[begin])
    absences = mask(absences, climate_layers[begin])

    xy_presence = keys(replace(presences, false => nothing));
    xy_absence = keys(replace(absences, false => nothing));
    xy = vcat(xy_presence, xy_absence);

    
    X = hcat([layer[xy] for layer in climate_layers]...);
    y = vcat(fill(1.0, length(xy_presence)), fill(0.0, length(xy_absence)));
    
    train_size = floor(Int, 0.7 * length(y));
    train_idx = StatsBase.sample(1:length(y), train_size; replace=false);
    test_idx = setdiff(1:length(y), train_idx);


    Xtrain, Xtest = X[train_idx, :], X[test_idx, :];
    Ytrain, Ytest = y[train_idx], y[test_idx];

    model = fit_evotree(
        GAUSS_TREE_PARAMS;
        x_train=Xtrain, 
        y_train=Ytrain, 
        x_eval=Xtest, 
        y_eval=Ytest);
    return model, xy, y, xy_presence, presences
end

function predict_sdm(climate_layers, model, I)
    # Build this smarter
    #all_values = hcat([layer[keys(layer)] for layer in climate_layers]...);

    all_values = zeros(Float32,length(I), length(climate_layers))

    for (i, idx) in enumerate(I)
        for l in 1:length(climate_layers)
            all_values[i,l] = climate_layers[l].grid[idx]     
        end 
    end

    pred = EvoTrees.predict(model, all_values);
    distribution = similar(climate_layers[1], Float64)
    distribution[I] = pred[:, 1]
    distribution
    
    uncertainty = similar(climate_layers[1], Float64)
    uncertainty[I] = pred[:, 2]
    uncertainty

    return rescale(distribution, (0,1)), rescale(uncertainty, (0,1))
end 

function compute_fit_stats_and_cutoff(distribution,xy,y)
    cutoff = LinRange(extrema(distribution)..., 500);

    obs = y .> 0
    
    tp = zeros(Float64, length(cutoff));
    fp = zeros(Float64, length(cutoff));
    tn = zeros(Float64, length(cutoff));
    fn = zeros(Float64, length(cutoff));
    
    for (i, c) in enumerate(cutoff)
        prd = distribution[xy] .>= c
        tp[i] = sum(prd .& obs)
        tn[i] = sum(.!(prd) .& (.!obs))
        fp[i] = sum(prd .& (.!obs))
        fn[i] = sum(.!(prd) .& obs)
    end
    
    tpr = tp ./ (tp .+ fn);
    fpr = fp ./ (fp .+ tn);
    J = (tp ./ (tp .+ fn)) + (tn ./ (tn .+ fp)) .- 1.0;
    ppv = tp ./ (tp .+ fp);

    roc_dx = [reverse(fpr)[i] - reverse(fpr)[i - 1] for i in 2:length(fpr)]
    roc_dy = [reverse(tpr)[i] + reverse(tpr)[i - 1] for i in 2:length(tpr)]
    ROCAUC = sum(roc_dx .* (roc_dy ./ 2.0))

    thr_index = last(findmax(J))
    τ = cutoff[thr_index]

    Dict(:rocauc=>ROCAUC, :threshold=>τ, :J=>J[last(findmax(J))]), τ
end 

function write_stats(statsdict, path)
    json_string = JSON.json(statsdict)
    open(path,"w") do f
      JSON.print(f, json_string)
    end
end 

function make_map(layer, species, cs=:thermal)
    fig = Figure(resolution=(1400, 1000))
    panel = GeoAxis(
        fig[1, 1];
        source = "+proj=longlat +datum=WGS84",
        dest = "+proj=ortho +lon_0=-90 -lat_0=60",
        title=species,
        spinewidth=0,
        titlealign=:left,
        lonlims = extrema(longitudes(layer)),
        latlims = extrema(latitudes(layer)),
    )
    CairoMakie.heatmap!(
        panel,
        sprinkle(convert(Float32, layer))...;
        shading = false,
        interpolate = false,
        colormap = cs,
    )
    return fig
end

function sprinkle(layer::T) where {T <: SimpleSDMLayer}
    return (
        longitudes(layer),
        latitudes(layer),
        transpose(replace(layer.grid, nothing => NaN)),
    )
end

load_fit_layers(y="2011-2040", s="ssp126") = [geotiff(SimpleSDMPredictor, decorrelated_chelsa_path(y,s,l)) for l in 1:19]
get_species_groups() = readdir(occurrence_tifs_path())
get_species_occurrence_files(group) = readdir(joinpath(occurrence_tifs_path(), group))
get_species(group) = map(x->convert(String, split(x,".",)[1]),get_species_occurrence_files(group))
occurrence_tifs_path() = joinpath(datadir(), OCCURRENCE_TIFS_DIR)

occurrence_tif_path(g,sp) = joinpath(occurrence_tifs_path(), g, string("$sp.tif"))


fit_and_project_sdms()
