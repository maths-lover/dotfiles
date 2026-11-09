// rice widget: cpu / memory / disk bars, bottom-right. Generated from "{{THEME}}" by rice.sh (RICE-MANAGED).
import { css } from "uebersicht";
// One shell line prints "cpu|mem|disk" as integer percentages.
export const command = `
  cpu=$(top -l 1 -n 0 | awk '/CPU usage/ {gsub("%","",$3); printf "%d", $3}');
  mem=$(vm_stat | awk '/Pages (active|wired down|occupied by compressor)/ {gsub("\\\\.","",$NF); u+=$NF} END {printf "%d", u*16384*100/'$(sysctl -n hw.memsize)'}');
  disk=$(df -H / | awk 'NR==2 {gsub("%","",$5); print $5}');
  echo "$cpu|$mem|$disk"`;
export const refreshFrequency = 5000;
export const className = `
  position: absolute; right: 48px; bottom: 56px; width: 260px;
  font-family: "Maple Mono NF", "JetBrainsMono Nerd Font", Menlo, monospace;
  font-size: 13px; color: {{FG_DIM}};
  .row { display: flex; align-items: center; gap: 12px; margin-top: 10px; }
  .label { width: 40px; text-transform: lowercase; }
  .bar { flex: 1; height: 4px; background: {{BG_ALT2}}; border-radius: 2px; overflow: hidden; }
  .fill { height: 100%; background: {{ACCENT}}; border-radius: 2px; }
  .val { width: 40px; text-align: right; color: {{FG}}; }
`;
const Row = ({ label, value }) => (
  <div className="row"><span className="label">{label}</span>
    <div className="bar"><div className="fill" style={{ width: `${Math.min(100, value)}%` }} /></div>
    <span className="val">{value}%</span></div>
);
export const render = ({ output }) => {
  const [cpu, mem, disk] = (output || "0|0|0").trim().split("|").map((n) => parseInt(n, 10) || 0);
  return (<div><Row label="cpu" value={cpu} /><Row label="mem" value={mem} /><Row label="disk" value={disk} /></div>);
};
