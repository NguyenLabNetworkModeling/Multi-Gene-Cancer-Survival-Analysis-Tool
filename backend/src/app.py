import cbioportal
import analysis
import json
from flask import Flask, jsonify, request, g, send_from_directory
from flask_cors import CORS

api = cbioportal.Api()

app = Flask(__name__)
CORS(app)


@app.route("/")
def index():
    # TODO
    return None


@app.route("/api/studies", methods=["GET"])
def api_get_studies():
    """Get a list of all studies available for analysis."""
    return jsonify(api.get_studies())


@app.route("/api/genes", methods=["GET"])
def api_get_gene():
    """Get a list of genes with a given prefix.

    Query params:
        prefix: gene HUGO ID prefix search
    """
    prefix = request.args.get("prefix")
    return jsonify(api.get_gene(prefix).to_dict("records"))


@app.route("/api/analyse", methods=["POST"])
def api_analyse():
    """Perform a survival analysis with the given configuration.

    JSON body example:
        {
            "analysis_id": 0,
            "study_id": "brca_metabric",
            "profile_id": "brca_metabric_mrna",
            "outcome_id": "os",
            "thresholds": [
                {
                    "gene": { "entrez": 675 },
                    "threshold": 0.7,
                    "direction": "above",
                    "control": "complement",
                },
                {
                    "gene": { "entrez": 5728 },
                    "threshold": 0.3,
                    "direction": "below",
                    "control": "mirrored",
                },
            ]
        }
    """
    config = request.get_json()
    result, error = analysis.perform(api, config)
    if error:
        return jsonify(error, 500)
    else:
        return jsonify(result)


if __name__ == "__main__":
    app.run(debug=True)
