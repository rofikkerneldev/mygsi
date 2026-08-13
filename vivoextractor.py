#!/usr/bin/env python3

import os
import sys
import zstandard


class ZstdImageExtract:
    def __init__(self, f, o):
        self.decoder = zstandard.ZstdDecompressor()
        self.file = f
        self.output = o
        self.BUFSIZE = 8192
        self.ALIGN = 0x2000000

    def extract(self):
        file_size = os.path.getsize(self.file)

        if file_size < self.ALIGN:
            cnt = 1
        else:
            cnt = (file_size + self.ALIGN - 1) // self.ALIGN

        with open(self.file, 'rb') as f, open(self.output, 'wb') as f2:
            for i in range(cnt):
                offset = i * self.ALIGN

                if offset >= file_size:
                    break

                f.seek(offset)

                dec = self.decoder.decompressobj()

                while not dec.eof:
                    data = f.read(self.BUFSIZE)

                    if not data:
                        break

                    f2.write(dec.decompress(data))

                f2.write(dec.flush())


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <input_folder>")
        sys.exit(1)

    input_dir = sys.argv[1]

    if not os.path.isdir(input_dir):
        print(f"Error: folder not found: {input_dir}")
        sys.exit(1)

    output_dir = os.path.join(input_dir, "out")
    os.makedirs(output_dir, exist_ok=True)

    img_files = sorted(
        f for f in os.listdir(input_dir)
        if f.lower().endswith(".img")
        and os.path.isfile(os.path.join(input_dir, f))
    )

    if not img_files:
        print("No .img files found.")
        return

    print(f"Found {len(img_files)} image(s)")
    print(f"Output folder: {output_dir}")
    print()

    for filename in img_files:
        input_file = os.path.join(input_dir, filename)
        output_file = os.path.join(output_dir, filename)

        print(f"[+] {filename}")

        try:
            ZstdImageExtract(input_file, output_file).extract()

            size = os.path.getsize(output_file)

            print(
                f"    OK -> out/{filename} "
                f"({size:,} bytes)"
            )

        except Exception as e:
            print(f"    FAILED: {e}")

            if os.path.exists(output_file):
                os.remove(output_file)

    print()
    print("Done.")


if __name__ == '__main__':
    main()
