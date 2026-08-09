import unittest
from unittest.mock import patch

from agentdash import collect, rate_limit_windows


class RateLimitWindowsTests(unittest.TestCase):
    def test_uses_a_single_primary_weekly_limit(self):
        windows = rate_limit_windows(
            {
                "primary": {"used_percent": 19.0, "window_minutes": 10_080, "resets_at": 1_785_913_796},
                "secondary": None,
            }
        )

        self.assertNotIn("session_pct", windows)
        self.assertEqual(windows["weekly_pct"], 19.0)
        self.assertEqual(windows["weekly_resets"], 1_785_913_796)

    def test_uses_separate_session_and_weekly_limits(self):
        windows = rate_limit_windows(
            {
                "primary": {"used_percent": 15.0, "window_minutes": 300, "resets_at": 1_785_913_796},
                "secondary": {"used_percent": 42.0, "window_minutes": 10_080, "resets_at": 1_786_518_596},
            }
        )

        self.assertEqual(windows["session_pct"], 15.0)
        self.assertEqual(windows["weekly_pct"], 42.0)


class CollectTests(unittest.TestCase):
    @patch("agentdash.get_codex", return_value={"weekly_pct": 0.0})
    @patch("agentdash.get_claude", return_value={"error": "HTTP Error 429: Too Many Requests"})
    def test_keeps_the_last_valid_provider_usage_after_a_refresh_error(self, _claude, _codex):
        state = collect(
            {
                "providers": {
                    "claude": {"session_pct": 14.0, "weekly_pct": 9.0},
                    "codex": {"weekly_pct": 0.0},
                }
            }
        )

        self.assertEqual(state["providers"]["claude"]["session_pct"], 14.0)
        self.assertEqual(state["providers"]["claude"]["weekly_pct"], 9.0)
        self.assertEqual(state["providers"]["claude"]["last_error"], "HTTP Error 429: Too Many Requests")


if __name__ == "__main__":
    unittest.main()
