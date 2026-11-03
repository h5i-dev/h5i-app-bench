"""Replay the pinned constructor attribute audit with the retained syn parser."""
import io
import json
import subprocess
import tarfile
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
with tempfile.TemporaryDirectory(prefix="h5i-constructor-attributes-") as temp:
    root = Path(temp)
    (root / "src").mkdir()
    for src, dst in [("constructor-attributes.rs", "src/main.rs"),
                     ("attribute-audit-Cargo.toml", "Cargo.toml"),
                     ("attribute-audit-Cargo.lock", "Cargo.lock")]:
        (root / dst).write_bytes((HERE / src).read_bytes())
    subprocess.run(["cargo", "build", "--offline", "--locked", "--manifest-path", str(root / "Cargo.toml")], check=True)
    output = []
    for app in ("nora", "artifactkeeper", "oxicloud"):
        plan = json.loads((REPO / "prove/ports" / app / "difftest/closed_records/plan.json").read_text())
        files = sorted({r["meta"]["file"] for r in plan["records"]})
        archive = subprocess.check_output(["git", f"--git-dir={REPO}/prove/results/upstream/{app}.git", "archive", plan["revision"], *files])
        source = root / app
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            for member in tar:
                if member.isfile() and member.name in files:
                    path = source / member.name
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(tar.extractfile(member).read())
        parsed = subprocess.check_output([str(root / "target/debug/forward-ast"), *[str(source / f) for f in files]], text=True)
        methods = {(str(Path(d["file"]).relative_to(source)), m["end"]): m
                   for line in parsed.splitlines() for d in [json.loads(line)] for m in d["methods"]}
        for record in plan["records"]:
            meta = record["meta"]
            method = methods[(meta["file"], meta["end"])]
            assert all(" [doc " in attr or " [allow " in attr for attr in method["context"] + method["attrs"]), method
            output.append(dict(app=app, constructor=record["name"], file=meta["file"], end=meta["end"], context=method["context"], attributes=method["attrs"]))
    expected = json.loads((HERE / "constructor-attributes.json").read_text())
    assert output == expected
    print("PASS: all 23 constructors have only documentation or lint attributes, including parent scopes.")
