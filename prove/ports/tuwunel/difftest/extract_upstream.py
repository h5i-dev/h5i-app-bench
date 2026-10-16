"""Copy tuwunel's code verbatim from the pinned commit into the crates under
upstream/, at the paths it has upstream, so `crate::`, `super::` and
`#[implement(..)]` resolve unchanged. Whole files are copied where the
kernel ports all of them; otherwise the ported items are cut out by name,
with their doc comments and attributes. Only these lines change:

- `use` statements are flattened to one path per line and pruned to the
  names the copied items use (plus extension traits), so the stubs need not
  provide the whole of ruma and tuwunel;
- methods cut from an `impl Service { .. }` block are put back into one;
- `mod` lines of files not copied are dropped, test modules cut;
- a seam line `mod stub; pub use stub::*;` is appended where the module's
  struct and storage are hand-written (upstream/*/src/**/stub.rs).

Items after a `// support` marker run but are not counted as ported
(count_loc.py): presentation and lazy-loading helpers.

  python3 extract_upstream.py <tuwunel checkout>
"""
import re, subprocess, sys
from pathlib import Path

COMMIT = "7801b8e"
HERE = Path(__file__).parent
UP = HERE / "upstream"
HEAD = f"// Copied from matrix-construct/tuwunel @ {COMMIT} by extract_upstream.py. Do not edit.\n"
SUPPORT = "\n// support: copied and run, not counted as ported\n"
SEAM = "\nmod stub;\npub use stub::*;\n"

# Traits are used through method calls, so their names need not appear.
TRAITS = {"Event", "Matches", "RelationTypeEqual", "TryIgnore", "FlatOk", "LogErr", "NotFound",
          "IsErrOr", "Deserialized", "Deref", "Tools", "TryTools", "IterStream", "Stream", "Deserialize"}


def show(repo, path):
    return subprocess.run(["git", "-C", repo, "show", f"{COMMIT}:src/{path}"],
                          capture_output=True, text=True, check=True).stdout


def split_uses(src):
    """(use statements, rest): the `use` items of a file. The file's inner
    doc comment and attributes stay at the top of `rest`, before the uses
    when written (see `write`)."""
    uses, rest, i = [], [], 0
    lines = src.splitlines(keepends=True)
    while i < len(lines):
        if re.match(r"(pub(\(\w+\))? )?use ", lines[i]):
            j = i
            while not lines[j].rstrip().endswith(";"):
                j += 1
            uses.append("".join(lines[i:j + 1]))
            i = j + 1
        else:
            rest.append(lines[i])
            i += 1
    return uses, "".join(rest)


def inner(rest):
    """(inner doc comment and attributes, the rest)."""
    lines = rest.splitlines(keepends=True)
    k, in_attr = 0, False
    while k < len(lines):
        s = lines[k].strip()
        if in_attr:
            in_attr = not s.endswith(")]")
        elif s.startswith("//") or s == "":
            pass
        elif s.startswith("#!["):
            in_attr = not s.endswith("]")
        else:
            break
        k += 1
    return "".join(lines[:k]), "".join(lines[k:])


def use_paths(stmt):
    """Flatten `use a::{b, c::{d as e}};` to [(vis, "a::b"), (vis, "a::c::d as e")]."""
    m = re.match(r"\s*((?:pub(?:\(\w+\))? )?)use\s+(.*);\s*$", stmt, re.S)
    vis, tree = m.group(1), re.sub(r"\s+", " ", m.group(2)).strip()

    def walk(prefix, t):
        t = t.strip()
        if not t:
            return []
        i = t.find("{")
        if i < 0:
            return [prefix + t]
        head, body = t[:i], t[i + 1:t.rindex("}")]
        parts, depth, cur = [], 0, ""
        for c in body:
            if c == "," and depth == 0:
                parts.append(cur)
                cur = ""
                continue
            depth += {"{": 1, "}": -1}.get(c, 0)
            cur += c
        parts.append(cur)
        out = []
        for p in parts:
            out += walk(prefix + head, p)
        return out

    return [(vis, p) for p in walk("", tree)]


def prune(uses, body):
    words = set(re.findall(r"\b\w+\b", body))
    out = []
    for stmt in uses:
        for vis, p in use_paths(stmt):
            if p.endswith("::self"):
                name, p = p.split("::")[-2], p[:-len("::self")]
            else:
                name = p.split(" as ")[-1].split("::")[-1]
            if name == "*" or name in words or name in TRAITS or name.endswith("Ext") \
                    or name == "_":
                out.append(f"use {p};\n")
    return "".join(out)


def item(src, header):
    """The item whose first line matches `header`, with its doc comments and
    attributes, through its closing brace or semicolon."""
    m = re.search(rf"^[ \t]*{header}", src, re.M)
    if not m:
        raise SystemExit(f"not found: {header}")
    lines = src[:m.start()].splitlines(keepends=True)
    k, in_attr = len(lines), False
    while k > 0:
        s = lines[k - 1].strip()
        if in_attr:
            in_attr = not s.startswith("#[")
        elif s.startswith("///") or (s.startswith("#[") and s.endswith("]")):
            pass
        elif s.endswith(")]"):
            in_attr = True
        else:
            break
        k -= 1
    start = len("".join(lines[:k]))
    depth, j = 0, m.end()
    while j < len(src):
        c = src[j]
        if c == ";" and depth == 0:
            return src[start:j + 1] + "\n"
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
            if depth == 0 and c == "}":
                return src[start:j + 1] + "\n"
        j += 1
    raise SystemExit(f"unbalanced: {header}")


def fn(name):
    return rf"(?:pub(?:\((?:crate|super)\))? )?(?:const )?(?:async )?fn {name}\b"


def cut(repo, path, ported, support=(), methods_of=None):
    """The use block and the named items of one file."""
    src = show(repo, path)
    uses, rest = split_uses(src)
    body = "".join(item(rest, h) + "\n" for h in ported)
    sup = "".join(item(rest, h) + "\n" for h in support)
    if methods_of:
        body = f"impl {methods_of} {{\n{body}}}\n"
    return uses, body, sup


def whole(repo, path, drop=()):
    src = show(repo, path)
    i = src.find("\n#[cfg(test)]\nmod tests {")
    if i >= 0:
        src = src[:i + 1]
    src = re.sub(r"\n#\[cfg\(test\)\]\nmod tests;\n", "\n", src)
    for d in drop:
        src = src.replace(d, "")
    return split_uses(src)


def write(crate, path, uses, body, sup="", extra="", seam=False):
    out = UP / crate / "src" / path
    out.parent.mkdir(parents=True, exist_ok=True)
    top, body = inner(body)
    text = HEAD + top + prune(uses, body + sup) + extra + "\n" + body + (SUPPORT + sup if sup else "") + (SEAM if seam else "")
    out.write_text(text)


def main(repo):
    S, C, A = "tuwunel_service", "tuwunel_core", "tuwunel_api"
    sa = "service/rooms/state_accessor/"

    # tuwunel_service: the visibility checks
    u, b, s = cut(repo, sa + "user_can.rs", [fn("user_can_see_event"), fn("user_shared_history"),
                                             fn("user_can_see_state_events"), fn("user_can_see_room")])
    write(S, "rooms/state_accessor/user_can.rs", u, b)
    u, b, s = cut(repo, sa + "state.rs", [
        fn("user_was_joined"), fn("user_was_invited"), fn("user_membership"), fn("user_membership_at_pdu"),
        fn("state_get_content"), fn("state_get"), fn("state_get_id"), fn("state_get_shortid"),
        fn("state_full"), fn("state_full_pdus"), fn("state_full_pdus_strict"), fn("state_full_ids"),
        fn("state_full_ids_strict"), fn("state_full_shortids"), fn("load_full_state")])
    write(S, "rooms/state_accessor/state.rs", u, b)
    u, b, s = cut(repo, sa + "room_state.rs", [fn("room_state_get_content"), fn("room_state_full"),
                                               fn("room_state_full_pdus"), fn("room_state_get")])
    write(S, "rooms/state_accessor/room_state.rs", u, b)
    u, b, s = cut(repo, sa + "server_can.rs", [fn("server_can_see_event")])
    write(S, "rooms/state_accessor/server_can.rs", u, b)
    u, b, s = cut(repo, sa + "mod.rs", [fn("is_world_readable"), fn("is_encrypted_room")], methods_of="Service")
    write(S, "rooms/state_accessor/mod.rs", u, b,
          extra="\nmod room_state;\nmod server_can;\nmod state;\nmod user_can;\n", seam=True)

    u, b, s = cut(repo, "service/rooms/state_cache/mod.rs", [
        fn("user_membership"), fn("once_joined"), fn("is_joined"), fn("is_knocked"), fn("is_invited"),
        fn("is_left"), fn("get_left_count"), fn("room_members"), fn("room_members_checked")])
    write(S, "rooms/state_cache/mod.rs", u, b, seam=True)

    u, b, s = cut(repo, "service/rooms/timeline/pdus.rs", [r"pub type PdusIterItem\b", fn("pdus"), fn("pdus_rev"),
                                                           fn("each_slice"), fn("each_pdu")])
    write(S, "rooms/timeline/pdus.rs", u, b)
    u, b, s = cut(repo, "service/rooms/timeline/mod.rs", [
        fn("shortstatehash_after"), fn("next_shortstatehash"), fn("next_timeline_count"),
        fn("last_timeline_count"), fn("count_to_id"), fn("pdu_count_to_id"), fn("get_pdu"),
        fn("get_pdu_from_id"), fn("get"), fn("get_outlier"), fn("get_non_outlier"), fn("get_from_id"),
        fn("get_pdu_count"), fn("get_shorteventid_from_pdu_id"), fn("get_event_id_from_pdu_id"),
        fn("get_pdu_id")])
    write(S, "rooms/timeline/mod.rs", u, b, extra="\nmod pdus;\npub use self::pdus::*;\n", seam=True)

    u, b, s = cut(repo, "service/rooms/pdu_metadata/relations.rs", [r"type StartKey", fn("get_relations"), fn("has_incoming_relation")])
    write(S, "rooms/pdu_metadata/relations.rs", u, b)

    u, b, s = cut(repo, "service/rooms/threads/mod.rs", [fn("threads_until"), fn("live_thread"), fn("is_participant")],
                  methods_of="Service")
    write(S, "rooms/threads/mod.rs", u, b, seam=True)

    u, b, s = cut(repo, "service/rooms/metadata/mod.rs", [fn("exists")])
    write(S, "rooms/metadata/mod.rs", u, b, seam=True)

    u, b, s = cut(repo, "service/rooms/state/mod.rs", [fn("get_room_shortstatehash"), fn("pdu_shortstatehash"),
                                                       fn("get_shortstatehash")])
    write(S, "rooms/state/mod.rs", u, b, seam=True)

    u, b, s = cut(repo, "service/users/mod.rs", [fn("user_is_ignored")], methods_of="Service")
    write(S, "users/mod.rs", u, b, seam=True)

    # tuwunel_core: the count type, the filter and the server name check
    for f in ("count.rs", "id.rs", "raw_id.rs"):
        u, rest = whole(repo, "core/matrix/pdu/" + f)
        write(C, "matrix/pdu/" + f, u, rest)
    u, b, s = cut(repo, "core/matrix/event/filter.rs", [
        r"pub trait Matches<T>", r"impl<E: Event> Matches<&E> for RoomEventFilter",
        r"impl Matches<&RoomId> for RoomFilter", r"impl Matches<&UserId> for Filter",
        fn("matches_user_id"), fn("matches_room_id"), fn("matches_room"), fn("matches_sender"),
        fn("matches_type"), fn("matches_url")])
    write(C, "matrix/event/filter.rs", u, b)
    u, rest = whole(repo, "core/matrix/event/relation.rs")
    write(C, "matrix/event/relation.rs", u, rest)
    u, b, s = cut(repo, "core/config/net.rs", [fn("is_forbidden_remote_server_name")])
    write(C, "config/net.rs", u, b)
    u, b, s = cut(repo, "core/utils/math.rs", [fn("usize_from_ruma_bounded")])
    write(C, "utils/math.rs", u, b)

    # tuwunel_core plumbing: stream and future combinators, result helpers
    for d, files in (("utils/stream", ["band", "broadband", "cloned", "expect", "ignore", "iter_stream", "ready",
                                       "tools", "try_broadband", "try_ready", "try_tools", "try_wideband",
                                       "wideband", "mod"]),
                     ("utils/future", ["bool_ext", "ext_ext", "mod", "option_ext", "option_stream",
                                       "ready_bool_ext", "ready_eq_ext", "try_ext_ext"]),
                     ("utils/result", ["flat_ok", "into_is_ok", "is_err_or", "log_err", "not_found",
                                       "map_expect", "and_then_ref", "unwrap_or_err", "filter",
                                       "map_ref"])):
        for f in files:
            u, rest = whole(repo, f"core/{d}/{f}.rs", drop=("mod try_parallel;\n", "\ttry_parallel::TryParallelExt,\n"))
            out = UP / C / "src" / d / f"{f}.rs"
            out.parent.mkdir(parents=True, exist_ok=True)
            top, rest = inner(rest)
            out.write_text(HEAD + top + "".join(u) + rest)
    u, rest = whole(repo, "core/utils/bool.rs")
    top, rest = inner(rest)
    (UP / C / "src/utils/bool.rs").write_text(HEAD + top + "".join(u) + rest)

    # tuwunel_api: the endpoints
    sup_msg = [fn("lazy_loading_witness"), fn("get_member_event"), fn("annotate_membership"),
               fn("with_membership"), fn("add_membership_unsigned")]
    u, b, s = cut(repo, "api/client/message.rs", [
        r"pub\(crate\) struct MessagesArgs", r"const IGNORED_MESSAGE_TYPES", r"type RelTypes",
        r"const LIMIT_MAX", r"const LIMIT_DEFAULT", fn("get_message_events_route"), fn("get_messages"),
        fn("event_filters"), fn("related_by_filter"), fn("ignored_filter"), fn("is_ignored_pdu"),
        fn("visibility_filter"), fn("event_filter")], support=sup_msg)
    write(A, "client/message.rs", u, b, s)
    u, rest = whole(repo, "api/client/context.rs")
    write(A, "client/context.rs", u, rest)
    u, rest = whole(repo, "api/client/relations.rs")
    write(A, "client/relations.rs", u, rest)
    u, b, s = cut(repo, "api/client/threads.rs", [fn("get_threads_route")],
                  support=[fn("apply_ignored_view"), fn("without_thread_bundle"), fn("apply_redacted_root"),
                           fn("adjust_thread_bundle")])
    write(A, "client/threads.rs", u, b, s)
    u, b, s = cut(repo, "api/client/state.rs", [fn("get_state_events_route"), fn("get_state_events_for_key_route")])
    write(A, "client/state.rs", u, b)
    u, rest = whole(repo, "api/client/membership/members.rs")
    write(A, "client/membership/members.rs", u, rest)
    u, rest = whole(repo, "api/client/room/initial_sync.rs")
    write(A, "client/room/initial_sync.rs", u, rest)
    u, rest = whole(repo, "api/client/room/event.rs")
    write(A, "client/room/event.rs", u, rest)


if __name__ == "__main__":
    main(sys.argv[1])
