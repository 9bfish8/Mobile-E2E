import os
import shutil
import subprocess
import time
from pathlib import Path

from appium.webdriver.common.appiumby import AppiumBy

import config


def adb_path() -> str:
    roots = (
        os.getenv("ANDROID_HOME"),
        os.getenv("ANDROID_SDK_ROOT"),
        str(Path(os.getenv("LOCALAPPDATA", "")) / "Android" / "sdk"),
    )
    exe = "adb.exe" if os.name == "nt" else "adb"
    for root in filter(None, roots):
        path = Path(root) / "platform-tools" / exe
        if path.exists():
            return str(path)
    return shutil.which("adb") or "adb"


def adb(*args: str) -> str:
    cmd = [adb_path()]
    if config.DEVICE_UDID:
        cmd += ["-s", config.DEVICE_UDID]
    result = subprocess.run(
        cmd + list(args),
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=True,
    )
    return result.stdout


def ui(selector: str) -> tuple[str, str]:
    """Locator for an Android UiSelector expression."""
    return AppiumBy.ANDROID_UIAUTOMATOR, selector


def find_now(driver, locator):
    """First match or None, without waiting."""
    elements = driver.find_elements(*locator)
    return elements[0] if elements else None


def wait_until(predicate, timeout: float, message: str, interval: float = 1.0):
    """Polls `predicate` until it returns a truthy value, which is returned."""
    deadline = time.monotonic() + timeout
    while True:
        result = predicate()
        if result:
            return result
        if time.monotonic() >= deadline:
            raise TimeoutError(f"{message} ({timeout:.0f}초 초과)")
        time.sleep(interval)


def press_home(driver) -> None:
    driver.press_keycode(3)  # KEYCODE_HOME


def open_in_app(driver, url: str, package: str) -> None:
    driver.execute_script("mobile: deepLink", {"url": url, "package": package})


def snap(driver, name: str) -> Path:
    config.RUN_DIR.mkdir(parents=True, exist_ok=True)
    path = config.RUN_DIR / f"{name}.png"
    driver.save_screenshot(str(path))
    print(f"    📸 {path}")
    return path
