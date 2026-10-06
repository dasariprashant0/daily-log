#!/usr/bin/env python3
"""Opens a Notion-style daily log page in the browser; saves ~/daily-log/YYYY-MM-DD.md. Stdlib only."""
import datetime, html, http.server, os, threading, urllib.parse, webbrowser

DIR = os.path.expanduser("~/daily-log")
TODAY = datetime.date.today()
FILE = os.path.join(DIR, TODAY.isoformat() + ".md")
FIELDS = [
    ("did", "📝 What I did", "Everything you worked on today…"),
    ("finished", "✅ Finished", "What got done and closed…"),
    ("started", "🚀 Started", "What you kicked off…"),
    ("pending", "⏳ Pending / blocked", "What's waiting on someone or something…"),
    ("todo", "📌 To do next", "What needs doing tomorrow…"),
]

PAGE = """<!doctype html><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
<title>Daily log</title>
<style>
:root{--bg:#fff;--fg:#37352f;--mute:#9b9a97;--line:#e9e9e7;--hover:#f7f7f5;--btn:#2383e2}
@media(prefers-color-scheme:dark){:root{--bg:#191919;--fg:#e6e6e4;--mute:#7f7f7d;--line:#2f2f2f;--hover:#252525}}
body{background:var(--bg);color:var(--fg);font:16px/1.5 ui-sans-serif,-apple-system,"Segoe UI",sans-serif;margin:0}
main{max-width:720px;margin:0 auto;padding:12vh 24px 80px}
h1{font-size:40px;margin:0 0 4px}
.date{color:var(--mute);margin-bottom:32px;padding-bottom:16px;border-bottom:1px solid var(--line)}
h2{font-size:20px;margin:28px 0 6px}
textarea{width:100%;box-sizing:border-box;min-height:84px;padding:8px 10px;border:1px solid transparent;border-radius:4px;
background:transparent;color:inherit;font:inherit;resize:vertical}
textarea:hover{background:var(--hover)}textarea:focus{outline:none;background:var(--hover);border-color:var(--line)}
button{margin-top:32px;background:var(--btn);color:#fff;border:0;border-radius:4px;padding:8px 18px;font:inherit;cursor:pointer}
</style>
<main><h1>Daily log</h1><div class=date>__DATE__</div>
<form method=post>__FIELDS__<button>Save log</button></form></main>
<script>
let saving=false;addEventListener("beforeunload",e=>{if(!saving){e.preventDefault();e.returnValue=""}});
document.querySelector("form").addEventListener("submit",()=>saving=true);
</script>"""


def page():
    fields = "".join(
        f'<h2>{t}</h2><textarea name={k} required placeholder="{html.escape(p)}"></textarea>' for k, t, p in FIELDS
    )
    return PAGE.replace("__DATE__", TODAY.strftime("%A, %d %B %Y")).replace("__FIELDS__", fields)


class H(http.server.BaseHTTPRequestHandler):
    def reply(self, body, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(body.encode())

    def do_GET(self):
        self.reply(page())

    def do_POST(self):
        data = urllib.parse.parse_qs(self.rfile.read(int(self.headers["Content-Length"])).decode())
        vals = {k: data.get(k, [""])[0].strip() for k, _, _ in FIELDS}
        if not all(vals.values()):  # server-side check too, `required` is bypassable
            return self.reply("Fill every box. Go back.", 400)
        with open(FILE, "w") as f:
            f.write(f"# {TODAY.isoformat()}\n\n" + "".join(f"## {t}\n{vals[k]}\n\n" for k, t, _ in FIELDS))
        self.reply("<body style='font:20px sans-serif;padding:20vh 0;text-align:center'>Saved ✓ You can close this tab.")
        threading.Thread(target=self.server.shutdown).start()

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    os.makedirs(DIR, exist_ok=True)
    if os.path.exists(FILE) and os.path.getsize(FILE):
        raise SystemExit  # already logged today
    srv = http.server.HTTPServer(("127.0.0.1", 0), H)
    webbrowser.open(f"http://127.0.0.1:{srv.server_port}/")
    srv.serve_forever()
