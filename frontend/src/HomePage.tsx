import React, { useState } from 'react';
import homeIntroImage from "./resources/home-intro.png";

function HomePage() {
    return (
        <div className="max-w-5xl m-auto py-8 px-2" >
            <h1 className="text-4xl" >Multi-Gene Cancer Survival Analysis Tool</h1>
            <article className="my-8 uncontrolled">
                <p className="font-medium">
                    This is a small online tool which compares the survival of cancer patients with different levels of gene expression across multiple genes.
                </p>

                <p>
                    By selecting a cancer study with publicly available clinical and gene expression data, as well as one or more genes and their
                    expression levels relative to all cases in a study cohort, you can plot and test the effect of a specific gene expression combination
                    on cancer survival rates. Data is obtained from the <a href="https://www.cbioportal.org/">cBioPortal for Cancer Genomics</a> and analysed
                    on the backend using the Python survival analysis library <a href="https://lifelines.readthedocs.io/en/latest/">lifelines</a>.
                </p>

                <p>
                    Click on the <span className="font-bold">Analysis</span> tab to get started, or check out the <span className="font-bold">How-To</span> page for more help.
                </p>
                <p>
                    This tool was developed at <a href="https://www.monash.edu/discovery-institute/nguyen-lab">Nguyen Lab</a> at
                     the <a href="https://www.monash.edu/discovery-institute">Monash Biomedicine Discovery Institute</a>. For more information,
                     check out the <span className="font-bold">About</span> page or get in contact with the lab.
                </p>
            </article>
            <img src={homeIntroImage} className="shadow border mt-12 mb-4" />
            <div className="italic text-sm text-center w-full mb-8">Example of the analysis page.</div>
        </div>
    )
}

export default HomePage;