// rice widget: system card (cpu/mem/disk, cpu sparkline, network, uptime, load), bottom-right. Generated from "{{THEME}}" by rice.sh (RICE-MANAGED).
import { css } from "uebersicht";
// One shell script prints "cpu|mem|disk|rx B/s|tx B/s|uptime s|load1 load5 load15|hist,csv".
// State: ~/.local/state/rice/cpu.hist (last 30 cpu samples), uber-net.prev ("epoch rx tx").
export const command = `
  S="$HOME/.local/state/rice"; mkdir -p "$S";
  cpu=$(top -l 1 -n 0 | awk '/CPU usage/ {printf "%d", $3+$5}');
  mem=$(vm_stat | awk '/Pages (active|wired down|occupied by compressor)/ {sub(/[.]/,"",$NF); u+=$NF} END {printf "%d", u*16384*100/'$(sysctl -n hw.memsize)'}');
  disk=$(df -H / | awk 'NR==2 {gsub("%","",$5); print $5}');
  echo "$cpu" >> "$S/cpu.hist"; tail -n 30 "$S/cpu.hist" > "$S/cpu.hist.$$" && mv "$S/cpu.hist.$$" "$S/cpu.hist";
  now=$(date +%s);
  set -- $(netstat -ib | awk '/^en[0-9]+ .*<Link#/ {rx+=$(NF-4); tx+=$(NF-1)} END {printf "%d %d", rx, tx}');
  rx=$1; tx=$2; drx=0; dtx=0;
  if [ -f "$S/uber-net.prev" ]; then
    read pt prx ptx < "$S/uber-net.prev";
    dt=$((now-pt));
    if [ "$dt" -gt 0 ]; then drx=$(( (rx-prx)/dt )); dtx=$(( (tx-ptx)/dt )); fi;
    [ "$drx" -lt 0 ] && drx=0; [ "$dtx" -lt 0 ] && dtx=0;
  fi;
  echo "$now $rx $tx" > "$S/uber-net.prev";
  boot=$(sysctl -n kern.boottime | awk '{gsub(",","",$4); print $4}');
  load=$(sysctl -n vm.loadavg | awk '{print $2, $3, $4}');
  echo "$cpu|$mem|$disk|$drx|$dtx|$((now-boot))|$load|$(tr '\\n' ',' < "$S/cpu.hist")"`;
export const refreshFrequency = 5000;
export const className = `
  position: absolute; right: 48px; bottom: 56px; width: 320px; height: 268px; box-sizing: border-box;
  padding: 16px 18px;
  .in { height: 100%; display: flex; flex-direction: column; justify-content: space-between; }
  font-family: "Maple Mono NF", "JetBrainsMono Nerd Font", Menlo, monospace;
  font-size: 12px; color: {{FG_DIM}};
  background: rgba({{BG_ALT_RGB}}, 0.72); border: 1px solid rgba({{BORDER_RGB}}, 0.8);
  border-radius: 14px; backdrop-filter: blur(24px); -webkit-backdrop-filter: blur(24px);
  box-shadow: 0 8px 28px rgba(0, 0, 0, 0.25);
  .head { display: flex; justify-content: space-between; font-size: 11px; letter-spacing: 0.1em; text-transform: uppercase; color: {{FG_MUTED}}; }
  .head b { font-weight: 600; color: {{ACCENT}}; }
  .row { display: flex; align-items: center; gap: 10px; }
  .label { width: 34px; text-transform: lowercase; }
  .bar { flex: 1; height: 5px; background: {{BG_ALT2}}; border-radius: 3px; overflow: hidden; }
  .fill { height: 100%; background: {{ACCENT}}; border-radius: 3px; }
  .fill.hot { background: {{C1}}; }
  .fill.warm { background: {{C3}}; }
  .val { width: 38px; text-align: right; color: {{FG}}; }
  .spark { display: block; width: 100%; height: 44px; }
  .meta { display: flex; justify-content: space-between; }
  .meta span b { font-weight: 500; color: {{FG}}; }
  .up { color: {{C2}}; } .down { color: {{C4}}; }
`;
const Row = ({ label, value }) => (
  <div className="row"><span className="label">{label}</span>
    <div className="bar"><div className={value >= 90 ? "fill hot" : value >= 75 ? "fill warm" : "fill"} style={{ width: `${Math.min(100, value)}%` }} /></div>
    <span className="val">{value}%</span></div>
);
const Spark = ({ data }) => {
  const W = 284, H = 44, n = 30;
  const pts = data.slice(-n).map((v, i, a) => [(i * W) / (n - 1) + (n - a.length) * (W / (n - 1)), H - 2 - (Math.min(100, v) / 100) * (H - 4)]);
  if (pts.length < 2) return <svg className="spark" viewBox={`0 0 ${W} ${H}`} />;
  const line = pts.map((p, i) => `${i ? "L" : "M"}${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");
  const area = `${line} L${pts[pts.length - 1][0].toFixed(1)},${H} L${pts[0][0].toFixed(1)},${H} Z`;
  return (
    <svg className="spark" viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none">
      <path d={area} fill="{{ACCENT}}" fillOpacity="0.16" />
      <path d={line} fill="none" stroke="{{ACCENT}}" strokeWidth="1.6" strokeLinejoin="round" strokeLinecap="round" vectorEffect="non-scaling-stroke" />
    </svg>
  );
};
const rate = (b) => (b >= 1048576 ? `${(b / 1048576).toFixed(1)}M` : b >= 1024 ? `${Math.round(b / 1024)}K` : `${b}B`);
const uptime = (s) => { const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60); return d ? `${d}d ${h}h` : h ? `${h}h ${m}m` : `${m}m`; };
export const render = ({ output }) => {
  const p = (output || "0|0|0|0|0|0|0 0 0|").trim().split("|");
  const [cpu, mem, disk, rx, tx, up] = p.slice(0, 6).map((n) => parseInt(n, 10) || 0);
  const load = (p[6] || "").trim().split(/\s+/).join("  ");
  const hist = (p[7] || "").split(",").filter((x) => x !== "").map((x) => parseInt(x, 10) || 0);
  return (
    <div className="in">
      <div className="head"><b>system</b><span>up {uptime(up)}</span></div>
      <Row label="cpu" value={cpu} />
      <Spark data={hist} />
      <Row label="mem" value={mem} />
      <Row label="disk" value={disk} />
      <div className="meta"><span className="down">{"↓"} <b>{rate(rx)}/s</b></span><span className="up">{"↑"} <b>{rate(tx)}/s</b></span></div>
      <div className="meta"><span>load</span><span><b>{load}</b></span></div>
    </div>
  );
};
