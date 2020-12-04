/** Page under the analysis tab for performing survival analyses. */

import React, { useState } from 'react';
import Select from 'react-select';
import { ControlType, Gene, GeneConfig } from './Gene';
import { MolecularProfile, OutcomeId, outcomeIdToString, OutcomeSpec, Study } from './Study';
import AsyncSelect from 'react-select/async';
import { AnalysisResult, getGenes, isValidAnalysisState } from './Api';
import { strictEqual } from 'assert';
import { generateKeyPair } from 'crypto';

/** Studies retrieved from the remote API and their laading + fail states. */
export type RemoteStudies = "loading" | "failed" | Array<Study>

type CreationSidebarProps = {
    studies: RemoteStudies,
    selectedStudy: null | Study,
    onClickStudy: (s: Study) => void,
    selectedOutcome: null | OutcomeSpec,
    selectedProfile: null | MolecularProfile,
    onSelectOutcome: (outcome: OutcomeSpec) => void,
    onSelectProfile: (profile: MolecularProfile) => void,
    selectedGenes: Array<Gene>,
    onSelectGenes: (gene: Array<Gene>) => void,
    geneConfigRecord: Record<string, GeneConfig>
    onChangeGeneThreshold: (gene: Gene, threshold: number) => void,
    onChangeGeneControlType: (gene: Gene) => void,
    onClickSubmitAnalysis: () => void,
}

/** Study selector for creating an analysis. */
function StudySelector(props: { studies: RemoteStudies, selectedStudy: null | Study, onClickStudy: (s: Study) => void }) {
    switch (props.studies) {
        case "loading":
            return (<Select isDisabled={true} isLoading={true} />)
        case "failed":
            return (<div>There was an error retrieving the list of available studies. Check your network connection and if the issue persists, please let us know.</div>)
        default:
            return (
                <Select
                    options={props.studies}
                    getOptionLabel={(s) => s.name}
                    getOptionValue={(s) => s.name}
                    placeholder="Select a study..."
                    inputId="study-selector"
                    value={props.selectedStudy}
                    onChange={(opt, act) => { if (opt) { props.onClickStudy(opt) } }}
                />
            )
    }
}

/** Information panel for a selected study. */
function StudyInfo(props: {
    selectedStudy: null | Study,
    selectedOutcome: null | OutcomeSpec,
    selectedProfile: null | MolecularProfile,
    onSelectOutcome: (o: OutcomeSpec) => void,
    onSelectProfile: (p: MolecularProfile) => void
}) {

    /** Convert an outcome to a displayable string with number of available cases. */
    function getOutcomeString(o: OutcomeSpec) {
        return outcomeIdToString(o.outcome_id) + " (" + o.count + ")";
    }

    if (props.selectedStudy) {
        return (
            <div>
                <article className="text-xs border-l border-gray-400 pl-4 my-2">
                    {props.selectedStudy.description}
                </article>
                <Select
                    options={props.selectedStudy.outcomes}
                    getOptionLabel={getOutcomeString}
                    getOptionValue={getOutcomeString}
                    value={props.selectedOutcome}
                    onChange={(opt, act) => { if (opt) { props.onSelectOutcome(opt) } }} />
                <Select
                    options={props.selectedStudy.molecular_profiles}
                    getOptionLabel={(p) => p.name}
                    getOptionValue={(p) => p.name}
                    value={props.selectedProfile}
                    onChange={(opt, act) => { if (opt) { props.onSelectProfile(opt) } }} />

            </div>)
    } else {
        return (<div></div>)
    }
}

/** Multi-selector for genes. */
function GeneSelector(props: { onSelectGenes: (gene: Array<Gene>) => void, selectedGenes: Array<Gene> }) {
    return (
        <AsyncSelect
            getOptionLabel={(s) => s.hugo}
            getOptionValue={(s) => s.hugo}
            placeholder="Type at least two characters to search genes..."
            inputId="gene-selector"
            isMulti
            cacheOptions
            loadOptions={getGenes}
            defaultOptions={[]}
            onChange={(opt, act) => { opt ? props.onSelectGenes(opt.slice()) : props.onSelectGenes([]) }}
            value={props.selectedGenes}
        />
    )
}


/** Configuration line for a single gene to select threshold + control type. */
function SingleGeneConfigurator(props: {
    gene: Gene,
    onChangeGeneControlType: (gene: Gene) => void,
    onChangeGeneThreshold: (gene: Gene, threshold: number) => void
    geneConfigRecord: Record<string, GeneConfig>,
}) {
    const geneConfig = props.geneConfigRecord[props.gene.hugo];
    const mirroredStyle = geneConfig.control == "mirrored" ? " bg-gray-400 text-white" : " border-gray-200 text-gray-500"
    return (
        <div className="flex">
            <div className="w-1/3">{props.gene.hugo}</div>
            <button onClick={(_) => props.onChangeGeneControlType(props.gene)} className={"px-2 rounded text-xs" + mirroredStyle}>Mirrored Controls</button>
            <GeneConfigSlider gene={props.gene} onChangeGeneThreshold={props.onChangeGeneThreshold} geneConfig={geneConfig} />
        </div>
    )
}



/** Slider to control gene threshold for each gene. */
function GeneConfigSlider(props: { onChangeGeneThreshold: (gene: Gene, thres: number) => void, gene: Gene, geneConfig: GeneConfig }) {
    const [state, setState] = useState({ threshold: props.geneConfig.threshold, direction: props.geneConfig.direction });
    const controlClass = " bg-gray-300";
    const testClass = " bg-blue-500";
    var middleSegmentLeft = 0, rightSegmentLeft = 0, leftSegmentWidth = 0, middleSegmentWidth = 0, rightSegmentWidth = 0;
    var leftSegmentClass = "", rightSegmentClass = "";
    if (props.geneConfig.control == "mirrored") {
        if (state.direction == "above") {
            leftSegmentWidth = 100 - state.threshold;
            rightSegmentWidth = leftSegmentWidth;
            rightSegmentClass = testClass;
            leftSegmentClass = controlClass;
        } else {
            leftSegmentWidth = state.threshold;
            rightSegmentWidth = state.threshold;
            leftSegmentClass = testClass;
            rightSegmentClass = controlClass;
        }
    } else {
        if (state.direction == "above") {
            rightSegmentWidth = 100 - state.threshold;
            leftSegmentWidth = state.threshold;
            leftSegmentClass = controlClass;
            rightSegmentClass = testClass;
        } else {
            leftSegmentWidth = state.threshold;
            rightSegmentWidth = 100 - leftSegmentWidth;
            leftSegmentClass = testClass;
            rightSegmentClass = controlClass;
        }
    }
    middleSegmentLeft = leftSegmentWidth;
    middleSegmentWidth = 100 - leftSegmentWidth - rightSegmentWidth;
    rightSegmentLeft = leftSegmentWidth + middleSegmentWidth;

    function pct(number: number) { return number.toString() + "%" };

    function onInput(threshold: number) {
        setState((prev) => {
            if (threshold > 50) {
                return { threshold: threshold, direction: "above" }
            } else if (threshold < 50) {
                return { threshold: threshold, direction: "below" }
            } else {
                return { ...prev, threshold: threshold }
            }
        })
    }

    return (
        <div className="flex">
            <div className="relative">
                <div style={{ width: pct(leftSegmentWidth), left: pct(0), zIndex: -10 }} className={"pointer-events-none absolute" + leftSegmentClass}>&nbsp;</div>
                <div style={{ width: pct(middleSegmentWidth), left: pct(middleSegmentLeft), zIndex: -10 }} className={"pointer-events-none absolute"}>&nbsp;</div>
                <div style={{ width: pct(rightSegmentWidth), left: pct(rightSegmentLeft), zIndex: -10 }} className={"pointer-events-none absolute" + rightSegmentClass}>&nbsp;</div>
                <input type="range" min="0" max="100"
                    className="z-30"
                    onInput={(e) => onInput(parseFloat(e.currentTarget.value))}
                    value={state.threshold}
                    onMouseUp={(e) => props.onChangeGeneThreshold(props.gene, state.threshold)} />
            </div>
            <input
                type="number" value={state.threshold} className="w-12 px-1"
                onInput={(e) => onInput(parseFloat(e.currentTarget.value))} />
            <div>%</div>
        </div>
    )
}


function SubmitButton(props: { onClickSubmit: () => void }) {
    return (
        <button onClick={props.onClickSubmit}>Submit Analysis</button>
    )
}

/** Creation sidebar containing all options for creating an analysis. */
function CreationSidebar(props: CreationSidebarProps) {

    const isValidToSubmit = (props.selectedStudy && props.selectedOutcome && props.selectedProfile && (props.selectedGenes.length > 0)) ? true : false;

    return (
        <article className="p-2 w-96 text-sm">
            <label htmlFor="study-selector">Select a Study:</label>
            <StudySelector studies={props.studies}
                onClickStudy={props.onClickStudy}
                selectedStudy={props.selectedStudy} />
            <StudyInfo selectedStudy={props.selectedStudy}
                selectedOutcome={props.selectedOutcome}
                selectedProfile={props.selectedProfile}
                onSelectOutcome={props.onSelectOutcome}
                onSelectProfile={props.onSelectProfile} />
            <hr />
            <GeneSelector onSelectGenes={props.onSelectGenes} selectedGenes={props.selectedGenes} />
            <div>
                {props.selectedGenes.map((gene) =>
                    <SingleGeneConfigurator
                        gene={gene} onChangeGeneThreshold={props.onChangeGeneThreshold}
                        key={gene.hugo} geneConfigRecord={props.geneConfigRecord}
                        onChangeGeneControlType={props.onChangeGeneControlType} />)}
            </div>
            <hr />
            { isValidToSubmit ? <SubmitButton onClickSubmit={props.onClickSubmitAnalysis} /> : <div></div>}
        </article>
    )

}

/** Analysis viewing container which contains all submitted analyses. */
function AnalysisPanelContainer() {
    return (
        <section>

        </section>
    )
}

/** Props for the analysis page. */
export type AnalysisState = {
    studies: RemoteStudies,
    selectedStudy: null | Study,
    selectedOutcome: null | OutcomeSpec,
    selectedProfile: null | MolecularProfile,
    selectedGenes: Array<Gene>,
    geneConfigRecord: Record<string, GeneConfig> // from HUGO id to threshold
}

/** Default analysis state. */
export const defaultAnalysisState: AnalysisState = {
    studies: "loading",
    selectedStudy: null,
    selectedOutcome: null,
    selectedProfile: null,
    selectedGenes: [],
    geneConfigRecord: {}
}

type Props = {
    analysisState: AnalysisState,
    onClickStudy: (s: Study) => void,
    onSelectOutcome: (outcome: OutcomeSpec) => void,
    onSelectProfile: (profile: MolecularProfile) => void,
    onSelectGenes: (genes: Array<Gene>) => void,
    onChangeGeneThreshold: (gene: Gene, threshold: number) => void,
    onChangeGeneControlType: (gene: Gene) => void,
    onClickSubmitAnalysis: () => void,
}

/** Main analysis page container. */
function AnalysisPage(props: Props) {
    return (
        <div className="w-full flex h-full" >
            <section className="shadow">
                <CreationSidebar
                    studies={props.analysisState.studies}
                    selectedStudy={props.analysisState.selectedStudy}
                    onClickStudy={props.onClickStudy}
                    selectedOutcome={props.analysisState.selectedOutcome}
                    selectedProfile={props.analysisState.selectedProfile}
                    onSelectOutcome={props.onSelectOutcome}
                    onSelectProfile={props.onSelectProfile}
                    selectedGenes={props.analysisState.selectedGenes}
                    onSelectGenes={props.onSelectGenes}
                    geneConfigRecord={props.analysisState.geneConfigRecord}
                    onChangeGeneThreshold={props.onChangeGeneThreshold}
                    onChangeGeneControlType={props.onChangeGeneControlType}
                    onClickSubmitAnalysis={props.onClickSubmitAnalysis}
                />
            </section>
            <section className="flex-grow">
                <AnalysisPanelContainer />
            </section>
        </div>
    )
}

export default AnalysisPage;