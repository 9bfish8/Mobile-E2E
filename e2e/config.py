import os
from datetime import datetime
from pathlib import Path

from dotenv import load_dotenv

E2E_DIR = Path(__file__).resolve().parent
load_dotenv(E2E_DIR / ".env")

APPIUM_URL = os.getenv("APPIUM_URL", "http://127.0.0.1:4723")
DEVICE_UDID = os.getenv("DEVICE_UDID") or None

APP_PACKAGE = "com.mobilee2e.mobile_e2e"
APP_ACTIVITY = ".MainActivity"

QR_TIMEOUT = int(os.getenv("QR_TIMEOUT", "120"))
WIFI_TIMEOUT = int(os.getenv("WIFI_TIMEOUT", "60"))

YOUTUBE_URL = os.getenv("YOUTUBE_URL", "https://www.youtube.com/watch?v=jNQXAC9IVRw")
YOUTUBE_WATCH_SECONDS = int(os.getenv("YOUTUBE_WATCH_SECONDS", "5"))

GATEWAY_URL = os.getenv("GATEWAY_URL", "http://192.168.219.1")
GATEWAY_EXPECT_TEXT = os.getenv("GATEWAY_EXPECT_TEXT") or None

# One folder per run: artifacts/20261102-153000/
RUN_DIR = E2E_DIR / "artifacts" / datetime.now().strftime("%Y%m%d-%H%M%S")
