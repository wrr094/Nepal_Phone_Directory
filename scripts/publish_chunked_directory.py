#!/usr/bin/env python3
"""Publish the contact CSV as deterministic, versioned gzip JSON chunks."""

import argparse
import csv
import gzip
import hashlib
import json
import os
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path


FORMAT_VERSION = 1
DEFAULT_CHUNK_COUNT = 32
MAX_STATIC_FILE_BYTES = 25 * 1024 * 1024


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def bucket_for(entry_id: str, chunk_count: int) -> int:
    digest = hashlib.sha256(entry_id.encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big") % chunk_count


def canonical_json(value) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=False,
    ).encode("utf-8")


def write_if_changed(path: Path, data: bytes) -> bool:
    if path.exists() and path.read_bytes() == data:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_bytes(data)
    os.replace(temporary, path)
    return True


def parse_args():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        type=Path,
        default=root / "outputs" / "nepal_public_phone_directory.csv",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=root / "outputs" / "chunked_directory" / "v1",
    )
    parser.add_argument("--chunk-count", type=int, default=DEFAULT_CHUNK_COUNT)
    parser.add_argument(
        "--base-url",
        default="",
        help="Optional public URL prefix. Relative URLs are emitted when omitted.",
    )
    parser.add_argument(
        "--prune",
        action="store_true",
        help="Remove unreferenced generated chunk files after a successful publish.",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    if args.chunk_count < 1:
        raise SystemExit("--chunk-count must be positive")

    with args.input.open(encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        columns = reader.fieldnames or []
        records = list(reader)

    if "Entry_ID" not in columns:
        raise SystemExit("Input CSV must contain Entry_ID")
    if any(not record["Entry_ID"].strip() for record in records):
        raise SystemExit("Every record must contain Entry_ID")
    ids = [record["Entry_ID"] for record in records]
    if len(ids) != len(set(ids)):
        raise SystemExit("Input CSV contains duplicate Entry_ID values")

    buckets = defaultdict(list)
    for record in records:
        buckets[bucket_for(record["Entry_ID"], args.chunk_count)].append(record)

    chunks_dir = args.output / "chunks"
    chunk_descriptors = []
    changed_chunks = 0
    referenced_filenames = set()
    for bucket in range(args.chunk_count):
        bucket_records = sorted(buckets[bucket], key=lambda item: item["Entry_ID"])
        payload = {
            "formatVersion": FORMAT_VERSION,
            "bucket": bucket,
            "recordCount": len(bucket_records),
            "records": bucket_records,
        }
        raw = canonical_json(payload)
        compressed = gzip.compress(raw, compresslevel=9, mtime=0)
        if len(compressed) >= MAX_STATIC_FILE_BYTES:
            raise SystemExit(
                f"Chunk {bucket} is {len(compressed)} bytes and exceeds the 25 MiB limit"
            )
        compressed_hash = sha256(compressed)
        filename = f"contacts-{bucket:02d}-{compressed_hash[:16]}.json.gz"
        referenced_filenames.add(filename)
        changed_chunks += write_if_changed(chunks_dir / filename, compressed)
        relative_url = f"chunks/{filename}"
        url = f"{args.base_url.rstrip('/')}/{relative_url}" if args.base_url else relative_url
        chunk_descriptors.append(
            {
                "bucket": bucket,
                "url": url,
                "recordCount": len(bucket_records),
                "compressedBytes": len(compressed),
                "uncompressedBytes": len(raw),
                "sha256": compressed_hash,
                "dataSha256": sha256(raw),
                "contentEncoding": "gzip",
                "mediaType": "application/json",
            }
        )

    version_material = canonical_json(
        {
            "formatVersion": FORMAT_VERSION,
            "chunkCount": args.chunk_count,
            "chunks": [item["sha256"] for item in chunk_descriptors],
        }
    )
    dataset_version = sha256(version_material)
    generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    manifest_path = args.output / "manifest.json"
    if manifest_path.exists():
        try:
            previous_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            unchanged_release = (
                previous_manifest.get("datasetVersion") == dataset_version
                and previous_manifest.get("columns") == columns
                and previous_manifest.get("chunks") == chunk_descriptors
            )
            if unchanged_release:
                generated_at = previous_manifest["generatedAt"]
        except (json.JSONDecodeError, KeyError):
            pass
    manifest = {
        "formatVersion": FORMAT_VERSION,
        "datasetVersion": dataset_version,
        "generatedAt": generated_at,
        "recordCount": len(records),
        "chunkCount": args.chunk_count,
        "bucketAlgorithm": "sha256-entry-id-u64-mod",
        "entryIdField": "Entry_ID",
        "columns": columns,
        "chunks": chunk_descriptors,
    }
    manifest_bytes = json.dumps(
        manifest, ensure_ascii=False, indent=2
    ).encode("utf-8") + b"\n"
    manifest_changed = write_if_changed(manifest_path, manifest_bytes)
    pruned_chunks = 0
    if args.prune and chunks_dir.exists():
        for path in chunks_dir.glob("contacts-*.json.gz"):
            if path.name not in referenced_filenames:
                path.unlink()
                pruned_chunks += 1
    print(
        json.dumps(
            {
                "recordCount": len(records),
                "chunkCount": args.chunk_count,
                "changedChunks": changed_chunks,
                "manifestChanged": manifest_changed,
                "prunedChunks": pruned_chunks,
                "datasetVersion": dataset_version,
                "output": str(args.output),
            }
        )
    )


if __name__ == "__main__":
    main()
