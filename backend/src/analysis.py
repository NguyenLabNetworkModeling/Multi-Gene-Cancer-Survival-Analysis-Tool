"""Functions for main survival analysis.

The main survival analysis looks at the combined effect of one or more genes
on cancer survival outcomes. Genes are combined based on percentile
thresholds within a cancer study population.

The key steps to performing the analysis are:

1. Extracting clinical outcomes from the study population
2. Extracting genetic expression for selected genes from the study population 
3. Binning the genetic expression data into a test and control group based on percentile thresholds
4. Joining the binned genetic expression data and clinical outcomes 
5. Correlating outcomes ~ group through survival analysis

"""

import pandas as pd
import numpy as np
import src.cbioportal as cbioportal
from typing import List
from lifelines import CoxPHFitter, KaplanMeierFitter


def allocate_group(column, threshold: float, direction: str, control: str):
    """Allocates a column's percentile values into a test or control group (or neither).

    Args:
        column: column of PERCENTILE data
        threshold (float): float threshold.
        direction (str): one of "above" or "below".
        control (str): one of "mirrored" or "complement".

    Returns:
        New column of values, one of:
        - 1 if satisfies test condition.
        - 0 if satisfies control condition.
        - -1 if satisfies neither.
    """
    if control == "complement":
        if direction == "above":
            return np.where(column > threshold, 1, 0)
        elif direction == "below":
            return np.where(column < threshold, 1, 0)
        else:
            raise Exception(
                f"Unknown threshold direction: {direction}. 'above' or 'below' expected."
            )
    elif control == "mirrored":
        if direction == "above":
            tests = np.where(column > threshold, 1, -1)
            controls = np.where(column < (1 - threshold), 1, 0)
            return tests + controls
        elif direction == "below":
            tests = np.where(column < threshold, 1, -1)
            controls = np.where(column > (1 - threshold), 1, 0)
            return tests + controls
    else:
        raise Exception(
            f"Unknown control type: {control}. 'mirrored' or 'complement' expected."
        )


def apply_thresholds(expression: pd.DataFrame, thresholds: List) -> pd.Series:
    """Allocates each row into test (1) and control (0) or neither (NaN).

    Args:
        expression (pd.DataFrame): mrna expression data
        thresholds (float): thresholds to apply. This should be a list of dicts
            where each dict has the following keys:
            - gene which is a dict with entrez (int): the entrez ID of the gene
            - threshold (float) the threshold (test does not include threshold
              value).
            - direction (str): one of "above" or "below" specifying direction
              of test group relative to threshold
            - control (str): one of "mirrored" or "complement" specifying how
              controls are defined. Mirrored controls are on the opposite side
              of (1 - threshold). Complement controls are on the opposite side
              of threshold.

    Returns:
        A column with values equal to 0 (control), 1 (test) or NaN.
    """

    def combine_groups(row):
        """Combine threshold groups in each row.
        - If all 0s, then 0
        - If all 1s, then 1
        - Else NaN
        """
        if np.all(row == 1):
            return 1
        elif np.all(row == 0):
            return 0
        else:
            return np.nan

    column_groups = []
    percentiles = expression.rank(pct=True)
    for thresh in thresholds:
        group = allocate_group(
            percentiles[thresh["gene"]["entrez"]],
            thresh["threshold"],
            thresh["direction"],
            thresh["control"],
        )
        column_groups.append(group)
    column_groups = pd.DataFrame(np.stack(column_groups, axis=1))
    combined = column_groups.apply(combine_groups, axis=1)
    return combined


def group_and_join(clinical, molecular, thresholds, outcome) -> pd.DataFrame:
    """Group the molecular data based on provided thresholds and join into a single dataframe without NaNs.

    Any rows which contain NaN are dropped.
    """
    molecular["group"] = apply_thresholds(molecular, thresholds).values
    joined = clinical.join(molecular, how="inner")
    if outcome == "os":  # remove irrelevant columns
        columns = [c for c in joined.columns if c not in ["dfs_months", "dfs_status"]]
        subset = joined[columns].copy()
        renamed = subset.rename(columns={"os_months": "months", "os_status": "status"})
    elif outcome == "dfs":
        columns = [c for c in joined.columns if c not in ["os_months", "os_status"]]
        subset = joined[columns].copy()
        renamed = subset.rename(
            columns={"dfs_months": "months", "dfs_status": "status"}
        )
    renamed.dropna(inplace=True)
    renamed["months"] = renamed["months"].astype(float)
    renamed["status"] = renamed["status"].astype(float).astype(int)
    renamed["group"] = renamed["group"].astype(int)
    return renamed


def perform_cph(data, outcome):
    """Perform Cox proportional hazards analysis given the clinical and molecular data and thresholds.

    Args:
        data (pd.DataFrame): dataframe with at least columns "months", "status" and "group".
        outcome (string): one of "dfs" or "os".
    """
    subset = data[["months", "status", "group"]]
    cph = CoxPHFitter()
    cph.fit(subset, "months", "status")
    return cph


def perform(api: cbioportal.Api, config):
    """Perform an analysis for a given configuration.

    The configuration is a dict which must contain:
    - study_id (str): study ID
    - profile_id (str): molecular profile ID
    - outcome_id (str): one of "os" or "dfs"
    - thresholds: list of threshold dicts

    Example configuration:

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

    Returns either:
        - (None, { "type": "api" | , "message": string, "debug": string })
        - (result, False)

    Example result:


    """
    outcome = config["outcome_id"]
    thresholds = config["thresholds"]
    entrez = [t["gene"]["entrez"] for t in thresholds]

    try:
        clinical = api.get_clinical_data(config["study_id"])
        molecular = api.get_molecular_data(entrez, config["profile_id"])
    except Exception as e:
        return None, {
            "type": "api",
            "message": "There was an API error. Let us know.",
            "debug": str(e),
        }

    joined = group_and_join(clinical, molecular, thresholds, outcome)

    if len(joined) < 20:
        return None, {
            "type": "data",
            "message": f"There was insufficient data to perform the analysis (n={len(joined)} after joining clinical data with available molecular data).",
            "debug": "",
        }

    try:
        cph = perform_cph(joined, outcome)
    except Exception as e:
        return None, {
            "type": "model",
            "message": "Performing the Cox Proportional Hazards analysis failed during fitting.",
            "debug": str(e),
        }

    num_test = int((joined.group == 1).sum())
    num_control = int((joined.group == 0).sum())
    num_clinical = int(clinical.count().max())
    num_excluded = num_clinical - (num_test + num_control)

    csv_data = joined.to_csv()

    def is_right_censor(row, df):
        "Determines if a row is right censored i.e. outcome is 0."
        return 0 in df[df.months == row["timeline"]].status.values

    test_kmf = KaplanMeierFitter()
    test_joined = joined[joined.group == 1]
    test_kmf.fit(test_joined.months, test_joined.status)
    test_km_data = (
        test_kmf.survival_function_.reset_index().astype("float").to_dict("records")
    )
    test_km_censors = [r for r in test_km_data if is_right_censor(r, test_joined)]

    cont_kmf = KaplanMeierFitter()
    cont_joined = joined[joined.group == 0]
    cont_kmf.fit(cont_joined.months, cont_joined.status)
    cont_km_data = (
        cont_kmf.survival_function_.reset_index().astype("float").to_dict("records")
    )
    cont_km_censors = [r for r in cont_km_data if is_right_censor(r, cont_joined)]

    hr = float(cph.hazard_ratios_.group.item())
    p = float(cph.summary.p.group.item())

    result = {
        "analysis_id": config["analysis_id"],
        "num_test": num_test,
        "num_control": num_control,
        "num_clinical": num_clinical,
        "num_excluded": num_excluded,
        "outcome": outcome,
        "outcome_units": "months",  # same for both os and dfs
        "hazard_ratio": hr,
        "p_value": p,
        "test_km_data": test_km_data,
        "test_km_censors": test_km_censors,
        "cont_km_data": cont_km_data,
        "cont_km_censors": cont_km_censors,
        "csv_data": csv_data,
    }
    return result, False
