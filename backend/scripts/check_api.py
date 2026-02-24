import json
import sys
from urllib.request import urlopen, Request


BASE = "http://127.0.0.1:8000/api"


def get_articles(page=1, page_size=10, q=""):
    url = f"{BASE}/articles/?page={page}&page_size={page_size}"
    if q:
        url += f"&q={q}"
    with urlopen(url) as resp:
        data = resp.read().decode("utf-8")
    return json.loads(data)


def create_sample():
    payload = {
        "title": "测试文章",
        "content": "这是第一篇测试文章内容。",
        "published": True,
    }
    req = Request(
        BASE + "/articles/",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))


def main():
    try:
        obj = get_articles()
        items = obj["results"]
        print("GET /articles/:", len(items), "total", obj["pagination"]["total"])
        if not items:
            created = create_sample()
            print("POST /articles/:", created["id"], created["title"])
            obj = get_articles()
            print("GET /articles/ (after create):", len(obj["results"]), "total", obj["pagination"]["total"])
        print("OK")
        return 0
    except Exception as e:
        print("ERROR:", e, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
