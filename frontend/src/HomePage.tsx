import React, { useState } from 'react';

function HomePage() {
    return (
        <div className="max-w-5xl m-auto py-8 px-2" >
            <h1 className="text-4xl" >Multi-Gene Survival Analysis</h1>
            <article className="my-8">
                This is a small web application to perform survival analyses of cBioPortal data.
            </article>
        </div>
    )
}

export default HomePage;