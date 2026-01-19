#!/usr/bin/env -S uv run
# /// script
# dependencies = ["huggingface-hub"]
# ///
from huggingface_hub import HfApi

api = HfApi()
for m in api.list_models(
    filter=["gguf", "llama.cpp"],
    limit=10000,
):
    print(m.modelId)
