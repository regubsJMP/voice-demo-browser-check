# Static server for probe/ on one port (127.0.0.1) that also takes the page's log lines: the page sends every line with
# navigator.sendBeacon('/log', …) and they are appended to <log file> — the whole log ends up in the run's artifacts, not only what fits
# on a screenshot (run 9: the important last lines were below the window).
#   python3 serve.py <port> <root> <log file>
import http.server
import sys

port, root, logf = int(sys.argv[1]), sys.argv[2], sys.argv[3]


class H(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=root, **k)

    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0) or 0)).decode("utf-8", "replace")
        with open(logf, "a", encoding="utf-8") as f:
            f.write(f"{port} {body}\n")
        self.send_response(204)
        self.end_headers()

    def log_message(self, *a):
        pass


http.server.ThreadingHTTPServer(("127.0.0.1", port), H).serve_forever()
