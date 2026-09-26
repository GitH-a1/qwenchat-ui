cat << 'EOF' > watchdog.sh
#!/bin/bash

echo "=========================================="
echo "  [+] Starting Watchdog for app_engine.py"
echo "=========================================="

# الانتقال لمجلد العمل
if [ -d "$HOME/codespaces_app" ]; then
    cd "$HOME/codespaces_app"
else
    cd /workspaces/* 2>/dev/null || true
fi

FASTAPI_CMD="python3 app_engine.py"

while true; do
    # فحص عمل منفذ FastAPI (8000)
    if ! nc -z localhost 8000 >/dev/null 2>&1; then
        echo "[!] $(date +'%H:%M:%S') - App Engine down. Restarting app_engine.py..."
        nohup $FASTAPI_CMD > /tmp/app_engine.log 2>&1 &
        sleep 4
    fi

    sleep 5
done
EOF

chmod 755 watchdog.sh
./watchdog.sh
