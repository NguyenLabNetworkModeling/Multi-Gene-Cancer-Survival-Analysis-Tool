import unittest
import cbioportal
import analysis
import numpy as np
import pandas as pd


class TestAnalysis(unittest.TestCase):
    """Tests for analysis functions."""

    def setUp(self):
        self.api = cbioportal.Api()
        self.test_study_id = "brca_tcga"
        self.test_profile_id = "brca_tcga_rna_seq_v2_mrna"
        self.test_entrez_ids = [672, 675]  # BRC1, BRCA
        self.test_clinical_data = pd.DataFrame(
            {
                "a": {"os_status": 0, "os_months": 12.0},
                "b": {"os_status": 1, "os_months": 24.3},
                "c": {"os_status": 0, "os_months": 36.9},
                "d": {"os_status": 1, "os_months": 8.0},
                "e": {"os_status": 0, "os_months": 48.0},
                "f": {"os_status": 1, "os_months": 4.3},
            }
        ).transpose()
        self.test_molecular_data = (
            pd.DataFrame(
                {
                    "b": {672: 0.8, 675: 0.5},  # 0.75, 0.67: NaN
                    "a": {672: 0.8, 675: 0.2},  # 0.75, 0.25: 1
                    "c": {672: 0.5, 675: 1.0},  # 0.5, 1.0: 0
                    "d": {672: 0.9, 675: 0.3},  # 1.0, 0.5: NaN
                    "e": {672: 0.2, 675: 0.7},  # 0.3, 0.83: 0
                    "f": {672: 0.0, 675: 0.2},  # 0.17, 0.25: NaN
                }
            ).transpose()
            * 1000
        )
        self.test_thresholds = [
            {
                "gene": {"entrez": 672},
                "threshold": 0.7,
                "direction": "above",
                "control": "complement",
            },
            {
                "gene": {"entrez": 675},
                "threshold": 0.4,
                "direction": "below",
                "control": "mirrored",
            },
        ]

    def test_allocate_group_above_mirrored(self):
        col = np.array([0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1])
        exp = np.array([0, 0, 0, -1, -1, -1, -1, -1, 1, 1, 1])
        res = analysis.allocate_group(col, 0.75, "above", "mirrored")
        np.testing.assert_equal(res, exp)

    def test_allocate_group_below_mirrored(self):
        col = np.array([0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1])
        exp = np.array([1, 1, 1, -1, -1, -1, -1, -1, 0, 0, 0])
        res = analysis.allocate_group(col, 0.25, "below", "mirrored")
        np.testing.assert_equal(res, exp)

    def test_allocate_group_above_complement(self):
        col = np.array([0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1])
        exp = np.array([0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1])
        res = analysis.allocate_group(col, 0.75, "above", "complement")
        np.testing.assert_equal(res, exp)

    def test_allocate_group_below_complement(self):
        col = np.array([0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1])
        exp = np.array([1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0])
        res = analysis.allocate_group(col, 0.25, "below", "complement")
        np.testing.assert_equal(res, exp)

    def test_apply_thresholds(self):
        copy = self.test_molecular_data.copy()
        exp = pd.Series([np.nan, 1, 0, np.nan, 0, np.nan])
        res = analysis.apply_thresholds(copy, self.test_thresholds)
        pd.testing.assert_series_equal(res, exp)

    def test_group_and_join(self):
        # TODO
        pass

    def test_perform_cph(self):
        # TODO
        pass

    def test_perform(self):
        # TODO
        pass
