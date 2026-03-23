import os.path
import json
from datetime import datetime, timezone
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
import re

# If modifying these scopes, delete the file token.json.
SCOPES = [
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/tasks.readonly",
    "https://www.googleapis.com/auth/drive.readonly",
]

# Paths
SECRETS_DIR = r"C:\Users\HP\FFS0_HPlaptop\ffs0-factory-super\.agent\secrets"
CLIENT_SECRET_FILE = os.path.join(
    SECRETS_DIR,
    "client_secret_2_772554845686-901i9881tkqcrm2gekje810jlotuumdo.apps.googleusercontent.com.json",
)
TOKEN_FILE = os.path.join(SECRETS_DIR, "google_token.json")
WORKSPACE_ROOT = r"C:\Users\HP\FFS0_HPlaptop\ffs0-factory-super"


def get_credentials():
    creds = None
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRET_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(TOKEN_FILE, "w") as token:
            token.write(creds.to_json())
    return creds


def clean_filename(title):
    clean = re.sub(r"[^a-zA-Z0-9]+", "-", title.lower()).strip("-")
    return clean[:50]


def sync_calendar(creds):
    print("Syncing Calendar...")
    service = build("calendar", "v3", credentials=creds)
    now = datetime.now(timezone.utc).isoformat()
    entries_dir = os.path.join(
        WORKSPACE_ROOT, ".agent", "kb", "reference", "calendar", "entries"
    )
    os.makedirs(entries_dir, exist_ok=True)

    events_result = (
        service.events()
        .list(
            calendarId="primary",
            timeMin=now,
            maxResults=50,
            singleEvents=True,
            orderBy="startTime",
        )
        .execute()
    )
    events = events_result.get("items", [])

    for event in events:
        start = event["start"].get("dateTime", event["start"].get("date"))
        end = event["end"].get("dateTime", event["end"].get("date"))
        data = {
            "id": f"cal:{event['id']}",
            "source_type": "google_calendar",
            "retrieved_at": now,
            "summary": event.get("summary", "No Title"),
            "description": event.get("description", ""),
            "location": event.get("location", ""),
            "start_time": start,
            "end_time": end,
            "status": event.get("status", ""),
            "organizer": event.get("organizer", {}).get("email", ""),
            "attendees": [
                a.get("email") for a in event.get("attendees", []) if a.get("email")
            ],
        }
        name = clean_filename(data["summary"])
        file_path = os.path.join(entries_dir, f"{name}-{event['id'][:8]}.json")
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
    print(f"Synced {len(events)} events.")


def sync_tasks(creds):
    print("Syncing Tasks...")
    service = build("tasks", "v1", credentials=creds)
    now = datetime.now(timezone.utc).isoformat()
    entries_dir = os.path.join(
        WORKSPACE_ROOT, ".agent", "kb", "reference", "tasks", "entries"
    )
    os.makedirs(entries_dir, exist_ok=True)

    tasklists_result = service.tasklists().list().execute()
    tasklists = tasklists_result.get("items", [])

    total_tasks = 0
    for tl in tasklists:
        tasks_result = service.tasks().list(tasklist=tl["id"]).execute()
        tasks = tasks_result.get("items", [])
        for task in tasks:
            data = {
                "id": f"task:{task['id']}",
                "source_type": "google_tasks",
                "retrieved_at": now,
                "title": task.get("title", "No Title"),
                "notes": task.get("notes", ""),
                "status": task.get("status", "needsAction"),
                "due": task.get("due", ""),
                "completed_at": task.get("completed", ""),
                "tasklist_id": tl["id"],
            }
            name = clean_filename(data["title"])
            file_path = os.path.join(entries_dir, f"{name}-{task['id'][:8]}.json")
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
            total_tasks += 1
    print(f"Synced {total_tasks} tasks across {len(tasklists)} lists.")


def sync_drive(creds):
    print("Syncing Drive for PRG040 Retroactive Scan (April 2025)...")
    service = build("drive", "v3", credentials=creds)
    now = datetime.now(timezone.utc).isoformat()
    entries_dir = os.path.join(
        WORKSPACE_ROOT, ".agent", "kb", "reference", "drive", "entries"
    )
    os.makedirs(entries_dir, exist_ok=True)

    query = "createdTime >= '2025-04-01T00:00:00Z'"

    results = (
        service.files()
        .list(
            q=query,
            pageSize=15,
            fields="nextPageToken, files(id, name, createdTime, mimeType, webViewLink)",
            orderBy="createdTime",
        )
        .execute()
    )

    items = results.get("files", [])
    import urllib.request

    for item in items:
        data = {
            "id": f"drive:{item['id']}",
            "source_type": "google_drive",
            "name": item.get("name"),
            "createdTime": item.get("createdTime"),
            "mimeType": item.get("mimeType"),
            "webViewLink": item.get("webViewLink"),
        }

        name = clean_filename(data["name"])
        file_path = os.path.join(entries_dir, f"{name}-{item['id'][:8]}.json")
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)

        try:
            morphism = {
                "envelope": {
                    "type": "ADD",
                    "actor": "urn:moos:agent:vscode-ai",
                    "add": {
                        "urn": f"urn:moos:drive:file:{item['id']}",
                        "type_id": "google_drive_file",
                        "stratum": "S1",
                        "payload": data,
                    },
                }
            }
            req = urllib.request.Request(
                "http://localhost:8000/morphisms",
                data=json.dumps(morphism).encode("utf-8"),
                headers={"Content-Type": "application/json"},
            )
            urllib.request.urlopen(req)
        except Exception as e:
            pass

    print(f"Synced {len(items)} historical Drive files for PRG040.")


def main():
    try:
        creds = get_credentials()
        sync_calendar(creds)
        sync_tasks(creds)
        sync_drive(creds)
        print("Google Sync complete!")
    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    main()
