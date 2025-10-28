#!/usr/bin/env python3
import argparse
import subprocess
import sys
import tempfile
import os
from datetime import datetime

import discord


def get_service_start_time(service_name: str) -> datetime:
    """Get the start time of the most recent service run as a datetime object"""
    try:
        result = subprocess.run(
            ["systemctl", "show", service_name, "--property=ActiveEnterTimestamp"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0:
            # output format: "ActiveEnterTimestamp=Mon 2024-01-01 12:00:00 UTC"
            timestamp_line = result.stdout.strip()
            if "=" in timestamp_line:
                timestamp_str = timestamp_line.split("=", 1)[1].strip()
                if timestamp_str and timestamp_str not in ["n/a", ""]:
                    # parse the timestamp string into a datetime object
                    return datetime.strptime(timestamp_str, "%a %Y-%m-%d %H:%M:%S %Z")
        return None
    except Exception:
        return None


def get_service_invocation_id(service_name: str) -> str:
    """Get the InvocationID of the most recent service run"""
    try:
        result = subprocess.run(
            ["systemctl", "show", "--value", "-p", "InvocationID", service_name],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0:
            invocation_id = result.stdout.strip()
            if invocation_id and invocation_id != "":
                return invocation_id
        return None
    except Exception:
        return None


def get_service_logs(service_name: str) -> str:
    """Get logs for the most recent run of a systemd service using InvocationID"""
    try:
        # get the invocation ID for the current/latest service run
        invocation_id = get_service_invocation_id(service_name)

        if invocation_id:
            # get logs for this specific invocation only
            result = subprocess.run(
                ["journalctl", f"_SYSTEMD_INVOCATION_ID={invocation_id}", "--no-pager"],
                capture_output=True,
                text=True,
                timeout=30,
            )
        else:
            # fallback: get recent logs with the last hour
            result = subprocess.run(
                [
                    "journalctl",
                    "--unit",
                    service_name,
                    "--since",
                    "1 hour ago",
                    "--no-pager",
                ],
                capture_output=True,
                text=True,
                timeout=30,
            )

        return result.stdout
    except subprocess.TimeoutExpired:
        return "Error: Timeout while fetching logs"
    except Exception as e:
        return f"Error fetching logs: {e}"


def send_service_notification(
    webhook_url: str, service_name: str, hostname: str, success: bool
) -> bool:
    """Send a service notification with logs attached"""

    try:
        webhook = discord.SyncWebhook.from_url(webhook_url)

        # get service start time for accurate timestamp
        timestamp = get_service_start_time(service_name)
        if not timestamp:
            # fallback to current time if we can't get service start time
            timestamp = datetime.now()

        timestamp_message = timestamp.strftime("%b %d %Y %H:%M:%S")
        timestamp_filename = timestamp.strftime("%Y-%m-%d_%H-%M-%S")

        # get logs
        logs = get_service_logs(service_name)

        # create message and embed
        if success:
            message = (
                f"**{service_name}** succeeded on **{hostname}** at {timestamp_message}"
            )
            title = f"{service_name} Success"
            color = discord.Color(0x00FF00)  # green
        else:
            message = (
                f"**{service_name}** failed on **{hostname}** at {timestamp_message}"
            )
            title = f"{service_name} Failed"
            color = discord.Color(0xFF0000)  # red

        embed = discord.Embed(description=message, color=color, title=title)

        # create temporary file with logs
        log_filename = f"{service_name}-{hostname}-{timestamp_filename}.log"
        with tempfile.NamedTemporaryFile(mode="w", suffix=".log", delete=True) as f:
            f.write(f"Logs for {service_name} on {hostname}\n")
            f.write(f"Timestamp: {timestamp_message}\n")
            f.write(f"Status: {'Succeeded' if success else 'Failed'}\n")
            f.write("=" * 50 + "\n\n")
            f.write(logs)
            f.flush()  # ensure content is written to disk

            webhook.send(
                embed=embed,
                file=discord.File(f.name, filename=log_filename),
            )

        return True

    except discord.NotFound:
        print("Error: Webhook not found. Check the webhook URL.", file=sys.stderr)
        return False
    except discord.HTTPException as e:
        print(f"Error sending webhook: {e}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Send service notifications to Discord via webhook",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument("webhook_url", help="Discord webhook URL")
    parser.add_argument(
        "--service", required=True, help="Service name for notification with logs"
    )
    parser.add_argument(
        "--hostname", required=True, help="Hostname for service notifications"
    )
    parser.add_argument(
        "--failure", action="store_true", help="Service failed (default: success)"
    )

    args = parser.parse_args()

    result = send_service_notification(
        args.webhook_url,
        args.service,
        args.hostname,
        not args.failure,
    )

    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
