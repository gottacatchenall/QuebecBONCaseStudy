using DrWatson
@quickactivate "QuebecBONCasestudy"

include(joinpath(srcdir(), "qcbon.jl"))
using Main.QCBON


# What this has to do to stay within disk memory limit:
# 1. Fit model and write model.bson
# 2. Plot SDM and uncertainty and save as png
# 3. Crop down to QC, mask, and save tifs

# 4. ? How compute combined group richness/uncertainty for contientnt? 



fit_and_project_sdms()

