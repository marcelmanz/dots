#!/usr/bin/env python3

import argparse
import requests
from datetime import datetime
from calendar import monthrange
import sys


class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'


BAMBOOHR_URL = "https://worldsensing.bamboohr.com/timesheet/hour/entries"
EMPLOYEE_ID = '<ID>'
PROJECT_ID = 6
TASK_ID = 9
DAILY_HOURS = 8
COUNTRY_ISO = 'ES'

if EMPLOYEE_ID == '<ID>':
    print("Error: Please set your EMPLOYEE_ID in the script.")
    sys.exit(1)

parser = argparse.ArgumentParser(description=f"BambooHR Timesheet Automation Tool")
parser.add_argument("--csrf", required=True)
parser.add_argument("--cookie", required=True)
args = parser.parse_args()

print(f"\n{Colors.BOLD}BambooHR Timesheet Automation{Colors.END}")
print(f"Employee ID: {Colors.BLUE}{EMPLOYEE_ID}{Colors.END}")
print(f"Project ID:  {Colors.BLUE}{PROJECT_ID}{Colors.END}")
print(f"Task ID:     {Colors.BLUE}{TASK_ID}{Colors.END}")
print(f"Daily Hours: {Colors.BLUE}{DAILY_HOURS}{Colors.END}")
print(f"Country:     {Colors.BLUE}{COUNTRY_ISO}{Colors.END}\n")

now = datetime.now()
days = monthrange(now.year, now.month)[1]
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

        return {item["date"] for item in data}
    except requests.RequestException:
        return set()


holidays = get_holidays(now.year)

print(f"{Colors.BOLD}Processing timesheet for {Colors.BLUE}{now.year}-{now.month:02d}{Colors.END}")
print(f"{Colors.BOLD}{'Date':<12} {'Status':<10} {'Details'}{Colors.END}")
print("-" * 50)


for day in range(1, days + 1):
    current_date = datetime(now.year, now.month, day)
    date_str = current_date.strftime("%Y-%m-%d")

    if current_date.weekday() in (5, 6):
        print(f"{date_str} {Colors.YELLOW}SKIPPED{Colors.END}    Weekend")
        continue

    if date_str in holidays:
        print(f"{date_str} {Colors.YELLOW}SKIPPED{Colors.END}    Public holiday in {COUNTRY_ISO}")
        continue

    date_str = f"{now.year}-{now.month:02d}-{day:02d}"
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
    try:
        r = requests.post(BAMBOOHR_URL, headers=headers, json=data)
        r.raise_for_status()

        print(f"{date_str} {Colors.GREEN}SUCCESS{Colors.END}    {DAILY_HOURS} hours logged")
    except requests.RequestException as e:
        print(f"{date_str} {Colors.RED}ERROR{Colors.END}     {str(e)}")
