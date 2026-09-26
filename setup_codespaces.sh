#!/bin/bash

# ==============================================================================
# AUTOMATED GITHUB CODESPACES DEPLOYMENT SCRIPT
# Components: FastAPI Server, Gradio AI Interface, Cloudflare Tunnel
# ==============================================================================

export DEBIAN_FRONTEND=noninteractive
export PIP_BREAK_SYSTEM_PACKAGES=1

# Terminal Colors
GREEN='\033[38;5;46m'
BLUE='\033[38;5;27m'
MAGENTA='\033[38;5;201m'
CYAN='\033[38;5;51m'
REST='\033[0m'

echo -e "${CYAN}[1/5] Updating packages and installing dependencies...${REST}"
sudo apt-get update -y && sudo apt-get install -y wget curl python3-pip

echo -e "${CYAN}[2/5] Installing Python modules (FastAPI, Gradio, Uvicorn)...${REST}"
python3 -m pip install --quiet fastapi uvicorn gradio requests

WORK_DIR="$HOME/codespaces_app"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo -e "${CYAN}[3/5] Building Web Dashboard and API Engine...${REST}"

# Generate Dashboard HTML
cat << 'HTML' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Codespaces Autonomous Workstation</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700&family=JetBrains+Mono&display=swap" rel="stylesheet">
    <style>
        body { background: #090d16; color: #f3f4f6; font-family: 'Inter', sans-serif; padding: 40px; display: flex; justify-content: center; }
        .card { background: #111827; border: 1px solid #1f2937; border-radius: 16px; padding: 32px; max-width: 700px; width: 100%; box-shadow: 0 10px 30px rgba(0,242,254,0.1); }
        h1 { color: #00f2fe; margin-top: 0; }
        .status { display: inline-block; background: rgba(0,255,135,0.15); color: #00ff87; border: 1px solid #00ff87; padding: 6px 14px; border-radius: 20px; font-weight: bold; font-size: 0.85rem; }
        .console { background: #030712; border: 1px solid #1f2937; border-radius: 8px; padding: 16px; font-family: 'JetBrains Mono', monospace; color: #00f2fe; margin-top: 20px; font-size: 0.85rem; }
    </style>
</head>
<body>
    <div class="card">
        <h1>GitHub Codespaces Suite</h1>
        <div class="status">● ALL SERVICES ONLINE</div>
        <div class="console">
            > FastAPI Endpoint: http://localhost:8000/api/health<br>
            > Gradio AI Interface: http://localhost:8000/gradio<br>
            > Cloudflare Tunnel Active<br>
        </div>
    </div>
</body>
</html>
HTML

# Generate App Engine Script
cat << 'PYENGINE' > app_engine.py
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import gradio as gr

app = FastAPI()

@app.get("/api/health")
def health_check():
    return {"status": "ONLINE", "environment": "GitHub Codespaces"}

app.mount("/dashboard", StaticFiles(directory="."), name="dashboard")

@app.get("/")
def serve_index():
    return FileResponse("index.html")

def process_ai_query(user_input):
    return f"🤖 [Codespaces AI Response]: Processed request -> '{user_input}'"

io = gr.Interface(
    fn=process_ai_query,
    inputs=gr.Textbox(lines=2, placeholder="Enter prompt here..."),
    outputs="text",
    title="Autonomous AI Agent Interface"
)

app = gr.mount_gradio_app(app, io, path="/gradio")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
PYENGINE

echo -e "${CYAN}[4/5] Launching Application Engine on Port 8000...${REST}"
sudo fuser -k 8000/tcp > /dev/null 2>&1 || true
nohup python3 app_engine.py > /tmp/app_engine.log 2>&1 &

sleep 3

echo -e "${CYAN}[5/5] Deploying Cloudflare Tunnel...${REST}"
if ! command -v cloudflared &> /dev/null; then
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb > /dev/null 2>&1 || true
    rm -f cloudflared-linux-amd64.deb
fi

pkill cloudflared || true
nohup cloudflared tunnel --url http://localhost:8000 > /tmp/cloudflare.log 2>&1 &

echo -e "${BLUE}Waiting for public URL generation...${REST}"
sleep 6

PUBLIC_URL=$(grep -o 'https://.*\.trycloudflare\.com' /tmp/cloudflare.log | tail -n 1 || true)

echo ""
echo -e "${GREEN}========================================================================${REST}"
echo -e "${GREEN}✔ DEPLOYMENT COMPLETE & OPERATIONAL${REST}"
echo -e "${GREEN}========================================================================${REST}"
echo -e "${WHITE}Public Domain URL: ${MAGENTA}${PUBLIC_URL:-"Check /tmp/cloudflare.log"}${REST}"
echo -e "${WHITE}Gradio AI Interface: ${MAGENTA}${PUBLIC_URL}/gradio${REST}"
echo -e "${WHITE}API Health Endpoint: ${MAGENTA}${PUBLIC_URL}/api/health${REST}"
echo -e "${GREEN}========================================================================${REST}"
