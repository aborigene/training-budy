import os
import datetime
from fastapi import FastAPI, Request
from mcp.server.fastmcp import FastMCP
import gspread
from google.auth import default
import uvicorn

# Initialize FastMCP
mcp = FastMCP("TrainingBudyMCP")

# Function to get Google Sheets client
def get_sheets_client():
    credentials, _ = default(scopes=[
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/drive"
    ])
    return gspread.authorize(credentials)

SHEET_ID = os.environ.get("SHEET_ID", "YOUR_SHEET_ID_HERE")

@mcp.tool()
def get_recent_metrics(limit: int = 5) -> str:
    """Read recent training metrics from the Google Sheet."""
    try:
        gc = get_sheets_client()
        sheet = gc.open_by_key(SHEET_ID).worksheet("Treinos")
        records = sheet.get_all_records()
        recent = records[-limit:] if len(records) > limit else records
        return str(recent)
    except Exception as e:
        return f"Error fetching metrics: {str(e)}"

@mcp.tool()
def get_subjective_notes(limit: int = 5) -> str:
    """Read subjective training notes from the Google Sheet."""
    try:
        gc = get_sheets_client()
        sheet = gc.open_by_key(SHEET_ID).worksheet("Notas")
        records = sheet.get_all_records()
        recent = records[-limit:] if len(records) > limit else records
        return str(recent)
    except Exception as e:
        return f"Error fetching notes: {str(e)}"

# Setup FastAPI for MCP SSE and /notes endpoint
app = FastAPI()

# In FastMCP (mcp>=1.0.0), SSE integration requires explicit SSE handling
from mcp.server.sse import SseServerTransport

# Global transport reference
sse_transport = None

@app.get("/mcp/sse")
async def handle_sse(request: Request):
    global sse_transport
    # Set the messages endpoint where clients will POST their MCP payloads
    sse_transport = SseServerTransport("/mcp/messages")
    
    # Run the FastMCP core server loop connected to this SSE transport
    import asyncio
    asyncio.create_task(mcp._mcp_server.run(
        sse_transport.messages_stream(),
        sse_transport.post_message,
        mcp._mcp_server._create_initialization_options()
    ))
    
    # Return the SSE event stream response
    return await sse_transport.handle_sse(request.scope, request.receive, request._send)

@app.post("/mcp/messages")
async def handle_messages(request: Request):
    global sse_transport
    if sse_transport is None:
        return {"error": "SSE connection not established"}
    
    # Forward the incoming POST payload to the active SSE transport
    await sse_transport.handle_post_message(request.scope, request.receive, request._send)
    return {}

@app.post("/notes")
async def add_note(request: Request):
    """
    Endpoint for iOS Shortcuts to send voice notes via POST JSON payload.
    Expected JSON: {"note": "My workout was hard today"}
    """
    try:
        data = await request.json()
        note = data.get("note", "")
        if not note:
            return {"status": "error", "message": "No note provided"}
        
        gc = get_sheets_client()
        sheet = gc.open_by_key(SHEET_ID).worksheet("Notas")
        
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        sheet.append_row([timestamp, note])
        return {"status": "success"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)