#!/usr/bin/env python3
"""Fetch recent Linux help posts from Reddit and Stack Overflow APIs.

Usage: python3 fetch_leads.py
Output: raw-results.json with posts from the last 48 hours.
GitHub Repo: https://github.com/Nop4n/linux-automation-scripts
"""
import json
import urllib.request
import urllib.error
from datetime import datetime, timedelta

GITHUB_REPO = "https://github.com/Nop4n/linux-automation-scripts"

def fetch_json(url, headers=None):
    """Fetch JSON from a URL."""
    req = urllib.request.Request(url)
    if headers:
        for k, v in headers.items():
            req.add_header(k, v)
    req.add_header('User-Agent', 'Mozilla/5.0 (LinuxHelpResearch/1.0)')
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read().decode())
    except Exception as e:
        return {"error": str(e)}

def search_reddit(query, limit=10):
    """Search Reddit for recent posts."""
    url = f"https://www.reddit.com/search.json?q={query}&sort=new&t=day&limit={limit}"
    data = fetch_json(url)
    results = []
    if "data" in data and "children" in data["data"]:
        for child in data["data"]["children"]:
            post = child["data"]
            results.append({
                "title": post.get("title", ""),
                "url": f"https://www.reddit.com{post.get('permalink', '')}",
                "subreddit": post.get("subreddit", ""),
                "selftext": (post.get("selftext", "") or "")[:300],
                "created_utc": post.get("created_utc", 0),
                "author": post.get("author", ""),
                "score": post.get("score", 0),
                "num_comments": post.get("num_comments", 0),
            })
    return results

def search_stackoverflow(tagged, limit=10):
    """Search Stack Overflow for recent questions."""
    tags = ";".join(tagged)
    url = f"https://api.stackexchange.com/2.3/questions/no-answers?tagged={tags}&site=stackoverflow&sort=creation&order=desc&pagesize={limit}&filter=withbody"
    data = fetch_json(url)
    results = []
    if "items" in data:
        for item in data["items"]:
            results.append({
                "title": item.get("title", ""),
                "url": item.get("link", ""),
                "tags": item.get("tags", []),
                "created_utc": item.get("creation_date", 0),
                "score": item.get("score", 0),
                "view_count": item.get("view_count", 0),
            })
    return results

if __name__ == "__main__":
    now = datetime.utcnow()
    cutoff = now - timedelta(hours=48)
    
    print("=" * 70)
    print(f"SEARCH TIME: {now.isoformat()}Z")
    print(f"LOOKING FOR POSTS AFTER: {cutoff.isoformat()}Z")
    print("=" * 70)
    
    # Reddit searches
    reddit_queries = [
        ("linux server setup help", "Server Setup"),
        ("linux slow performance server", "Slow Linux"),
        ("docker install error linux", "Docker Problems"),
        ("linux server security hardening", "Server Security"),
        ("linux help new server", "General Linux Help"),
        ("ubuntu server setup", "Ubuntu Server"),
        ("nginx configuration help", "Nginx Help"),
        ("ssh server setup linux", "SSH Setup"),
        ("linux cron automation", "Linux Automation"),
        ("docker compose error", "Docker Compose"),
    ]
    
    all_reddit = []
    for query, category in reddit_queries:
        print(f"\n--- Reddit: {category} (query: {query}) ---")
        posts = search_reddit(query, limit=5)
        if not posts:
            print("  No results or error")
        for p in posts:
            created = datetime.utcfromtimestamp(p["created_utc"])
            age_hours = (now - created).total_seconds() / 3600
            p["age_hours"] = age_hours
            p["category"] = category
            print(f"  [{age_hours:.1f}h ago] r/{p['subreddit']}: {p['title']}")
            print(f"    URL: {p['url']}")
            if p["selftext"]:
                print(f"    Preview: {p['selftext'][:150]}...")
            all_reddit.append(p)
    
    # Stack Overflow searches
    so_queries = [
        (["linux", "bash"], "Linux/Bash"),
        (["linux", "shell"], "Linux Shell"),
        (["docker", "linux"], "Docker/Linux"),
        (["linux", "cron"], "Cron/Automation"),
        (["nginx", "linux"], "Nginx/Linux"),
        (["systemd", "linux"], "Systemd"),
    ]
    
    all_so = []
    for tags, category in so_queries:
        print(f"\n--- Stack Overflow: {category} (tags: {tags}) ---")
        questions = search_stackoverflow(tags, limit=5)
        if not questions:
            print("  No results or error")
        for q in questions:
            created = datetime.utcfromtimestamp(q["created_utc"])
            age_hours = (now - created).total_seconds() / 3600
            q["age_hours"] = age_hours
            q["category"] = category
            print(f"  [{age_hours:.1f}h ago] {q['title']}")
            print(f"    URL: {q['url']}")
            all_so.append(q)
    
    # Save results
    print(f"\n\n{'='*70}")
    print(f"TOTAL REDDIT POSTS FOUND: {len(all_reddit)}")
    print(f"TOTAL SO QUESTIONS FOUND: {len(all_so)}")
    
    # Filter to last 48 hours
    recent_reddit = [p for p in all_reddit if p.get("age_hours", 999) < 48]
    recent_so = [q for q in all_so if q.get("age_hours", 999) < 48]
    print(f"REDDIT POSTS IN LAST 48H: {len(recent_reddit)}")
    print(f"SO QUESTIONS IN LAST 48H: {len(recent_so)}")
    
    # Save JSON for further processing
    with open("/home/hp/products/raw-results.json", "w") as f:
        json.dump({
            "fetched_at": now.isoformat(),
            "reddit": all_reddit,
            "stackoverflow": all_so,
        }, f, indent=2)
    
    print("\nResults saved to /home/hp/products/raw-results.json")
