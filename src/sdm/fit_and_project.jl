function fit_and_project_sdms()
    run(`mkdir -p $(joinpath(datadir(), SDMS_DIR))`)

    groups = get_species_groups()
    speciessets = get_species.(groups)

    for (i,species) in enumerate(speciessets)
        @info "\tGroup: $(groups[i])"
        for sp in species
            @info "\t\tSpecies: $sp"
            fit_and_project(groups[i],sp)
        end
    end
end

function fit_and_project(group,species)
    occ_layer = geotiff(SimpleSDMPredictor, occurrence_tif_path(group,species))

    climate_layers = load_fit_layers()

    pres, abs = get_pres_and_abs(occ_layer)
    model, xy, y, xy_pres, pres = fit_sdm(pres, abs, climate_layers)
    
    run(`mkdir -p $(joinpath(datadir(), SDMS_DIR, group))`)
    run(`mkdir -p $(joinpath(datadir(), SDMS_DIR, group, species))`)

    prediction, uncertainty = predict_sdm(climate_layers, model)
    dict = compute_fit_stats_and_cutoff(prediction, xy, y)

    write_stats(dict, joinpath(datadir(), SDMS_DIR, group, species, "fit.json"))

    for y in CHELSA_YEARS
        run(`mkdir -p $(joinpath(datadir(),SDMS_DIR, group, species, y))`)

        for s in SSPs
            run(`mkdir -p $(joinpath(datadir(),SDMS_DIR, group, species, y, s))`)

            theselayers = [geotiff(SimpleSDMPredictor, decorrelated_chelsa_path(y,s,l)) for l in 1:19]
            prediction, uncertainty = predict_sdm(theselayers, model)

            geotiff(joinpath(datadir(), SDMS_DIR, group, species, y, s, "prediction.tif"), prediction)
            geotiff(joinpath(datadir(), SDMS_DIR, group, species, y, s, "uncertainty.tif"), uncertainty)
        end
    end
end

function get_pres_and_abs(occurrence_layer)
    template = geotiff(SimpleSDMPredictor, get_template_path())
    @info template, occurrence_layer
    presences = convert(Bool, mask(template, occurrence_layer))
    absences = rand(SurfaceRangeEnvelope, presences)
    presences, absences 
end 

function fit_sdm(presences, absences, climate_layers)
    
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

function predict_sdm(climate_layers, model)
    all_values = hcat([layer[keys(layer)] for layer in climate_layers]...);
    pred = EvoTrees.predict(model, all_values);
    distribution = similar(climate_layers[1], Float64)
    distribution[keys(distribution)] = pred[:, 1]
    distribution
    
    uncertainty = similar(climate_layers[1], Float64)
    uncertainty[keys(uncertainty)] = pred[:, 2]
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

load_fit_layers(y="2011-2040", s="ssp126") = [geotiff(SimpleSDMPredictor, decorrelated_chelsa_path(y,s,l)) for l in 1:19]
get_species_groups() = readdir(occurrence_tifs_path())
get_species_occurrence_files(group) = readdir(joinpath(occurrence_tifs_path(), group))
get_species(group) = map(x->convert(String, split(x,".",)[1]),get_species_occurrence_files(group))
occurrence_tifs_path() = joinpath(datadir(), OCCURRENCE_TIFS_DIR)

occurrence_tif_path(g,sp) = joinpath(occurrence_tifs_path(), g, string("$sp.tif"))


fit_and_project_sdms()