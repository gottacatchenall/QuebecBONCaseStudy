module QCBON
    using SimpleSDMLayers
    using DrWatson
    using ArchGDAL
    using DataFrames, CSV
    using Downloads
    using MultivariateStats
    using EvoTrees
    using StatsBase
    using JSON

    const bounds = (top=67.0, bottom=23.0, left=-133.0, right=-50.0)
    #const bounds = (top=50.0, bottom=45.0, left=-70.0, right=-66.0)
   
   
    const CHELSA_YEARS = ["2011-2040", "2041-2070", "2071-2100"]
    const SSPs = ["ssp126", "ssp370", "ssp585"]
    const CHELSA_RAW_DIR = "CHELSA_raw"
    const CHELSA_MASKED_DIR = "CHELSA_masked"
    const CHELSA_DECORRELATED_DIR = "CHELSA_decorrelated"
    const OCCURRENCE_DATA_DIR = "occurrence_clean"
    const OCCURRENCE_TIFS_DIR = "occurrence_tifs"

    const SDMS_DIR = "SDMs"

    const GAUSS_TREE_PARAMS = EvoTreeGaussian(;
        loss=:gaussian,
        metric=:gaussian,
        nrounds=100,
        nbins=100,
        λ=0.0,
        γ=0.0,
        η=0.1,
        max_depth=7,
        min_weight=1.0,
        rowsample=0.5,
        colsample=1.0,
    )



    export 
        bounds, 
        CHELSA_YEARS, 
        SSPs, 
        CHELSA_RAW_DIR, 
        CHELSA_MASKED_DIR, 
        CHELSA_DECORRELATED_DIR, 
        OCCURRENCE_DATA_DIR, 
        OCCURRENCE_TIFS_DIR,
        SDMS_DIR,
        GAUSS_TREE_PARAMS

    include("setup/download_chelsa.jl")
    include("setup/download_water_cover.jl")

    include("setup/clean_occurrence.jl")
    include("setup/make_template_layer.jl")
    include("setup/preallocate_layers.jl")
    include("setup/preprocess_chelsa.jl")
    include("setup/decorrelate_chelsa.jl")
    include("setup/convert_occurrence_to_tif.jl")

    include("sdm/fit_and_project.jl")

    export get_template_path, decorrelated_chelsa_path
    export check_inbounds
    export download_chelsa, download_water_cover
    export make_template_layer, mask_chelsa, decorrelate_chelsa, convert_occurrence_to_tifs
end