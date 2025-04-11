#!/usr/bin/env python3
from datetime import datetime
import requests

HEADER = f"""# Google520 Hosts Start
# Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
# Project: https://github.com/yhjyhjlqx/Google520

"""
FOOTER = "\n# Google520 Hosts End"

def fetch_domains():
    try:
        with open('domains.txt') as f:
            return [d.strip() for d in f if d.strip() and not d.startswith('#')]
    except:
        return [
            "google.com", 
            "www.google.com",
            "mail.google.com"
        ]

def generate_hosts(target_ip="127.0.0.1"):
    return HEADER + "\n".join(f"{target_ip} {d}" for d in fetch_domains()) + FOOTER

if __name__ == "__main__":
    with open("hosts", "w") as f:
        f.write(generate_hosts())
    print("Google520 hosts file generated")
