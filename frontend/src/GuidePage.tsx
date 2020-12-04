import React, { useState } from 'react';
import step1 from "./resources/step1.png";
import step2 from "./resources/step2.png";
import step3 from "./resources/step3.png";
import step45 from "./resources/step45.png";
import step6 from "./resources/step6.png";


function GuidePage() {
    return (
        <div className="max-w-5xl m-auto py-8 px-2" >
            <h1 className="text-4xl" >How-To Guide</h1>
            <article className="my-8 uncontrolled">
                <p>Here's a labelled screenshot of the <span className="font-bold">Analysis</span> tab when you first click onto it. The first step is to select a cancer study from the drop-down menu.
                You can type in the select box to search the list of available studies.
                </p>
                <img src={step1} className="shadow m-8 border"></img>
                <p className="">Once you have selected a study, a description of the study will appear in a box below, as well as a selector for the survival outcome and a
                selector for the gene expression profile. Defaults will appear for both the outcome and gene expression profile selectors, though some studies
                may have additional options to choose from.
                </p>
                <img src={step2} className="shadow m-8 border"></img>
                <p className="">Next, choose the genes which you wish to combine to create a test group. Search for genes by typing
                their HUGO ID into the search box (e.g. "BRCA1"). You must type at least 2 characters in the gene select box
                for options to begin appearing. </p>
                <p className="">
                    Once you have selected a gene, it will be added below the selector with a slider. You can deselect a gene by clicking the "×" symbol next to it in the select box.
                </p>
                <p>
                    You can change the Test criterion for each gene using the slider or input box next to it. The blue-coloured region indicates the criteria
                    that Test cases must fulfil for each gene. The grey-coloured region indicates the criteria that Control cases must fulfil for each gene.
                </p>
                <p>
                    Test and Control cases must fulfil <span className="font-bold">all</span> genes' criteria in order to be included, so be very cautious about
                    adding more than 2 or 3 genes or using stringent criteria as you will likely have an insufficient number of cases to perform any meaningful analysis.
                </p>
                <img src={step3} className="shadow m-8 border"></img>
                <p>
                    Once you have selected your genes and their thresholds, click on the Submit Analysis button below. It will only be visible if you
                    have selected a study and at least one gene. Once you click the button, the analysis will be added to the right and will
                    begin to load.
                </p>
                <p>
                    After the analysis has finished loading, you will see a summary card of the analysis on the right. If the analysis was unsuccessful
                    because of a network error, too few cases that fulfil the gene expression criteria, or because of failure to fit the survival analysis model,
                    an error will be shown instead.
                </p>
                <img src={step45} className="shadow m-8 border"></img>
                <p>
                    You can <span className="font-bold">click</span> on the analysis summary card to open the analysis in more detail.
                </p>
                <img src={step6} className="shadow m-8 border"></img>
                <p>
                    In the detailed analysis view, a text description of the analysis and a Kaplan Meier plot is shown. You can download the configuration used for the
                    analysis as JSON, which includes all the information you've specified to configure the analysis including the selected study, outcome, expression
                    profile and gene thresholds. You can also download a CSV file containing the clinical and gene expression data (where genes are identified by their
                    ENTREZ ID) as well as a PNG of the Kaplan Meier plot. We recommend keeping the JSON configuration file together with a downloaded CSV or PNG file
                    in order to be able to replicate an analysis.
                </p>
                <p className="mb-8">
                    Once you have finished reviewing the analysis details, you can close the modal by clicking the Close button at the top right.
                </p>

                <br></br>
            </article>
        </div>
    )
}

export default GuidePage;