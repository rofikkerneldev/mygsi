import argparse
import hashlib
import os
import sys
import time

import requests


API = "https://api.gofile.io"
LOCALE = "en-US"
USER_AGENT = "Mozilla/5.0"
TOKEN_SECRET = "12af056dacea0b"
TOKEN_WINDOW_SEC = 14400

COMMON_HEADERS = {
    "User-Agent": USER_AGENT,
    "Accept": "*/*",
    "Origin": "https://gofile.io",
    "Referer": "https://gofile.io/",
}


def get_account_token():
    response = requests.post(
        f"{API}/accounts",
        headers=COMMON_HEADERS,
        timeout=15,
    )

    response.raise_for_status()

    data = response.json()

    if data.get("status") != "ok":
        raise RuntimeError(
            f"GoFile account creation failed: {data}"
        )

    return data["data"]["token"]


def generate_website_token(account_token):
    time_window = str(
        int(time.time()) // TOKEN_WINDOW_SEC
    )

    raw = (
        f"{USER_AGENT}::"
        f"{LOCALE}::"
        f"{account_token}::"
        f"{time_window}::"
        f"{TOKEN_SECRET}"
    )

    return hashlib.sha256(
        raw.encode()
    ).hexdigest()


def get_content(content_id, account_token):
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
        f"{API}/contents/{content_id}"
        "?cache=true"
        "&sortField=createTime"
        "&sortDirection=1"
    )

    response = requests.get(
        url,
        headers=headers,
        timeout=20,
    )

    response.raise_for_status()

    data = response.json()

    if data.get("status") != "ok":
        raise RuntimeError(
            f"GoFile content error: {data}"
        )

    return data["data"]


def extract_files(data):
    files = []

    if data["type"] == "file":
        files.append(data)

    elif data["type"] == "folder":
        children = data.get("children", {})

        for child in children.values():
            if child["type"] == "file":
                files.append(child)

    return files


def download_file(url, output_path):
    temp_path = output_path + ".part"

    downloaded = 0

    if os.path.exists(temp_path):
        downloaded = os.path.getsize(temp_path)

    headers = {
        "User-Agent": USER_AGENT,
        "Referer": "https://gofile.io/",
        "Origin": "https://gofile.io",
    }

    if downloaded > 0:
        headers["Range"] = f"bytes={downloaded}-"

        print(
            f"Resuming from "
            f"{downloaded / 1024 / 1024:.2f} MB"
        )

    print(f"Downloading: {os.path.basename(output_path)}")
    print(f"URL: {url}")

    with requests.get(
        url,
        headers=headers,
        stream=True,
        timeout=(20, 60),
    ) as response:

        if downloaded > 0 and response.status_code == 200:
            print(
                "Server ignored Range request."
            )
            print(
                "Restarting download from zero."
            )

            downloaded = 0
            os.remove(temp_path)

        response.raise_for_status()

        total = response.headers.get("Content-Length")

        if total:
            total = int(total) + downloaded

        mode = "ab" if downloaded > 0 else "wb"

        with open(temp_path, mode) as f:

            last_percent = -1

            for chunk in response.iter_content(
                chunk_size=1024 * 1024
            ):
                if not chunk:
                    continue

                f.write(chunk)
                downloaded += len(chunk)

                if total:
                    percent = int(
                        downloaded * 100 / total
                    )

                    if percent != last_percent:
                        last_percent = percent

                        print(
                            f"\rProgress: "
                            f"{percent:3d}% "
                            f"("
                            f"{downloaded / 1024 / 1024:.1f}/"
                            f"{total / 1024 / 1024:.1f} MB)",
                            end="",
                            flush=True,
                        )

    print()

    os.replace(
        temp_path,
        output_path
    )

    print(
        f"Download complete: {output_path}"
    )


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "url",
        help="GoFile URL"
    )

    parser.add_argument(
        "-o",
        "--output",
        default="firmware.zip",
        help="Output filename"
    )

    args = parser.parse_args()

    parts = args.url.rstrip("/").split("/")

    if len(parts) < 2 or parts[-2] != "d":
        print(
            "ERROR: Invalid GoFile URL"
        )
        sys.exit(1)

    content_id = parts[-1]

    print("======================================")
    print("GoFile Downloader")
    print("======================================")
    print(f"Content ID: {content_id}")

    print()
    print("Creating guest account...")

    token = get_account_token()

    print("Guest account: OK")

    print()
    print("Getting content...")

    data = get_content(
        content_id,
        token
    )

    print(
        f"Content type: {data['type']}"
    )

    files = extract_files(data)

    if not files:
        raise RuntimeError(
            "No downloadable files found"
        )

    print(
        f"Files found: {len(files)}"
    )

    for file in files:
        print(
            f"- {file['name']} "
            f"({file['size'] / 1024 / 1024:.2f} MB)"
        )

    if len(files) > 1:
        raise RuntimeError(
            "GoFile contains multiple files. "
            "Automatic firmware selection is not "
            "implemented yet."
        )

    file = files[0]

    download_url = file["link"]

    print()
    print(
        f"Selected: {file['name']}"
    )

    download_file(
        download_url,
        args.output
    )

    print()
    print("======================================")
    print("SUCCESS")
    print("======================================")

    size = os.path.getsize(args.output)

    print(
        f"File: {args.output}"
    )

    print(
        f"Size: {size / 1024 / 1024:.2f} MB"
    )


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nCancelled.")
        sys.exit(1)
    except Exception as e:
        print()
        print(f"ERROR: {e}")
        sys.exit(1)
