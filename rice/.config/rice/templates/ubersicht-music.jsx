// rice widget: Noctis now-playing card, bottom-right above the system card. Generated from "{{THEME}}" by rice.sh (RICE-MANAGED).
import { css } from "uebersicht";
// Reads Noctis's Local API (~/Library/Application Support/Noctis/local-api.json). Prints the now-playing JSON,
// then a base64 192px cover (refetched only when the track changes; cached in ~/.local/state/rice/uber-cover.jpg).
// Prints nothing when Noctis is not running.
export const command = `
  F="$HOME/Library/Application Support/Noctis/local-api.json"; S="$HOME/.local/state/rice"; mkdir -p "$S";
  grep -q '"running": *true' "$F" 2>/dev/null || exit 0;
  port=$(grep -o '"port": *[0-9]*' "$F" | grep -o '[0-9]*$'); tok=$(grep -o '"token": *"[^"]*"' "$F" | cut -d'"' -f4);
  np=$(curl -s --max-time 2 -H "Authorization: Bearer $tok" "http://127.0.0.1:$port/api/v1/now-playing") || exit 0;
  [ -n "$np" ] || exit 0;
  printf '%s\\n' "$np" | tr -d '\\n';
  echo;
  key=$(printf '%s' "$np" | grep -o '"trackId":"[^"]*"' | head -n 1);
  if [ "$key" != "$(cat "$S/uber-cover.key" 2>/dev/null)" ]; then
    rm -f "$S/uber-cover.jpg";
    if curl -s --max-time 4 -f -H "Authorization: Bearer $tok" "http://127.0.0.1:$port/api/v1/artwork/current" -o "$S/uber-cover.raw"; then
      sips -Z 192 -s format jpeg "$S/uber-cover.raw" --out "$S/uber-cover.jpg" >/dev/null 2>&1;
    fi;
    printf '%s' "$key" > "$S/uber-cover.key";
  fi;
  [ -f "$S/uber-cover.jpg" ] && base64 -i "$S/uber-cover.jpg" | tr -d '\\n'; true`;
export const refreshFrequency = 3000;
// Sits above the system card: 56px margin + 268px card + 16px gap.
export const className = `
  position: absolute; right: 48px; bottom: 340px; width: 320px;
  font-family: "Maple Mono NF", "JetBrainsMono Nerd Font", Menlo, monospace;
  .card { height: 96px; box-sizing: border-box; padding: 12px; display: flex; align-items: center; gap: 14px;
  background: rgba({{BG_ALT_RGB}}, 0.72); border: 1px solid rgba({{BORDER_RGB}}, 0.8);
  border-radius: 14px; backdrop-filter: blur(24px); -webkit-backdrop-filter: blur(24px);
  box-shadow: 0 8px 28px rgba(0, 0, 0, 0.25); }
  .cover { width: 72px; height: 72px; flex: none; border-radius: 9px; background: {{BG_ALT2}} center / cover no-repeat; }
  .info { flex: 1; min-width: 0; }
  .state { font-size: 10px; letter-spacing: 0.1em; text-transform: uppercase; color: {{ACCENT}}; }
  .title { margin-top: 3px; font-size: 14px; font-weight: 600; color: {{FG}}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .artist, .album { font-size: 11.5px; color: {{FG_DIM}}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .album { color: {{FG_MUTED}}; }
  .bar { margin-top: 8px; height: 4px; background: {{BG_ALT2}}; border-radius: 2px; overflow: hidden; }
  .fill { height: 100%; background: {{ACCENT}}; border-radius: 2px; }
`;
export const render = ({ output }) => {
  const [json, cover] = (output || "").trim().split("\n");
  if (!json) return null;
  let np;
  try { np = JSON.parse(json); } catch (e) { return null; }
  if (!np || !np.title || np.state === "stopped") return null;
  const pct = np.durationMs ? Math.min(100, (100 * (np.positionMs || 0)) / np.durationMs) : 0;
  const artist = (np.artists || []).join(", ");
  const bg = cover ? { backgroundImage: `url(data:image/jpeg;base64,${cover})` } : {};
  return (
    <div className="card">
      <div className="cover" style={bg} />
      <div className="info">
        <div className="state">{np.state === "playing" ? "now playing" : "paused"}</div>
        <div className="title">{np.title}</div>
        <div className="artist">{artist}</div>
        <div className="album">{np.album}</div>
        <div className="bar"><div className="fill" style={{ width: `${pct}%` }} /></div>
      </div>
    </div>
  );
};
