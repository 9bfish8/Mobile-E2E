from pages import system_dialogs
from support import find_now, ui, wait_until

# Semantics identifiers set in lib/main.dart (exposed as Android resource-ids).
_START = ui('new UiSelector().resourceId("btn_start")')
_STATUS = ui('new UiSelector().resourceId("status")')


class E2EApp:
    """The Flutter app: QR scan → Wi-Fi connect."""

    def __init__(self, driver):
        self.driver = driver

    def status(self) -> str | None:
        """IDLE / SCANNING / CONNECTING / CONNECTED:<ssid> / FAILED:<reason>, or None if not on screen."""
        element = find_now(self.driver, _STATUS)
        if element is None:
            return None
        return element.get_attribute("content-desc") or element.text

    def start_scan(self) -> None:
        wait_until(lambda: find_now(self.driver, _START), 15, "앱 시작 버튼(btn_start)을 찾지 못함").click()
        print("\n>>> 폰 카메라에 와이파이 QR을 비춰주세요")

    def wait_until_finished(self, timeout: float) -> str:
        """Waits through the camera scan and Wi-Fi connection, tapping system dialogs on the way.

        The scanner page and the "Save network?" sheet both hide `status`, so it is
        read whenever it is visible rather than tracked step by step.
        """

        def finished():
            system_dialogs.dismiss_wifi_dialogs(self.driver)
            status = self.status()
            return status if status and status.startswith(("CONNECTED:", "FAILED:")) else None

        return wait_until(finished, timeout, "QR 스캔/와이파이 연결이 끝나지 않음")
