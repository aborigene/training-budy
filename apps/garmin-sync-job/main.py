import os
import json
import datetime
import gspread
from google.auth import default
from garminconnect import Garmin

def main():
    # Credentials from Secret Manager via Environment Variables
    garmin_user = os.environ.get("GARMIN_USER")
    garmin_pass = os.environ.get("GARMIN_PASS")
    
    if not garmin_user or not garmin_pass:
        print("Error: GARMIN_USER or GARMIN_PASS not set.")
        return

    # Authenticate Garmin Connect
    try:
        client = Garmin(garmin_user, garmin_pass)
        client.login()
        print("Logged into Garmin Connect successfully.")
    except Exception as e:
        print(f"Error logging into Garmin: {e}")
        return

    # Fetch latest activities (e.g., last 5)
    activities = client.get_activities(0, 5)

    # Authenticate Google Sheets via ADC (Attached Service Account)
    try:
        credentials, project = default(scopes=[
            "https://www.googleapis.com/auth/spreadsheets",
            "https://www.googleapis.com/auth/drive"
        ])
        gc = gspread.authorize(credentials)
        print("Authenticated with Google Sheets.")
    except Exception as e:
        print(f"Error authenticating with Google Sheets: {e}")
        return

    # Spreadsheet needs to be shared with SA email
    sheet_id = os.environ.get("SHEET_ID", "YOUR_SHEET_ID_HERE") 
    try:
        spreadsheet = gc.open_by_key(sheet_id)
        worksheet = spreadsheet.worksheet("Treinos")
    except Exception as e:
        print(f"Error opening spreadsheet or worksheet: {e}")
        return

    # Get existing activity IDs to avoid duplicates
    existing_records = worksheet.get_all_records()
    existing_ids = [str(r.get('Activity ID', '')) for r in existing_records]

    # Insert new activities
    for act in activities:
        act_id = str(act.get('activityId'))
        if act_id not in existing_ids:
            row = [
                act_id,
                act.get('startTimeLocal', ''),
                act.get('activityName', ''),
                act.get('activityType', {}).get('typeKey', ''),
                act.get('distance', 0),
                act.get('duration', 0),
                act.get('averageHR', 0)
            ]
            worksheet.append_row(row)
            print(f"Inserted activity {act_id} into Google Sheets.")
        else:
            print(f"Activity {act_id} already exists.")

if __name__ == "__main__":
    main()