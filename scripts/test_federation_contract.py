import unittest

from federation_contract import validate_claims, validate_repository


class FederationContractTest(unittest.TestCase):
    def setUp(self):
        self.repo = dict(
            owner="example",
            owner_id="123",
            name="infra",
            repository_id="456",
            apply_environment="apply",
        )
        self.actual = {"id": 456, "owner": {"id": 123}, "full_name": "example/infra"}
        self.claims = {
            "iss": "https://token.actions.githubusercontent.com",
            "aud": "api://AzureADTokenExchange",
            "sub": "repo:example@123/infra@456:pull_request",
        }

    def test_missing_empty_invalid_and_wrong_ids_are_rejected(self):
        validate_repository(self.repo, self.actual)
        for value in (None, "", "wrong", "999"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                validate_repository(dict(self.repo, repository_id=value), self.actual)

    def test_old_subject_wrong_audience_and_issuer_are_rejected(self):
        validate_claims(self.repo, self.claims)
        for key, value in (
            ("sub", "repo:example/infra:pull_request"),
            ("aud", "other"),
            ("iss", "https://other.invalid"),
        ):
            with self.subTest(key=key), self.assertRaises(ValueError):
                validate_claims(self.repo, dict(self.claims, **{key: value}))
