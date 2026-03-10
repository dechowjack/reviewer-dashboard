from __future__ import annotations

import os
import socket
import threading
from contextlib import closing

import uvicorn


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


def main() -> None:
    # Standalone mode uses app-local storage and triggers a one-time migration
    # from data/reviewer_dashboard.db when present.
    os.environ.setdefault("REVIEWER_DASHBOARD_STANDALONE", "1")

    from app.main import app

    port = _find_free_port()
    config = uvicorn.Config(app, host="127.0.0.1", port=port, log_level="warning")
    server = uvicorn.Server(config)
    thread = threading.Thread(target=server.run, daemon=True)
    thread.start()

    _wait_for_server(port)

    try:
        import webview
    except Exception as exc:  # pragma: no cover
        server.should_exit = True
        thread.join(timeout=2)
        raise RuntimeError("pywebview is required for desktop mode. Install with: pip install pywebview") from exc

    webview.create_window(
        title="Reviewer Ticket Dashboard",
        url=f"http://127.0.0.1:{port}",
        width=1440,
        height=920,
        min_size=(1180, 760),
    )
    webview.start()

    server.should_exit = True
    thread.join(timeout=2)


if __name__ == "__main__":
    main()
