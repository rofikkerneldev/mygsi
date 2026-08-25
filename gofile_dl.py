#!/usr/bin/env python3
#Copyright 2026 RofikKernelDev
import argparse
import hashlib
import os
import sys
import time
from pathlib import Path
from urllib.parse import urlparse

import requests


GOFILE_API = "https://api.gofile.io"

USER_AGENT = "Mozilla/5.0"
LOCALE = "en-US"

# Used by GoFile website-token generation.
TOKEN_SECRET = "12af056dacea0b"
TOKEN_WINDOW_SEC = 14400

COMMON_HEADERS = {
    "User-Agent": USER_AGENT,
    "Accept": "*/*",
    "Origin": "https://gofile.io",
    "Referer": "https://gofile.io/",
}


def create_guest_account():
    print("Creating GoFile guest account...")

    response = requests.post(
        f"{GOFILE_API}/accounts",
        headers=COMMON_HEADERS,
        timeout=20,
    )

    response.raise_for_status()

    data = response.json()

    if data.get("status") != "ok":
        raise RuntimeError(
            f"GoFile account creation failed: {data}"
        )

    token = data["data"].get("token")

    if not token:
        raise RuntimeError(
            "GoFile did not return an account token."
        )

    print("Guest account: OK")

    return token


def generate_website_token(account_token):
    time_window = str(
        int(time.time()) // TOKEN_WINDOW_SEC
    )

    seed = (
        f"{USER_AGENT}::"
        f"{LOCALE}::"
        f"{account_token}::"
        f"{time_window}::"
        f"{TOKEN_SECRET}"
    )

    return hashlib.sha256(
        seed.encode("utf-8")
    ).hexdigest()


def get_content(content_id, account_token):
    print("Getting GoFile content...")

    website_token = generate_website_token(
        account_token
    )

    headers = {
        **COMMON_HEADERS,
        "Authorization": f"Bearer {account_token}",
        "X-Website-Token": website_token,
        "X-BL": LOCALE,
    }

    url = (
        f"{GOFILE_API}/contents/{content_id}"
        "?page=1"
        "&pageSize=100"
        "&sortField=name"
        "&sortDirection=1"
    )

    response = requests.get(
        url,
        headers=headers,
        timeout=30,
    )

    response.raise_for_status()

    result = response.json()

    if result.get("status") != "ok":
        raise RuntimeError(
            f"GoFile content request failed: {result}"
        )

    return result["data"]


def get_files(data):
    files = []

    if data.get("type") == "file":
        files.append(data)
        return files

    if data.get("type") != "folder":
        return files

    children = data.get("children", {})

    for child in children.values():
        if child.get("type") == "file":
            files.append(child)

    return files


def format_size(size):
    size = float(size)

    units = [
        "B",
        "KB",
        "MB",
        "GB",
        "TB",
    ]

    for unit in units:
        if size < 1024:
            return f"{size:.2f} {unit}"

        size /= 1024

    return f"{size:.2f} PB"


def download_file(
    download_url,
    output_path,
    account_token,
    expected_size,
):
    output_path = Path(output_path)
    part_path = Path(str(output_path) + ".part")

    output_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    existing_size = 0

    if part_path.exists():
        existing_size = part_path.stat().st_size

    print()
    print("======================================")
    print("Download")
    print("======================================")

    print(f"Output       : {output_path}")
    print(f"Expected     : {format_size(expected_size)}")
    print(f"Already have : {format_size(existing_size)}")

    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "*/*",
        "Referer": "https://gofile.io/",
        "Origin": "https://gofile.io",
        "Cookie": f"accountToken={account_token}",
    }

    # If an existing partial file is larger than the expected file,
    # it cannot be valid.
    if existing_size > expected_size:
        print(
            "Existing .part file is larger than expected."
        )
        print("Deleting corrupted partial file.")

        part_path.unlink()

        existing_size = 0

    # Already completely downloaded.
    if existing_size == expected_size:
        print()
        print(
            "Partial file already has the expected size."
        )

        os.replace(
            part_path,
            output_path,
        )

        return

    if existing_size > 0:
        headers["Range"] = (
            f"bytes={existing_size}-"
        )

        print(
            f"Resuming from {format_size(existing_size)}..."
        )

    else:
        print("Starting new download...")

    with requests.get(
        download_url,
        headers=headers,
        stream=True,
        timeout=(30, 120),
    ) as response:

        print(
            f"HTTP status : {response.status_code}"
        )

        content_type = (
            response.headers.get(
                "Content-Type",
                ""
            )
        )

        print(
            f"Content-Type: {content_type}"
        )

        # Resume must return 206.
        if existing_size > 0:
            if response.status_code != 206:
                raise RuntimeError(
                    "Server did not accept the Range "
                    f"request. HTTP {response.status_code}"
                )

        else:
            if response.status_code != 200:
                raise RuntimeError(
                    f"Download failed. "
                    f"HTTP {response.status_code}"
                )

        if (
            "application/zip" not in content_type
            and "application/octet-stream" not in content_type
        ):
            raise RuntimeError(
                "GoFile returned an unexpected "
                f"Content-Type: {content_type}"
            )

        content_range = response.headers.get(
            "Content-Range"
        )

        if content_range:
            print(
                f"Content-Range: {content_range}"
            )

        # IMPORTANT:
        # If the server ignores our Range request and
        # returns 200, we do NOT append to the existing
        # partial file.
        if existing_size > 0:
            mode = "ab"
            downloaded = existing_size
        else:
            mode = "wb"
            downloaded = 0

        with open(part_path, mode) as file:

            last_percent = -1
            last_report = 0

            for chunk in response.iter_content(
                chunk_size=1024 * 1024
            ):
                if not chunk:
                    continue

                file.write(chunk)

                downloaded += len(chunk)

                percent = int(
                    downloaded * 100 / expected_size
                )

                now = time.time()

                if (
                    percent != last_percent
                    or now - last_report >= 2
                ):
                    last_percent = percent
                    last_report = now

                    print(
                        "\r"
                        f"Progress: {percent:3d}% "
                        f"("
                        f"{format_size(downloaded)} / "
                        f"{format_size(expected_size)}"
                        f")",
                        end="",
                        flush=True,
                    )

    print()

    actual_size = part_path.stat().st_size

    print(
        f"Downloaded size: {actual_size} bytes"
    )

    if actual_size != expected_size:
        raise RuntimeError(
            "Download size mismatch!\n"
            f"Expected: {expected_size}\n"
            f"Received: {actual_size}"
        )

    os.replace(
        part_path,
        output_path,
    )

    print("Download completed.")


def calculate_md5(path):
    md5 = hashlib.md5()

    with open(path, "rb") as file:
        while True:
            chunk = file.read(
                8 * 1024 * 1024
            )

            if not chunk:
                break

            md5.update(chunk)

    return md5.hexdigest()


def verify_file(path, expected_md5):
    if not expected_md5:
        print(
            "No MD5 supplied by GoFile. "
            "Skipping MD5 verification."
        )
        return

    print()
    print("======================================")
    print("MD5 Verification")
    print("======================================")

    print("Calculating MD5...")

    actual_md5 = calculate_md5(path)

    print(f"Expected MD5: {expected_md5}")
    print(f"Actual MD5  : {actual_md5}")

    if actual_md5.lower() != expected_md5.lower():
        raise RuntimeError(
            "MD5 verification FAILED!"
        )

    print("MD5: OK")


def parse_gofile_url(url):
    parsed = urlparse(url)

    if parsed.netloc not in (
        "gofile.io",
        "www.gofile.io",
    ):
        raise ValueError(
            "URL is not a GoFile URL."
        )

    parts = [
        part
        for part in parsed.path.split("/")
        if part
    ]

    if len(parts) != 2 or parts[0] != "d":
        raise ValueError(
            "Expected URL format:\n"
            "https://gofile.io/d/XXXXXXXX"
        )

    return parts[1]


def main():
    parser = argparse.ArgumentParser(
        description="Standalone GoFile downloader"
    )

    parser.add_argument(
        "url",
        help="GoFile public URL",
    )

    parser.add_argument(
        "-o",
        "--output",
        default="firmware.zip",
        help="Output filename",
    )

    args = parser.parse_args()

    print("======================================")
    print("GoFile Downloader")
    print("======================================")

    content_id = parse_gofile_url(
        args.url
    )

    print(
        f"Content ID: {content_id}"
    )

    # --------------------------------------------------
    # 1. Guest account
    # --------------------------------------------------

    account_token = create_guest_account()

    # --------------------------------------------------
    # 2. Content metadata
    # --------------------------------------------------

    data = get_content(
        content_id,
        account_token,
    )

    print(
        f"Content type: {data.get('type')}"
    )

    files = get_files(data)

    if not files:
        raise RuntimeError(
            "No downloadable files found."
        )

    print(
        f"Files found: {len(files)}"
    )

    for index, file in enumerate(files, 1):
        print(
            f"[{index}] "
            f"{file.get('name')} "
            f"({format_size(file.get('size', 0))})"
        )

    # --------------------------------------------------
    # 3. Select file
    # --------------------------------------------------

    if len(files) > 1:
        raise RuntimeError(
            "This GoFile contains multiple files. "
            "Automatic selection is not implemented."
        )

    file = files[0]

    filename = file["name"]
    download_url = file["link"]
    expected_size = int(file["size"])
    expected_md5 = file.get("md5")

    # Save original filename for GitHub Actions
with open("gofile_filename.txt", "w", encoding="utf-8") as f:
    f.write(filename)
    
    print()
    print(f"Selected file: {filename}")
    print(f"Size         : {format_size(expected_size)}")

    # --------------------------------------------------
    # 4. Download
    # --------------------------------------------------

    download_file(
        download_url=download_url,
        output_path=args.output,
        account_token=account_token,
        expected_size=expected_size,
    )

    # --------------------------------------------------
    # 5. Verify
    # --------------------------------------------------

    verify_file(
        Path(args.output),
        expected_md5,
    )

    # --------------------------------------------------
    # 6. Final result
    # --------------------------------------------------

    final_size = Path(args.output).stat().st_size

    print()
    print("======================================")
    print("SUCCESS")
    print("======================================")

    print(
        f"File: {args.output}"
    )

    print(
        f"Size: {format_size(final_size)}"
    )


if __name__ == "__main__":
    try:
        main()

    except KeyboardInterrupt:
        print()
        print("Cancelled.")
        sys.exit(130)

    except Exception as error:
        print()
        print("======================================")
        print("ERROR")
        print("======================================")
        print(error)
        sys.exit(1)
