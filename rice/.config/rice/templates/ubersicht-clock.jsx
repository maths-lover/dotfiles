// rice widget: big clock + date, bottom-left. Generated from "{{THEME}}" by rice.sh (RICE-MANAGED).
import { css } from "uebersicht";
export const command = "date '+%H:%M|%A, %d %B'";
export const refreshFrequency = 10000;
export const className = `
  position: absolute; left: 48px; bottom: 56px;
  font-family: "Maple Mono NF", "JetBrainsMono Nerd Font", Menlo, monospace;
  color: {{FG}}; text-shadow: 0 2px 18px {{BG}};
  .time { font-size: 96px; font-weight: 300; line-height: 1; letter-spacing: -0.04em; color: {{ACCENT}}; }
  .date { margin-top: 8px; font-size: 20px; color: {{FG_DIM}}; }
`;
export const render = ({ output }) => {
  const [time, date] = (output || "|").trim().split("|");
  return (<div><div className="time">{time}</div><div className="date">{date}</div></div>);
};
