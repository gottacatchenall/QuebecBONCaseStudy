using DrWatson
@quickactivate "QuebecBONCasestudy"

include(joinpath(srcdir(), "qcbon.jl"))
using Main.QCBON


fit_and_project_sdms()

