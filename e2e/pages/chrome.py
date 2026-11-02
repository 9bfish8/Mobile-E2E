from urllib.parse import urlparse

from appium.webdriver.common.appiumby import AppiumBy

from support import find_now, open_in_app, press_home, ui, wait_until

PACKAGE = "com.android.chrome"

_URL_BAR = ui(f'new UiSelector().resourceId("{PACKAGE}:id/url_bar")')
# Chrome error pages always show a code like ERR_CONNECTION_TIMED_OUT, whatever the language.
_ERROR_CODE = ui('new UiSelector().textContains("ERR_")')
# First-run screens and the "not secure" interstitial, tapped when they show up.
_INTERRUPTIONS = ui(
    'new UiSelector().textMatches("(?i)^(accept & continue|동의 및 계속|use without an account'
    '|계정 없이 사용|no thanks|아니요|continue to site|사이트로 이동)$")'
)
_PAGE_CONTENT = (
    AppiumBy.XPATH,
    "//android.webkit.WebView//*[string-length(@text) > 0 or string-length(@content-desc) > 0]",
)


class Chrome:
    def __init__(self, driver):
        self.driver = driver

    def open(self, url: str) -> None:
        press_home(self.driver)
        open_in_app(self.driver, url, PACKAGE)

    def wait_loaded(self, url: str, timeout: float = 30, expect_text: str | None = None) -> None:
        host = urlparse(url).hostname

        def loaded():
            interruption = find_now(self.driver, _INTERRUPTIONS)
            if interruption is not None:
                print(f"    Chrome 팝업 처리: {interruption.text}")
                interruption.click()
                return False
            error = find_now(self.driver, _ERROR_CODE)
            if error is not None:
                raise AssertionError(f"게이트웨이 접속 실패: {error.text}")
            url_bar = find_now(self.driver, _URL_BAR)
            if url_bar is None or host not in (url_bar.text or ""):
                return False
            if expect_text:
                return self._has_text(expect_text)
            return find_now(self.driver, _PAGE_CONTENT) is not None

        wait_until(loaded, timeout, f"{url} 페이지가 열리지 않음")

    def _has_text(self, text: str) -> bool:
        return any(
            find_now(self.driver, ui(f'new UiSelector().{attr}("{text}")')) is not None
            for attr in ("textContains", "descriptionContains")
        )
