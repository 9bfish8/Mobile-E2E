import subprocess

import pytest
from appium import webdriver
from appium.options.android import UiAutomator2Options

import config
from support import adb, snap

# Granted before the session so runtime-permission dialogs never block the flow.
_PERMISSIONS = ("android.permission.CAMERA", "android.permission.ACCESS_FINE_LOCATION")


@pytest.fixture(scope="session")
def driver():
    try:
        for permission in _PERMISSIONS:
            adb("shell", "pm", "grant", config.APP_PACKAGE, permission)
    except subprocess.CalledProcessError as e:
        pytest.exit(
            f"adb 권한 부여 실패 — 폰 연결과 앱 설치(flutter install)를 확인하세요.\n{e.stderr}",
            returncode=2,
        )

    options = UiAutomator2Options()
    options.app_package = config.APP_PACKAGE
    options.app_activity = config.APP_ACTIVITY
    options.no_reset = True
    options.new_command_timeout = 300
    # Restart the app on every run so it starts from the IDLE state.
    options.set_capability("forceAppLaunch", True)
    options.set_capability("shouldTerminateApp", True)
    if config.DEVICE_UDID:
        options.udid = config.DEVICE_UDID

    drv = webdriver.Remote(config.APPIUM_URL, options=options)
    yield drv
    drv.quit()


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    report = outcome.get_result()
    if report.when == "call" and report.failed:
        drv = item.funcargs.get("driver")
        if drv is not None:
            snap(drv, f"FAILED_{item.name}")
