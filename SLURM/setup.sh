#!/bin/bash


#SBATCH --time=12:00:00
#SBATCH --account=def-gonzalez
#SBATCH --mem=128G

export JULIA_DEPOT_PATH = "/project/def-gonzalez/mcatchen/JuliaEnvironments/QCBON"

module load julia/1.8.1
julia --project=/project/def-gonzalez/mcatchen/QuebecBONCaseStudy ../scripts/setup.jl

echo "exiting"
