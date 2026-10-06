#!/usr/bin/env python3
"""Discover local tools; optionally inspect public DNS. No account mutations."""

import argparse
import datetime
import json
import re
import shutil
import subprocess


HOSTNAME = "n8nautomation.learnwithsk.dev"


def lookup(dig, resolver, name, record_type):
    argv = [dig, "+time=2", "+tries=1", "+noall", "+comments", "+answer", "+authority"]
    if resolver != "system":
        argv.append("@" + resolver)
    argv.extend([name, record_type])
    result = {"resolver": resolver, "name": name, "type": record_type}
    try:
        proc = subprocess.run(argv, capture_output=True, text=True, timeout=5, check=False)
        match = re.search(r"status: ([A-Z]+)", proc.stdout)
        result.update({
            "exit_code": proc.returncode,
            "dns_status": match.group(1) if match else None,
            "answer_or_authority": [
                line for line in proc.stdout.splitlines() if line and not line.startswith(";")
            ],
        })
        if proc.returncode != 0 or not match:
            result["error"] = (proc.stderr or proc.stdout).strip()[:600]
    except (OSError, subprocess.TimeoutExpired) as exc:
        result.update({"dns_status": None, "error": str(exc)[:600]})
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dns", action="store_true", help="Query public DNS; no provider credentials used")
    args = parser.parse_args()
    result = {
        "checked_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "checked_at_ist": datetime.datetime.now(
            datetime.timezone(datetime.timedelta(hours=5, minutes=30))
        ).isoformat(),
        "tools": {name: shutil.which(name) for name in (
            "terraform", "ansible", "docker", "oci", "cloudflared", "python3", "dig"
        )},
        "provider_account_inspection": "Not performed by this script",
        "dns_checks": [],
    }
    if args.dns:
        dig = result["tools"]["dig"]
        if dig:
            result["dns_checks"] = [
                lookup(dig, resolver, HOSTNAME, kind)
                for resolver in ("system", "1.1.1.1", "8.8.8.8")
                for kind in ("A", "AAAA", "CNAME")
            ]
            result["dns_checks"].append(lookup(dig, "1.1.1.1", "learnwithsk.dev", "NS"))
        else:
            result["dns_error"] = "dig is unavailable; no DNS observation made"
    print(json.dumps(result, indent=2))
    return 1 if args.dns and (
        result.get("dns_error") or any(item.get("error") for item in result["dns_checks"])
    ) else 0


if __name__ == "__main__":
    raise SystemExit(main())
