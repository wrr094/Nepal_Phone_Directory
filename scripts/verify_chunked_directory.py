#!/usr/bin/env python3
"""Verify chunk integrity, deterministic assignment, and dataset completeness."""

import argparse
import gzip
import hashlib
import json
from pathlib import Path

from publish_chunked_directory import MAX_STATIC_FILE_BYTES, bucket_for, canonical_json


def parse_args():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "directory",
        nargs="?",
        type=Path,
        default=root / "outputs" / "chunked_directory" / "v1",
    )
    return parser.parse_args()


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main():
    directory = parse_args().directory
    manifest = json.loads((directory / "manifest.json").read_text(encoding="utf-8"))
    chunk_count = manifest["chunkCount"]
    all_ids = set()
    total_records = 0
    max_chunk_bytes = 0

    for descriptor in manifest["chunks"]:
        path = directory / "chunks" / Path(descriptor["url"]).name
        compressed = path.read_bytes()
        max_chunk_bytes = max(max_chunk_bytes, len(compressed))
        assert len(compressed) < MAX_STATIC_FILE_BYTES, f"oversized chunk: {path}"
        assert digest(compressed) == descriptor["sha256"], f"hash mismatch: {path}"
        raw = gzip.decompress(compressed)
        assert digest(raw) == descriptor["dataSha256"], f"data hash mismatch: {path}"
        payload = json.loads(raw)
        assert payload["bucket"] == descriptor["bucket"]
        assert payload["recordCount"] == descriptor["recordCount"]
        assert len(payload["records"]) == descriptor["recordCount"]
        for record in payload["records"]:
            entry_id = record[manifest["entryIdField"]]
            assert entry_id not in all_ids, f"duplicate Entry_ID: {entry_id}"
            assert bucket_for(entry_id, chunk_count) == descriptor["bucket"]
            assert list(record.keys()) == manifest["columns"], f"schema drift: {entry_id}"
            all_ids.add(entry_id)
        total_records += len(payload["records"])

    assert len(manifest["chunks"]) == chunk_count
    assert total_records == manifest["recordCount"]
    version_material = canonical_json(
        {
            "formatVersion": manifest["formatVersion"],
            "chunkCount": chunk_count,
            "chunks": [item["sha256"] for item in manifest["chunks"]],
        }
    )
    assert digest(version_material) == manifest["datasetVersion"]
    print(
        json.dumps(
            {
                "verified": True,
                "recordCount": total_records,
                "chunkCount": chunk_count,
                "maxCompressedChunkBytes": max_chunk_bytes,
                "datasetVersion": manifest["datasetVersion"],
            }
        )
    )


if __name__ == "__main__":
    main()
