import React, { useState } from 'react';

export type Page = "home" | "analysis" | "guide" | "about";

type Props = {
    page: Page,
    onClickPage: (page: Page) => void
}

function Nav(props: Props) {
    function makeTab(text: String, link: Page) {
        const activeClass = link == props.page ? " border-b border-blue-500 text-blue-600" : " text-gray-700";
        return (
            <button
                className={"px-4 py-2 hover:bg-gray-200" + activeClass}
                onClick={(_) => props.onClickPage(link)}>
                {text}
            </button>
        )
    }
    return (
        <nav className="flex max-w-5xl m-auto">
            {makeTab("Home", "home")}
            {makeTab("Analysis", "analysis")}
            {makeTab("How-To", "guide")}
            {makeTab("About", "about")}
        </nav>
    )
}

export default Nav;