from __future__ import annotations

import importlib.util
import sys
import unittest
from decimal import Decimal
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "build_verified_outputs.py"
MODULE_SPEC = importlib.util.spec_from_file_location("build_verified_outputs", MODULE_PATH)
if MODULE_SPEC is None or MODULE_SPEC.loader is None:
    raise RuntimeError(f"Could not load analytics module from {MODULE_PATH}")
analytics = importlib.util.module_from_spec(MODULE_SPEC)
sys.modules[MODULE_SPEC.name] = analytics
MODULE_SPEC.loader.exec_module(analytics)


class FinancialMetricTests(unittest.TestCase):
    def test_asset_band_boundaries(self) -> None:
        self.assertEqual("Under $1B", analytics.asset_band(Decimal("999999")))
        self.assertEqual("$1B–$10B", analytics.asset_band(Decimal("1000000")))
        self.assertEqual("$10B–$250B", analytics.asset_band(Decimal("10000000")))
        self.assertEqual("$250B+", analytics.asset_band(Decimal("250000000")))

    def test_quarterly_net_income_uses_year_to_date_difference(self) -> None:
        first_quarter = self._record("20240331", "10")
        second_quarter = self._record("20240630", "24")
        results = analytics.quarterly_net_income([first_quarter, second_quarter])
        self.assertEqual(Decimal("10"), results[(1, "20240331")])
        self.assertEqual(Decimal("14"), results[(1, "20240630")])

    def test_quarterly_net_income_does_not_cross_year_boundary(self) -> None:
        fourth_quarter = self._record("20231231", "40")
        first_quarter = self._record("20240331", "11")
        results = analytics.quarterly_net_income([fourth_quarter, first_quarter])
        self.assertEqual(Decimal("11"), results[(1, "20240331")])

    @staticmethod
    def _record(report_date: str, net_income: str):
        return analytics.FinancialRecord(
            cert=1,
            report_date=report_date,
            name="Test Bank",
            state="VA",
            asset=Decimal("1000000"),
            deposits=Decimal("800000"),
            net_loans=Decimal("600000"),
            year_to_date_net_income=Decimal(net_income),
            roa=Decimal("1.0"),
            roe=Decimal("10.0"),
            net_interest_margin=Decimal("3.0"),
            equity_to_assets=Decimal("10.0"),
            loans_to_deposits=Decimal("75.0"),
            noncurrent_loans_ratio=Decimal("1.0"),
            net_charge_off_ratio=Decimal("0.2"),
        )


if __name__ == "__main__":
    unittest.main()
