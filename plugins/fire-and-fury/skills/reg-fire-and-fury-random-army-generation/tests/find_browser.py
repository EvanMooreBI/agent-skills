"""Find Chrome, Chromium or Edge the same way the PowerShell scripts do."""
import os
import shutil
import sys
from pathlib import Path

NAMES = ('chrome', 'google-chrome', 'google-chrome-stable', 'chromium', 'chromium-browser', 'msedge', 'microsoft-edge')


def default_paths():
    if sys.platform == 'win32':
        roots = [os.environ.get('ProgramFiles', r'C:\Program Files'), os.environ.get('ProgramFiles(x86)', r'C:\Program Files (x86)'), os.environ.get('LOCALAPPDATA', '')]
        return [Path(root) / 'Google/Chrome/Application/chrome.exe' for root in roots if root] + \
               [Path(root) / 'Microsoft/Edge/Application/msedge.exe' for root in roots[:2]]
    if sys.platform == 'darwin':
        return [Path('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'), Path('/Applications/Chromium.app/Contents/MacOS/Chromium'), Path('/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge')]
    return [Path('/usr/bin/google-chrome'), Path('/usr/bin/chromium'), Path('/usr/bin/chromium-browser'), Path('/snap/bin/chromium'), Path('/usr/bin/microsoft-edge')]


def find_browser() -> Path:
    configured = os.environ.get('CHROME_PATH')
    if configured and Path(configured).is_file():
        return Path(configured)
    for name in NAMES:
        found = shutil.which(name)
        if found:
            return Path(found)
    for path in default_paths():
        if path.is_file():
            return path
    raise SystemExit('Chrome, Chromium, or Microsoft Edge is required. Install one, or set CHROME_PATH to its executable.')
