#!/usr/bin/env -S uv run

# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "requests>=2.31.0",
#   "python-dateutil>=2.9.0",
# ]
# ///

# Example:
# ./scripts/work/bamboo-timesheet.py --csrf '<csrf-header>' --cookie '<cookie-header>' --month <month-relative-num>

import argparse
import requests
from datetime import datetime
from calendar import monthrange
from dateutil.relativedelta import relativedelta
import sys


class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'


BAMBOOHR_URL = "https://worldsensing.bamboohr.com/timesheet/hour/entries"
EMPLOYEE_ID = '349'
PROJECT_ID = 6
TASK_ID = 9
DAILY_HOURS = 8
COUNTRY_ISO = 'ES'
COUNTIES = {'ES-CT', 'ES-B'}

if EMPLOYEE_ID == '<ID>':
    print("Error: Please set your EMPLOYEE_ID in the script.")
    sys.exit(1)

parser = argparse.ArgumentParser(description=f"BambooHR Timesheet Automation Tool")
parser.add_argument("--csrf", required=True)
parser.add_argument("--cookie", required=True)
parser.add_argument("--ignore", default="", help="Comma-separated list of days to skip (e.g. 2,3,5,7)")
parser.add_argument("--month", type=int, default=0,
                    help="Relative month offset (e.g. -1 = last month, 0 = current, 1 = next)")
parser.add_argument("--dry-run", action="store_true")
args = parser.parse_args()

print(f"\n{Colors.BOLD}BambooHR Timesheet Automation{Colors.END}")
print(f"Employee ID: {Colors.BLUE}{EMPLOYEE_ID}{Colors.END}")
print(f"Project ID:  {Colors.BLUE}{PROJECT_ID}{Colors.END}")
print(f"Task ID:     {Colors.BLUE}{TASK_ID}{Colors.END}")
print(f"Daily Hours: {Colors.BLUE}{DAILY_HOURS}{Colors.END}")
print(f"Country:     {Colors.BLUE}{COUNTRY_ISO}{Colors.END}\n")

base_date = datetime.now() + relativedelta(months=args.month)
year, month = base_date.year, base_date.month
days = monthrange(year, month)[1]
headers = {
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "en-US,en;q=0.7,es-ES;q=0.3",
    "Content-Type": "application/json;charset=utf-8",
    "X-CSRF-TOKEN": args.csrf,
    "Origin": "https://worldsensing.bamboohr.com",
    "Referer": f"https://worldsensing.bamboohr.com/employees/timesheet/?id={EMPLOYEE_ID}",
    "Cookie": args.cookie,
    "Sec-Fetch-Dest": "empty",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "same-origin",
}


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
        r = requests.post(BAMBOOHR_URL, headers=headers, json=data)
        r.raise_for_status()
        print(f"{date_str} {Colors.GREEN}SUCCESS{Colors.END}    {DAILY_HOURS} hours logged")
    except requests.RequestException as e:
        print(f"{date_str} {Colors.RED}ERROR{Colors.END}     {str(e)}")

print(f"\n{Colors.BOLD}Total hours: {Colors.BLUE}{total_hours}{Colors.END}")
