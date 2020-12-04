/** Page under the analysis tab for performing survival analyses. */

import React, { useState } from 'react';
import Select from 'react-select';
import { ControlType, Gene, GeneConfig } from './Gene';
import { MolecularProfile, OutcomeId, outcomeIdToString, OutcomeSpec, Study } from './Study';
import AsyncSelect from 'react-select/async';
import { AnalysisGeneConfig, AnalysisResult, getGenes, isValidAnalysisState, KMPoint, RemoteAnalysis } from './Api';
import { strictEqual } from 'assert';
import { generateKeyPair } from 'crypto';
import { defaultProps } from 'react-select/src/Select';
import { ResponsiveContainer, LineChart, Line, ScatterChart, Scatter, XAxis, YAxis, CartesianGrid, Legend } from "recharts";
import { resultsAriaMessage } from 'react-select/src/accessibility';

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

/** Transform a gene config object into components of an information string based on group. */
function geneConfigToComponents(config: AnalysisGeneConfig, group: "test" | "control") {
    const comparer = group == "test"
        ? (config.direction == "above" ? ">" : "<")
        : (config.control == "complement"
            ? (config.direction == "above" ? "≤" : "≥")
            : (config.direction == "above" ? "<" : ">"));

    const threshold = group == "test"
        ? config.threshold
        : (config.control == "complement" ? config.threshold : 1 - config.threshold);

    return { gene: config.gene, comparer: comparer, threshold: threshold, group: group };

}

/** Body of each single analysis card */
function AnalysisCardBody(props: { remoteAnalysis: RemoteAnalysis}) {
    switch (props.remoteAnalysis.result) {
            case "loading": {
                return (
                    <div className="p-2 text-sm text-gray-700 flex justify-center items-center h-full text-center font-medium">
                        Loading...
                    </div>
                )
            }
            case "error": {
                return (
                        <div className="p-2 text-sm text-red-500 flex justify-center items-center h-full text-center font-medium">
                            Whoops, that didn't work: {props.remoteAnalysis.message}
                        </div>
                )
            }
            default: {
                return (
                        <div className="flex h-full">
                            <div className="p-2 pl-2 flex-grow flex justify-center items-center">
                                <div className="text-xs h-24 w-24 2xl:h-36 2xl:w-48 border-b border-l border-gray-500">
                                    <ResponsiveContainer>
                                        <LineChart margin={{ top: 0, right: 0, bottom: 0, left: 0}}>
                                            <XAxis type="number" dataKey="timeline" name="Time" unit={props.remoteAnalysis.result.outcome_units} hide/>
                                            <YAxis type="number" dataKey="KM_estimate" name="Survival Estimate" hide/>
                                            <Line name="Test" data={props.remoteAnalysis.result.test_km_data} 
                                                dataKey="KM_estimate" type="stepAfter"
                                                stroke="#2563EB" 
                                                isAnimationActive={false} dot={false}/>
                                            <Line name="Control" data={props.remoteAnalysis.result.cont_km_data} 
                                                dataKey={(x: KMPoint) => x.KM_estimate} type="stepAfter" 
                                                stroke="#6B7280"
                                                isAnimationActive={false} dot={false}/>
                                        </LineChart>
                                    </ResponsiveContainer>
                                </div>
                            </div>
                            <div className="text-xs pr-4 flex items-center justify-center">
                                <table className="text-right">
                                    <tr className="text-center border-b border-gray-300">
                                        <td colSpan={2} className="font-medium" >{outcomeIdToString(props.remoteAnalysis.config.outcome_id)}</td>
                                    </tr>
                                    <tr className="font-mono pt-1">
                                        <td className="font-bold pr-1 text-left">HR</td>
                                        <td>{props.remoteAnalysis.result.hazard_ratio.toFixed(2)}</td>
                                    </tr>
                                    <tr className="font-mono pt-1">
                                        <td className="font-bold pr-1 text-left">p</td>
                                        <td>{props.remoteAnalysis.result.p_value.toFixed(3)}</td>
                                    </tr>
                                    <tr className="font-mono pt-1">
                                        <td className="font-bold pr-1 text-left">n_test</td>
                                        <td>{props.remoteAnalysis.result.num_test}</td>
                                    </tr>
                                    <tr className="font-mono pt-1">
                                        <td className="font-bold pr-1 text-left">n_control</td>
                                        <td>{props.remoteAnalysis.result.num_control}</td>
                                    </tr>
                                </table>
                            </div>
                        </div>
                )
            }
        }
}

/** View a single analysis card in batch view. */
const AnalysisCard = React.memo((props: { remoteAnalysis: RemoteAnalysis, onDeleteAnalysis: (id: number) => void }) => {

    function viewGene(config: AnalysisGeneConfig, group: "test" | "control") {
        const components = geneConfigToComponents(config, group);
        const textColor = config.direction == "above" ? (group == "test" ? " text-pink-700" : " text-purple-700") : (group == "test" ? " text-purple-700" : " text-pink-700");
        return (
            <div className={"flex mr-1" + textColor}>
                <div className="text-xs border px-1 font-medium">{config.gene.hugo}</div>
                <div>{components.comparer}</div>
                <div className="">{components.threshold}</div>
            </div>
        )
    }

    var addedClass;
    switch (props.remoteAnalysis.result) {
        case "loading": addedClass = " border-t-2 border-gray-200"; break;
        case "error": addedClass = " border-t-2 border-gray-300"; break;
        default: addedClass = " border-t-2 border-blue-400"; break;
    }
    
    return (
        <article className={"hover:shadow-lg transition-shadow cursor-pointer shadow bg-white h-72 rounded-bl rounded-br flex flex-col transition-colors" + addedClass}>
            <div className="border-b border-gray-100 p-2 2xl:p-3 2xl:px-4">
                <div className="flex items-center">
                    <div className="text-sm mb-2 font-medium overflow-hidden h-4">{props.remoteAnalysis.config.study.name}</div>
                    <button className="px-2 text-gray-300 rounded border-gray-300 ml-auto border text-normal hover:bg-red-500 hover:border-red-500 hover:text-white pb-1" 
                        onClick={(_) => props.onDeleteAnalysis(props.remoteAnalysis.config.analysis_id)}>×</button>
                </div>
                <div className="flex text-xs mb-1">
                    <div className=" mr-2 w-12 text-blue-500 font-medium ">Test:</div>
                    <div className="flex flex-wrap">{props.remoteAnalysis.config.thresholds.map(g => viewGene(g, "test"))} </div>
                </div>
                <div className="flex text-xs">
                    <div className="mr-2 w-12 font-medium text-gray-500">Control:</div>
                    <div className="flex flex-wrap">{props.remoteAnalysis.config.thresholds.map(g => viewGene(g, "control"))}</div>
                </div>
            </div>
            <div className="p-1 flex-grow">
                <AnalysisCardBody remoteAnalysis={props.remoteAnalysis} />
            </div>
        </article>
    )

    
});

/** Analysis viewing container which contains all submitted analyses. */
function AnalysisPanelContainer(props: { analyses: Array<RemoteAnalysis>, onDeleteAnalysis: (id: number) => void }) {
    return (
        <section className="p-8 grid gap-8 grid-cols-1 lg:grid-cols-2 xl:grid-cols-3">
            {props.analyses.map((a: RemoteAnalysis) => 
                <AnalysisCard remoteAnalysis={a} key={a.config.analysis_id} onDeleteAnalysis={props.onDeleteAnalysis} />)}
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
    analyses: Array<RemoteAnalysis>,
    onDeleteAnalysis: (id: number) => void,
}

/** Main analysis page container. */
function AnalysisPage(props: Props) {
    return (
        <div className="w-full flex h-full" >
            <section className="shadow-lg z-10">
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
            <section className="flex-grow overflow-auto bg-gray-100">
                <AnalysisPanelContainer analyses={props.analyses} onDeleteAnalysis={props.onDeleteAnalysis} />
            </section>
        </div>
    )
}

export default AnalysisPage;