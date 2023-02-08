#!/bin/bash


#SBATCH --time=0:10:00
#SBATCH --account=def-gonzalez
#SBATCH --mem=4G

export JULIA_DEPOT_PATH = "/project/def-gonzalez/mcatchen/JuliaEnvironments/QCBON"

module load julia/1.8.1
julia ../scripts/setup.jl

echo "exiting"
