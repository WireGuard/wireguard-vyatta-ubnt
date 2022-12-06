#!/usr/bin/env python3

import json
import os
import sys

target_dir = os.path.abspath(sys.argv[1])

directories = []

contents = os.listdir(target_dir)

for item in contents:
    item_full_path = os.path.join(target_dir, item)
    if os.path.isdir(item_full_path):
        directories.append(item)

print(f"directories={json.dumps(directories)}")
