import './styles.css';
import '../node_modules/chart.js/dist/Chart.min.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import Chart from 'chart.js';

var app = Elm.Main.init({
    node: document.getElementById('root')
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();

// When the analysis modal is to be shown, change the class to visible
function showAnalysisModalLoading() {
    document.getElementById("analysis-loading").innerHTML = "Loading...this may take a few moments.";
    document.getElementById("analysis-modal-background").className = "visible";
    document.getElementById("analysis-modal-background").style.display = "flex";
    document.getElementById("analysis-modal").className = "visible";
    document.getElementById("analysis-loading").className = "visible";
};
// convert list of x and y to list of points with initial 0, 100 point
function toPointsWithZero(xs, ys) {
    var points = [{ x: 0, y: 100 }];
    var length = xs.length;
    for (var i = 0; i < length; i++) {
        points.push({ x: xs[i], y: ys[i] * 100 });
    };
    return points;
};

// raw to-points
function toPoints(xs, ys) {
    var points = [];
    var length = xs.length;
    for (var i = 0; i < length; i++) {
        points.push({ x: xs[i], y: ys[i] * 100 });
    };
    return points;
};

// Charts js setup
Chart.platform.disableCSSInjection = true;
var ctx = document.getElementById("analysis-plot");
var chart = new Chart(ctx, { type: "scatter", backgroundColor: "#ffffff", datasets: [] });

function plot(chart, analysis, analysisMeta) {
    var newLabels = ["Test", "Control", "Test Censors", "Control Censors"];
    var newDatasets = [{
        label: 'Test',
        data: toPointsWithZero(analysis.km.test.steps.times, analysis.km.test.steps.survival),
        borderColor: "#FFA500",
        steppedLine: "after",
        backgroundColor: "rgba(0,0,0,0)",
        pointRadius: 0,
        showLine: true,
    }, {
        label: "Control",
        data: toPointsWithZero(analysis.km.control.steps.times, analysis.km.control.steps.survival),
        borderColor: "#4682b4",
        steppedLine: "after",
        backgroundColor: "rgba(0,0,0,0",
        pointRadius: 0,
        showLine: true,
    }, {
        label: "Test Censors",
        data: toPoints(analysis.km.test.censors.times, analysis.km.test.censors.survival),
        pointBorderColor: "#FFA500",
        pointBorderWidth: 2,
        pointRadius: 5,
        pointStyle: "cross",
    }, {
        label: "Control Censors",
        data: toPoints(analysis.km.control.censors.times, analysis.km.control.censors.survival),
        pointBorderColor: "#4682b4",
        pointBorderWidth: 2,
        pointRadius: 5,
        pointStyle: "cross",
    }
    ];
    var newOptions = {
        scales: {
            yAxes: [{
                ticks: {
                    beginAtZero: true
                },
                scaleLabel: {
                    display: true,
                    labelString: analysisMeta["y_label"],
                }
            }],
            xAxes: [{
                ticks: {
                    suggestedMin: 0,
                    suggestedMax: 200
                },
                scaleLabel: {
                    display: true,
                    labelString: analysisMeta["x_label"],
                }
            }]
        },
        legend: {
            labels: {
                filter: function (item, chart) {
                    // Logic to remove a particular legend item goes here
                    return !item.text.includes('Censors');
                }
            }
        },
        title: {
            display: true,
            text: 'Kaplan-Meier Curve'
        }
    };
    chart.data.labels = newLabels;
    chart.data.datasets = newDatasets;
    chart.options = newOptions;
    chart.update();
};

// fill an element with a specified id with the specified text
function idText(id, text) {
    var element = document.getElementById(id);
    element.innerHTML = text;
}

function clearText(id) {
    var element = document.getElementById(id);
    element.innerHTML = "";
}

// replace element with a clear version of itself
function clearElement(id) {
    var element = document.getElementById(id);
    element.innerHTML = "";
}

//replace the canvas element
// function clearCanvas(ctx) {
//     document.ctx.remove();
//     var parent = document.getElementById("analysis-right");
//     parent.append('<canvas id="analysis-plot" width="400" height="400"></canvas>');
//     document.ctx = document.getElementById("analysis-plot");
//     return ctx
// }

// build the test criteria list inside a ul/ol element with a specified id given a list of gene configs
function testCriteriaList(id, genes) {
    var container = document.getElementById(id);
    var numGenes = genes.length;
    for (var i = 0; i < numGenes; i++) {
        var gene = genes[i];
        var item = document.createElement("li");
        var string = gene["hugo"].concat(" ", gene["side"], " the ", gene["percentile"].toString(), "-th percentile")
        item.innerHTML = string;
        container.appendChild(item);
    }
}

// build the control criteria list inside a ul/ol element with a specified id given a list of gene configs
function controlCriteriaList(id, genes) {
    var container = document.getElementById(id);
    var numGenes = genes.length;
    for (var i = 0; i < numGenes; i++) {
        var gene = genes[i];
        var item = document.createElement("li");
        var side = gene["side"] == "above" ? "below" : "above";
        if (gene["control_type"] == "mirrored") {
            var percentile = 100 - gene["percentile"];
        } else {
            var percentile = gene["percentile"]
        }
        var string = gene["hugo"].concat(" ", side, " the ", percentile.toString(), "-th percentile (", gene["control_type"], ")")
        item.innerHTML = string;
        container.appendChild(item);
    }
}

// fill the template with the retrieved text
function fillText(analysis, analysisMeta) {
    idText("analysis-study-name", analysisMeta["study_name"]);
    idText("analysis-study-id", analysisMeta["study_id"]);
    idText("analysis-molecular-profile", analysisMeta["profile_name"]);
    testCriteriaList("analysis-test-criteria-list", analysisMeta["genes"]);
    controlCriteriaList("analysis-control-criteria-list", analysisMeta["genes"]);
    idText("analysis-num-available", analysis.num_available.toString());
    idText("analysis-num-test", analysis.num_test.toString());
    idText("analysis-num-control", analysis.num_control.toString());
    idText("analysis-event-type", analysis.event_type);
    idText("analysis-event-time-units", analysis.event_time_unit);
    idText("analysis-hazard-ratio", Number.parseFloat(analysis.cox.hr).toFixed(4));
    idText("analysis-p-value", Number.parseFloat(analysis.cox.p_value).toFixed(4));
    // make the initial div visible again 
    document.getElementById("analysis-loaded").className = "visible";
    document.getElementById("analysis-study-text").style.display = "block";
    document.getElementById("analysis-study-text").className = "visible";
}

// reverse of fill text
function unfilltext() {
    clearText("analysis-study-name");
    clearText("analysis-study-id");
    clearText("analysis-molecular-profile");
    clearElement("analysis-test-criteria-list");
    clearElement("analysis-control-criteria-list");
    clearText("analysis-num-available");
    clearText("analysis-num-test");
    clearText("analysis-num-control");
    clearText("analysis-event-type");
    clearText("analysis-event-time-units");
    clearText("analysis-hazard-ratio");
    clearText("analysis-p-value");
    // make the initial div invisible again 
    document.getElementById("analysis-loaded").className = "";
    document.getElementById("analysis-study-text").style.display = "none";
}


// When the analysis modal is to be closed, make things invisible
function hideAnalysisModal() {
    document.getElementById("analysis-modal-background").className = "";
    document.getElementById("analysis-modal").className = "";
    document.getElementById("analysis-loaded").className = "";
    document.getElementById("analysis-study-text").style.display = "none";
    document.getElementById("analysis-study-text").className = "";
    unfilltext();
}

function receivedAnalysis(chart, data) {
    document.getElementById("analysis-loading").className = "";
    var [analysisMeta, analysisJson] = data;
    var analysis = JSON.parse(analysisJson);
    plot(chart, analysis, analysisMeta);
    fillText(analysis, analysisMeta);
}

function receivedError(string) {
    document.getElementById("analysis-loading").innerHTML = string;
}

function closedAnalysisModal() {
    hideAnalysisModal();
    app.ports.closedAnalysisModal.send(null);
}

// set the analysis modal button to send a message to the port
document.getElementById("analysis-header-close-button").onclick = function () { closedAnalysisModal() };


// Port subscriptions
app.ports.clickedSubmitAnalysis.subscribe(showAnalysisModalLoading);
app.ports.receivedAnalysis.subscribe((data) => { receivedAnalysis(chart, data) });
app.ports.receivedError.subscribe(receivedError);
