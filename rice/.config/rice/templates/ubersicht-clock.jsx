// rice widget: big clock + calendar card, bottom-left. Generated from "{{THEME}}" by rice.sh (RICE-MANAGED).
import { css } from "uebersicht";
// One line: "HH:MM|Weekday|DD Month YYYY|ISO week|hour".
export const command = "date '+%H:%M|%A|%d %B %Y|%V|%H'";
export const refreshFrequency = 10000;
export const className = `
  position: absolute; left: 48px; bottom: 56px;
  font-family: "Maple Mono NF", "JetBrainsMono Nerd Font", Menlo, monospace;
  color: {{FG}}; text-shadow: 0 2px 18px {{BG}};
  .cal {
    width: 252px; margin-bottom: 28px; padding: 14px 16px 12px; box-sizing: border-box;
    background: rgba({{BG_ALT_RGB}}, 0.72); border: 1px solid rgba({{BORDER_RGB}}, 0.8);
    border-radius: 14px; backdrop-filter: blur(24px); -webkit-backdrop-filter: blur(24px);
    text-shadow: none; box-shadow: 0 8px 28px rgba(0, 0, 0, 0.25);
  }
  .month { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 12px; letter-spacing: 0.08em; text-transform: uppercase; color: {{FG_DIM}}; }
  .month b { font-weight: 600; color: {{FG}}; }
  .grid { display: grid; grid-template-columns: repeat(7, 1fr); row-gap: 2px; font-size: 12px; text-align: center; }
  .dow { color: {{FG_MUTED}}; font-size: 10px; padding-bottom: 4px; }
  .d { height: 24px; line-height: 24px; color: {{FG_DIM}}; }
  .d.today { color: {{BG}}; background: {{ACCENT}}; border-radius: 7px; font-weight: 700; }
  .time { font-size: 104px; font-weight: 200; line-height: 1; letter-spacing: -0.05em; color: {{FG}}; }
  .rule { width: 56px; height: 2px; margin: 14px 0 12px; background: {{ACCENT}}; border-radius: 1px; }
  .day { font-size: 22px; font-weight: 500; color: {{ACCENT}}; letter-spacing: 0.02em; }
  .date { margin-top: 4px; font-size: 16px; color: {{FG_DIM}}; }
  .sub { margin-top: 10px; font-size: 12px; letter-spacing: 0.06em; color: {{FG_MUTED}}; }
`;
const DOW = ["M", "T", "W", "T", "F", "S", "S"];
const greeting = (h) => (h < 5 ? "burning the midnight oil" : h < 12 ? "good morning" : h < 18 ? "good afternoon" : "good evening");
const Calendar = () => {
  const now = new Date();
  const y = now.getFullYear(), m = now.getMonth(), today = now.getDate();
  const lead = (new Date(y, m, 1).getDay() + 6) % 7; // Monday-first
  const days = new Date(y, m + 1, 0).getDate();
  const cells = [];
  for (let i = 0; i < lead; i++) cells.push(<div className="d" key={`b${i}`} />);
  for (let d = 1; d <= days; d++) cells.push(<div className={d === today ? "d today" : "d"} key={d}>{d}</div>);
  const name = now.toLocaleString("en-GB", { month: "long" });
  return (
    <div className="cal">
      <div className="month"><b>{name}</b><span>{y}</span></div>
      <div className="grid">
        {DOW.map((x, i) => <div className="dow" key={`w${i}`}>{x}</div>)}
        {cells}
      </div>
    </div>
  );
};
export const render = ({ output }) => {
  const [time, day, date, week, hour] = (output || "||||").trim().split("|");
  return (
    <div>
      <Calendar />
      <div className="time">{time}</div>
      <div className="rule" />
      <div className="day">{day}</div>
      <div className="date">{date}</div>
      <div className="sub">{greeting(parseInt(hour, 10) || 0)} · week {week}</div>
    </div>
  );
};
