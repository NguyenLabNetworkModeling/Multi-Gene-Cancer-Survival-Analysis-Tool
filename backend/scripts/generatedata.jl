"Generate data for the backend so data that stays stable does not have to be continually fetched from the cBioPortal API."

using CBioPortal, SQLite, DataFrames, CSV

db = SQLite.DB("./db.db")

"""Pre-fetch studies from the cBioPortal api. 

To be a valid study, a study must satisfy the following requirements:

1. There must be clinical data with `clinicalAttributeId`s of (`OS_MONTHS` & `OS_STATUS`) or (`DFS_STATUS` & `DFS_MONTHS`)
2. There must be molecular profile data with `molecularProfileType` of `MRNA_EXPRESSION` 

We want to store:
1. Each study's relevant clinical data table with survival outcomes
2. Each study's relevant metadata including surival outcome type and survival measure
3. Each study's valid molecular profiles

Logs into `./logs/generate_studies.log`
Errors into `./logs/generate_studies.err`

"""
studies = CBioPortal.get_studies() # retrieve list of all studies on cBioPortal
valid_studies  = [] # initialise array of valid studies (store their JSON)
valid_study_survival_type = [] # initialise array of valid study survival data type
valid_study_molecular_profiles = []
study_log_file = "./logs/generate_studies.log" # filename of log file        
study_err_file = "./logs/generate_studies.err" # filename of error file
# iterate through all possible studies and check if valid
open(study_log_file, "w") do f    
    open(study_err_file, "w") do ef
        write(f, "study_id, valid, survival_outcome, survival_measure, num_patients\n")
        for study in studies
            study_id = study["studyId"]
            try
                clinicaldata = CBioPortal.get_clinicaldata(Dict("study_id" => study_id))
                preprocessed, outcome, measure = CBioPortal.preprocess_clinicaldata(clinicaldata)
                num_patients = size(preprocessed)[1]
                if num_patients > 0
                    molecularprofiles = CBioPortal.get_molecularprofiles(Dict("study_id" => study_id))
                    mrnaprofiles = [p for p in molecularprofiles if p["molecularAlterationType"] == "MRNA_EXPRESSION"]
                    if !isnothing(mrnaprofiles) && length(mrnaprofiles) > 0
                        preprocessed.STUDY_ID = study_id
                        push!(valid_studies, preprocessed)
                        push!(valid_study_survival_type, [study_id, outcome, measure])
                        for p in mrnaprofiles 
                            name = get(p, "name", "(Unknown name)")
                            profileId = get(p, "molecularProfileId", "(Unknown ID")
                            description = get(p, "description", "(Unknown description")
                            datatype = get(p, "datatype", "(Unknown datatype)")
                            push!(valid_study_molecular_profiles, [study_id, profileId, name, description, datatype])
                        end
                        write(f, """$study_id, 1, $outcome, $measure, $num_patients\n""")
                    else
                        write(f, """$study_id, 0, none, none, 0\n""")
                    end
                else
                    write(f, """$study_id, 0, none, none, 0\n""")
                end
            catch e
                write(ef, """$study_id, $(string(e))""")
            end
        end
    end
end
# make proper data tables
table_clinical_data = vcat(valid_studies...) 
table_survival_meta = DataFrame(permutedims(hcat(valid_study_survival_type...)), [:STUDY_ID, :SURVIVAL_OUTCOME, :SURVIVAL_TIME_UNIT]) 
table_study_profiles = DataFrame(permutedims(hcat(valid_study_molecular_profiles...)), [:STUDY_ID, :PROFILE_ID, :NAME, :DESCRIPTION, :DATATYPE]) 
# write to db
db_clinical_data = table_clinical_data |> SQLite.load!(db, "clinical_data") # write clinical data to db
db_study_survival_meta = table_survival_meta |> SQLite.load!(db, "study_survival_meta")
db_study_profiles = table_study_profiles |> SQLite.load!(db, "study_profiles")
# backup write to CSV
CSV.write("./logs/clinical_data.csv", table_clinical_data)
CSV.write("./logs/study_survival_meta.csv", table_survival_meta)
CSV.write("./logs/study_profiles.csv", table_study_profiles)

""" A table of genes was made in the earlier repo and simply merged with this database to produce a valid list of genes. """
