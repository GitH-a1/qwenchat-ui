import time
import urllib.request
import ssl

# المنافذ والروابط المراد الحفاظ على نشاطها
LOCAL_ENDPOINT = "http://localhost:8000/api/health"

# تعطيل التدقيق للشهادات لضمان عدم توقف الطلب
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

print("🚀 [Heartbeat Engine] Started...")
print("📡 Keeping TCP Sockets & Cloudflare Tunnel Active in background...\n")

headers = {'User-Agent': 'KeepAlive-Daemon/1.0'}

while True:
    try:
        # إرسال نبضة للسيرفر المحلي
        req = urllib.request.Request(LOCAL_ENDPOINT, headers=headers)
        with urllib.request.urlopen(req, timeout=2, context=ctx) as resp:
            if resp.status == 200:
                print(f"🟢 [{time.strftime('%H:%M:%S')}] Heartbeat Ping ACK (200 OK)", end="\r")
    except Exception as e:
        print(f"\n⚠️ [{time.strftime('%H:%M:%S')}] Ping Drop: {e}. Re-trying...")

    # فترات انتظار قصيرة لمنع إغلاق السوكيت
    time.sleep(3)
