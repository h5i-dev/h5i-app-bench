#![allow(dead_code)]
use std::fmt::Write;
#[derive(Clone,Copy)]
pub enum Lang { En, Ru, Zh }
pub struct Translations<'a> { pub recent_activity: &'a str, pub last_n_events: &'a str, pub time: &'a str, pub action: &'a str, pub artifact: &'a str, pub registry: &'a str, pub source: &'a str }
/// Escape HTML special characters
pub fn html_escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}
/// Render a single activity log row
pub fn render_activity_row(
    timestamp: &str,
    action: &str,
    artifact: &str,
    registry: &str,
    source: &str,
) -> String {
    let action_color = match action {
        "PULL" => "text-blue-400",
        "PUSH" => "text-green-400",
        "CACHE" => "text-yellow-400",
        "PROXY" => "text-purple-400",
        _ => "text-slate-400",
    };

    format!(
        r##"
        <tr class="border-b border-slate-700/50 text-sm">
            <td class="px-4 py-2 text-slate-500">{}</td>
            <td class="px-4 py-2 font-medium {}"><span class="px-2 py-0.5 bg-slate-700 rounded">{}</span></td>
            <td class="px-4 py-2 text-slate-300 font-mono text-xs">{}</td>
            <td class="px-4 py-2 text-slate-400">{}</td>
            <td class="px-4 py-2 text-slate-500">{}</td>
        </tr>
        "##,
        html_escape(timestamp),
        action_color,
        html_escape(action),
        html_escape(artifact),
        html_escape(registry),
        html_escape(source)
    )
}
/// Render the activity log container
pub fn render_activity_log(rows: &str, t: &Translations) -> String {
    format!(
        r##"
        <div class="bg-[#1e293b] rounded-lg border border-slate-700 overflow-hidden">
            <div class="px-4 py-3 border-b border-slate-700 flex items-center justify-between">
                <h3 class="text-slate-200 font-semibold">{}</h3>
                <span class="text-xs text-slate-500">{}</span>
            </div>
            <div class="overflow-auto max-h-80">
                <table class="w-full" id="activity-log">
                    <thead class="sticky top-0 bg-slate-800">
                        <tr class="text-left text-xs text-slate-500 uppercase border-b border-slate-700">
                            <th class="px-4 py-2">{}</th>
                            <th class="px-4 py-2">{}</th>
                            <th class="px-4 py-2">{}</th>
                            <th class="px-4 py-2">{}</th>
                            <th class="px-4 py-2">{}</th>
                        </tr>
                    </thead>
                    <tbody>
                        {}
                    </tbody>
                </table>
            </div>
        </div>
        "##,
        t.recent_activity,
        t.last_n_events,
        t.time,
        t.action,
        t.artifact,
        t.registry,
        t.source,
        rows
    )
}
/// Render the polling script for auto-refresh
pub fn render_polling_script() -> String {
    r##"
    <script>
        setInterval(async () => {
            try {
                const data = await fetch('/api/ui/dashboard').then(r => r.json());

                // Update global stats
                document.getElementById('stat-downloads').textContent = data.global_stats.downloads;
                document.getElementById('stat-uploads').textContent = data.global_stats.uploads;
                document.getElementById('stat-artifacts').textContent = data.global_stats.artifacts;
                document.getElementById('stat-cache-hit').textContent = data.global_stats.cache_hit_percent.toFixed(1) + '%';

                // Format storage size
                const bytes = data.global_stats.storage_bytes;
                let sizeStr;
                if (bytes >= 1073741824) sizeStr = (bytes / 1073741824).toFixed(1) + ' GB';
                else if (bytes >= 1048576) sizeStr = (bytes / 1048576).toFixed(1) + ' MB';
                else if (bytes >= 1024) sizeStr = (bytes / 1024).toFixed(1) + ' KB';
                else sizeStr = bytes + ' B';
                document.getElementById('stat-storage').textContent = sizeStr;

                // Update uptime
                const uptime = document.getElementById('uptime');
                if (uptime) {
                    const secs = data.uptime_seconds;
                    const hours = Math.floor(secs / 3600);
                    const mins = Math.floor((secs % 3600) / 60);
                    uptime.textContent = hours + 'h ' + mins + 'm';
                }
            } catch (e) {
                console.error('Dashboard poll failed:', e);
            }
        }, 5000);
    </script>
    "##.to_string()
}
/// Dark theme header with language switcher
fn header_dark(lang: Lang) -> String {
    let (en_class, ru_class, zh_class) = match lang {
        Lang::En => (
            "text-white font-semibold",
            "text-slate-400 hover:text-slate-200",
            "text-slate-400 hover:text-slate-200",
        ),
        Lang::Ru => (
            "text-slate-400 hover:text-slate-200",
            "text-white font-semibold",
            "text-slate-400 hover:text-slate-200",
        ),
        Lang::Zh => (
            "text-slate-400 hover:text-slate-200",
            "text-slate-400 hover:text-slate-200",
            "text-white font-semibold",
        ),
    };

    format!(
        r##"
        <header class="h-16 bg-[#1e293b] border-b border-slate-700 flex items-center justify-between px-4 md:px-6">
            <div class="flex items-center">
                <button onclick="toggleSidebar()" class="md:hidden p-2 -ml-2 mr-2 rounded-lg hover:bg-slate-700">
                    <svg class="w-6 h-6 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
                    </svg>
                </button>
                <div class="md:hidden flex items-center">
                    <span class="font-bold text-slate-200 tracking-tight">N<span class="inline-block w-4 h-4 rounded-full border-2 border-current align-middle mx-px"></span>RA</span>
                </div>
            </div>
            <div class="flex items-center space-x-2 md:space-x-4">
                <!-- Language switcher -->
                <div class="flex items-center border border-slate-600 rounded-lg overflow-hidden text-sm">
                    <button onclick="setLang('en')" class="px-3 py-1.5 {} transition-colors">EN</button>
                    <span class="text-slate-600">|</span>
                    <button onclick="setLang('ru')" class="px-3 py-1.5 {} transition-colors">RU</button>
                    <span class="text-slate-600">|</span>
                    <button onclick="setLang('zh')" class="px-3 py-1.5 {} transition-colors">中文</button>
                </div>
                <a href="https://github.com/getnora-io/nora" target="_blank" class="p-2 text-slate-400 hover:text-slate-200 hover:bg-slate-700 rounded-lg">
                    <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                        <path fill-rule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clip-rule="evenodd"/>
                    </svg>
                </a>
                <a href="/api-docs" class="p-2 text-slate-400 hover:text-slate-200 hover:bg-slate-700 rounded-lg" title="API Docs">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                    </svg>
                </a>
            </div>
        </header>
    "##,
        en_class, ru_class, zh_class
    )
}
/// Simple URL encoding for path components
pub fn encode_uri_component(s: &str) -> String {
    let mut result = String::new();
    for c in s.chars() {
        match c {
            'a'..='z' | 'A'..='Z' | '0'..='9' | '-' | '_' | '.' | '~' => result.push(c),
            _ => {
                for byte in c.to_string().as_bytes() {
                    let _ = write!(result, "%{:02X}", byte);
                }
            }
        }
    }
    result
}
/// HTMX search bar that filters a registry's repo list into `#repo-table-body`.
/// The hierarchical browsers (Maven/Go) embed this so they honour the same
/// search contract as the flat-list pages — `/api/ui/<registry>/search` is a
/// generic handler that works for every registry type.
fn registry_search_bar(registry: &str, placeholder: &str) -> String {
    format!(
        r##"<div class="flex items-center justify-end mb-4">
            <div class="relative w-full md:w-auto">
                <input type="text" placeholder="{placeholder}"
                    class="w-full md:w-auto pl-10 pr-4 py-2 bg-slate-800 border border-slate-600 text-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent placeholder-slate-500"
                    hx-get="/api/ui/{registry}/search" hx-trigger="keyup changed delay:300ms"
                    hx-target="#repo-table-body" name="q">
                <svg class="absolute left-3 top-2.5 h-5 w-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
            </div>
        </div>"##
    )
}
pub fn search(r:&str,p:&str)->String { registry_search_bar(r,p) }
pub fn header(l:Lang)->String { header_dark(l) }
