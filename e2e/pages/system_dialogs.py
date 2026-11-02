from support import find_now, ui

# Android 11+ "네트워크를 저장하시겠습니까?" sheet opened by registerWifiNetwork.
_SAVE_NETWORK = ui('new UiSelector().textMatches("(?i)^(저장|save)$")')
# Runtime permission dialog, in case a permission was not pre-granted.
_ALLOW_PERMISSION = ui('new UiSelector().resourceIdMatches(".*:id/permission_allow.*")')


def dismiss_wifi_dialogs(driver) -> str | None:
    """Taps a known system dialog if one is showing; returns which one."""
    for name, locator in (("save_network", _SAVE_NETWORK), ("allow_permission", _ALLOW_PERMISSION)):
        element = find_now(driver, locator)
        if element is not None:
            element.click()
            print(f"    시스템 팝업 처리: {name}")
            return name
    return None
