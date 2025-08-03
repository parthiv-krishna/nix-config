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


def check_service_status(service_name: str) -> bool:
    """Check if a systemd service is active"""
    try:
        result = subprocess.run(
            ["systemctl", "is-active", service_name], capture_output=True, text=True
        )
        return result.returncode == 0
    except Exception:
        return False


def send_service_notification(
    webhook_url: str,
    service_name: str,
    hostname: str,
) -> bool:
    """Send a service notification with logs attached"""

    try:
        webhook = discord.SyncWebhook.from_url(webhook_url)

        # Check service status
        is_active = check_service_status(service_name)
        timestamp = datetime.now().isoformat()

        # Get logs
        logs = get_service_logs(service_name)

        # Create message and embed
        if is_active:
            message = f"**{service_name}** succeeded on **{hostname}** at {timestamp}"
            title = f"{service_name} Success"
            color = discord.Color(0x00FF00)  # green
        else:
            message = f"**{service_name}** failed on **{hostname}** at {timestamp}"
            title = f"{service_name} Failed"
            color = discord.Color(0xFF0000)  # red

        embed = discord.Embed(description=message, color=color, title=title)

        # Create temporary file with logs
        with tempfile.NamedTemporaryFile(mode="w", suffix=".log", delete=True) as f:
            f.write(f"Logs for {service_name} on {hostname}\n")
            f.write(f"Timestamp: {timestamp}\n")
            f.write(f"Status: {'Active' if is_active else 'Failed'}\n")
            f.write("=" * 50 + "\n\n")
            f.write(logs)
            f.flush()  # Ensure content is written to disk

            webhook.send(
                embed=embed,
                file=discord.File(f.name, filename=f"{service_name}-{hostname}.log"),
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

    args = parser.parse_args()

    success = send_service_notification(
        args.webhook_url,
        args.service,
        args.hostname,
    )

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
