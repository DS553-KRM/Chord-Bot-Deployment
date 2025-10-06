import sys
from gradio_client import Client

url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"
c = Client(url)

print("== Endpoints & Signatures ==")
print(c.view_api(all_endpoints=True))

tests = ["C E", "C,E", "C,E,G"]
for s in tests:
    try:
        out = c.predict(s, api_name="/predict")   # note leading slash here
        print(f"> {s!r} -> {out}")
    except Exception as e:
        print(f"> {s!r} -> ERROR: {e}")

