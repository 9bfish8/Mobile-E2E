import re

from support import adb, open_in_app, press_home, wait_until

PACKAGE = "com.google.android.youtube"

# `dumpsys media_session` prints e.g. "state=PlaybackState {state=3, ..." or "{state=PLAYING(3), ...".
_PLAYING = re.compile(r"state=PlaybackState \{state=(PLAYING\()?3\b")


def is_playing(package: str) -> bool:
    """True if `package` has a media session in the PLAYING state."""
    current = None
    for line in adb("shell", "dumpsys", "media_session").splitlines():
        line = line.strip()
        if line.startswith("package="):
            current = line.removeprefix("package=")
        elif current == package and _PLAYING.search(line):
            return True
    return False


class YouTube:
    def __init__(self, driver):
        self.driver = driver

    def play(self, url: str) -> None:
        press_home(self.driver)
        open_in_app(self.driver, url, PACKAGE)

    def wait_playing(self, timeout: float = 45) -> None:
        wait_until(lambda: is_playing(PACKAGE), timeout, "YouTube 재생(PLAYING) 상태를 확인하지 못함")
