#!/usr/bin/env python3
import argparse
import subprocess
import sys
import tempfile
import os
from datetime import datetime

import discord


def get_service_logs(service_name: str) -> str:
    """Get all logs for a systemd service"""
    try:
        result = subprocess.run(
            ["journalctl", "--unit", service_name, "--no-pager"],
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
    webhook_url: str,
    service_name: str,
    hostname: str,
    success: bool
) -> bool:
    """Send a service notification with logs attached"""

    try:
        webhook = discord.SyncWebhook.from_url(webhook_url)

        timestamp_message = datetime.now().strftime("%b %d %Y %H:%M:%S")
        timestamp_filename = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

        # get logs
        logs = get_service_logs(service_name)

        # create message and embed
        if success:
            message = f"**{service_name}** succeeded on **{hostname}** at {timestamp_message}"
            title = f"{service_name} Success"
            color = discord.Color(0x00FF00)  # green
        else:
            message = f"**{service_name}** failed on **{hostname}** at {timestamp_message}"
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
    parser.add_argument("--failure", action="store_true", help="Service failed (default: success)")

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
