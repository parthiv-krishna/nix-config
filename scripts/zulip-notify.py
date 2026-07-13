#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
from datetime import datetime
from urllib.parse import urlencode

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


def summarize_logs(
    api_url: str,
    api_key: str,
    model: str,
    service_name: str,
    hostname: str,
    logs: str,
) -> str:
    """Summarize service logs via a direct OpenAI-compatible chat completion.

    Returns a short summary string, or None if summarization fails or is
    disabled (no api_url/api_key/model).
    """
    if not (api_url and api_key and model):
        return None

    prompt = (
        f"The systemd service '{service_name}' on host '{hostname}' failed. "
        "Below are its logs. In 1-3 sentences, briefly summarize the most "
        "likely cause of the failure. Be concise and specific; do not include "
        "any preamble, markdown headers, or suggestions unless critical.\n\n"
        "=== LOGS ===\n"
        f"{logs}"
    )

    try:
        response = requests.post(
            f"{api_url.rstrip('/')}/chat/completions",
            headers={"Authorization": f"Bearer {api_key}"},
            json={
                "model": model,
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 2048,
                "temperature": 1,
                "top_p": 0.95,
            },
            timeout=120,
        )
    except Exception as e:
        print(f"Summarizer request error: {e}", file=sys.stderr)
        return None

    if response.status_code != 200:
        print(
            f"Summarizer HTTP {response.status_code}: {response.text[:300]}",
            file=sys.stderr,
        )
        return None

    try:
        message = response.json()["choices"][0]["message"]
    except (ValueError, KeyError, IndexError) as e:
        print(f"Summarizer parse error: {e}", file=sys.stderr)
        return None

    # reasoning models may split output; prefer the final answer content and
    # fall back to reasoning_content if content is empty
    summary = (message.get("content") or message.get("reasoning_content") or "").strip()
    return summary or None


def send_service_notification(
    webhook_url: str,
    channel: str,
    service_name: str,
    hostname: str,
    success: bool,
    summarizer_api_url: str = "",
    summarizer_api_key: str = "",
    summarizer_model: str = "",
) -> bool:
    """Send a status service notification to a Zulip incoming webhook.

    On failure, optionally include an AI-generated summary of the service logs.
    """

    # topic is always "hostname/service" so messages thread per host and service
    topic = f"{hostname}/{service_name}"

    # get service start time for accurate timestamp
    timestamp = get_service_start_time(service_name)
    if not timestamp:
        # fallback to current time if we can't get service start time
        timestamp = datetime.now()

    timestamp_message = timestamp.strftime("%b %d %Y %H:%M:%S")

    # build the message
    if success:
        status_emoji = ":check:"
        status_word = "succeeded"
    else:
        status_emoji = ":cross_mark:"
        status_word = "failed"

    text = (
        f"{status_emoji} **{service_name}** {status_word} on "
        f"**{hostname}** at {timestamp_message}"
    )

    # on failure, try to attach a brief AI summary of the logs
    if not success and summarizer_api_key:
        logs = get_service_logs(service_name)
        if logs.strip():
            summary = summarize_logs(
                summarizer_api_url,
                summarizer_api_key,
                summarizer_model,
                service_name,
                hostname,
                logs,
            )
            if summary:
                text += f"\n\n**Summary:** {summary}"

    # route to the desired channel/topic via URL params on the incoming webhook
    params = {"stream": channel, "topic": topic}
    sep = "&" if "?" in webhook_url else "?"
    url = f"{webhook_url}{sep}{urlencode(params)}"

    try:
        response = requests.post(url, json={"text": text}, timeout=30)
    except Exception as e:
        print(f"Error sending notification: {e}", file=sys.stderr)
        return False

    try:
        data = response.json()
    except ValueError:
        print(
            f"Error sending notification: HTTP {response.status_code}, "
            f"non-JSON response: {response.text[:500]}",
            file=sys.stderr,
        )
        return False

    if data.get("result") != "success":
        code = data.get("code", "")
        msg = data.get("msg", "unknown error")
        suffix = f" (code: {code})" if code else ""
        print(
            f"Error sending notification: HTTP {response.status_code}: {msg}{suffix}",
            file=sys.stderr,
        )
        return False

    return True


def main():
    parser = argparse.ArgumentParser(
        description="Send service status notifications to a Zulip incoming webhook",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "--webhook-url",
        required=True,
        help="Zulip incoming webhook URL (including api_key)",
    )
    parser.add_argument(
        "--channel", required=True, help="Zulip channel (stream) to post to"
    )
    parser.add_argument("--service", required=True, help="Service name for the status")
    parser.add_argument(
        "--hostname", required=True, help="Hostname for service notifications"
    )
    parser.add_argument(
        "--failure", action="store_true", help="Service failed (default: success)"
    )
    parser.add_argument(
        "--summarizer-api-url",
        default="",
        help="OpenAI-compatible base URL for log summarization (e.g. "
        "https://inference-api.nvidia.com/v1).",
    )
    parser.add_argument(
        "--summarizer-model",
        default="",
        help="Model id to use for summarization (e.g. openai/openai/gpt-5.6-luna).",
    )

    args = parser.parse_args()

    # API key comes from the environment (not a CLI arg) to avoid exposing it
    # in the process list. Empty disables summarization.
    summarizer_api_key = os.environ.get("SUMMARIZER_API_KEY", "")

    result = send_service_notification(
        args.webhook_url,
        args.channel,
        args.service,
        args.hostname,
        not args.failure,
        args.summarizer_api_url,
        summarizer_api_key,
        args.summarizer_model,
    )

    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
