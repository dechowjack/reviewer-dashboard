# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_submodules

hiddenimports = ['webview', 'openpyxl']
hiddenimports += collect_submodules('app')
hiddenimports += collect_submodules('openpyxl')
hiddenimports += collect_submodules('webview')


a = Analysis(
    ['C:\\Users\\jldechow\\Documents\\GitHub\\reviewer-dashboard\\app\\desktop.py'],
    pathex=[],
    binaries=[],
    datas=[('C:\\Users\\jldechow\\Documents\\GitHub\\reviewer-dashboard\\app\\static', 'app/static'), ('C:\\Users\\jldechow\\Documents\\GitHub\\reviewer-dashboard\\app\\templates', 'app/templates')],
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
    icon=['C:\\Users\\jldechow\\Documents\\GitHub\\reviewer-dashboard\\assets\\icons\\reviewer_dashboard.ico'],
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
