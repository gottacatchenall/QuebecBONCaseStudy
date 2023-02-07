using DrWatson
@quickactivate "QuebecBONCasestudy"

include(joinpath(srcdir(), "qcbon.jl"))
using Main.QCBON


download_chelsa()
download_water_cover()
