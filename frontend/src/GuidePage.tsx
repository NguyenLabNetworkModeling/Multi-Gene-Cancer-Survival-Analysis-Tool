import React, { useState } from 'react';
import step1 from "./resources/step1.png";
import step2 from "./resources/step2.png";
import step3 from "./resources/step3.png";

function GuidePage() {
    return (
        <div className="max-w-5xl m-auto py-8 px-2" >
            <h1 className="text-4xl" >How-To Guide</h1>
            <article className="my-8 uncontrolled">
                <p className="font-bold">This page is still in-progress.</p>
                <p>Here's a labelled screenshot of the Analysis tab when you first click onto it. The first step is to select a cancer study from the drop-down menu.
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
            </article>
        </div>
    )
}

export default GuidePage;