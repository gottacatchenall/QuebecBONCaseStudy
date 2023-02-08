function convert_occurrence_to_tifs()
    parentdir = joinpath(DATA_DIR, OCCURRENCE_DATA_DIR)
    csvs = readdir(parentdir)

    tmp = geotiff(SimpleSDMPredictor, get_template_path())
    run(`mkdir -p $(joinpath(DATA_DIR, "occurrence_tifs"))`)

    for csv in csvs
        group  = convert(String, split(csv,".")[1])
        run(`mkdir -p $(joinpath(DATA_DIR, "occurrence_tifs", group))`)
        df = CSV.read(joinpath(parentdir, csv), DataFrame)
        
        species = unique(df.species)
        @info "\t", group
        for s in species
            tmp.grid .= 0.
            thisdf = filter(r->r.species == s, df)


            for r in eachrow(thisdf)
                lat, long = Float32.([r.latitude, r.longitude])
                if check_inbounds(tmp, lat,long)
                    i = SimpleSDMLayers._point_to_cartesian(tmp, Point(long,lat))
                    tmp.grid[i] = 1.
                end
            end

            outpath = joinpath(DATA_DIR, "occurrence_tifs", group, string(s, ".tif"))
            geotiff(outpath, tmp)
        end
    end

end

function check_inbounds(tmp, lat, long)
    bb = boundingbox(tmp)
    lat > bb[:bottom] && lat < bb[:top] && long > bb[:left] && long < bb[:right]
end 