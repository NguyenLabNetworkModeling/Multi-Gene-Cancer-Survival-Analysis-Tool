import React, { useState } from 'react';

function AboutPage() {
    return (
        <div className="max-w-5xl m-auto py-8 px-2" >
            <h1 className="text-4xl" >About</h1>
            <article className="my-8 uncontrolled">
                <h1 className="text-xl font-medium">Methods</h1>
                <p>
                    Clinical data was retrieved from <a href="https://www.cbioportal.org/">cBioPortal</a> on 2nd December 2020
                    for all studies which had at least 40 cases with either Overall Survival or
                    Disease-Free survival data recorded, and at least one mRNA expression profile available. When an analysis is submitted to this online tool,
                    the backend retrieves gene expression data from cBioPortal for the selected genes on-demand and joins this with the cached clinical data.
                    The backend then converts the expression data for each gene into percentiles (relative to all cases with available data in the specified study) and
                    assigns each case to either the Test group or Control group, or excludes the case based on the gene thresholds submitted through this app.
                    The Test group and Control group survival outcomes are then estimated using a Kaplan-Meier model and compared using a Cox Proportional Hazards
                    model as supplied by the Python survival analysis <a href="https://lifelines.readthedocs.io/en/latest/">lifelines</a> library. The results are then supplied
                    back to the user's browser for viewing and plotting.
                </p>
                <h1 className="text-xl font-medium mt-8">Contact</h1>
                <p>
                    This online tool was developed at <a href="https://www.monash.edu/discovery-institute/nguyen-lab">Nguyen Lab</a>. For more information, please contact the lab.
                </p>
            </article>
        </div>
    )
}

export default AboutPage;