module QCBON
    using SimpleSDMLayers
    using DrWatson
    using ArchGDAL
    using DataFrames, CSV
    using Downloads
    using MultivariateStats

    const bounds = (top=67.0, bottom=23.0, left=-133.0, right=-50.0)
    #const bounds = (top=50.0, bottom=45.0, left=-70.0, right=-66.0)
    const CHELSA_YEARS = ["2011-2040", "2041-2070", "2071-2100"]
    const SSPs = ["ssp126", "ssp370", "ssp585"]
    const CHELSA_RAW_DIR = "CHELSA_raw"
    const CHELSA_MASKED_DIR = "CHELSA_masked"
    const CHELSA_DECORRELATED_DIR = "CHELSA_decorrelated"
    const OCCURRENCE_DATA_DIR = "occurrence_clean"

    export bounds, CHELSA_YEARS, SSPs, CHELSA_RAW_DIR, CHELSA_MASKED_DIR, CHELSA_DECORRELATED_DIR, OCCURRENCE_DATA_DIR

    include("setup/download_chelsa.jl")
    include("setup/download_water_cover.jl")

    include("setup/clean_occurrence.jl")
    include("setup/make_template_layer.jl")
    include("setup/preallocate_layers.jl")
    include("setup/preprocess_chelsa.jl")
    include("setup/decorrelate_chelsa.jl")
    include("setup/convert_occurrence_to_tif.jl")


    export download_chelsa, download_water_cover
    export make_template_layer, mask_chelsa, decorrelate_chelsa, convert_occurrence_to_tifs
end