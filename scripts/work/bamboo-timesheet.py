#!/usr/bin/env -S uv run

# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "requests>=2.31.0",
#   "python-dateutil>=2.9.0",
#   "browser-cookie3>=0.19.1",
#   "beautifulsoup4>=4.12.0",
# ]
# ///

# Example:
# ./scripts/work/bamboo-timesheet.py --month <month-relative-num>

import argparse
import requests
import browser_cookie3
from datetime import datetime
from calendar import monthrange
from dateutil.relativedelta import relativedelta
from requests.cookies import RequestsCookieJar
from bs4 import BeautifulSoup
from urllib.parse import urlparse, parse_qs
import random
import base64
import json
import re
import sys


class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'


BAMBOOHR_DOMAIN = "worldsensing.bamboohr.com"
BAMBOOHR_URL = f"https://{BAMBOOHR_DOMAIN}/timesheet/hour/entries"
TIMESHEET_URL = f"https://{BAMBOOHR_DOMAIN}/employees/timesheet/?id="
TIMESHEET_PAGE_URL = f"https://{BAMBOOHR_DOMAIN}/employees/timesheet/"
PUSHER_AUTH_URL = f"https://{BAMBOOHR_DOMAIN}/pusher/auth"
EMPLOYEE_ID = None
PROJECT_ID = 16
TASK_ID = 27
DAILY_HOURS = 8
COUNTRY_ISO = 'ES'
COUNTIES = {'ES-CT', 'ES-B'}
DEFAULT_UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"

parser = argparse.ArgumentParser(description=f"BambooHR Timesheet Automation Tool")
parser.add_argument("--csrf", default=None, help="Override CSRF token")
parser.add_argument("--cookie", default=None, help="Override cookies header")
parser.add_argument("--ignore", default="", help="Comma-separated list of days to skip (e.g. 2,3,5,7)")
parser.add_argument("--month", type=int, default=0,
                    help="Relative month offset (e.g. -1 = last month, 0 = current, 1 = next)")
parser.add_argument("--dry-run", action="store_true")
parser.add_argument("--browser", default="auto",
                    choices=["auto", "chrome", "chromium", "brave", "vivaldi", "edge", "firefox", "opera", "safari"],
                    help="Browser profile to read cookies from")
parser.add_argument("--user-agent", default=DEFAULT_UA)
parser.add_argument("--employee-id", default=None, help="Override auto-detected employee id")
args = parser.parse_args()

if PROJECT_ID is None or TASK_ID is None:
    print(f"{Colors.RED}ERROR{Colors.END}     Please do a request in Bamboo and extract the IDs for project and task from https://worldsensing.bamboohr.com/timesheet/hour/entries")
    sys.exit(1)

def header_to_cookiejar(cookie_header):
    jar = RequestsCookieJar()
    for part in cookie_header.split(";"):
        item = part.strip()
        if not item or "=" not in item:
            continue
        name, value = item.split("=", 1)
        jar.set(name.strip(), value.strip(), domain=BAMBOOHR_DOMAIN)
    return jar


def load_browser_cookies(browser_choice):
    loaders = {
        "chrome": browser_cookie3.chrome,
        "chromium": browser_cookie3.chromium,
        "brave": browser_cookie3.brave,
        "vivaldi": browser_cookie3.vivaldi,
        "edge": browser_cookie3.edge,
        "firefox": browser_cookie3.firefox,
        "opera": browser_cookie3.opera,
        "safari": browser_cookie3.safari,
    }

    def filter_cookies(cookie_jar):
        filtered = RequestsCookieJar()
        for cookie in cookie_jar:
            domain = cookie.domain or ""
            if BAMBOOHR_DOMAIN in domain or domain.endswith(".bamboohr.com"):
                filtered.set(cookie.name, cookie.value, domain=domain, path=cookie.path)
        return filtered

    if browser_choice == "auto":
        for loader in loaders.values():
            try:
                jar = filter_cookies(loader())
                if len(jar):
                    return jar
            except (browser_cookie3.BrowserCookieError, TypeError, FileNotFoundError):
                continue
        raise browser_cookie3.BrowserCookieError("No supported browser profile with BambooHR cookies was found.")
    loader = loaders[browser_choice]
    return filter_cookies(loader())


def detect_cookies():
    if args.cookie:
        return header_to_cookiejar(args.cookie)
    try:
        return load_browser_cookies(args.browser)
    except browser_cookie3.BrowserCookieError as exc:
        print(f"{Colors.RED}ERROR{Colors.END}     Could not read cookies: {exc}")
        sys.exit(1)


def get_cookie_value(cookie_jar, name):
    for cookie in cookie_jar:
        if cookie.name.lower() == name.lower():
            return cookie.value
    return None


def decode_bhr_features(value):
    if not value:
        return {}
    try:
        padding = '=' * (-len(value) % 4)
        for decoder in (base64.b64decode, base64.urlsafe_b64decode):
            try:
                decoded = decoder(value + padding).decode("utf-8", errors="ignore")
                return json.loads(decoded)
            except Exception:
                continue
    except Exception:
        return {}


def get_ll_values(cookie_jar):
    llcid = get_cookie_value(cookie_jar, "llcid")
    lluid = get_cookie_value(cookie_jar, "lluid")
    if llcid and lluid:
        return llcid, lluid
    features_cookie = get_cookie_value(cookie_jar, "bhr_features")
    features = decode_bhr_features(features_cookie)
    if features:
        llcid = features.get("llcid") or features.get("companyId")
        lluid = features.get("lluid") or features.get("userId")
        if llcid and lluid:
            return llcid, lluid
    return None, None


def extract_employee_id_from_text(text):
    patterns = [
        r"[\"']?employeeId[\"']?\s*[:=]\s*[\"']?(?P<id>\d+)",
        r"[\"']?currentEmployeeId[\"']?\s*[:=]\s*[\"']?(?P<id>\d+)",
        r"data-employee-id\s*=\s*[\"'](?P<id>\d+)[\"']",
        r"employee-id\s*=\s*[\"'](?P<id>\d+)[\"']",
    ]
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return match.group("id")
    return None


def detect_employee_id(session):
    if args.employee_id:
        return str(args.employee_id)
    cookie_jar = session.cookies
    cookie_names = ["employeeId", "employeeID", "employee_id", "currentEmployeeId"]
    for name in cookie_names:
        value = get_cookie_value(cookie_jar, name)
        if value:
            return str(value)
    features_cookie = get_cookie_value(cookie_jar, "bhr_features")
    features = decode_bhr_features(features_cookie)
    if isinstance(features, dict):
        for key in ["employeeId", "employeeID", "employee_id"]:
            value = features.get(key)
            if value:
                return str(value)
    try:
        for cookie in cookie_jar:
            name_lower = (cookie.name or "").lower()
            value = (cookie.value or "").strip()
            if "employee" in name_lower and "id" in name_lower and value.isdigit():
                return value
        response = session.get(TIMESHEET_PAGE_URL, timeout=15, allow_redirects=True)
        session.cookies.update(response.cookies)
        parsed = urlparse(response.url or "")
        query_id = parse_qs(parsed.query or "").get("id", [None])[0]
        if query_id and query_id.isdigit():
            return query_id
        text = response.text or ""
        employee_id = extract_employee_id_from_text(text)
        if employee_id:
            return employee_id
    except requests.RequestException:
        pass
    print(f"{Colors.RED}ERROR{Colors.END}     Could not determine employee ID. Provide it with --employee-id or ensure the browser profile is logged into BambooHR.")
    sys.exit(1)


def build_pusher_payload(cookie_jar):
    llcid, lluid = get_ll_values(cookie_jar)
    if not llcid or not lluid:
        return None
    socket_id = f"{random.randint(100000, 999999)}.{random.randint(1000000, 9999999)}"
    channel_name = f"private-{llcid}-identityVerification-{lluid}"
    return {"socket_id": socket_id, "channel_name": channel_name}


def get_csrf_from_cookies(cookie_jar):
    for cookie in cookie_jar:
        if 'csrf' in cookie.name.lower():
            return cookie.value
    return None


def extract_csrf_from_response(response):
    header = response.headers.get("x-csrf-token") or response.headers.get("X-CSRF-TOKEN")
    if header:
        return header

    cookie_token = get_csrf_from_cookies(response.cookies)
    if cookie_token:
        return cookie_token

    patterns = [
        r'name="csrf-token"\s+content="([^"]+)"',
        r"name='csrf-token'\s+content='([^']+)'",
        r'"csrfToken"\s*:\s*"([^"]+)"',
        r"csrfToken\s*=\s*'([^']+)'",
        r'csrfToken\s*=\s*"([^"]+)"',
        r'"csrf"\s*:\s*"([^"]+)"',
        r"csrf\s*=\s*'([^']+)'",
        r'data-csrf-token="([^"]+)"',
        r"data-csrf-token='([^']+)'",
        r'CSRF_TOKEN\s*=\s*"([^"]+)"',
        r"CSRF_TOKEN\s*=\s*'([^']+)'",
    ]
    text = response.text or ""
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return match.group(1)

    try:
        soup = BeautifulSoup(text, "html.parser")
    except Exception:
        soup = None

    if soup:
        for tag in soup.find_all(["meta", "input", "div", "span"]):
            for attr_name, attr_value in tag.attrs.items():
                attr_name_lower = attr_name.lower()
                values = []
                if isinstance(attr_value, str):
                    values = [attr_value]
                elif isinstance(attr_value, (list, tuple)):
                    values = [v for v in attr_value if isinstance(v, str)]
                if 'csrf' in attr_name_lower:
                    value = tag.attrs.get("content") or tag.attrs.get("value")
                    if value:
                        return value
                    if values:
                        return values[0]
                for val in values:
                    if 'csrf' in val.lower():
                        value = tag.attrs.get("content") or tag.attrs.get("value")
                        if value:
                            return value
        for script in soup.find_all("script"):
            script_text = script.string or script.text or ""
            for pattern in patterns:
                match = re.search(pattern, script_text, re.IGNORECASE)
                if match:
                    return match.group(1)

    return None


def get_token_from_pusher(session):
    payload = build_pusher_payload(session.cookies)
    if not payload:
        return None
    headers = {
        "Accept": "*/*",
        "Content-Type": "application/x-www-form-urlencoded",
        "Origin": f"https://{BAMBOOHR_DOMAIN}",
        "Referer": f"https://{BAMBOOHR_DOMAIN}/employees/timesheet/?id={EMPLOYEE_ID}",
        "User-Agent": session.headers.get("User-Agent", DEFAULT_UA),
    }
    try:
        response = session.post(PUSHER_AUTH_URL, data=payload, headers=headers, timeout=15)
    except requests.RequestException:
        return None
    session.cookies.update(response.cookies)
    token = response.headers.get("x-csrf-token") or response.headers.get("X-CSRF-TOKEN")
    if token:
        return token
    return extract_csrf_from_response(response)


def detect_csrf_token(session):
    if args.csrf:
        return args.csrf
    token = get_token_from_pusher(session)
    if token:
        return token
    url = f"{TIMESHEET_URL}{EMPLOYEE_ID}"
    response = session.get(url, timeout=15)
    if response.status_code == 401 and "Set-Cookie" in response.headers:
        session.cookies.update(response.cookies)
        response = session.get(url, timeout=15)
    session.cookies.update(response.cookies)
    if response.status_code >= 400:
        print(f"{Colors.RED}ERROR{Colors.END}     Unable to fetch CSRF token, status {response.status_code}")
        sys.exit(1)
    token = extract_csrf_from_response(response)
    if not token:
        token = get_csrf_from_cookies(session.cookies)
    if not token:
        print(f"{Colors.RED}ERROR{Colors.END}     Could not determine CSRF token. Did you log in via the selected browser profile?")
        sys.exit(1)
    return token


cookie_jar = detect_cookies()
if not len(cookie_jar):
    print(f"{Colors.RED}ERROR{Colors.END}     No cookies found. Ensure you are logged into BambooHR in the selected browser profile.")
    sys.exit(1)
session = requests.Session()
session.cookies.update(cookie_jar)
session.headers["User-Agent"] = args.user_agent
EMPLOYEE_ID = detect_employee_id(session)
base_headers = {
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "en-US,en;q=0.7,es-ES;q=0.3",
    "Content-Type": "application/json;charset=utf-8",
    "Origin": f"https://{BAMBOOHR_DOMAIN}",
    "Referer": f"https://{BAMBOOHR_DOMAIN}/employees/timesheet/?id={EMPLOYEE_ID}",
    "User-Agent": args.user_agent,
    "Sec-Fetch-Dest": "empty",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "same-origin",
}
session.headers.update(base_headers)
print(f"\n{Colors.BOLD}BambooHR Timesheet Automation{Colors.END}")
print(f"Employee ID: {Colors.BLUE}{EMPLOYEE_ID}{Colors.END}")
print(f"Project ID:  {Colors.BLUE}{PROJECT_ID}{Colors.END}")
print(f"Task ID:     {Colors.BLUE}{TASK_ID}{Colors.END}")
print(f"Daily Hours: {Colors.BLUE}{DAILY_HOURS}{Colors.END}")
print(f"Country:     {Colors.BLUE}{COUNTRY_ISO}{Colors.END}\n")
csrf_token = detect_csrf_token(session)
session.headers["X-CSRF-TOKEN"] = csrf_token


base_date = datetime.now() + relativedelta(months=args.month)
year, month = base_date.year, base_date.month
days = monthrange(year, month)[1]


def get_holidays(year):
    url = f"https://date.nager.at/api/v3/PublicHolidays/{year}/{COUNTRY_ISO}"
    try:
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        data = r.json()
        return {
            item["date"]
            for item in data
            if not item.get("counties") or any(county in COUNTIES for county in item["counties"])
        }
    except requests.RequestException:
        return set()


holidays = get_holidays(year)
ignore_days = {int(d) for d in args.ignore.split(",") if d.strip().isdigit()}

print(f"{Colors.BOLD}Processing timesheet for {Colors.BLUE}{year}-{month:02d}{Colors.END}")
print(f"{Colors.BOLD}{'Date':<12} {'Status':<10} {'Details'}{Colors.END}")
print("-" * 50)

total_hours = 0

for day in range(1, days + 1):
    current_date = datetime(year, month, day)
    date_str = current_date.strftime("%Y-%m-%d")

    if day in ignore_days:
        print(f"{date_str} {Colors.YELLOW}SKIPPED{Colors.END}    Ignored via --ignore flag")
        continue

    if current_date.weekday() in (5, 6):
        print(f"{date_str} {Colors.YELLOW}SKIPPED{Colors.END}    Weekend")
        continue

    if date_str in holidays:
        print(f"{date_str} {Colors.YELLOW}SKIPPED{Colors.END}    Public holiday in {COUNTRY_ISO}")
        continue

    date_str = f"{year}-{month:02d}-{day:02d}"
    total_hours += DAILY_HOURS
    data = {
        "hours": [
            {
                "id": None,
                "dailyEntryId": 1,
                "employeeId": EMPLOYEE_ID,
                "date": date_str,
                "hours": DAILY_HOURS,
                "note": "",
                "projectId": PROJECT_ID,
                "taskId": TASK_ID
            }
        ]
    }
    if args.dry_run:
        print(f"{date_str} {Colors.BLUE}DRY RUN{Colors.END}    {DAILY_HOURS} hours pending")
        continue

    try:
        r = session.post(BAMBOOHR_URL, json=data)
        r.raise_for_status()
        print(f"{date_str} {Colors.GREEN}SUCCESS{Colors.END}    {DAILY_HOURS} hours logged")
    except requests.RequestException as e:
        print(f"{date_str} {Colors.RED}ERROR{Colors.END}     {str(e)}")

print(f"\n{Colors.BOLD}Total hours: {Colors.BLUE}{total_hours}{Colors.END}")
