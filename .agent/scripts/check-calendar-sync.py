import os
import json
import urllib.request
from datetime import datetime, timezone
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = ['https://www.googleapis.com/auth/calendar.readonly']
SECRETS_DIR = r'C:\Users\HP\FFS0_HPlaptop\ffs0-factory-super\.agent\secrets'
TOKEN_FILE = os.path.join(SECRETS_DIR, 'google_token.json')

def get_credentials():
    if os.path.exists(TOKEN_FILE):
        return Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    return None

def main():
    creds = get_credentials()
    if not creds:
        print("FAIL: No google_token.json found.")
        return

    try:
        service = build('calendar', 'v3', credentials=creds)
        # Check today's events from Google Calendar
        now = datetime.now(timezone.utc).isoformat()
        events_result = service.events().list(calendarId='primary', timeMin=now, maxResults=50, singleEvents=True, orderBy='startTime').execute()
        gcal_events = events_result.get('items', [])
        
        # Check HG for calendar_event nodes
        req = urllib.request.urlopen("http://localhost:8000/state/lens?kind=calendar_event")
        hg_data = json.loads(req.read())
        hg_nodes = hg_data.get('nodes', {})
        
        # We look for the newly generated sourcing events (e.g. "Review Source: ...")
        new_sources = [node for urn, node in hg_nodes.items() if "source-check" in urn]
        
        missing = []
        found = []
        for node in new_sources:
            summary = node.get("payload", {}).get("summary", "")
            match = next((e for e in gcal_events if e.get("summary") == summary), None)
            if match:
                found.append(summary)
            else:
                missing.append(summary)

        print(f"Total Source Nodes in HG: {len(new_sources)}")
        for f in found:
            print(f"[x] GCAL SYNCED: {f}")
        for m in missing:
            print(f"[ ] MISSING IN GCAL: {m}")
            
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == '__main__':
    main()
    main()
