//! Complete byte output of pinned Nora escaping and UI fragments.
//! UTF-8 inputs retain their original representation. Extra invalid byte inputs
//! are admitted by the proof domain; no UTF-8 normalization occurs.
#[derive(Clone,Copy)]
pub enum Lang { En, Ru, Zh }
pub struct Translations { pub recent_activity: Vec<u8>, pub last_n_events: Vec<u8>, pub time: Vec<u8>, pub action: Vec<u8>, pub artifact: Vec<u8>, pub registry: Vec<u8>, pub source: Vec<u8> }

pub fn append(out: &mut Vec<u8>, bytes: &[u8]) { out.extend_from_slice(bytes); }
pub fn language_index(lang: Lang) -> u8 { match lang { Lang::En => 0, Lang::Ru => 1, Lang::Zh => 2 } }
pub fn header_class(lang: Lang, which: u8) -> Vec<u8> {
    if which == language_index(lang) { b"text-white font-semibold".to_vec() } else { b"text-slate-400 hover:text-slate-200".to_vec() }
}

pub fn action_color(action: &[u8]) -> Vec<u8> {
    if action == b"PULL".as_slice() { b"text-blue-400".to_vec() }
    else if action == b"PUSH".as_slice() { b"text-green-400".to_vec() }
    else if action == b"CACHE".as_slice() { b"text-yellow-400".to_vec() }
    else if action == b"PROXY".as_slice() { b"text-purple-400".to_vec() }
    else { b"text-slate-400".to_vec() }
}


pub fn html_byte(b: u8) -> Vec<u8> {
    match b { b'&' => b"&amp;".to_vec(), b'<' => b"&lt;".to_vec(), b'>' => b"&gt;".to_vec(), b'"' => b"&quot;".to_vec(), b'\'' => b"&#39;".to_vec(), _ => [b].to_vec() }
}
pub fn uri_allowed(b: u8) -> bool {
    (b >= b'a' && b <= b'z') || (b >= b'A' && b <= b'Z') || (b >= b'0' && b <= b'9') || b == b'-' || b == b'_' || b == b'.' || b == b'~'
}
pub fn uri_byte(b: u8) -> Vec<u8> {
    if uri_allowed(b) { [b].to_vec() } else {
        let digits = b"0123456789ABCDEF";
        [b'%', digits[(b / 16) as usize], digits[(b % 16) as usize]].to_vec()
    }
}
pub fn html_escape(s: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < s.len() {
        let piece = html_byte(s[i]);
        append(&mut out, &piece);
        i += 1;
    }
    out
}
pub fn encode_uri_component(s: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < s.len() {
        let piece = uri_byte(s[i]);
        append(&mut out, &piece);
        i += 1;
    }
    out
}

pub fn render_activity_row(timestamp: &[u8], action: &[u8], artifact: &[u8], registry: &[u8], source: &[u8]) -> Vec<u8> {
    let action_color = action_color(action);
    let mut out = Vec::new();
    append(&mut out, b"\x0a        <tr class=\x22border-b border-slate-700/50 text-sm\x22>\x0a            <td class=\x22px-4 py-2 text");
    append(&mut out, b"-slate-500\x22>");
    append(&mut out, &html_escape(timestamp));
    append(&mut out, b"</td>\x0a            <td class=\x22px-4 py-2 font-medium ");
    append(&mut out, &action_color);
    append(&mut out, b"\x22><span class=\x22px-2 py-0.5 bg-slate-700 rounded\x22>");
    append(&mut out, &html_escape(action));
    append(&mut out, b"</span></td>\x0a            <td class=\x22px-4 py-2 text-slate-300 font-mono text-xs\x22>");
    append(&mut out, &html_escape(artifact));
    append(&mut out, b"</td>\x0a            <td class=\x22px-4 py-2 text-slate-400\x22>");
    append(&mut out, &html_escape(registry));
    append(&mut out, b"</td>\x0a            <td class=\x22px-4 py-2 text-slate-500\x22>");
    append(&mut out, &html_escape(source));
    append(&mut out, b"</td>\x0a        </tr>\x0a        ");
    out
}

pub fn render_activity_log(rows: &[u8], t: &Translations) -> Vec<u8> {
    let mut out = Vec::new();
    append(&mut out, b"\x0a        <div class=\x22bg-[#1e293b] rounded-lg border border-slate-700 overflow-hidden\x22>\x0a         ");
    append(&mut out, b"   <div class=\x22px-4 py-3 border-b border-slate-700 flex items-center justify-between\x22>\x0a         ");
    append(&mut out, b"       <h3 class=\x22text-slate-200 font-semibold\x22>");
    append(&mut out, &t.recent_activity);
    append(&mut out, b"</h3>\x0a                <span class=\x22text-xs text-slate-500\x22>");
    append(&mut out, &t.last_n_events);
    append(&mut out, b"</span>\x0a            </div>\x0a            <div class=\x22overflow-auto max-h-80\x22>\x0a                <tab");
    append(&mut out, b"le class=\x22w-full\x22 id=\x22activity-log\x22>\x0a                    <thead class=\x22sticky top-0 bg-slate-800");
    append(&mut out, b"\x22>\x0a                        <tr class=\x22text-left text-xs text-slate-500 uppercase border-b border");
    append(&mut out, b"-slate-700\x22>\x0a                            <th class=\x22px-4 py-2\x22>");
    append(&mut out, &t.time);
    append(&mut out, b"</th>\x0a                            <th class=\x22px-4 py-2\x22>");
    append(&mut out, &t.action);
    append(&mut out, b"</th>\x0a                            <th class=\x22px-4 py-2\x22>");
    append(&mut out, &t.artifact);
    append(&mut out, b"</th>\x0a                            <th class=\x22px-4 py-2\x22>");
    append(&mut out, &t.registry);
    append(&mut out, b"</th>\x0a                            <th class=\x22px-4 py-2\x22>");
    append(&mut out, &t.source);
    append(&mut out, b"</th>\x0a                        </tr>\x0a                    </thead>\x0a                    <tbody>\x0a   ");
    append(&mut out, b"                     ");
    append(&mut out, rows);
    append(&mut out, b"\x0a                    </tbody>\x0a                </table>\x0a            </div>\x0a        </div>\x0a       ");
    append(&mut out, b" ");
    out
}

pub fn render_polling_script() -> Vec<u8> {
    let mut out = Vec::new();
    append(&mut out, b"\x0a    <script>\x0a        setInterval(async () => {\x0a            try {\x0a                const data = a");
    append(&mut out, b"wait fetch('/api/ui/dashboard').then(r => r.json());\x0a\x0a                // Update global stats\x0a   ");
    append(&mut out, b"             document.getElementById('stat-downloads').textContent = data.global_stats.downloads");
    append(&mut out, b";\x0a                document.getElementById('stat-uploads').textContent = data.global_stats.upload");
    append(&mut out, b"s;\x0a                document.getElementById('stat-artifacts').textContent = data.global_stats.art");
    append(&mut out, b"ifacts;\x0a                document.getElementById('stat-cache-hit').textContent = data.global_stat");
    append(&mut out, b"s.cache_hit_percent.toFixed(1) + '%';\x0a\x0a                // Format storage size\x0a                co");
    append(&mut out, b"nst bytes = data.global_stats.storage_bytes;\x0a                let sizeStr;\x0a                if (by");
    append(&mut out, b"tes >= 1073741824) sizeStr = (bytes / 1073741824).toFixed(1) + ' GB';\x0a                else if (b");
    append(&mut out, b"ytes >= 1048576) sizeStr = (bytes / 1048576).toFixed(1) + ' MB';\x0a                else if (bytes ");
    append(&mut out, b">= 1024) sizeStr = (bytes / 1024).toFixed(1) + ' KB';\x0a                else sizeStr = bytes + ' B");
    append(&mut out, b"';\x0a                document.getElementById('stat-storage').textContent = sizeStr;\x0a\x0a             ");
    append(&mut out, b"   // Update uptime\x0a                const uptime = document.getElementById('uptime');\x0a          ");
    append(&mut out, b"      if (uptime) {\x0a                    const secs = data.uptime_seconds;\x0a                    co");
    append(&mut out, b"nst hours = Math.floor(secs / 3600);\x0a                    const mins = Math.floor((secs % 3600) /");
    append(&mut out, b" 60);\x0a                    uptime.textContent = hours + 'h ' + mins + 'm';\x0a                }\x0a    ");
    append(&mut out, b"        } catch (e) {\x0a                console.error('Dashboard poll failed:', e);\x0a            }\x0a");
    append(&mut out, b"        }, 5000);\x0a    </script>\x0a    ");
    out
}

pub fn header_piece_0() -> Vec<u8> { b"\x0a        <header class=\x22h-16 bg-[#1e293b] border-b border-slate-700 flex items-center justify-between px-4 md:px-6\x22>\x0a            <div class=\x22flex items-center\x22>\x0a                <button onclick=\x22toggleSidebar()\x22 class=\x22md:hidden p-2 -ml-2 mr-2 rounded-lg ho".to_vec() }

pub fn header_piece_1() -> Vec<u8> { b"ver:bg-slate-700\x22>\x0a                    <svg class=\x22w-6 h-6 text-slate-300\x22 fill=\x22none\x22 stroke=\x22currentColor\x22 viewBox=\x220 0 24 24\x22>\x0a                        <path stroke-linecap=\x22round\x22 stroke-linejoin=\x22round\x22 stroke-width=\x222\x22 d=\x22M4 6h16M4 12h16M4 18h16\x22/>\x0a  ".to_vec() }

pub fn header_piece_2() -> Vec<u8> { b"                  </svg>\x0a                </button>\x0a                <div class=\x22md:hidden flex items-center\x22>\x0a                    <span class=\x22font-bold text-slate-200 tracking-tight\x22>N<span class=\x22inline-block w-4 h-4 rounded-full border-2 border-current a".to_vec() }

pub fn header_piece_3() -> Vec<u8> { b"lign-middle mx-px\x22></span>RA</span>\x0a                </div>\x0a            </div>\x0a            <div class=\x22flex items-center space-x-2 md:space-x-4\x22>\x0a                <!-- Language switcher -->\x0a                <div class=\x22flex items-center border border-slate-60".to_vec() }

pub fn header_piece_4() -> Vec<u8> { b"0 rounded-lg overflow-hidden text-sm\x22>\x0a                    <button onclick=\x22setLang('en')\x22 class=\x22px-3 py-1.5 text-white font-semibold transition-colors\x22>EN</button>\x0a                    <span class=\x22text-slate-600\x22>|</span>\x0a                    <button oncl".to_vec() }

pub fn header_piece_5() -> Vec<u8> { b"ick=\x22setLang('ru')\x22 class=\x22px-3 py-1.5 text-slate-400 hover:text-slate-200 transition-colors\x22>RU</button>\x0a                    <span class=\x22text-slate-600\x22>|</span>\x0a                    <button onclick=\x22setLang('zh')\x22 class=\x22px-3 py-1.5 text-slate-400 hover:".to_vec() }

pub fn header_piece_6() -> Vec<u8> { b"text-slate-200 transition-colors\x22>\xe4\xb8\xad\xe6\x96\x87</button>\x0a                </div>\x0a                <a href=\x22https://github.com/getnora-io/nora\x22 target=\x22_blank\x22 class=\x22p-2 text-slate-400 hover:text-slate-200 hover:bg-slate-700 rounded-lg\x22>\x0a                    <svg class=".to_vec() }

pub fn header_piece_7() -> Vec<u8> { b"\x22w-5 h-5\x22 fill=\x22currentColor\x22 viewBox=\x220 0 24 24\x22>\x0a                        <path fill-rule=\x22evenodd\x22 d=\x22M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454".to_vec() }

pub fn header_piece_8() -> Vec<u8> { b"-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75".to_vec() }

pub fn header_piece_9() -> Vec<u8> { b" 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688".to_vec() }

pub fn header_piece_10() -> Vec<u8> { b".482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z\x22 clip-rule=\x22evenodd\x22/>\x0a                    </svg>\x0a                </a>\x0a                <a href=\x22/api-docs\x22 class=\x22p-2 text-slate-400 hover:text-slate-200 hover:bg-slate-700 rounded-lg\x22 title=\x22API Doc".to_vec() }

pub fn header_piece_11() -> Vec<u8> { b"s\x22>\x0a                    <svg class=\x22w-5 h-5\x22 fill=\x22none\x22 stroke=\x22currentColor\x22 viewBox=\x220 0 24 24\x22>\x0a                        <path stroke-linecap=\x22round\x22 stroke-linejoin=\x22round\x22 stroke-width=\x222\x22 d=\x22M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0".to_vec() }

pub fn header_piece_12() -> Vec<u8> { b" 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z\x22/>\x0a                    </svg>\x0a                </a>\x0a            </div>\x0a        </header>\x0a    ".to_vec() }

pub fn header_piece_13() -> Vec<u8> { b"0 rounded-lg overflow-hidden text-sm\x22>\x0a                    <button onclick=\x22setLang('en')\x22 class=\x22px-3 py-1.5 text-slate-400 hover:text-slate-200 transition-colors\x22>EN</button>\x0a                    <span class=\x22text-slate-600\x22>|</span>\x0a                    <".to_vec() }

pub fn header_piece_14() -> Vec<u8> { b"button onclick=\x22setLang('ru')\x22 class=\x22px-3 py-1.5 text-white font-semibold transition-colors\x22>RU</button>\x0a                    <span class=\x22text-slate-600\x22>|</span>\x0a                    <button onclick=\x22setLang('zh')\x22 class=\x22px-3 py-1.5 text-slate-400 hover:".to_vec() }

pub fn header_piece_15() -> Vec<u8> { b"button onclick=\x22setLang('ru')\x22 class=\x22px-3 py-1.5 text-slate-400 hover:text-slate-200 transition-colors\x22>RU</button>\x0a                    <span class=\x22text-slate-600\x22>|</span>\x0a                    <button onclick=\x22setLang('zh')\x22 class=\x22px-3 py-1.5 text-white".to_vec() }

pub fn header_piece_16() -> Vec<u8> { b" font-semibold transition-colors\x22>\xe4\xb8\xad\xe6\x96\x87</button>\x0a                </div>\x0a                <a href=\x22https://github.com/getnora-io/nora\x22 target=\x22_blank\x22 class=\x22p-2 text-slate-400 hover:text-slate-200 hover:bg-slate-700 rounded-lg\x22>\x0a                    <svg class=".to_vec() }

pub fn header_dark(lang: Lang) -> Vec<u8> {
    match lang {
        Lang::En => {
            let mut out = Vec::new();
            let piece = header_piece_0();
            append(&mut out, &piece);
            let piece = header_piece_1();
            append(&mut out, &piece);
            let piece = header_piece_2();
            append(&mut out, &piece);
            let piece = header_piece_3();
            append(&mut out, &piece);
            let piece = header_piece_4();
            append(&mut out, &piece);
            let piece = header_piece_5();
            append(&mut out, &piece);
            let piece = header_piece_6();
            append(&mut out, &piece);
            let piece = header_piece_7();
            append(&mut out, &piece);
            let piece = header_piece_8();
            append(&mut out, &piece);
            let piece = header_piece_9();
            append(&mut out, &piece);
            let piece = header_piece_10();
            append(&mut out, &piece);
            let piece = header_piece_11();
            append(&mut out, &piece);
            let piece = header_piece_12();
            append(&mut out, &piece);
            out
        },
        Lang::Ru => {
            let mut out = Vec::new();
            let piece = header_piece_0();
            append(&mut out, &piece);
            let piece = header_piece_1();
            append(&mut out, &piece);
            let piece = header_piece_2();
            append(&mut out, &piece);
            let piece = header_piece_3();
            append(&mut out, &piece);
            let piece = header_piece_13();
            append(&mut out, &piece);
            let piece = header_piece_14();
            append(&mut out, &piece);
            let piece = header_piece_6();
            append(&mut out, &piece);
            let piece = header_piece_7();
            append(&mut out, &piece);
            let piece = header_piece_8();
            append(&mut out, &piece);
            let piece = header_piece_9();
            append(&mut out, &piece);
            let piece = header_piece_10();
            append(&mut out, &piece);
            let piece = header_piece_11();
            append(&mut out, &piece);
            let piece = header_piece_12();
            append(&mut out, &piece);
            out
        },
        Lang::Zh => {
            let mut out = Vec::new();
            let piece = header_piece_0();
            append(&mut out, &piece);
            let piece = header_piece_1();
            append(&mut out, &piece);
            let piece = header_piece_2();
            append(&mut out, &piece);
            let piece = header_piece_3();
            append(&mut out, &piece);
            let piece = header_piece_13();
            append(&mut out, &piece);
            let piece = header_piece_15();
            append(&mut out, &piece);
            let piece = header_piece_16();
            append(&mut out, &piece);
            let piece = header_piece_7();
            append(&mut out, &piece);
            let piece = header_piece_8();
            append(&mut out, &piece);
            let piece = header_piece_9();
            append(&mut out, &piece);
            let piece = header_piece_10();
            append(&mut out, &piece);
            let piece = header_piece_11();
            append(&mut out, &piece);
            let piece = header_piece_12();
            append(&mut out, &piece);
            out
        },
    }
}

pub fn registry_search_bar(registry: &[u8], placeholder: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    append(&mut out, b"<div class=\x22flex items-center justify-end mb-4\x22>\x0a            <div class=\x22relative w-full md:w-au");
    append(&mut out, b"to\x22>\x0a                <input type=\x22text\x22 placeholder=\x22");
    append(&mut out, placeholder);
    append(&mut out, b"\x22\x0a                    class=\x22w-full md:w-auto pl-10 pr-4 py-2 bg-slate-800 border border-slate-6");
    append(&mut out, b"00 text-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-tr");
    append(&mut out, b"ansparent placeholder-slate-500\x22\x0a                    hx-get=\x22/api/ui/");
    append(&mut out, registry);
    append(&mut out, b"/search\x22 hx-trigger=\x22keyup changed delay:300ms\x22\x0a                    hx-target=\x22#repo-table-body\x22");
    append(&mut out, b" name=\x22q\x22>\x0a                <svg class=\x22absolute left-3 top-2.5 h-5 w-5 text-slate-500\x22 fill=\x22non");
    append(&mut out, b"e\x22 stroke=\x22currentColor\x22 viewBox=\x220 0 24 24\x22><path stroke-linecap=\x22round\x22 stroke-linejoin=\x22round");
    append(&mut out, b"\x22 stroke-width=\x222\x22 d=\x22M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z\x22/></svg>\x0a            </div>\x0a  ");
    append(&mut out, b"      </div>");
    out
}
