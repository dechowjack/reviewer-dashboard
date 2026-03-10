# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_submodules

hiddenimports = ['webview']
hiddenimports += collect_submodules('app')


a = Analysis(
    ['/Users/jldechow/Documents/Codex/reviewer-dashboard/app/desktop.py'],
    pathex=[],
    binaries=[],
    datas=[('/Users/jldechow/Documents/Codex/reviewer-dashboard/app/static', 'app/static'), ('/Users/jldechow/Documents/Codex/reviewer-dashboard/app/templates', 'app/templates')],
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='Reviewer Ticket Dashboard',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['/Users/jldechow/Documents/Codex/reviewer-dashboard/assets/icons/reviewer_dashboard_1024.png'],
)
coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='Reviewer Ticket Dashboard',
)
app = BUNDLE(
    coll,
    name='Reviewer Ticket Dashboard.app',
    icon='/Users/jldechow/Documents/Codex/reviewer-dashboard/assets/icons/reviewer_dashboard_1024.png',
    bundle_identifier=None,
)
