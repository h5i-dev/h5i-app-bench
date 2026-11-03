## Complete pinned sidebar byte output

`sidebar::sidebar` reaches the complete pinned
`components.rs::sidebar_dark_with_registries` body. Its canonical theorem
states termination and equality of every decoded output byte to an independent
model of the four original format templates. The model preserves navigation
order, active classes, fill/stroke attributes, visibility, unescaped caller
text, all icon bytes, whitespace and the version field. Empty registry
membership suppresses the entire registry section; the dashboard remains
visible, and authentication controls the token section.

Caller adapters embed `active_page.unwrap_or("")` and the three fields actually
read from `Translations` as UTF-8 byte vectors. `Enabled` carries the membership
bit for each of the exact 16 registry enum variants; `None` becomes all enabled.
The source enum order and navigation order differ for Go/Raw, so the reference
adapter obtains each bit by variant membership. The `PubDart` bit is named
`pub_dart` to avoid the Rust keyword `pub`; its source navigation ID stays `pub`.
The theorem also admits arbitrary byte strings outside the UTF-8 caller image.

The source VERSION expression `env!("CARGO_PKG_VERSION")` resolves to 1.3.2 in
the pinned workspace. The kernel receives version bytes explicitly, and the
reference adapter passes that exact value. No build environment behavior is
included in the source credit. The kernel returns bounded, at most 128-byte
constant fragments plus caller text in fixed-size arrays; `decode` concatenates
them mathematically. This representation avoids a machine-size bound on the
combined logical output. It proves the byte result and pure kernel termination
under the extraction's allocation model; it does not model allocator failure or
verify a host allocator. Independent models split source literals at 96-byte
boundaries before relating them to the kernel fragments.

`python3 prove/harness/nora_sidebar.py audit --port prove/ports/nora` regenerates
all five generated artifacts byte identically from the immutable source. It
compiles the unchanged upstream function and all icon constants with projected
translation and registry carriers, then compares complete output on 135,160
cases. These include every registry subset with both authentication choices,
None/empty enabled selections over all recognized and several unknown active
IDs, and arbitrary Unicode/control-character translation fields. The proof
covers every carrier input, beyond this finite differential evidence. Helpers,
carrier definitions and icon constants receive no independent line credit.
