using Genie.Router
using Genie.Renderer.Json
using Genie.Responses
using Genie.Requests
using SQLite, DataFrames
using Analysis

# Load all available data
db = SQLite.DB("./app/data/db.db")
clinical_data = SQLite.DBInterface.execute(db, "select * from clinical_data") |> DataFrame
survival_meta = SQLite.DBInterface.execute(db, "select * from study_survival_meta") |> DataFrame
survival_profiles = SQLite.DBInterface.execute(db, "select * from study_profiles") |> DataFrame
genes = SQLite.DBInterface.execute(db, "select * from genes") |> DataFrame

"Converts a DataFrame into an array of dictionaries."
function dftodict(df)
  objects = []
  for row in eachrow(df)
    object = Dict{String, Any}()
    for col in propertynames(df)
      push!(object, string(col) => row[col])
    end
    push!(objects, object)
  end
  return objects
end

"Joins the study and profile data to produce an array of dictionarys (each item representing a study)."
function preprocess_studies(survival_meta, survival_profiles)
  studies = []
  metaprops = propertynames(survival_meta)
  profileprops = propertynames(survival_profiles)
  for metarow in eachrow(survival_meta)
    object = Dict{String, Any}()
    for metacol in metaprops
      push!(object, string(metacol) => metarow[metacol])
    end
    profiles = []
    for profilerow in eachrow(survival_profiles)
      if metarow["ID"] == profilerow["STUDY_ID"]
        profileobj = Dict{String, Any}()
        for profilecol in profileprops
          push!(profileobj, string(profilecol) => profilerow[profilecol])
        end
        push!(profiles, profileobj)
      end
    end
    push!(object, "PROFILES" => profiles)
    push!(studies, object)
  end
  return studies
end

# Create a constant representing the JSON of all valid studies and their profiles
const json_studies = json(preprocess_studies(survival_meta, survival_profiles))

# Create a constant representing all valid genes
# Then filter to ensure every gene object has an entrez ID as it will be needed for the cBioPortal API during analysis
const dict_genes = dftodict(genes)
filter!(x -> !isempty(x["entrez"]), dict_genes)

route("/") do
  serve_static_file("welcome.html")
end

"""List all valid studies.
"""
route("/study") do 
  json_studies
end


"Search genes for all genes with HUGO ID starting with prefix."
function search_genes(genedict, prefix)
  filtered = filter(d -> startswith(lowercase(d["hugo"]), prefix), dict_genes)
  results = Dict("query" => prefix, "results" => filtered)
  return json(results)
end

"""List genes with a given prefix.

Query args:
- prefix (String): Minimum 2 character prefix to filter all genes by.

Returns:
- Array of objects with type {"name": string, "entrez": string, "hugo": string}
"""
route("/gene") do 
  prefix = haskey(@params, :prefix) ? @params(:prefix) : nothing
  if isnothing(prefix)
    return json(Dict("message" => "You must use a prefix of at least 2 characters."), status=422)
  elseif length(prefix) < 2
    return json(Dict("message" => "You must use a prefix of at least 2 characters."), status=422)
  else
    return search_genes(dict_genes, lowercase(prefix))
  end
end

#= Performs main analysis given a JSON config body.

Example post body:

    {
        "study_id": "brca_tcga_pub2015",
        "molecular_profile_id": "brca_tcga_pub2015_rna_seq_v2_mrna",
        "genes": [
            { "hugo": "BRCA1",
              "entrez": 672,
              "side": "above",
              "percentile": 75,
              "control_type": "mirrored"
            },
            { "hugo": "BRCA2",
              "entrez": 675,
              "side": "above",
              "percentile": 75,
              "control_type": "complement"
            }
        ]
    }

=#
route("/analysis", method=POST) do
    config = jsonpayload()
    results = Analysis.perform_survival_analysis(config, clinical_data, survival_meta)
    return json(results)
end
