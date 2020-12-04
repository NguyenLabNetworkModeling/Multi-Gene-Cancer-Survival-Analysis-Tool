/** Contains all functions which interact with the backend API. */

import { AnalysisState } from "./AnalysisPage";
import { ControlType, convertGeneToBackendShape, Direction, Gene, GeneWithNumberEntrez } from "./Gene";
import { OutcomeId, Study } from "./Study";

/** Base backend API url without a trailing slash. */
const baseUrl = "http://127.0.0.1:5000"

/** Retrieve a list of all studies from the remote API. */
export function getStudies(onSuccess: (studies: Array<Study>) => void, onFailure: () => void) {
    const url = baseUrl + "/api/studies";
    fetch(url)
        .then((res) => { if (res.ok) { return res.json() } else { throw new Error() } })
        .then((res: Array<Study>) => onSuccess(res))
        .catch((reason) => onFailure())
}

/** Retrieve a list of genes matching a prefix from the remote API. Return empty array if error. */
export function getGenes(prefix: string, callback: (genes: Array<Gene>) => void) {
    if (prefix.length >= 2) {
        const url = baseUrl + "/api/genes?prefix=" + prefix;
        return fetch(url)
            .then((res) => { if (res.ok) { return res.json() } else { return [] } })
            .then((res) => callback(res))
            .catch(() => { callback([]) })
    } else {
        callback([])
    }
}

/** Expected shape of gene config for posting analysis to backend API.
 * Note threshold in this data shape is range 0-1, whereas it exists as 0-100 in frontend.
 */
export type AnalysisGeneConfig = {
    gene: GeneWithNumberEntrez,
    threshold: number, // range 0 to 1
    direction: Direction,
    control: ControlType
}

/** The expected shape of data by the backend API. */
export type AnalysisConfig = {
    analysis_id: number,
    study_id: string,
    profile_id: string,
    outcome_id: OutcomeId,
    thresholds: Array<AnalysisGeneConfig>
}

/** Possible states of the remote analysis. */
export type RemoteAnalysis =
    { config: AnalysisConfig, result: AnalysisResult } |
    { config: AnalysisConfig, result: "loading" } |
    { config: AnalysisConfig, result: "error", message: string };

export function isValidAnalysisState(state: AnalysisState) {
    return (state.selectedStudy && state.selectedProfile && state.selectedOutcome && (state.selectedGenes.length > 0));
}

/** Parse an analysis state into a sendable analysis config. */
export function parseAnalyisState(analysisId: number, state: AnalysisState): null | AnalysisConfig {

    if (state.selectedStudy && state.selectedProfile && state.selectedOutcome) {
        const study_id = state.selectedStudy.study_id;
        const profile_id = state.selectedProfile.profile_id;
        const outcome_id = state.selectedOutcome.outcome_id;

        var thresholds: Array<AnalysisGeneConfig> = [];

        if (state.selectedGenes.length > 0) {
            state.selectedGenes.forEach(gene => {
                const config = state.geneConfigRecord[gene.hugo];
                var newConfig = {
                    gene: convertGeneToBackendShape(gene),
                    threshold: config.threshold / 100,
                    direction: config.direction,
                    control: config.control,
                }
                thresholds.push(newConfig);
            })
        }

        return {
            analysis_id: analysisId,
            study_id: study_id,
            profile_id: profile_id,
            outcome_id: outcome_id,
            thresholds: thresholds
        }

    } else {
        return null;
    }

}

/** Single point for KM plot */
export type KMPoint = {
    timeline: number,
    KM_estimate: number,
}

/** Type of completed analysis sent from backend API. */
export type AnalysisResult = {
    "analysis_id": number,
    "num_test": number,
    "num_control": number,
    "num_clinical": number,
    "num_excluded": number,
    "outcome": OutcomeId,
    "outcome_units": string,
    "hazard_ratio": number,
    "p_value": number,
    "test_km_data": Array<KMPoint>,
    "test_km_censors": Array<KMPoint>,
    "cont_km_data": Array<KMPoint>,
    "cont_km_censors": Array<KMPoint>,
    "csv_data": string,
}

/** Send an analysis to the backend. */
export function postAnalysis(config: AnalysisConfig, onSuccess: (_: AnalysisResult) => void, onFailure: (id: number, s: string) => void) {
    const url = baseUrl + "/api/analyse";
    fetch(url, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(config) })
        .then((res) => { if (res.ok) { res.json().then((json) => onSuccess(json)) } else { res.json().then((json) => onFailure(config.analysis_id, json)) } })
        .catch((e) => onFailure(config.analysis_id, "Uncaught error."))
}
