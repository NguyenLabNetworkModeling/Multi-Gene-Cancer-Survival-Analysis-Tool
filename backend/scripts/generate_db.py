"""Pre-fetches clinical studies and outcome data and saves them into a local SQLite database.

Undertakes the following steps:
1. Retrieves all available studies from the remote client.
2. Filters out studies without survival outcome data or without >=1 MRNA expression profile
3. Saves each valid study's clinical data table, meta data, valid survival outcomes, and valid molecular profiles
"""

import sys
import os

sys.path.insert(1, os.path.join(sys.path[0], ".."))

import pandas as pd
import src.cbioportal as cbioportal
from typing import List, Tuple
from sqlalchemy import create_engine

API = cbioportal.Api()


def get_valid_outcomes(df: pd.DataFrame) -> List[str]:
    """Returns the valid survival outcomes for a clinical data dataframe.

    A survival outcome is valid if there are least 40 patients with os_status
    & os_months or dfs_status & dfs_months.
    """
    has_os = "os_status" in df.columns and "os_months" in df.columns
    has_dfs = "dfs_status" in df.columns and "dfs_months" in df.columns
    num_os = len(df.os_months.dropna()) if has_os else 0
    num_dfs = len(df.dfs_months.dropna()) if has_dfs else 0
    valid_os = has_os and num_os >= 40
    valid_dfs = has_dfs and num_dfs >= 40
    valid = []
    if valid_os:
        valid.append(("os", num_os))
    if valid_dfs:
        valid.append(("dfs", num_dfs))
    return valid


def get_valid_profiles(profiles: List) -> List:
    """Returns the valid molecular profiles for a list of molecular profiles.

    A molecular profile is valid if it has a molecularAlterationType of
    MRNA_EXPRESSION and and datatype of CONTINUOUS.
    """
    valid = []
    for p in profiles:
        if (
            p.molecularAlterationType == "MRNA_EXPRESSION"
            and p.datatype == "CONTINUOUS"
        ):
            valid.append(p)
    return valid


def validate_study(study):
    """Validates a study object based on valid outcomes and valid profiles and returns the validated data."""
    clinical_data_raw = API._get_remote_clinical_data(study.studyId)
    clinical_data = API._preprocess_remote_clinical_data(clinical_data_raw)
    molecular_profiles = API._get_remote_molecular_profiles(study.studyId)
    valid_outcomes = get_valid_outcomes(clinical_data)
    valid_profiles = get_valid_profiles(molecular_profiles)
    valid = len(valid_outcomes) > 0 and len(valid_profiles) > 0
    if valid:
        return True, clinical_data, valid_outcomes, valid_profiles
    else:
        return False, None, None, None


def study_to_dict(study):
    """Converts a study into a dictionary of data."""
    return {
        "study_id": study.studyId,
        "cancer_type_id": study.cancerTypeId,
        "description": study.description,
        "name": study.name,
        "pmid": study.pmid,
        "short_name": study.shortName,
    }


def outcome_to_dict(study_id, outcome: Tuple[str, int]):
    """Converts an outcome tuple into a dictionary of data."""
    return {"study_id": study_id, "outcome_id": outcome[0], "count": outcome[1]}


def profile_to_dict(study_id, profile):
    """Converts a profile into a dictionary of data."""
    return {
        "study_id": study_id,
        "profile_id": profile.molecularProfileId,
        "name": profile.name,
        "description": profile.description,
        "datatype": profile.datatype,
        "molecularAlterationType": profile.molecularAlterationType,
    }


def generate_dataframes():
    """Generates the database of valid studies and meta-data.

    Also logs to "generate_db.log".
    """
    studies = API._get_remote_studies()
    all_valid_studies = []  # one row per study
    all_valid_clinical = []  # one to many for each study
    all_valid_outcomes = []  # one to many for each study
    all_valid_profiles = []  # one to many for each study
    with open("./generate_db.log", "w") as log:
        # Iterate through each study
        for study in studies:
            valid, clinical_data, outcomes, profiles = validate_study(study)
            if valid:
                log.write(f"{study.studyId:40}: VALID\n")
                # Add to temp study list
                all_valid_studies.append(study_to_dict(study))
                # Add to temp clinical data list
                clinical_data["study_id"] = study.studyId
                all_valid_clinical.append(clinical_data)
                # Add to temp outcome list
                for outcome in outcomes:
                    all_valid_outcomes.append(outcome_to_dict(study.studyId, outcome))
                # Add to temp profile list
                for profile in profiles:
                    all_valid_profiles.append(profile_to_dict(study.studyId, profile))
            else:
                log.write(f"{study.studyId:40}: INVALID\n")
    studies = pd.DataFrame(all_valid_studies)
    clinical = pd.concat(all_valid_clinical)
    outcomes = pd.DataFrame(all_valid_outcomes)
    profiles = pd.DataFrame(all_valid_profiles)
    return studies, clinical, outcomes, profiles


def generate_database():
    """Generates and saves the database of filtered study and clinical data."""
    engine = create_engine("sqlite:///data.db")
    studies, clinical, outcomes, profiles = generate_dataframes()
    studies.to_sql("study", con=engine)
    clinical.to_sql("study_clinical_data", con=engine)
    outcomes.to_sql("study_outcome", con=engine)
    profiles.to_sql("study_profile", con=engine)


# Run the generator
generate_database()
