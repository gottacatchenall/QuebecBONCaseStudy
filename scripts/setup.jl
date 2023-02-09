using DrWatson
@quickactivate "QuebecBONCasestudy"

include(joinpath(srcdir(), "qcbon.jl"))
using Main.QCBON


@info "Making template layer..."
make_template_layer(bounds)

@info "Masking chelsa layers..."
mask_chelsa(bounds)

@info "Decorrelating chelsa layers..."
decorrelate_chelsa(bounds)

#@info "Converting occurrences to tifs..."
#convert_occurrence_to_tifs()


#=
fit_current_sdms()
project_future_sdms()

compute_gained_richness()
compute_lost_richness()
compute_uncertainty()
=#
