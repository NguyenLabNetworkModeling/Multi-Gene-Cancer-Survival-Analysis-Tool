/** Contains the main top-level application code and callbacks manipulating top-level state. 
 * 
 * Most application state relating to performing the analyses is kept in the top-level 
 * so that it persists between changing tabs.
*/

import React, { useEffect, useState } from 'react';
import AboutPage from './AboutPage';
import AnalysisPage, { AnalysisState, defaultAnalysisState, RemoteStudies } from './AnalysisPage';
import { AnalysisConfig, AnalysisResult as AnalysisResult, getStudies, parseAnalyisState, postAnalysis, RemoteAnalysis } from './Api';
import { ControlType, defaultGeneThreshold, Gene, GeneConfig } from './Gene';
import GuidePage from './GuidePage';
import HomePage from './HomePage';
import Nav, { Page } from "./Nav";
import { MolecularProfile, OutcomeSpec, Study } from './Study';

/** Main application state. */
type State = {
  page: Page,
  analysisState: AnalysisState,
  currentAnalysisNumber: number,
  analyses: Record<number, RemoteAnalysis>
}

/** Default application state. */
const defaultState: State = {
  page: "home",
  analysisState: defaultAnalysisState,
  currentAnalysisNumber: 0,
  analyses: {}
}

/** Top-level application run in the root div. */
function App() {

  /** Called when clicking a tab in the navbar to change page. */
  function onClickPage(page: Page) {
    setState((prev) => ({ ...prev, page: page }))
  }

  /** Callback on successfully fetching studies on app initialisation. */
  function getStudiesOnSuccess(studies: Array<Study>) {
    setState((prev) => ({ ...prev, analysisState: { ...prev.analysisState, studies: studies } }));
  }

  /** Callback on failing to fetch studies on app initialisation. */
  function getStudiesOnFailure() {
    setState((prev) => ({ ...prev, analysisState: { ...prev.analysisState, studies: "failed" } }));
  }

  /** Callback on clicking a study in the analysis creator. */
  function onClickStudy(study: Study) {
    const defaultOutcome = study.outcomes[0]; // guaranteed >=1 outcome
    const defaultProfile = study.molecular_profiles[0]; // guaranteed >= 1 profile
    setState((prev) => {
      return {
        ...prev,
        analysisState: {
          ...prev.analysisState,
          selectedStudy: study,
          selectedOutcome: defaultOutcome,
          selectedProfile: defaultProfile
        }
      }
    })
  }

  /** Callback on selecting an outcome in the study info. */
  function onSelectOutcome(outcome: OutcomeSpec) {
    setState((prev) => ({ ...prev, analysisState: { ...prev.analysisState, selectedOutcome: outcome } }))
  }

  /** Callback on selecting a molecular profile in the study info. */
  function onSelectProfile(profile: MolecularProfile) {
    setState((prev) => ({ ...prev, analysisState: { ...prev.analysisState, selectedProfile: profile } }))
  }

  /** Callback on selecting a gene from the gene multi-select. */
  function onSelectGenes(genes: Array<Gene>) {
    setState((prev) => {

      // remove unused/removed genes from the record
      // this is inefficient, but hopefully should be no more than ~1-3 genes selected at any time.
      var newConfigRecord: Record<string, GeneConfig> = {};
      genes.forEach((gene) => {
        if (gene.hugo in prev.analysisState.geneConfigRecord) {
          newConfigRecord[gene.hugo] = prev.analysisState.geneConfigRecord[gene.hugo];
        } else {
          newConfigRecord[gene.hugo] = defaultGeneThreshold;
        }
      });

      return { ...prev, analysisState: { ...prev.analysisState, selectedGenes: genes, geneConfigRecord: newConfigRecord } }
    })
  }

  /** Callback on change gene threshold number. */
  function onChangeGeneThreshold(gene: Gene, threshold: number) {
    setState((prev) => {
      const configRecord = prev.analysisState.geneConfigRecord;
      const oldConfig = configRecord[gene.hugo];
      var newConfig: GeneConfig;
      if (threshold > 50) {
        newConfig = { ...oldConfig, direction: "above", threshold: threshold };
      } else if (threshold < 50) {
        newConfig = { ...oldConfig, direction: "below", threshold: threshold };
      } else {
        newConfig = { ...oldConfig, threshold: threshold }
      };
      var newConfigRecord: Record<string, GeneConfig> = {}
      Object.assign(newConfigRecord, configRecord);
      newConfigRecord[gene.hugo] = newConfig;
      return { ...prev, analysisState: { ...prev.analysisState, geneConfigRecord: newConfigRecord } }
    })
  }

  /** Callback on change gene config control type - toggles between mirrored and complement. */
  function onChangeGeneControlType(gene: Gene) {
    setState((prev) => {
      const configRecord = prev.analysisState.geneConfigRecord;
      const oldConfig = configRecord[gene.hugo];
      var newConfig: GeneConfig;

      if (oldConfig.control == "mirrored") {
        newConfig = { ...oldConfig, control: "complement" };
      } else {
        newConfig = { ...oldConfig, control: "mirrored" }
      }

      // create new config object and modify
      var newConfigRecord: Record<string, GeneConfig> = {}
      Object.assign(newConfigRecord, configRecord);
      newConfigRecord[gene.hugo] = newConfig;
      return { ...prev, analysisState: { ...prev.analysisState, geneConfigRecord: newConfigRecord } }
    })
  }
  /** Callback on successfully receiving an analysis. */
  function onAnalysisSuccess(result: AnalysisResult) {
    setState((prev) => {
      console.log(result);
      var newAnalyses: Record<number, RemoteAnalysis> = {};
      Object.assign(newAnalyses, prev.analyses)
      newAnalyses[result.analysis_id] = { config: prev.analyses[result.analysis_id].config, result: result };
      return { ...prev, analyses: newAnalyses }
    })
  }

  /** Callback on receiving a failed analysis.  */
  function onAnalysisFailure(analysisId: number, message: string) {
    setState((prev) => {
      var newAnalyses: Record<number, RemoteAnalysis> = {};
      Object.assign(newAnalyses, prev.analyses)
      newAnalyses[analysisId] = { config: prev.analyses[analysisId].config, result: "error", message: message };
      return { ...prev, analyses: newAnalyses }
    })
  }



  /** Callback on clicking the submit button. */
  function onClickSubmitAnalysis() {
    setState((prev) => {
      const parsedConfig = parseAnalyisState(prev.currentAnalysisNumber, prev.analysisState);

      if (parsedConfig) {
        postAnalysis(parsedConfig, onAnalysisSuccess, onAnalysisFailure);

        var newAnalyses: Record<number, RemoteAnalysis> = {};
        Object.assign(newAnalyses, prev.analyses);
        newAnalyses[prev.currentAnalysisNumber] = { config: parsedConfig, result: "loading" };

        return { ...prev, analyses: newAnalyses, currentAnalysisNumber: prev.currentAnalysisNumber + 1 }
      } else {
        return prev;
      }
    })
  }

  // Initialise the application state
  const [state, setState] = useState(defaultState);

  // Fetch studies on initialisation if loading
  useEffect(() => { getStudies(getStudiesOnSuccess, getStudiesOnFailure) }, [])

  /** Dispatches page content based on active page in main app state. */
  function PageContent() {
    switch (state.page) {
      case "home":
        return <HomePage />
      case "analysis":
        return <AnalysisPage
          analysisState={state.analysisState}
          onClickStudy={onClickStudy}
          onSelectOutcome={onSelectOutcome}
          onSelectProfile={onSelectProfile}
          onSelectGenes={onSelectGenes}
          onChangeGeneThreshold={onChangeGeneThreshold}
          onChangeGeneControlType={onChangeGeneControlType}
          onClickSubmitAnalysis={onClickSubmitAnalysis}
        />
      case "guide":
        return <GuidePage />
      case "about":
        return <AboutPage />
    }
  }

  return (
    <main className="w-screen h-screen flex flex-col">
      <header className="w-full shadow z-10 border-b border-gray-300">
        <Nav page={state.page} onClickPage={onClickPage} />
      </header>
      <section className="w-full z-0 flex-grow overflow-auto">
        <PageContent />
      </section>
    </main>
  );
}

export default App;
