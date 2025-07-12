#!/usr/bin/env python3

import yaml
import os
import subprocess
import shutil
import sys

with open("tests/tests.yaml", "r") as f:
    tests = yaml.safe_load(f)

print(tests)

for testname in tests["tests"]:
    ltest = tests["tests"][testname]
    print(ltest)
    directory = ltest["directory"]
    tpath = f"tests/{directory}"
    output = f"{tpath}/output"
    if os.path.exists(output):
        print("Need clean")
        shutil.rmtree(output)
    boardyaml = ltest["boardyaml"]
    cmd = ["./lavalab-gen.py", "-o", output, f"{tpath}/{boardyaml}"]
    # TODO verify warnings
    print(cmd)
    ret = subprocess.run(cmd)
    print(ret)
    if ret.returncode != 0:
        print("ERROR")
        sys.exit(1)
    # now test
    if "tests" not in ltest:
        ltest["tests"] = []
    if ltest["tests"] is None:
        ltest["tests"] = []
    for itest in ltest["tests"]:
        print(itest)
        if "filecompare" in itest:
            fpath = os.path.join(output, itest["filecompare"])
            print(f"DEBUG: tpath={tpath}")
            fbase = os.path.join(tpath, itest["base"])
            print(f"DEBUG compare {fpath} and {fbase}")
            cmd = ["diff", '-u', fbase, fpath]
            ret = subprocess.run(cmd)
            if ret.returncode != 0:
                print("ERROR")
                sys.exit(1)
        if "directory" in itest:
            fpath = os.path.join(output, itest["directory"])
            exists = itest["exists"]
            if exists:
                if os.path.exists(fpath):
                    print(f"DIR {fpath} OK")
                else:
                    print(f"DIR {fpath} KO")
    if "buildit" in ltest:
        dockcomp = os.path.join(output, ltest["buildit"])
        cmd = ["docker", "compose", '-f', dockcomp, "build"]
        ret = subprocess.run(cmd)
        if ret.returncode != 0:
            print("ERROR")
            sys.exit(1)
