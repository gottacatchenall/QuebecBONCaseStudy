function download_water_cover()
    url = "https://data.earthenv.org/consensus_landcover/without_DISCover/Consensus_reduced_class_12.tif"
    run(`mkdir -p $(joinpath(DATA_DIR, CHELSA_MASKED_DIR))`)
    dirpath = joinpath(DATA_DIR, CHELSA_MASKED_DIR, "templates")
    run(`mkdir -p $dirpath`)

    outpath = joinpath(dirpath, "watercover.tif")
    Downloads.download(url, outpath)
end