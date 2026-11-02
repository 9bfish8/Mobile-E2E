# E2E 자동화 (Appium + pytest)

PC에서 Appium으로 폰을 조작해 아래 흐름을 자동으로 확인합니다.

1. Mobile E2E 앱 → **카메라로 와이파이 QR 스캔**(사람이 QR을 비춤) → 와이파이 연결
2. 홈 → YouTube에서 영상 재생 → 재생 중(PLAYING)인지 확인
3. 홈 → Chrome으로 `http://192.168.219.1` 접속 → 게이트웨이 페이지가 열렸는지 확인

단계별 스크린샷은 `e2e/artifacts/<실행시각>/`에 저장됩니다.

## 준비 (최초 1회)

- 폰: USB 디버깅 ON, USB로 PC에 연결 (`adb devices`에 보여야 함)
- 폰: YouTube, Chrome을 **한 번씩 직접 열어** 첫 실행 화면(로그인/약관)을 넘겨두기
- 앱 설치: 프로젝트 루트에서 `flutter install` (또는 `flutter run` 한 번)
- 설정: `e2e/.env.example`을 `e2e/.env`로 복사 후 필요시 수정

Python 패키지(이미 `e2e/.venv`에 설치됨, 새 PC라면):

```powershell
python -m venv e2e\.venv
e2e\.venv\Scripts\python -m pip install -r e2e\requirements.txt
```

## 실행

터미널 1 — Appium 서버:

```powershell
powershell -ExecutionPolicy Bypass -File e2e\start_appium.ps1
```

터미널 2 — 테스트:

```powershell
cd e2e
.venv\Scripts\python -m pytest
```

`>>> 폰 카메라에 와이파이 QR을 비춰주세요`가 나오면 QR을 비추면 됩니다.
"네트워크 저장" 팝업은 자동으로 눌러줍니다.

## 구조

| 파일 | 역할 |
|---|---|
| `conftest.py` | Appium 세션 생성, 권한 미리 부여, 실패 시 스크린샷 |
| `config.py` | `.env` 설정값 |
| `support.py` | adb, 대기, 홈 버튼, 딥링크, 스크린샷 헬퍼 |
| `pages/e2e_app.py` | Flutter 앱 (`btn_start`, `status` 식별자로 조작) |
| `pages/system_dialogs.py` | "네트워크 저장", 권한 팝업 |
| `pages/youtube.py` | 영상 열기, `dumpsys media_session`으로 재생 확인 |
| `pages/chrome.py` | URL 열기, 에러(`ERR_…`) 여부와 페이지 로딩 확인 |
| `tests/test_full_flow.py` | 전체 시나리오 |

Flutter 앱의 상태값(`status`): `IDLE` → `SCANNING` → `CONNECTING` → `CONNECTED:<SSID>` 또는 `FAILED:<이유>`
