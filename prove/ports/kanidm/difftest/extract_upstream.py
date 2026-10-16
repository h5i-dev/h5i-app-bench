"""Build the `kanidmd_lib` crate in upstream/ from kanidm's own sources at the
pinned commit. The access module's files are copied whole (`mod.rs` and
`profiles.rs` item by item, without the cache, the parsers and the tests),
so `crate::` paths resolve as in kanidm. The entry, filter, value, identity
and event code they call is cut item by item from the same commit and put
after small stubs (upstream/stubs/) that stand in for what is not copied:
the entry states, the value-set trait object, the filter cache. Test seams
are appended from upstream/seams/. `kanidm_proto`'s `attribute.rs` and
`constants.rs` are copied into upstream/proto.

  python3 extract_upstream.py <kanidm checkout>
"""
import re, shutil, subprocess, sys
from pathlib import Path

COMMIT = "f608c4f"
HERE = Path(__file__).parent
UP = HERE / "upstream"
HEAD = f"// Copied from kanidm/kanidm @ {COMMIT} by extract_upstream.py. Do not edit.\n"
LIB = "server/lib/src/"


def show(repo, path):
    return subprocess.run(["git", "-C", repo, "show", f"{COMMIT}:{path}"],
                          capture_output=True, text=True, check=True).stdout


def before_tests(src):
    """The file up to its first top-level `#[cfg(test)]` item."""
    i = src.find("\n#[cfg(test)]")
    return src if i < 0 else src[:i + 1]


def item(src, header, start=0):
    """The item starting at the line matching `header` (with its doc comments
    and attributes), through its closing brace."""
    m = re.compile(rf"^[ \t]*(?:(?:///.*|#\[.*\])\n[ \t]*)*{header}", re.M).search(src, start)
    if not m:
        raise SystemExit(f"not found: {header}")
    i = src.index("{", m.end() - 1 if src[m.end() - 1] == "{" else m.end())
    depth, j = 0, i
    while j < len(src):
        c = src[j]
        if src.startswith("//", j):  # skip line comments
            j = src.index("\n", j)
        elif src.startswith("/*", j):  # and block comments
            j = src.index("*/", j) + 1
        elif c == '"':  # and string literals
            j += 1
            while src[j] != '"':
                j += 2 if src[j] == "\\" else 1
        elif c == "'" and re.match(r"'(\\.|[^\\'])'", src[j:j + 4]):  # and char literals
            j = src.index("'", j + 2)
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return src[m.start():j + 1] + "\n"
        j += 1
    raise SystemExit(f"unbalanced: {header}")


def fns(src, impl_header, names):
    """Functions `names` from the impl block starting at `impl_header`."""
    block = item(src, impl_header)
    return "".join("\n" + item(block, rf"(?:pub(?:\([a-z]+\))? )?fn {n}\b") for n in names)


def line(src, header):
    m = re.search(rf"^{header}.*;\n", src, re.M)
    if not m:
        raise SystemExit(f"not found: {header}")
    return m.group(0)


def items(src, headers):
    return "\n".join(item(src, h) for h in headers)


def esc(s):
    return re.escape(s)


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def stub(rel):
    return (UP / "stubs" / rel).read_text()


def proto(repo):
    out = UP / "proto/src"
    if out.exists():
        shutil.rmtree(out)
    write(out / "lib.rs", (UP / "proto/stubs/lib.rs").read_text())
    c = show(repo, "proto/src/constants.rs").replace("pub mod uri;\n", "")
    write(out / "constants.rs", HEAD + c)
    a = before_tests(show(repo, "proto/src/attribute.rs"))
    # utoipa is not available offline: drop the OpenAPI schema derive.
    a = a.replace("use utoipa::ToSchema;\n", "").replace(", ToSchema", "")
    a = a.replace("    #[schema(value_type = String)]\n", "")
    write(out / "attribute.rs", HEAD + a)


def main(repo):
    proto(repo)
    out = UP / "src"
    if out.exists():
        shutil.rmtree(out)
    for s in (UP / "stubs").glob("**/*.rs"):
        write(out / s.relative_to(UP / "stubs"), s.read_text())

    def add(rel, text):
        p = out / rel
        p.write_text(p.read_text() + "\n" + HEAD + text)

    # The access module.
    acc = LIB + "server/access/"
    for f in ("search.rs", "modify.rs", "create.rs", "delete.rs", "protected.rs", "migration.rs"):
        write(out / "server/access" / f, HEAD + before_tests(show(repo, acc + f)))
    m = before_tests(show(repo, acc + "mod.rs"))
    add("server/access/mod.rs", items(m, [
        r"pub enum Access\b", r"pub enum AccessClass\b", r"pub struct AccessEffectivePermission\b",
        r"pub enum AccessBasicResult\b", r"pub enum AccessSrchResult\b", r"pub enum AccessModResult\b",
        r"struct AccessControlsInner\b", r"fn resolve_access_conditions\b",
        r"pub trait AccessControlsTransaction\b"]))
    p = show(repo, acc + "profiles.rs")
    add("server/access/profiles.rs", items(p, [
        r"pub struct AccessControlSearchResolved\b", r"pub struct AccessControlSearch\b",
        r"pub struct AccessControlDeleteResolved\b", r"pub struct AccessControlDelete\b",
        r"pub struct AccessControlCreateResolved\b", r"pub struct AccessControlCreate\b",
        r"pub struct AccessControlModifyResolved\b", r"pub struct AccessControlModify\b",
        r"pub enum AccessControlReceiver\b", r"pub enum AccessControlReceiverCondition\b",
        r"pub enum AccessControlTarget\b", r"pub enum AccessControlTargetCondition\b",
        r"pub struct AccessControlProfile\b"]))

    # What the access module calls.
    i = show(repo, LIB + "server/identity.rs")
    add("server/identity.rs", items(i, [
        r"pub enum AccessScope\b", r"pub struct IdentUser\b", r"pub enum InternalRole\b",
        r"impl InternalRole\b", r"pub enum IdentType\b", r"pub enum IdentityId\b",
        esc("impl From<&IdentType> for IdentityId")]) +
        "\nimpl Identity {" + fns(i, r"impl Identity\b",
                                  ["access_scope", "get_uuid", "get_event_origin_id", "get_memberof"]) + "}\n")

    e = show(repo, LIB + "entry.rs")
    add("entry.rs", items(e, [
        r"pub struct EntryReduced\b", r"pub struct Entry<VALID, STATE>",
        esc("impl<VALID, STATE> Clone for Entry<VALID, STATE>"),
        esc("impl<VALID, STATE> std::fmt::Debug for Entry<VALID, STATE>"),
        esc("impl<STATE> Entry<EntryInit, STATE>")]) +
        "\nimpl Entry<EntrySealed, EntryCommitted> {" +
        fns(e, esc("impl Entry<EntrySealed, EntryCommitted> {"), ["reduce_attributes"]) + "}\n" +
        "\nimpl<STATE> Entry<EntrySealed, STATE> {" +
        fns(e, esc("impl<STATE> Entry<EntrySealed, STATE>\n"), ["get_uuid"]) + "}\n" +
        "\nimpl<VALID, STATE> Entry<VALID, STATE> {" +
        fns(e, esc("impl<VALID, STATE> Entry<VALID, STATE> {"), [
            "attr_keys", "get_ava_names", "get_ava_set", "get_ava_refer", "get_ava_as_iutf8",
            "get_ava_as_oauthscopemaps", "get_ava_iter_iutf8", "get_ava_single_refer",
            "attribute_pres", "attribute_equality", "attribute_substring", "attribute_startswith",
            "attribute_endswith", "attribute_lessthan", "entry_match_no_index",
            "entry_match_no_index_inner"]) + "}\n")

    f = show(repo, LIB + "filter.rs")
    add("filter.rs", items(f, [
        r"enum FilterComp\b", esc("impl fmt::Debug for FilterComp"), r"pub enum FilterResolved\b",
        esc("impl fmt::Debug for FilterResolved"), esc("impl PartialEq for FilterResolved"),
        esc("impl PartialOrd for FilterResolved"), esc("impl Ord for FilterResolved")]) +
        "\nimpl Filter<FilterValidResolved> {" +
        fns(f, esc("impl Filter<FilterValidResolved> {"), ["to_inner"]) + "}\n" +
        "\nimpl Filter<FilterValid> {" +
        fns(f, esc("impl Filter<FilterValid> {"), ["resolve", "get_attr_set"]) + "}\n" +
        "\nimpl FilterComp {" + fns(f, esc("impl FilterComp {"), ["get_attr_set"]) + "}\n" +
        "\nimpl FilterResolved {" +
        fns(f, esc("impl FilterResolved {"), [
            "resolve_cacheable", "resolve_no_idx", "fast_optimise", "optimise",
            "get_slopeyness_factor"]) + "}\n")

    v = show(repo, LIB + "value.rs")
    add("value.rs",
        "\nimpl PartialValue {" + fns(v, esc("impl PartialValue {"),
                                      ["new_utf8s", "new_iutf8", "new_iname", "to_str"]) + "}\n" +
        "\nimpl Value {" + fns(v, esc("impl Value {"),
                               ["new_utf8s", "new_iutf8", "new_iname", "to_str"]) + "}\n")

    vs = ""
    for file, ty, extra in [
            ("utf8.rs", "ValueSetUtf8", []),
            ("iutf8.rs", "ValueSetIutf8", ["as_iutf8_set", "as_iutf8_iter"]),
            ("iname.rs", "ValueSetIname", []),
            ("uuid.rs", "ValueSetUuid", ["to_uuid_single"]),
            ("uuid.rs", "ValueSetRefer", ["to_refer_single", "as_refer_set"]),
            ("uint32.rs", "ValueSetUint32", []),
            ("oauth.rs", "ValueSetOauthScopeMap", ["as_oauthscopemap"])]:
        src = show(repo, LIB + "valueset/" + file)
        vs += (f"\nimpl ValueSetT for {ty} {{" +
               fns(src, esc(f"impl ValueSetT for {ty} {{"),
                   ["contains", "substring", "startswith", "endswith", "lessthan"] + extra) +
               "\n    fn clone_box(&self) -> ValueSet {\n        Box::new(self.clone())\n    }\n}\n")
    add("valueset.rs", vs)

    mo = show(repo, LIB + "modify.rs")
    add("modify.rs", "#[derive(Serialize, Deserialize, Debug, Clone)]\n" + line(mo, r"pub struct ModifyValid\b") +
        items(mo, [r"pub enum Modify\b", r"pub struct ModifyList<VALID>"]) +
        "\nimpl ModifyList<ModifyValid> {" +
        fns(mo, esc("impl ModifyList<ModifyValid> {"), ["iter"]) + "}\n")

    ev = show(repo, LIB + "event.rs")
    add("event.rs", items(ev, [r"pub struct SearchEvent\b", r"pub struct CreateEvent\b",
                               r"pub struct DeleteEvent\b", r"pub struct ModifyEvent\b"]))
    b = show(repo, LIB + "server/batch_modify.rs")
    add("server/batch_modify.rs", line(b, r"pub type ModSetValid\b") + "\n" +
        item(b, r"pub struct BatchModifyEvent\b"))

    en = show(repo, LIB + "constants/entries.rs")
    add("constants/entries.rs", items(en, [
        r"pub enum EntryClass\b", esc("impl From<EntryClass> for &'static str"),
        esc("impl AsRef<str> for EntryClass"), esc("impl From<&EntryClass> for &'static str"),
        esc("impl From<EntryClass> for String"), esc("impl From<EntryClass> for Value"),
        esc("impl From<EntryClass> for PartialValue"),
        esc("impl From<EntryClass> for crate::prelude::AttrString"),
        esc("impl Display for EntryClass")]))
    write(out / "constants/uuids.rs", HEAD + before_tests(show(repo, LIB + "constants/uuids.rs")))

    mac = show(repo, LIB + "macros.rs")
    add("macros.rs", item(mac, r"macro_rules! btreeset\b"))

    # Seams go after the copied text, never inside it.
    for rel, seam in [("server/access/mod.rs", "access_mod.rs"), ("server/access/profiles.rs", "profiles.rs"),
                      ("entry.rs", "entry.rs"), ("modify.rs", "modify.rs"), ("filter.rs", "filter.rs")]:
        p = out / rel
        p.write_text(p.read_text() + (UP / "seams" / seam).read_text())


if __name__ == "__main__":
    main(sys.argv[1])
