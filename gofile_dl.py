def download_file(url, output_path, account_token, expected_size):
    temp_path = output_path + ".part"

    downloaded = 0

    if os.path.exists(temp_path):
        downloaded = os.path.getsize(temp_path)

    headers = {
        "User-Agent": "Mozilla/5.0",
        "Accept": "*/*",
        "Referer": "https://gofile.io/",
        "Origin": "https://gofile.io",
        "Cookie": f"accountToken={account_token}",
    }

    if downloaded > 0:
        headers["Range"] = f"bytes={downloaded}-"
        print(f"Resuming from {downloaded / 1024 / 1024:.2f} MB")

    print(f"Downloading: {os.path.basename(output_path)}")
    print(f"Expected size: {expected_size / 1024 / 1024:.2f} MB")

    with requests.get(
        url,
        headers=headers,
        stream=True,
        timeout=(20, 60),
    ) as response:

        if downloaded > 0:
            if response.status_code != 206:
                raise RuntimeError(
                    f"Resume failed: HTTP {response.status_code}"
                )
        else:
            if response.status_code != 200:
                raise RuntimeError(
                    f"Download failed: HTTP {response.status_code}"
                )

        content_type = response.headers.get(
            "Content-Type", ""
        )

        if "application/zip" not in content_type:
            raise RuntimeError(
                f"Unexpected Content-Type: {content_type}"
            )

        mode = "ab" if downloaded > 0 else "wb"

        with open(temp_path, mode) as f:
            for chunk in response.iter_content(
                chunk_size=1024 * 1024
            ):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)

                    percent = (
                        downloaded * 100 / expected_size
                    )

                    print(
                        f"\rProgress: "
                        f"{percent:6.2f}% "
                        f"({downloaded / 1024 / 1024:.2f} / "
                        f"{expected_size / 1024 / 1024:.2f} MB)",
                        end="",
                        flush=True,
                    )

    print()

    if downloaded != expected_size:
        raise RuntimeError(
            f"Size mismatch! "
            f"Expected {expected_size}, "
            f"got {downloaded}"
        )

    os.replace(temp_path, output_path)

    print("Download verified successfully.")
