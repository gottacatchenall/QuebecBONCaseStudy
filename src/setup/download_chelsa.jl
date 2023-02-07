
const URL_BASE = "https://os.zhdk.cloud.switch.ch/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/"
const CLIMATE_MODEL = "GFDL-ESM4"



function download_chelsa()    
    run(`mkdir -p $(joinpath(datadir(), CHELSA_RAW_DIR))`)
    for y in CHELSA_YEARS, s in SSPs, l in 1:19
        @info "Downloading $y, $s, $l"
        outpath = raw_layer_path(y,s,l)
        Downloads.download(layer_url(y,s,l), outpath)
    end 
end

load_chelsa_layer(y,s,l,bounds) = geotiff(SimpleSDMPredictor, raw_layer_path(y,s,l); bounds...)


function load_chelsa(bounds)
    dict = Dict()
    for y in CHELSA_YEARS
        dict[y] = Dict()
        for s in SSPs
            dict[y][s] = []
            for l in 1:19
                path = raw_layer_path(y,s,l)
                push!(dict[y][s], geotiff(SimpleSDMPredictor, path; bounds...))
            end    
        end
    end 
    dict
end 



raw_layer_path(y,s,l) = joinpath(datadir(), CHELSA_RAW_DIR, y, s, "layer_$l.tif")

layer_url(year, ssp, layernum) = string(
           URL_BASE, 
           year, 
           "/", 
           CLIMATE_MODEL, 
           "/", 
           ssp, 
           "/bio/CHELSA_bio", 
           layernum, 
           "_", 
           year, 
           "_gfdl-esm4_", 
           ssp, 
           "_V.2.1.tif")


function _find_span(n, m, M, pos, side)
    side in [:left, :right, :bottom, :top] || throw(ArgumentError("side must be one of :left, :right, :bottom, top"))
    
    pos > M && return nothing
    pos < m && return nothing
    stride = (M - m) / n
    centers = (m + 0.5stride):stride:(M-0.5stride)
    pos_diff = abs.(pos .- centers)
    pos_approx = isapprox.(pos_diff, 0.5stride)
    if any(pos_approx)
        if side in [:left, :bottom]
            span_pos = findlast(pos_approx)
        elseif side in [:right, :top]
            span_pos = findfirst(pos_approx)
        end
    else
        span_pos = last(findmin(abs.(pos .- centers)))
    end
    return (stride, centers[span_pos], span_pos)
end

"""
    geotiff(::Type{LT}, file, bandnumber::Integer=1; left=nothing, right=nothing, bottom=nothing, top=nothing) where {LT <: SimpleSDMLayer}

The geotiff function reads a geotiff file, and returns it as a matrix of the
correct type. The optional arguments `left`, `right`, `bottom`, and `left` are
defining the bounding box to read from the file. This is particularly useful if
you want to get a small subset from large files.

The first argument is the type of the `SimpleSDMLayer` to be returned.
"""
function SimpleSDMLayers.geotiff(
    ::Type{LT},
    file::AbstractString,
    bandnumber::Integer=1;
    left = -180.0,
    right = 180.0,
    bottom = -90.0,
    top = 90.0
) where {LT<:SimpleSDMLayer}

    # This next block is reading the geotiff file, but also making sure that we
    # clip the file correctly to avoid reading more than we need.
    # This next block is reading the geotiff file, but also making sure that we
    # clip the file correctly to avoid reading more than we need.
    layer = ArchGDAL.read(file) do dataset

        transform = ArchGDAL.getgeotransform(dataset)
        wkt = ArchGDAL.getproj(dataset)

        # The data we need is pretty much always going to be stored in the first
        # band, but this is not the case for the future WorldClim data.
        band = ArchGDAL.getband(dataset, bandnumber)
        
        #T = ArchGDAL.pixeltype(band)
        T = Float32
        # The nodata is not always correclty identified, so if it is not found, we assumed it is the smallest value in the band
        nodata = isnothing(ArchGDAL.getnodatavalue(band)) ? convert(T, ArchGDAL.minimum(band)) : convert(T, ArchGDAL.getnodatavalue(band))

        # Get the correct latitudes
        minlon = transform[1]
        maxlat = transform[4]
        maxlon = minlon + size(band,1)*transform[2]
        minlat = maxlat - abs(size(band,2)*transform[6])

        left = isnothing(left) ? minlon : max(left, minlon)
        right = isnothing(right) ? maxlon : min(right, maxlon)
        bottom = isnothing(bottom) ? minlat : max(bottom, minlat)
        top = isnothing(top) ? maxlat : min(top, maxlat)

        lon_stride, lat_stride = transform[2], transform[6]
        
        width = ArchGDAL.width(dataset)
        height = ArchGDAL.height(dataset)

        #global lon_stride, lat_stride
        #global left_pos, right_pos
        #global bottom_pos, top_pos

        lon_stride, left_pos, min_width = _find_span(width, minlon, maxlon, left, :left)
        _, right_pos, max_width = _find_span(width, minlon, maxlon, right, :right)
        lat_stride, top_pos, max_height = _find_span(height, minlat, maxlat, top, :top)
        _, bottom_pos, min_height = _find_span(height, minlat, maxlat, bottom, :bottom)

        max_height, min_height = height .- (min_height, max_height) .+ 1

        # We are now ready to initialize a matrix of the correct type.
        buffer = Matrix{T}(undef, length(min_width:max_width), length(min_height:max_height))
        ArchGDAL.read!(dataset, buffer, bandnumber, min_height:max_height, min_width:max_width)
        buffer = convert(Matrix{Union{Nothing,eltype(buffer)}}, rotl90(buffer))
        replace!(buffer, nodata => nothing)
        LT(buffer, left_pos-0.5lon_stride, right_pos+0.5lon_stride, bottom_pos-0.5lat_stride, top_pos+0.5lat_stride)
    end

    return layer

end