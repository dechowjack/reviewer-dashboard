from __future__ import annotations

import os
import socket
import sys
import traceback
import threading
from datetime import datetime, timezone
from contextlib import closing
from pathlib import Path

import uvicorn


def _app_name() -> str:
    return "Reviewer Ticket Dashboard"


def _log_path() -> Path:
    override = os.getenv("REVIEWER_DASHBOARD_LOG_PATH")
    if override:
        return Path(override).expanduser()

    if sys.platform == "darwin":
        base_dir = Path.home() / "Library" / "Logs"
    elif sys.platform.startswith("win"):
        local_appdata = os.getenv("LOCALAPPDATA")
        if local_appdata:
            base_dir = Path(local_appdata).expanduser()
        else:
            base_dir = Path.home() / "AppData" / "Local"
        base_dir = base_dir / _app_name() / "Logs"
    else:
        base_dir = Path.home() / ".local" / "state" / "reviewer-ticket-dashboard"

    return base_dir / "desktop-startup.log"


def _find_free_port(start_port: int = 50000, end_port: int = 65000) -> int:
    for port in range(start_port, end_port + 1):
        with closing(socket.socket()) as sock:
            try:
                sock.bind(("127.0.0.1", port))
            except OSError:
                continue
            return port
    raise RuntimeError("No available local port found for the desktop server.")


def _wait_for_server(port: int, timeout_s: float = 12.0) -> None:
    import time

    end = time.monotonic() + timeout_s
    while time.monotonic() < end:
        with closing(socket.socket()) as sock:
            try:
                sock.connect(("127.0.0.1", port))
                return
            except OSError:
                pass
        time.sleep(0.1)
    raise TimeoutError("Server did not start in time.")


def _log_startup_error(message: str, exc: BaseException | None = None) -> None:
    log_path = _log_path()
    try:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("a", encoding="utf-8") as handle:
            handle.write(f"[{datetime.now(timezone.utc).isoformat()}Z] {message}\n")
            if exc is not None:
                handle.write("".join(traceback.format_exception(exc.__class__, exc, exc.__traceback__)))
            else:
                handle.write("No exception object provided.\n")
            handle.write("-" * 80 + "\n")
    except Exception:
        pass


def _stop_server(server: uvicorn.Server | None, thread: threading.Thread | None) -> None:
    if server is not None:
        server.should_exit = True
    if thread is not None and thread.is_alive():
        thread.join(timeout=2)


def main() -> None:
    # Standalone mode uses app-local storage and triggers a one-time migration
    # from data/reviewer_dashboard.db when present.
    os.environ.setdefault("REVIEWER_DASHBOARD_STANDALONE", "1")

    server: uvicorn.Server | None = None
    thread: threading.Thread | None = None

    try:
        from app.main import app

        port = _find_free_port()
        config = uvicorn.Config(
            app,
            host="127.0.0.1",
            port=port,
            log_config=None,
            log_level="warning",
            access_log=False,
            use_colors=False,
        )
        server = uvicorn.Server(config)
        thread = threading.Thread(target=server.run, daemon=True)
        thread.start()

        _wait_for_server(port, timeout_s=25.0)

        try:
            import webview
        except Exception as exc:  # pragma: no cover
            raise RuntimeError("pywebview is required for desktop mode. Install with: pip install pywebview") from exc

        webview.create_window(
            title="Reviewer Ticket Dashboard",
            url=f"http://127.0.0.1:{port}",
            width=1440,
            height=920,
            min_size=(1180, 760),
        )
        webview.start()
    except Exception as exc:
        _stop_server(server, thread)
        _log_startup_error("Desktop app failed to start", exc)
        raise
    finally:
        _stop_server(server, thread)


if __name__ == "__main__":
    main()
