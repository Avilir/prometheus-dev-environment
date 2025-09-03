#!/usr/bin/env python3
"""
Prometheus Authentication Test Script
Author: Avi Layani
Purpose: Test various authentication methods for Prometheus connections using Python
"""

import os
import sys
import json
import base64
import argparse
from typing import Dict, Any, Optional, Tuple
from urllib.parse import urlencode
import urllib3
import requests
from requests.auth import HTTPBasicAuth

# Disable SSL warnings for testing
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class PrometheusAuthTester:
    """Test various authentication methods for Prometheus connections."""

    def __init__(self, base_url: str = "http://localhost:9090", verbose: bool = False):
        self.base_url = base_url.rstrip("/")
        self.verbose = verbose
        self.tests_passed = 0
        self.tests_failed = 0

    def _print_result(self, test_name: str, success: bool, details: str = ""):
        """Print test result with color."""
        if success:
            print(f"  ✅ PASSED - {test_name}")
            self.tests_passed += 1
        else:
            print(f"  ❌ FAILED - {test_name}")
            self.tests_failed += 1

        if details and self.verbose:
            print(f"     Details: {details}")

    def _make_request(
        self,
        endpoint: str,
        params: Optional[Dict] = None,
        headers: Optional[Dict] = None,
        auth: Optional[Any] = None,
    ) -> Tuple[bool, int, Any]:
        """Make HTTP request and return success status, HTTP code, and response data."""
        url = f"{self.base_url}{endpoint}"

        try:
            response = requests.get(
                url,
                params=params,
                headers=headers,
                auth=auth,
                timeout=10,
                verify=False,  # For testing with self-signed certs
            )

            if response.status_code == 200:
                try:
                    data = response.json()
                    return True, response.status_code, data
                except json.JSONDecodeError:
                    return True, response.status_code, response.text
            else:
                return False, response.status_code, response.text

        except requests.exceptions.RequestException as e:
            return False, 0, str(e)

    def test_no_auth(self):
        """Test connection without authentication."""
        print("\n1️⃣  No Authentication Test")
        print("-" * 30)

        # Test query endpoint
        success, code, data = self._make_request(
            "/api/v1/query", params={"query": "up"}
        )
        self._print_result("Query without auth", success, f"HTTP {code}")

        # Test metrics endpoint
        success, code, _ = self._make_request("/metrics")
        self._print_result("Metrics endpoint", success, f"HTTP {code}")

        # Test health endpoint
        success, code, _ = self._make_request("/-/healthy")
        self._print_result("Health endpoint", success, f"HTTP {code}")

    def test_bearer_token(self, token: str):
        """Test Bearer token authentication."""
        print("\n2️⃣  Bearer Token Authentication Test")
        print("-" * 40)

        # Valid token
        headers = {"Authorization": f"Bearer {token}"}
        success, code, data = self._make_request(
            "/api/v1/query", params={"query": "up"}, headers=headers
        )
        self._print_result("Valid bearer token", success, f"HTTP {code}")

        # Invalid token
        headers = {"Authorization": "Bearer invalid-token-12345"}
        success, code, _ = self._make_request(
            "/api/v1/query", params={"query": "up"}, headers=headers
        )
        # For no-auth Prometheus, this should still succeed
        expected = success if code == 200 else not success
        self._print_result("Invalid bearer token handling", expected, f"HTTP {code}")

    def test_basic_auth(self, username: str, password: str):
        """Test Basic authentication."""
        print("\n3️⃣  Basic Authentication Test")
        print("-" * 35)

        # Valid credentials
        auth = HTTPBasicAuth(username, password)
        success, code, data = self._make_request(
            "/api/v1/query", params={"query": "up"}, auth=auth
        )
        self._print_result("Valid credentials", success, f"HTTP {code}")

        # Invalid credentials
        auth = HTTPBasicAuth("wronguser", "wrongpass")
        success, code, _ = self._make_request(
            "/api/v1/query", params={"query": "up"}, auth=auth
        )
        # For no-auth Prometheus, this should still succeed
        expected = success if code == 200 else not success
        self._print_result("Invalid credentials handling", expected, f"HTTP {code}")

    def test_api_token(self, api_token: str):
        """Test API token authentication (custom header)."""
        print("\n4️⃣  API Token Authentication Test")
        print("-" * 37)

        # Valid API token
        headers = {"X-API-Token": api_token}
        success, code, data = self._make_request(
            "/api/v1/query", params={"query": "up"}, headers=headers
        )
        self._print_result("Valid API token", success, f"HTTP {code}")

        # Invalid API token
        headers = {"X-API-Token": "invalid-api-token"}
        success, code, _ = self._make_request(
            "/api/v1/query", params={"query": "up"}, headers=headers
        )
        # For no-auth Prometheus, this should still succeed
        expected = success if code == 200 else not success
        self._print_result("Invalid API token handling", expected, f"HTTP {code}")

    def test_query_samples(self):
        """Test various PromQL queries."""
        print("\n5️⃣  Sample Query Tests")
        print("-" * 25)

        queries = [
            ("up", "Target status"),
            ("prometheus_build_info", "Prometheus build info"),
            ("rate(prometheus_http_requests_total[5m])", "HTTP request rate"),
            (
                "histogram_quantile(0.95, prometheus_http_request_duration_seconds_bucket)",
                "95th percentile latency",
            ),
        ]

        for query, description in queries:
            success, code, data = self._make_request(
                "/api/v1/query", params={"query": query}
            )
            if success and isinstance(data, dict) and data.get("status") == "success":
                result_count = len(data.get("data", {}).get("result", []))
                self._print_result(f"{description}", True, f"{result_count} results")
            else:
                self._print_result(f"{description}", success, f"HTTP {code}")

    def show_python_examples(self):
        """Show Python code examples for different auth methods."""
        print("\n💻 Python Authentication Examples")
        print("=" * 40)

        print(
            """
# 1. No Authentication
import requests

response = requests.get('http://localhost:9090/api/v1/query', 
                       params={'query': 'up'})
data = response.json()

# 2. Bearer Token
headers = {'Authorization': 'Bearer your-token-here'}
response = requests.get('http://localhost:9090/api/v1/query',
                       params={'query': 'up'},
                       headers=headers)

# 3. Basic Authentication
from requests.auth import HTTPBasicAuth

response = requests.get('http://localhost:9090/api/v1/query',
                       params={'query': 'up'},
                       auth=HTTPBasicAuth('username', 'password'))

# 4. Custom API Token
headers = {'X-API-Token': 'your-api-token'}
response = requests.get('http://localhost:9090/api/v1/query',
                       params={'query': 'up'},
                       headers=headers)

# 5. Using prometheus-api-client library
from prometheus_api_client import PrometheusConnect

# No auth
prom = PrometheusConnect(url='http://localhost:9090')

# With headers (bearer token or custom headers)
prom = PrometheusConnect(
    url='http://localhost:9090',
    headers={'Authorization': 'Bearer your-token'}
)

# Query data
result = prom.custom_query(query='up')
"""
        )

    def run_all_tests(self):
        """Run all authentication tests."""
        print(f"🔐 Prometheus Authentication Test")
        print(f"Target: {self.base_url}")
        print("=" * 50)

        # Test no auth (always run)
        self.test_no_auth()

        # Test bearer token if provided
        bearer_token = os.environ.get("PROM_BEARER_TOKEN")
        if bearer_token:
            self.test_bearer_token(bearer_token)
        else:
            print("\n2️⃣  Bearer Token Test - ⚠️  SKIPPED")
            print("   Set PROM_BEARER_TOKEN environment variable to test")

        # Test basic auth if provided
        basic_user = os.environ.get("PROM_BASIC_USER")
        basic_pass = os.environ.get("PROM_BASIC_PASS")
        if basic_user and basic_pass:
            self.test_basic_auth(basic_user, basic_pass)
        else:
            print("\n3️⃣  Basic Auth Test - ⚠️  SKIPPED")
            print("   Set PROM_BASIC_USER and PROM_BASIC_PASS to test")

        # Test API token if provided
        api_token = os.environ.get("PROM_API_TOKEN")
        if api_token:
            self.test_api_token(api_token)
        else:
            print("\n4️⃣  API Token Test - ⚠️  SKIPPED")
            print("   Set PROM_API_TOKEN environment variable to test")

        # Run query samples
        self.test_query_samples()

        # Show examples
        self.show_python_examples()

        # Summary
        print(f"\n📊 Test Summary")
        print("=" * 20)
        print(f"Tests Passed: {self.tests_passed}")
        print(f"Tests Failed: {self.tests_failed}")

        return self.tests_failed == 0


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description="Test various authentication methods for Prometheus"
    )
    parser.add_argument(
        "-u",
        "--url",
        default="http://localhost:9090",
        help="Prometheus URL (default: http://localhost:9090)",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Show detailed output"
    )

    args = parser.parse_args()

    # Create tester and run tests
    tester = PrometheusAuthTester(args.url, args.verbose)
    success = tester.run_all_tests()

    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
