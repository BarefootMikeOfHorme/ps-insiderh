import os
import subprocess
import sys

import pytest

PWSH = shutil = None
try:
    import shutil
    PWSH = shutil.which('pwsh') or shutil.which('powershell')
except Exception:
    PWSH = None

pytestmark = pytest.mark.skipif(PWSH is None, reason='pwsh/powershell not available')


def test_wdac_policy_validation(tmp_path):
    wdac_dir = tmp_path / 'wdac'
    wdac_dir.mkdir()
    policy = wdac_dir / 'policy.xml'
    policy.write_text('<Policy><Rule Id="test"/><Policy></Policy>')

    env = os.environ.copy()
    env['GITHUB_WORKSPACE'] = str(tmp_path)

    script = os.path.join(os.getcwd(), 'ci', 'wdac_validate.ps1')
    # Use pwsh to execute the script
    subprocess.check_call([PWSH, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script], env=env)
