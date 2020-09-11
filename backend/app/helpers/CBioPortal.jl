"Interaction interface with the cBioPortal API."
module CBioPortal

using HTTP, JSON, DataFrames

"The API base URL (without `/`) to construct requests."
const baseurl = "https://www.cbioportal.org/api"

"Send a GET request to the cBioPortal API and receive the JSON body."
function portal_request_get(path; query=nothing)
    request = HTTP.get(baseurl * path, query=query)
    json = request.body |> String |> JSON.Parser.parse
    return json
end

"Send a POST request to the cBioPortal API and receive the JSON body."
function portal_request_post(path, body; query=nothing)
    body_json = JSON.Writer.json(body)
    request = HTTP.post(baseurl * path, ["Content-Type" => "application/json"], body_json, query=query)
    json = request.body |> String |> JSON.Parser.parse
    return json
end

"Retrieve a list of studies as JSON."
function get_studies()
    response = portal_request_get("/studies")
    return response
end

"Retrieve clinical data as JSON."
function get_clinicaldata(config)
    clinical_attributes_of_interest = ["VITAL_STATUS", "OS_STATUS", "OS_MONTHS", "DFS_STATUS", "DFS_MONTHS", "DAYS_TO_LAST_FOLLOWUP", "DAYS_TO_DEATH"]
    response = portal_request_post("/studies/$(config["study_id"])/clinical-data/fetch",
        Dict("attributeIds" => clinical_attributes_of_interest),
        query="clinicalDataType=PATIENT")
    return response
end

"Preprocess retrieved clinical data (converts response JSON => DataFrame)."
function preprocess_clinicaldata(response)
    
    # Initialise df for all clinical data
    patient_df = DataFrame(
        PATIENT_ID=String[],
        VITAL_STATUS=Union{String,Missing}[],
        OS_STATUS=Union{String,Missing}[],
        OS_MONTHS=Union{Float64,Missing}[],
        DFS_STATUS=Union{String,Missing}[],
        DFS_MONTHS=Union{Float64,Missing}[],
        DAYS_TO_LAST_FOLLOWUP_OR_DEATH=Union{Float64,Missing}[],
    )
    
    # Fill temporary dict to accumulate clinical data keyed by patient ID
    patient_dict = Dict()
    keys = Set(["VITAL_STATUS", "OS_STATUS", "OS_MONTHS", "DFS_STATUS", "DFS_MONTHS", "DAYS_TO_LAST_FOLLOWUP", "DAYS_TO_DEATH"])
    floats = Set(["OS_MONTHS", "DFS_MONTHS", "DAYS_TO_LAST_FOLLOWUP", "DAYS_TO_DEATH"])
    for object in response
        clinical_attribute = object["clinicalAttributeId"]
        if clinical_attribute in keys
            object_patient_id = object["patientId"]
            
            if clinical_attribute in floats
                value = parse(Float64, object["value"])
            else
                value = object["value"]
            end
            
            if haskey(patient_dict, object_patient_id)
                patient_dict[object_patient_id][clinical_attribute] = value
            else
                patient_dict[object_patient_id] = Dict{String,Any}(clinical_attribute => value)
            end
        end
    end
    
    # Fill dataframe with patient rows
    for (patient_id, attributes) in patient_dict
        
        if haskey(attributes, "DAYS_TO_LAST_FOLLOWUP")
            days_to_last_followup_or_death = attributes["DAYS_TO_LAST_FOLLOWUP"]
        elseif haskey(attributes, "DAYS_TO_DEATH")
            days_to_last_followup_or_death = attributes["DAYS_TO_DEATH"]
        else
            days_to_last_followup_or_death = missing
        end
        
        new_patient = [
            patient_id,
            get(attributes, "VITAL_STATUS", missing),
            get(attributes, "OS_STATUS", missing),     
            get(attributes, "OS_MONTHS", missing),  
            get(attributes, "DFS_STATUS", missing),  
            get(attributes, "DFS_MONTHS", missing),  
            days_to_last_followup_or_death,  
        ]
        push!(patient_df, new_patient)
        end
    
    # choose combination of status and time
    df_os = dropmissing(patient_df[:, [:PATIENT_ID, :OS_STATUS, :OS_MONTHS]])
    num_os = size(df_os)[1]
    df_os_days = dropmissing(patient_df[:, [:PATIENT_ID, :OS_STATUS, :DAYS_TO_LAST_FOLLOWUP_OR_DEATH]])
    num_os_days = size(df_os_days)[1]
    df_dfs = dropmissing(patient_df[:, [:PATIENT_ID, :DFS_STATUS, :DFS_MONTHS]])
    num_dfs = size(df_dfs)[1]
    
    # Status of 0 indicates right-censor, 1 indicates event (e.g. death)
    function tostatus(string)
        if contains(string, "0")
            return 0
        elseif contains(string, "1")
            return 1
        else
            throw("Unknown status string.")
        end
    end
    
    # Return the combination with the most data points
    most_data = max(num_os, num_os_days, num_dfs)
    if num_os == most_data
        status = tostatus.(df_os.OS_STATUS)
        df_os.STATUS = status
        rename!(df_os, :OS_MONTHS => :TIME)
        return (df_os, "Overall Survival", "MONTHS")
    elseif num_os_days == most_data
        status = tostatus.(df_os_days.OS_STATUS)
        df_os_days.STATUS = status
        rename!(df_os_days, :DAYS_TO_LAST_FOLLOWUP_OR_DEATH => :TIME)
        return (df_os_days, "Overall Survival", "DAYS")
    elseif df_dfs == most_data
    status = tostatus.(df_dfs.DFS_STATUS)
        df_dfs.STATUS = status
        rename!(df_dfs, :DFS_MONTHS => :TIME)
        return (df_dfs, "Disease-Free Survival", "MONTHS")
    end

end

"Retrieve molecular profiles as JSON."
function get_molecularprofiles(config)
    return portal_request_get("/studies/$(config["study_id"])/molecular-profiles")
end


end
