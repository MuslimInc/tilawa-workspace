#!/usr/bin/env python3
import unittest

from core import BM25


class Bm25AvgdlTest(unittest.TestCase):
    def test_score_does_not_divide_by_zero_when_all_docs_are_empty(self):
        bm25 = BM25()
        bm25.fit(["", "  ", "a"])

        scores = bm25.score("query")

        self.assertEqual(len(scores), 3)


if __name__ == "__main__":
    unittest.main()
