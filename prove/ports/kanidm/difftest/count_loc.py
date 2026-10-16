"""Lines of upstream code the kernel ports: each item is cut from the pinned
commit and counted without blank lines, comments, attributes and `use`
statements.

  python3 count_loc.py <kanidm checkout>
"""
import re, sys
from extract_upstream import LIB, before_tests, esc, fns, item, show

ACC = LIB + "server/access/"
# Whole files (up to their tests).
WHOLE = [ACC + f for f in ("search.rs", "modify.rs", "create.rs", "delete.rs", "protected.rs", "migration.rs")]
ITEMS = {
    ACC + "mod.rs": [r"pub enum Access\b", r"pub enum AccessClass\b", r"pub struct AccessEffectivePermission\b",
                     r"pub enum AccessBasicResult\b", r"pub enum AccessSrchResult\b",
                     r"pub enum AccessModResult\b", r"struct AccessControlsInner\b",
                     r"fn resolve_access_conditions\b", r"pub trait AccessControlsTransaction\b"],
    ACC + "profiles.rs": [r"pub struct AccessControlSearchResolved\b", r"pub struct AccessControlSearch\b",
                          r"pub struct AccessControlDeleteResolved\b", r"pub struct AccessControlDelete\b",
                          r"pub struct AccessControlCreateResolved\b", r"pub struct AccessControlCreate\b",
                          r"pub struct AccessControlModifyResolved\b", r"pub struct AccessControlModify\b",
                          r"pub enum AccessControlReceiver\b", r"pub enum AccessControlReceiverCondition\b",
                          r"pub enum AccessControlTarget\b", r"pub enum AccessControlTargetCondition\b",
                          r"pub struct AccessControlProfile\b"],
    LIB + "server/identity.rs": [r"pub enum AccessScope\b", r"pub struct IdentUser\b", r"pub enum InternalRole\b",
                                 r"impl InternalRole\b", r"pub enum IdentType\b"],
    LIB + "filter.rs": [r"enum FilterComp\b", r"pub enum FilterResolved\b"],
    LIB + "modify.rs": [r"pub enum Modify\b"],
}
FNS = {
    LIB + "server/identity.rs": [(r"impl Identity\b", ["access_scope", "get_uuid", "get_memberof"])],
    LIB + "entry.rs": [
        (esc("impl<STATE> Entry<EntryInit, STATE>"), ["get_uuid"]),
        (esc("impl Entry<EntrySealed, EntryCommitted> {"), ["reduce_attributes"]),
        (esc("impl<STATE> Entry<EntrySealed, STATE>\n"), ["get_uuid"]),
        (esc("impl<VALID, STATE> Entry<VALID, STATE> {"), [
            "attr_keys", "get_ava_names", "get_ava_set", "get_ava_refer", "get_ava_as_iutf8",
            "get_ava_as_oauthscopemaps", "get_ava_iter_iutf8", "get_ava_single_refer", "attribute_pres",
            "attribute_equality", "attribute_substring", "attribute_startswith", "attribute_endswith",
            "attribute_lessthan", "entry_match_no_index", "entry_match_no_index_inner"])],
    LIB + "filter.rs": [
        (esc("impl Filter<FilterValid> {"), ["get_attr_set"]),
        (esc("impl FilterComp {"), ["get_attr_set"]),
        (esc("impl FilterResolved {"), ["resolve_no_idx"])],
    LIB + "value.rs": [(esc("impl PartialValue {"), ["to_str"]), (esc("impl Value {"), ["to_str"])],
}
VALUESETS = [("utf8.rs", "ValueSetUtf8", []), ("iutf8.rs", "ValueSetIutf8", ["as_iutf8_set", "as_iutf8_iter"]),
             ("iname.rs", "ValueSetIname", []), ("uuid.rs", "ValueSetUuid", ["to_uuid_single"]),
             ("uuid.rs", "ValueSetRefer", ["to_refer_single", "as_refer_set"]), ("uint32.rs", "ValueSetUint32", []),
             ("oauth.rs", "ValueSetOauthScopeMap", ["as_oauthscopemap"])]


def code(text):
    n, depth, in_use = 0, 0, False
    for line in text.splitlines():
        s = line.strip()
        if depth or s.startswith("/*"):
            depth = 0 if "*/" in s else 1
            continue
        if in_use:
            in_use = not s.endswith(";")
            continue
        if s.startswith("use ") or s.startswith("pub use "):
            in_use = not s.endswith(";")
            continue
        if s and not s.startswith("//") and not s.startswith("#[") and not s.startswith("#!["):
            n += 1
    return n


def main(repo):
    total = 0

    def report(name, n):
        nonlocal total
        print(f"{n:5}  {name}")
        total += n

    for f in WHOLE:
        report(f, code(before_tests(show(repo, f))))
    for f in sorted(set(ITEMS) | set(FNS)):
        src = show(repo, f)
        n = sum(code(item(src, h)) for h in ITEMS.get(f, []))
        n += sum(code(fns(src, impl, names)) for impl, names in FNS.get(f, []))
        report(f, n)
    n = 0
    for file, ty, extra in VALUESETS:
        src = show(repo, LIB + "valueset/" + file)
        n += code(fns(src, esc(f"impl ValueSetT for {ty} {{"),
                      ["contains", "substring", "startswith", "endswith", "lessthan"] + extra))
    report(LIB + "valueset/*.rs", n)
    print(f"{total:5}  total")


if __name__ == "__main__":
    main(sys.argv[1])
