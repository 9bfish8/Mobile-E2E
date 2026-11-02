import time

import config
from pages.chrome import Chrome
from pages.e2e_app import E2EApp
from pages.youtube import YouTube
from support import snap


def test_qr_wifi_youtube_gateway(driver):
    print("\n[1/3] QR 스캔 → 와이파이 연결")
    app = E2EApp(driver)
    app.start_scan()
    status = app.wait_until_finished(config.QR_TIMEOUT + config.WIFI_TIMEOUT)
    snap(driver, "1_wifi")
    assert status.startswith("CONNECTED:"), f"와이파이 연결 실패: {status}"
    print(f"    {status}")

    print("[2/3] 홈 → YouTube 재생")
    youtube = YouTube(driver)
    youtube.play(config.YOUTUBE_URL)
    youtube.wait_playing()
    time.sleep(config.YOUTUBE_WATCH_SECONDS)
    snap(driver, "2_youtube")

    print("[3/3] 홈 → Chrome으로 게이트웨이 접속")
    chrome = Chrome(driver)
    chrome.open(config.GATEWAY_URL)
    chrome.wait_loaded(config.GATEWAY_URL, expect_text=config.GATEWAY_EXPECT_TEXT)
    snap(driver, "3_gateway")
