#!/usr/bin/env python3
import argparse
import subprocess
import sys
import tempfile
from datetime import datetime

import requests


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


def upload_log_file(
    session: requests.Session,
    realm_url: str,
    filename: str,
    content: str,
) -> str:
    """Upload a log file to Zulip and return its URL, or None on failure."""
    try:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".log", delete=True) as f:
            f.write(content)
            f.flush()
            f.seek(0)
            with open(f.name, "rb") as fp:
                response = session.post(
                    f"{realm_url}/api/v1/user_uploads",
                    files={"filename": (filename, fp)},
                    timeout=30,
                )
        response.raise_for_status()
        data = response.json()
        if data.get("result") != "success":
            print(
                f"Error uploading log file: {data.get('msg', 'unknown error')}",
                file=sys.stderr,
            )
            return None
        # prefer "url" (newer servers), fall back to deprecated "uri"
        return data.get("url") or data.get("uri")
    except Exception as e:
        print(f"Error uploading log file: {e}", file=sys.stderr)
        return None


def send_message(
    session: requests.Session,
    realm_url: str,
    channel: str,
    topic: str,
    content: str,
) -> bool:
    """Send a channel message to Zulip."""
    try:
        response = session.post(
            f"{realm_url}/api/v1/messages",
            data={
                "type": "stream",
                "to": channel,
                "topic": topic,
                "content": content,
            },
            timeout=30,
        )
        response.raise_for_status()
        data = response.json()
        if data.get("result") != "success":
            print(
                f"Error sending message: {data.get('msg', 'unknown error')}",
                file=sys.stderr,
            )
            return False
        return True
    except Exception as e:
        print(f"Error sending message: {e}", file=sys.stderr)
        return False


def send_service_notification(
    realm_url: str,
    bot_email: str,
    api_key: str,
    channel: str,
    service_name: str,
    hostname: str,
    success: bool,
) -> bool:
    """Send a service notification to Zulip with logs attached as an upload."""

    session = requests.Session()
    session.auth = (bot_email, api_key)

    # topic is always "hostname/service" so messages thread per host and service
    topic = f"{hostname}/{service_name}"

    # get service start time for accurate timestamp
    timestamp = get_service_start_time(service_name)
    if not timestamp:
        # fallback to current time if we can't get service start time
        timestamp = datetime.now()

    timestamp_message = timestamp.strftime("%b %d %Y %H:%M:%S")
    timestamp_filename = timestamp.strftime("%Y-%m-%d_%H-%M-%S")

    # get logs
    logs = get_service_logs(service_name)

    # build the log file contents
    log_filename = f"{service_name}-{hostname}-{timestamp_filename}.log"
    log_body = (
        f"Logs for {service_name} on {hostname}\n"
        f"Timestamp: {timestamp_message}\n"
        f"Status: {'Succeeded' if success else 'Failed'}\n" + "=" * 50 + "\n\n" + logs
    )

    # upload the log file
    log_url = upload_log_file(session, realm_url, log_filename, log_body)

    # build the message
    if success:
        status_emoji = ":check:"
        status_word = "succeeded"
    else:
        status_emoji = ":cross_mark:"
        status_word = "failed"

    content = (
        f"{status_emoji} **{service_name}** {status_word} on "
        f"**{hostname}** at {timestamp_message}"
    )
    if log_url:
        content += f"\n\n[{log_filename}]({log_url})"
    else:
        content += "\n\n(log upload failed; check journalctl on the host)"

    return send_message(session, realm_url, channel, topic, content)


def main():
    parser = argparse.ArgumentParser(
        description="Send service notifications to Zulip via the bot API",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "--realm-url",
        required=True,
        help="Zulip realm URL (e.g. https://org.zulipchat.com)",
    )
    parser.add_argument("--bot-email", required=True, help="Zulip bot email address")
    parser.add_argument("--api-key", required=True, help="Zulip bot API key")
    parser.add_argument(
        "--channel", required=True, help="Zulip channel (stream) to post to"
    )
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

    # normalize realm URL (strip trailing slash)
    realm_url = args.realm_url.rstrip("/")

    result = send_service_notification(
        realm_url,
        args.bot_email,
        args.api_key,
        args.channel,
        args.service,
        args.hostname,
        not args.failure,
    )

    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
