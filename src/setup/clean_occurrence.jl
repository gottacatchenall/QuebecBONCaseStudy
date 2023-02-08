const filenames = ["amphib", "angio", "arthro", "bryophytes", "conifers", "fungi", "mammals"]


_nevermind_the_bollocks(str) = uppercasefirst(lowercase(string(split(str, " ")[1], " ", split(str, " ")[2])))

function clean_occurrence()
    indirpath = joinpath(DATA_DIR, "occurrence_raw")   
    outdirpath = joinpath(DATA_DIR, "occurrence_clean")   
    run(`mkdir -p $outdirpath`)

    for f in filenames
        filepath = joinpath(indirpath, string(f,".csv"))
        rawdf = CSV.read(filepath, DataFrame)
        rawdf = rawdf[completecases(rawdf[!, [:verbatimScientificName, :decimalLongitude, :decimalLatitude]]), :]
        species = _nevermind_the_bollocks.(rawdf[!, :verbatimScientificName])

        @info "There are $(length(unique(species))) $f species: $(unique(species))"

        for s in unique(species)
            i = findall(x->x==s, species)
            @info "$s: $(length(i)) occurrences"
        end

        df = DataFrame(
            gbifID=rawdf[!, :gbifID],
            species = species,
            latitude = rawdf[!, :decimalLatitude],
            longitude = rawdf[!, :decimalLongitude]
        )

        outpath = joinpath(outdirpath, string(f,".csv"))
        CSV.write(outpath, df)

        @info "\n\n"
    end

end

