import os
import re
import sys
from urllib.parse import urlparse

from telethon import TelegramClient


API_ID = int(os.environ["TG_API_ID"])
API_HASH = os.environ["TG_API_HASH"]
TELEGRAM_LINK = os.environ["TELEGRAM_LINK"]

OUTPUT_DIR = "Output"


def parse_telegram_link(link):
    parsed = urlparse(link)

    if parsed.scheme not in ("http", "https"):
        raise ValueError("Telegram link harus menggunakan http/https")

    if parsed.netloc not in ("t.me", "www.t.me", "telegram.me"):
        raise ValueError("Hanya link Telegram public yang didukung")

    parts = parsed.path.strip("/").split("/")

    if len(parts) != 2:
        raise ValueError(
            "Format link harus seperti https://t.me/channel/12345"
        )

    username = parts[0]
    message_id = int(parts[1])

    if username.startswith("+") or username.startswith("joinchat"):
        raise ValueError("Private/invite link tidak didukung")

    return username, message_id


async def main():
    username, message_id = parse_telegram_link(TELEGRAM_LINK)

    print(f"Channel : @{username}")
    print(f"Message : {message_id}")

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    client = TelegramClient(
        "github_actions_session",
        API_ID,
        API_HASH
    )

    await client.start()

    try:
        print("Getting Telegram message...")

        message = await client.get_messages(
            username,
            ids=message_id
        )

        if not message:
            raise RuntimeError("Message tidak ditemukan")

        if not message.file:
            raise RuntimeError(
                "Message tersebut tidak berisi file/document"
            )

        filename = message.file.name

        if not filename:
            filename = f"telegram_{message_id}"

        output_path = os.path.join(OUTPUT_DIR, filename)

        size = message.file.size

        print(f"Filename: {filename}")

        if size:
            print(f"Size    : {size / 1024 / 1024:.2f} MB")

        print()
        print("Starting download...")

        last_percent = -1

        def progress(current, total):
            nonlocal last_percent

            if not total:
                return

            percent = int(current * 100 / total)

            if percent != last_percent:
                last_percent = percent

                downloaded = current / 1024 / 1024
                total_mb = total / 1024 / 1024

                print(
                    f"\rDownloading: "
                    f"{percent:3d}% "
                    f"({downloaded:.1f}/{total_mb:.1f} MB)",
                    end="",
                    flush=True
                )

        await client.download_media(
            message,
            file=output_path,
            progress_callback=progress
        )

        print()
        print()
        print(f"DOWNLOAD_COMPLETE={output_path}")

    finally:
        await client.disconnect()


if __name__ == "__main__":
    import asyncio

    try:
        asyncio.run(main())
    except Exception as e:
        print()
        print(f"ERROR: {e}")
        sys.exit(1)
