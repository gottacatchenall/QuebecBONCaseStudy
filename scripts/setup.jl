using DrWatson
@quickactivate "QuebecBONCasestudy"

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

include(joinpath(srcdir(), "setup", "download_chelsa.jl"))
include(joinpath(srcdir(), "setup", "download_water_cover.jl"))
include(joinpath(srcdir(), "setup","clean_occurrence.jl"))
include(joinpath(srcdir(), "setup","make_template_layer.jl"))
include(joinpath(srcdir(), "setup","preallocate_layers.jl"))
include(joinpath(srcdir(), "setup","preprocess_chelsa.jl"))
include(joinpath(srcdir(), "setup","decorrelate_chelsa.jl"))
include(joinpath(srcdir(), "setup","convert_occurrence_to_tif.jl"))


@info "Making template layer..."
make_template_layer(bounds)

@info "Masking chelsa layers..."
mask_chelsa(bounds)

@info "Decorrelating chelsa layers..."
decorrelate_chelsa(bounds)

@info "Converting occurrences to tifs..."
convert_occurrence_to_tifs()


#=
fit_current_sdms()
project_future_sdms()

compute_gained_richness()
compute_lost_richness()
compute_uncertainty()
=#
