/** Contains types and functions relating to cancer studies. */

/** Globally available survival outcomes are Overall Survival (os) or 
 * Disease-Free Survival (dfs). 
 */
export type OutcomeId = "os" | "dfs";

/** Convert an outcome ID "overall survival" or "disease-free survival". */
export function outcomeIdToString(outcome: OutcomeId) {
    switch (outcome) {
        case "os": return "Overall Survival"
        case "dfs": return "Disease-Free Survival"
    }
}

/** Each study may be associated with one or two available survival 
 * outcomes and will specify how many cases with this outcome are 
 * available. 
 */
export type OutcomeSpec = {
    study_id: string,
    outcome_id: OutcomeId,
    count: number,
}

/** Each study is associated with one or more available MRNA expression 
 * molecular profiles.
 */
export type MolecularProfile = {
    study_id: string,
    profile_id: string,
    name: string,
    description: string,
    datatype: string,
    molecularAlterationType: string
}

/** A cancer study and its associated metadata. */
export type Study = {
    study_id: string,
    cancer_type_id: string,
    description: string,
    name: string,
    pmid: null | string,
    short_name: null | string,
    outcomes: Array<OutcomeSpec>,
    molecular_profiles: Array<MolecularProfile>
}