using DrWatson
@quickactivate "QuebecBONCasestudy"


println(
"""

"""
) 



#const bounds = (top=67.0, bottom=23.0, left=-133.0, right=-50.0)
const bounds = (top=67.0, bottom=65.0, left=-133.0, right=-132.0)

# Need to be done on login node
# download_chelsa()
# download_water_cover()

const CHELSA_YEARS = ["2011-2040", "2041-2070", "2071-2100"]
const SSPs = ["ssp126", "ssp370", "ssp585"]

const CHELSA_RAW_DIR = "CHELSA_raw"
const CHELSA_MASKED_DIR = "CHELSA_masked"
const CHELSA_DECORRELATED_DIR = "CHELSA_decorrelated"


make_template_layer(bounds)
mask_chelsa(bounds)


# layers = preallocate_layers(bounds)

decorrelate_chelsa(bounds)
convert_occurrence_to_tifs(bounds)


#=
fit_current_sdms()
project_future_sdms()

compute_gained_richness()
compute_lost_richness()
compute_uncertainty()
=#
