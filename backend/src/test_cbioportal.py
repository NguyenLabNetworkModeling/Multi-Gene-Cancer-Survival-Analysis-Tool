import unittest
import cbioportal
import pandas as pd


class TestCBioPortal(unittest.TestCase):
    "Tests for interacting with the cBioPortal API."

    def setUp(self):
        "Set-up requires creation of the API for all tests and a test study ID."
        self.api = cbioportal.Api()
        self.test_study_id = "brca_tcga"
        self.test_profile_id = "brca_tcga_rna_seq_v2_mrna"
        self.test_entrez_ids = [672, 675]  # BRC1, BRCA2

    def test_create_api(self):
        "The API should be created and be an instance of the API class."
        self.assertIsInstance(self.api, cbioportal.Api)

    def test_get_remote_studies(self):
        "Remote studies should have at least one element with a study ID."
        results = self.api._get_remote_studies()
        self.assertGreater(len(results), 0)
        example = results[0]
        self.assertIsNotNone(example.studyId)

    def test_get_remote_clinical_data(self):
        "Clinical data should have at least one result for the test study ID."
        results = self.api._get_remote_clinical_data(self.test_study_id)
        self.assertGreater(len(results), 0)

    def test_preprocess_remote_clinical_data(self):
        "Preprocessing the clinical data from the test study should give a dataframe with length > 0."
        results = self.api._get_remote_clinical_data(self.test_study_id)
        preprocessed = self.api._preprocess_remote_clinical_data(results)
        self.assertIsInstance(preprocessed, pd.DataFrame)
        self.assertGreater(len(preprocessed), 0)

    def test_get_remote_molecular_profiles(self):
        "There should be at least one molecular profile for the test study ID."
        results = self.api._get_remote_molecular_profiles(self.test_study_id)
        self.assertGreater(len(results), 0)

    def test_get_remote_molecular_data(self):
        "There should be at least one result for the test molecular profile and test genes."
        results = self.api._get_remote_molecular_data(
            self.test_entrez_ids, self.test_profile_id
        )
        self.assertGreater(len(results), 0)

    def test_preprocess_remote_molecular_data(self):
        "Preprocessing the clinical data from the test molecular profile should give a dataframe with length > 0."
        results = self.api._get_remote_molecular_data(
            self.test_entrez_ids, self.test_profile_id
        )
        preprocessed = self.api._preprocess_remote_molecular_data(results)
        self.assertIsInstance(preprocessed, pd.DataFrame)
        self.assertGreater(len(preprocessed), 0)

    def test_get_studies(self):
        "Retrieving the locally-stored studies should return a list with at least one element."
        results = self.api.get_studies()
        self.assertGreater(len(results), 0)

    def test_get_clinical_data(self):
        "Retrieving the clinical data for the test study should return a dataframe with at least one element."
        results = self.api.get_clinical_data(self.test_study_id)
        self.assertIsInstance(results, pd.DataFrame)
        self.assertGreater(len(results), 0)

    def test_get_molecular_data(self):
        "Retrieving the molecular data for the test profile should return a dataframe with at least one element."
        results = self.api.get_molecular_data(
            self.test_entrez_ids, self.test_profile_id
        )
        self.assertIsInstance(results, pd.DataFrame)
        self.assertGreater(len(results), 0)


if __name__ == "__main__":
    unittest.main()