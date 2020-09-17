module Analysis

using HTTP, JSON, DataFrames, Survival, StatsModels, StatsBase, CBioPortal

function parse_config(jsonstring)
    return JSON.Parser.parse(jsonstring)
end

function load_clinical_subset(config, clinical_data, survival_meta)
    study_id = config["study_id"]
    subset = clinical_data[(clinical_data.STUDY_ID.==study_id), :]
    meta = survival_meta[survival_meta.ID.==study_id, ["SURVIVAL_OUTCOME", "SURVIVAL_TIME_UNIT"]]
    outcome = meta[1][1]
    time_unit = meta[2][1]
    return (subset, outcome, time_unit)
end


function preprocess_moleculardata(response, config)
    # Initialise df
    df = DataFrame(PATIENT_ID=String[])
    for gene in config["genes"]
        df[:, string(gene["entrez"])] = Union{Float64, Missing}[]
    end

    # Fill temp dict
    dict = Dict()
    for object in response
        patient_id = object["patientId"]
        value = object["value"]
        entrez = object["entrezGeneId"]
        if haskey(dict, patient_id)
            dict[patient_id][entrez] = value
        else
            dict[patient_id] = Dict(entrez => value)
        end
    end

    # Fill df
    for (patient, values) in dict
        new_patient::Array{Any} = [ patient ]
        for gene in config["genes"]
            value = get(values, gene["entrez"], missing)
            push!(new_patient, value)
        end
        push!(df, new_patient)
    end

    dropmissing!(df)

    # Group based on columns
    groups = []
    percentiles = Dict(string(g["entrez"]) => StatsBase.percentile(df[:, string(g["entrez"])], g["percentile"]) for g in config["genes"])
    opposites = Dict(string(g["entrez"]) => StatsBase.percentile(df[:, string(g["entrez"])], 100-g["percentile"]) for g in config["genes"])
    # mirrored controls fulfil all the criteria of the test in the opposite percentile
    # complement controls are any cases not in the test group
    # NOTE that these are set per-gene
    # Also note that a control must be a control in ALL genes to be classified as a control
    # eg. if a case fulfils one gene criteria ("test group") but not another gene criteria ("control group") it will be completely excluded (neither group)
    for row in eachrow(df)
        satisfied_test = []
        satisfied_control = []
        for gene in config["genes"]
            entrez = string(gene["entrez"])
            percentile = percentiles[entrez]
            opposite = opposites[entrez]
            if gene["side"] == "above"
                single_satisfy_test = row[entrez] >= percentile
                if gene["control_type"] == "mirrored"
                    single_satisfy_control = row[entrez] < opposite
                elseif gene["control_type"] == "complement"
                    single_satisfy_control = !(single_satisfy_test)
                end
            elseif gene["side"] == "below"
                single_satisfy_test = row[entrez] <= percentile
                if gene["control_type"] == "mirrored"
                    single_satisfy_control = row[entrez] > opposite
                elseif gene["control_type"] == "complement"
                    single_satisfy_control = !(single_satisfy_test)
                end
            end
            push!(satisfied_test, single_satisfy_test)
            push!(satisfied_control, single_satisfy_control)
        end
        if all(satisfied_test)
            push!(groups, "TEST")
        elseif all(satisfied_control)
            push!(groups, "CONTROL")
        else
            push!(groups, "NEITHER")
        end
    end
    df.GROUP = groups
    return df
end


function join_data(clinicaldata, moleculardata)
    joined = innerjoin(clinicaldata, moleculardata, on=:PATIENT_ID)
    return joined
end

function preprocess_km(km_fit)
    # Steps
    steps = Dict(
        "times" => km_fit.times,
        "survival" => km_fit.survival
    )

    # Scatter
    censor_times = []
    censor_survival = []
    for (i, censored) in enumerate(km_fit.ncensor)
        if censored > 0
            push!(censor_times, km_fit.times[i])
            push!(censor_survival, km_fit.survival[i])
        end
    end
    censors = Dict(
        "times" => censor_times,
        "survival" => censor_survival
    )

    # Aggregating
    result = Dict(
        "steps" => steps,
        "censors" => censors
    )

    return result
end

function perform_km(joined)
    controls = joined[joined.GROUP .== "CONTROL", :]
    test = joined[joined.GROUP .== "TEST", :]

    km_control = fit(KaplanMeier, controls.TIME, controls.STATUS)
    km_test = fit(KaplanMeier, test.TIME, test.STATUS)

    km_results = Dict(
        "control" => preprocess_km(km_control),
        "test" => preprocess_km(km_test)
        )
    return km_results
end

function perform_cox(joined)
    subset = filter(row -> (row.GROUP == "CONTROL" || row.GROUP=="TEST"), joined)
    subset.EVENT = EventTime.(subset.TIME, Bool.(subset.STATUS))
    subset.GROUP_INT = map(row -> row.GROUP == "CONTROL" ? 0 : row.GROUP == "TEST" ? 1 : -1, eachrow(subset))
    cox_model = coxph(@formula(EVENT ~ GROUP_INT), subset)
    coefs = coeftable(cox_model)
    results = Dict(
        "p_value" => coefs.cols[4][1],
        "estimate" => coefs.cols[1][1],
        "hr" => exp(coefs.cols[1][1]),
    )
    return results
end

function perform_survival_analysis(config, all_clinical_data, all_survival_meta)
    local clinicaldata, clinicalevent, clinicaltimeunit, moleculardata
    @sync begin
        @async begin
            moleculardata_dict = CBioPortal.get_moleculardata(config)
            moleculardata = preprocess_moleculardata(moleculardata_dict, config)
        end
        @async begin
            (clinicaldata, clinicalevent, clinicaltimeunit) = load_clinical_subset(config, all_clinical_data, all_survival_meta)
        end
    end

    # Join the data
    joined = join_data(clinicaldata, moleculardata)
    total_num_joined = size(joined)[1]
    num_control = sum(joined.GROUP.=="CONTROL")
    num_test = sum(joined.GROUP.=="TEST")
    total_num_analysis = num_control + num_test

    # Perform statistics
    km = perform_km(joined)
    cox = perform_cox(joined)

    # Aggregate
    result = Dict(
        "km" => km,
        "cox" => cox,
        "event_type" => clinicalevent,
        "event_time_unit" => clinicaltimeunit,
        "num_available" => total_num_joined,
        "num_analysis" => total_num_analysis,
        "num_control" => num_control,
        "num_test" => num_test,
        "config" => config,
    )

    return result
end


end
