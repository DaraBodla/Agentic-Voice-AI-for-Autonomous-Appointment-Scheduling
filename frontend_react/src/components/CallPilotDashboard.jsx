import { useState, useEffect, useRef } from "react";

// ─── Design Tokens ──────────────────────────────────────────────────────────
const T = {
  bg: "#06060C", bg1: "#0C0D15", bg2: "#13141F", bg3: "#1A1B2A",
  border: "#222338", borderActive: "#3D3E5C",
  text: "#E2E2F0", textDim: "#8B8BA7", textMuted: "#55556E",
  accent: "#7C5CFC", accentGlow: "#7C5CFC44", accentLight: "#A594FD",
  accentDim: "rgba(124,92,252,0.12)",
  green: "#00D68F", greenDim: "rgba(0,214,143,0.12)",
  red: "#FF5C8A", redDim: "rgba(255,92,138,0.12)",
  orange: "#FFB347", orangeDim: "rgba(255,179,71,0.12)",
  blue: "#5CB8FF", blueDim: "rgba(92,184,255,0.12)",
  radius: "10px", radiusLg: "14px",
};

const font = `'DM Sans', -apple-system, sans-serif`;
const mono = `'JetBrains Mono', 'Fira Code', monospace`;

// ─── Global Styles ──────────────────────────────────────────────────────────
const globalCSS = `
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;1,9..40,400&family=JetBrains+Mono:wght@400;500;600&display=swap');
*{margin:0;padding:0;box-sizing:border-box;}
html{font-size:14px;}
body{background:${T.bg};color:${T.text};font-family:${font};-webkit-font-smoothing:antialiased;}
::-webkit-scrollbar{width:6px;height:6px;}
::-webkit-scrollbar-track{background:transparent;}
::-webkit-scrollbar-thumb{background:${T.border};border-radius:3px;}
::selection{background:${T.accent};color:#fff;}
@keyframes fadeUp{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
@keyframes fadeIn{from{opacity:0}to{opacity:1}}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
@keyframes slideIn{from{opacity:0;transform:translateX(-8px)}to{opacity:1;transform:translateX(0)}}
@keyframes shimmer{0%{background-position:-200% 0}100%{background-position:200% 0}}
@keyframes glow{0%,100%{box-shadow:0 0 8px ${T.accentGlow}}50%{box-shadow:0 0 20px ${T.accentGlow}}}
.anim-up{animation:fadeUp .4s ease both}
.anim-in{animation:fadeIn .3s ease both}
.skeleton{background:linear-gradient(90deg,${T.bg2} 25%,${T.bg3} 50%,${T.bg2} 75%);background-size:200% 100%;animation:shimmer 1.5s infinite;border-radius:6px;}
`;

// ─── Icons (inline SVG) ─────────────────────────────────────────────────────
const icons = {
  booking: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6A19.79 19.79 0 012.12 4.18 2 2 0 014.11 2h3a2 2 0 012 1.72c.13.81.37 1.61.7 2.36a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.75.33 1.55.57 2.36.7A2 2 0 0122 16.92z"/></svg>,
  campaigns: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M12 20V10"/><path d="M18 20V4"/><path d="M6 20v-4"/></svg>,
  history: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>,
  providers: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>,
  settings: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="3"/><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/></svg>,
  chevDown: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="6 9 12 15 18 9"/></svg>,
  check: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="20 6 9 17 4 12"/></svg>,
  x: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>,
  bell: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>,
  play: <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><polygon points="5 3 19 12 5 21 5 3"/></svg>,
  stop: <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><rect x="4" y="4" width="16" height="16" rx="2"/></svg>,
  map: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>,
  star: <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor" stroke="none"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>,
  calendar: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>,
};

// ─── Shared Components ──────────────────────────────────────────────────────
const Pill = ({ children, active, color, onClick, style }) => (
  <span onClick={onClick} style={{
    display: "inline-flex", alignItems: "center", gap: 4, padding: "4px 10px",
    borderRadius: 20, fontSize: 11, fontWeight: 600, letterSpacing: .5, cursor: onClick ? "pointer" : "default",
    background: active ? (color || T.accent) : T.bg2,
    color: active ? "#fff" : T.textDim,
    border: `1px solid ${active ? (color || T.accent) : T.border}`,
    transition: "all .2s", ...style,
  }}>{children}</span>
);

const Badge = ({ children, color = T.green, bg }) => (
  <span style={{
    display: "inline-flex", alignItems: "center", gap: 3, padding: "2px 8px",
    borderRadius: 4, fontSize: 10, fontWeight: 600, fontFamily: mono,
    background: bg || (color + "1A"), color,
  }}>{children}</span>
);

const Card = ({ children, style, glow, onClick }) => (
  <div onClick={onClick} style={{
    background: T.bg1, border: `1px solid ${glow ? T.accent : T.border}`,
    borderRadius: T.radiusLg, padding: 20, transition: "all .25s",
    boxShadow: glow ? `0 0 24px ${T.accentGlow}` : "none",
    cursor: onClick ? "pointer" : "default", ...style,
  }}>{children}</div>
);

const SectionTitle = ({ children, sub }) => (
  <div style={{ marginBottom: 14 }}>
    <div style={{ fontSize: 12, fontWeight: 600, letterSpacing: 1.2, color: T.textDim, textTransform: "uppercase" }}>{children}</div>
    {sub && <div style={{ fontSize: 12, color: T.textMuted, marginTop: 2 }}>{sub}</div>}
  </div>
);

const StatusDot = ({ status }) => {
  const colors = { queued: T.textMuted, calling: T.accent, connected: T.blue, negotiating: T.orange, done: T.green, failed: T.red };
  const c = colors[status] || T.textMuted;
  const pulse = status === "calling" || status === "connected" || status === "negotiating";
  return <span style={{
    width: 8, height: 8, borderRadius: "50%", background: c, display: "inline-block",
    boxShadow: pulse ? `0 0 8px ${c}` : "none",
    animation: pulse ? "pulse 1.5s infinite" : "none",
  }} />;
};

const Btn = ({ children, primary, danger, small, disabled, onClick, style }) => (
  <button disabled={disabled} onClick={onClick} style={{
    display: "inline-flex", alignItems: "center", gap: 6,
    padding: small ? "6px 14px" : "10px 22px",
    borderRadius: 8, border: "none", cursor: disabled ? "not-allowed" : "pointer",
    fontSize: small ? 12 : 13, fontWeight: 600, fontFamily: font,
    background: danger ? T.red : primary ? T.accent : T.bg3,
    color: primary || danger ? "#fff" : T.textDim,
    opacity: disabled ? .5 : 1, transition: "all .2s", ...style,
  }}>{children}</button>
);

const Input = ({ label, placeholder, icon, mono: useMono, value, onChange, style }) => (
  <div style={{ ...style }}>
    {label && <div style={{ fontSize: 11, fontWeight: 600, color: T.textDim, letterSpacing: .8, marginBottom: 6, textTransform: "uppercase" }}>{label}</div>}
    <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "9px 14px", background: T.bg2, border: `1px solid ${T.border}`, borderRadius: 8 }}>
      {icon && <span style={{ color: T.textMuted, display: "flex" }}>{icon}</span>}
      <input placeholder={placeholder} value={value} onChange={onChange} style={{
        background: "transparent", border: "none", outline: "none", color: T.text, width: "100%",
        fontSize: 13, fontFamily: useMono ? mono : font,
      }} />
    </div>
  </div>
);

const Slider = ({ label, value, onChange, color }) => (
  <div style={{ marginBottom: 14 }}>
    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
      <span style={{ fontSize: 12, color: T.textDim }}>{label}</span>
      <span style={{ fontSize: 12, fontFamily: mono, color: color || T.accentLight }}>{value}%</span>
    </div>
    <input type="range" min={0} max={100} value={value} onChange={e => onChange(+e.target.value)}
      style={{ width: "100%", accentColor: color || T.accent, height: 3 }} />
  </div>
);

const Toggle = ({ checked, onChange, label }) => (
  <label style={{ display: "flex", alignItems: "center", gap: 10, cursor: "pointer" }}>
    <div onClick={onChange} style={{
      width: 36, height: 20, borderRadius: 10, background: checked ? T.accent : T.bg3,
      border: `1px solid ${checked ? T.accent : T.border}`, position: "relative", transition: "all .2s", flexShrink: 0,
    }}>
      <div style={{
        width: 14, height: 14, borderRadius: "50%", background: "#fff", position: "absolute", top: 2,
        left: checked ? 19 : 3, transition: "left .2s",
      }} />
    </div>
    <span style={{ fontSize: 13, color: T.text }}>{label}</span>
  </label>
);

// ─── Sidebar ────────────────────────────────────────────────────────────────
const Sidebar = ({ active, onNav }) => {
  const items = [
    { id: "booking", icon: icons.booking, label: "New Booking" },
    { id: "campaigns", icon: icons.campaigns, label: "Active Campaigns" },
    { id: "history", icon: icons.history, label: "History" },
    { id: "providers", icon: icons.providers, label: "Providers" },
    { id: "settings", icon: icons.settings, label: "Settings" },
  ];
  return (
    <div style={{
      width: 220, background: T.bg1, borderRight: `1px solid ${T.border}`,
      display: "flex", flexDirection: "column", height: "100vh", flexShrink: 0,
    }}>
      {/* Logo */}
      <div style={{ padding: "20px 20px 24px", display: "flex", alignItems: "center", gap: 10 }}>
        <div style={{
          width: 34, height: 34, borderRadius: 10,
          background: `linear-gradient(135deg, ${T.accent}, ${T.accentLight})`,
          display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16,
        }}>📞</div>
        <div>
          <span style={{ fontWeight: 700, fontSize: 17, color: T.text }}>Call</span>
          <span style={{ fontWeight: 700, fontSize: 17, color: T.accentLight }}>Pilot</span>
        </div>
      </div>

      {/* Nav */}
      <nav style={{ flex: 1, padding: "0 10px" }}>
        {items.map(it => (
          <div key={it.id} onClick={() => onNav(it.id)} style={{
            display: "flex", alignItems: "center", gap: 10, padding: "10px 12px",
            borderRadius: 8, marginBottom: 2, cursor: "pointer", transition: "all .15s",
            background: active === it.id ? T.accentDim : "transparent",
            color: active === it.id ? T.accentLight : T.textDim,
            fontWeight: active === it.id ? 600 : 400, fontSize: 13,
          }}>
            {it.icon} {it.label}
          </div>
        ))}
      </nav>

      {/* Integration status */}
      <div style={{ padding: 16, borderTop: `1px solid ${T.border}` }}>
        <div style={{ fontSize: 10, fontWeight: 600, color: T.textMuted, letterSpacing: 1, marginBottom: 8, textTransform: "uppercase" }}>Integrations</div>
        {["OpenAI", "ElevenLabs", "Twilio", "Google Calendar", "Google Places"].map((s, i) => (
          <div key={s} style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 11, color: T.textDim, marginBottom: 4 }}>
            <span style={{ color: i < 3 ? T.green : T.red, fontSize: 10 }}>{i < 3 ? "●" : "●"}</span> {s}
            <span style={{ marginLeft: "auto", fontSize: 9, fontFamily: mono, color: i < 3 ? T.green : T.textMuted }}>{i < 3 ? "OK" : "—"}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

// ─── Topbar ─────────────────────────────────────────────────────────────────
const Topbar = ({ mode, setMode }) => (
  <div style={{
    height: 52, background: T.bg1, borderBottom: `1px solid ${T.border}`,
    display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 24px",
  }}>
    <div />
    <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
      {/* Mode toggle */}
      <div style={{
        display: "flex", borderRadius: 20, overflow: "hidden", border: `1px solid ${T.border}`,
      }}>
        {["DEMO", "LIVE"].map(m => (
          <div key={m} onClick={() => setMode(m)} style={{
            padding: "5px 16px", fontSize: 11, fontWeight: 600, letterSpacing: .5, cursor: "pointer",
            background: mode === m ? (m === "LIVE" ? T.green : T.accent) : "transparent",
            color: mode === m ? "#fff" : T.textMuted, transition: "all .2s",
          }}>{m === "DEMO" ? "● " : "⚡ "}{m}</div>
        ))}
      </div>

      {/* Bell */}
      <div style={{ position: "relative", color: T.textDim, cursor: "pointer" }}>
        {icons.bell}
        <span style={{ position: "absolute", top: -2, right: -2, width: 7, height: 7, borderRadius: "50%", background: T.red }} />
      </div>

      {/* Avatar */}
      <div style={{
        width: 32, height: 32, borderRadius: "50%", background: `linear-gradient(135deg, ${T.accent}, ${T.blue})`,
        display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 700, color: "#fff", cursor: "pointer",
      }}>D</div>
    </div>
  </div>
);

// ─── Page: New Booking ──────────────────────────────────────────────────────
const BookingPage = ({ onStart }) => {
  const [service, setService] = useState("dentist");
  const [timeChips, setTimeChips] = useState(["morning", "afternoon"]);
  const [strategy, setStrategy] = useState("swarm");
  const [maxProviders, setMaxProviders] = useState(5);
  const [weights, setWeights] = useState({ earliest: 40, rating: 30, distance: 30 });
  const [scriptOpen, setScriptOpen] = useState(false);

  const services = [
    { id: "dentist", icon: "🦷", label: "Dentist" },
    { id: "mechanic", icon: "🔧", label: "Mechanic" },
    { id: "salon", icon: "💇", label: "Salon" },
    { id: "other", icon: "📋", label: "Other" },
  ];

  const setWeight = (key, val) => {
    const remaining = 100 - val;
    const others = Object.keys(weights).filter(k => k !== key);
    const otherSum = others.reduce((s, k) => s + weights[k], 0);
    const newW = { ...weights, [key]: val };
    others.forEach(k => { newW[k] = otherSum > 0 ? Math.round(weights[k] / otherSum * remaining) : Math.round(remaining / others.length); });
    const total = Object.values(newW).reduce((a, b) => a + b, 0);
    if (total !== 100) newW[others[0]] += 100 - total;
    setWeights(newW);
  };

  return (
    <div style={{ padding: 28, maxWidth: 900, animation: "fadeUp .5s ease" }}>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 28 }}>
        <div>
          <h1 style={{ fontSize: 26, fontWeight: 700, marginBottom: 6 }}>Book an Appointment</h1>
          <p style={{ color: T.textDim, fontSize: 14, lineHeight: 1.6, maxWidth: 480 }}>
            Tell CallPilot what you need. Our AI agent will call providers, negotiate availability, and find the best option.
          </p>
        </div>
        {/* Campaign Plan Summary */}
        <Card style={{ width: 200, padding: 14, background: T.bg2, flexShrink: 0, marginLeft: 20 }}>
          <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: 1, color: T.textMuted, marginBottom: 10, textTransform: "uppercase" }}>Campaign Plan</div>
          {[
            ["Providers", maxProviders],
            ["Strategy", strategy === "swarm" ? "Swarm ⚡" : "Single"],
            ["Earliest", `${weights.earliest}%`],
            ["Rating", `${weights.rating}%`],
            ["Distance", `${weights.distance}%`],
          ].map(([k, v]) => (
            <div key={k} style={{ display: "flex", justifyContent: "space-between", fontSize: 12, marginBottom: 4 }}>
              <span style={{ color: T.textDim }}>{k}</span>
              <span style={{ fontFamily: mono, color: T.accentLight, fontWeight: 600 }}>{v}</span>
            </div>
          ))}
        </Card>
      </div>

      {/* Service Selection */}
      <SectionTitle sub="We'll find providers near your location.">Service Type</SectionTitle>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginBottom: 24 }}>
        {services.map(s => (
          <Card key={s.id} onClick={() => setService(s.id)} glow={service === s.id}
            style={{ padding: 16, textAlign: "center", cursor: "pointer", background: service === s.id ? T.accentDim : T.bg2 }}>
            <div style={{ fontSize: 28, marginBottom: 6 }}>{s.icon}</div>
            <div style={{ fontSize: 13, fontWeight: service === s.id ? 600 : 400, color: service === s.id ? T.accentLight : T.textDim }}>{s.label}</div>
          </Card>
        ))}
      </div>

      {/* Time Preferences */}
      <SectionTitle sub="When works best for you?">Time Preferences</SectionTitle>
      <Card style={{ marginBottom: 20, padding: 18 }}>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14, marginBottom: 16 }}>
          <Input label="Start Date" placeholder="Feb 8, 2026" icon={icons.calendar} />
          <Input label="End Date" placeholder="Feb 15, 2026" icon={icons.calendar} />
        </div>
        <div style={{ marginBottom: 14 }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: T.textDim, letterSpacing: .8, marginBottom: 8, textTransform: "uppercase" }}>Time of Day</div>
          <div style={{ display: "flex", gap: 8 }}>
            {["morning", "afternoon", "evening"].map(t => (
              <Pill key={t} active={timeChips.includes(t)} color={T.accent}
                onClick={() => setTimeChips(p => p.includes(t) ? p.filter(x => x !== t) : [...p, t])}>
                {t === "morning" ? "🌅" : t === "afternoon" ? "☀️" : "🌙"} {t.charAt(0).toUpperCase() + t.slice(1)}
              </Pill>
            ))}
          </div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14, marginBottom: 14 }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: T.textDim, letterSpacing: .8, marginBottom: 6, textTransform: "uppercase" }}>Duration</div>
            <div style={{ display: "flex", gap: 6 }}>
              {["15m", "30m", "45m", "60m"].map(d => <Pill key={d} active={d === "30m"}>{d}</Pill>)}
            </div>
          </div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: T.textDim, letterSpacing: .8, marginBottom: 6, textTransform: "uppercase" }}>Flexibility</div>
            <input type="range" min={0} max={100} defaultValue={50} style={{ width: "100%", accentColor: T.accent }} />
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: 10, color: T.textMuted }}><span>Strict</span><span>Flexible</span></div>
          </div>
        </div>
        <Badge color={T.green}>{icons.check} Calendar conflicts will be avoided</Badge>
      </Card>

      {/* Location */}
      <SectionTitle>Location</SectionTitle>
      <Card style={{ marginBottom: 20, padding: 18 }}>
        <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: 14, marginBottom: 12 }}>
          <Input placeholder="Enter address or use my location" icon={icons.map} />
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: T.textDim, letterSpacing: .8, marginBottom: 6, textTransform: "uppercase" }}>Radius</div>
            <div style={{ display: "flex", gap: 6 }}>
              {["2km", "5km", "10km"].map(r => <Pill key={r} active={r === "5km"}>{r}</Pill>)}
            </div>
          </div>
        </div>
        <div style={{ display: "flex", gap: 6 }}>
          <Pill active>🏠 Home</Pill>
          <Pill>🏢 Work</Pill>
          <Pill>📍 Custom</Pill>
        </div>
      </Card>

      {/* Calling Strategy */}
      <SectionTitle sub="How should the AI agent call providers?">Calling Strategy</SectionTitle>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 20 }}>
        <Card onClick={() => setStrategy("swarm")} glow={strategy === "swarm"}
          style={{ cursor: "pointer", background: strategy === "swarm" ? T.accentDim : T.bg2 }}>
          <div style={{ fontSize: 22, marginBottom: 6 }}>🐝</div>
          <div style={{ fontSize: 15, fontWeight: 600, color: strategy === "swarm" ? T.accentLight : T.text }}>Swarm Mode</div>
          <div style={{ fontSize: 12, color: T.textDim, marginTop: 4 }}>Call all providers simultaneously. Fastest results.</div>
          <Badge color={T.accent} style={{ marginTop: 8 }}>⚡ Parallel</Badge>
        </Card>
        <Card onClick={() => setStrategy("single")} glow={strategy === "single"}
          style={{ cursor: "pointer", background: strategy === "single" ? T.accentDim : T.bg2 }}>
          <div style={{ fontSize: 22, marginBottom: 6 }}>📞</div>
          <div style={{ fontSize: 15, fontWeight: 600, color: strategy === "single" ? T.accentLight : T.text }}>Single Call</div>
          <div style={{ fontSize: 12, color: T.textDim, marginTop: 4 }}>Call one at a time. Stops at first success.</div>
          <Badge color={T.blue} style={{ marginTop: 8 }}>Sequential</Badge>
        </Card>
      </div>

      {/* Provider count */}
      <div style={{ display: "flex", gap: 10, marginBottom: 20, alignItems: "center" }}>
        <span style={{ fontSize: 12, color: T.textDim, whiteSpace: "nowrap" }}>Max providers:</span>
        {[3, 5, 8, 10, 15].map(n => (
          <Pill key={n} active={maxProviders === n} onClick={() => setMaxProviders(n)}>{n}</Pill>
        ))}
      </div>

      {/* Ranking Weights */}
      <SectionTitle sub="How should results be ranked?">Ranking Weights</SectionTitle>
      <Card style={{ marginBottom: 20, padding: 18 }}>
        <div style={{ display: "flex", gap: 6, marginBottom: 16 }}>
          {[
            { label: "Balanced", w: { earliest: 34, rating: 33, distance: 33 } },
            { label: "Fastest", w: { earliest: 60, rating: 20, distance: 20 } },
            { label: "Best Rated", w: { earliest: 20, rating: 60, distance: 20 } },
            { label: "Closest", w: { earliest: 20, rating: 20, distance: 60 } },
          ].map(p => (
            <Pill key={p.label} onClick={() => setWeights(p.w)}
              active={weights.earliest === p.w.earliest && weights.rating === p.w.rating}>
              {p.label}
            </Pill>
          ))}
        </div>
        <Slider label="⏰ Earliest Available" value={weights.earliest} onChange={v => setWeight("earliest", v)} />
        <Slider label="⭐ Provider Rating" value={weights.rating} onChange={v => setWeight("rating", v)} color={T.orange} />
        <Slider label="📍 Proximity" value={weights.distance} onChange={v => setWeight("distance", v)} color={T.green} />
      </Card>

      {/* Agent Script Collapsible */}
      <div onClick={() => setScriptOpen(!scriptOpen)} style={{
        display: "flex", alignItems: "center", gap: 8, cursor: "pointer", marginBottom: 12,
        fontSize: 12, color: T.textDim, fontWeight: 500,
      }}>
        <span style={{ transform: scriptOpen ? "rotate(180deg)" : "rotate(0)", transition: "transform .2s", display: "flex" }}>{icons.chevDown}</span>
        Agent Script & Negotiation
      </div>
      {scriptOpen && (
        <Card style={{ marginBottom: 20, padding: 16, animation: "fadeUp .3s ease" }}>
          <div style={{ fontFamily: mono, fontSize: 12, color: T.textDim, lineHeight: 1.7, padding: 12, background: T.bg, borderRadius: 8, marginBottom: 12 }}>
            "Hi, I'm calling on behalf of my client to schedule a {service} appointment.
            Do you have any availability this week? I'm flexible on timing..."
          </div>
          <div style={{ display: "flex", gap: 6, marginBottom: 12 }}>
            <span style={{ fontSize: 11, color: T.textDim, alignSelf: "center" }}>Tone:</span>
            <Pill active>Polite</Pill><Pill>Firm</Pill><Pill>Minimal</Pill>
          </div>
          <div style={{ fontSize: 11, color: T.textMuted }}>
            Agent will ask: ✓ availability ✓ duration ✓ booking method ✓ new patient forms ✓ insurance
          </div>
        </Card>
      )}

      {/* CTA */}
      <div style={{ display: "flex", gap: 12, alignItems: "center", paddingTop: 8 }}>
        <Btn primary onClick={onStart}>{icons.play} Start Campaign</Btn>
        <Btn>Save Template</Btn>
      </div>
    </div>
  );
};

// ─── Page: Campaign Monitor ─────────────────────────────────────────────────
const MonitorPage = ({ onComplete }) => {
  const [calls, setCalls] = useState([
    { id: 1, name: "Bright Smile Dental", rating: 4.7, dist: "12 min", status: "done", slots: 2, conf: 94, transcript: "Receptionist: We have openings Tuesday and Thursday.\nAgent: Tuesday at 10am works perfectly." },
    { id: 2, name: "City Dental Care", rating: 4.3, dist: "17 min", status: "negotiating", slots: 1, conf: 78, transcript: "Agent: Any availability this week?\nReceptionist: Let me check..." },
    { id: 3, name: "Premier Associates", rating: 4.9, dist: "23 min", status: "calling", slots: 0, conf: 0, transcript: "" },
    { id: 4, name: "Affordable Dental", rating: 4.1, dist: "8 min", status: "done", slots: 3, conf: 91, transcript: "Receptionist: We have multiple openings.\nAgent: Great, what times work?" },
    { id: 5, name: "Harmony Wellness", rating: 4.5, dist: "20 min", status: "failed", slots: 0, conf: 0, transcript: "No answer after 3 rings." },
  ]);

  const [expandedId, setExpandedId] = useState(null);
  const [elapsed, setElapsed] = useState(12);

  useEffect(() => {
    const t = setInterval(() => setElapsed(e => e + 1), 1000);
    return () => clearInterval(t);
  }, []);

  const logs = [
    { time: "00:01", event: "Campaign started", detail: "5 providers queued", color: T.accent },
    { time: "00:02", event: "Called Bright Smile Dental", detail: "Connecting...", color: T.blue },
    { time: "00:03", event: "Called City Dental Care", detail: "Connecting...", color: T.blue },
    { time: "00:04", event: "Called Premier Associates", detail: "Ringing...", color: T.blue },
    { time: "00:05", event: "Bright Smile offered 2 slots", detail: "Tue 10:15 AM, Thu 2:30 PM", color: T.green },
    { time: "00:06", event: "Slot validated", detail: "No calendar conflicts ✓", color: T.green },
    { time: "00:08", event: "Affordable Dental offered 3 slots", detail: "Mon 9 AM, Wed 11 AM, Fri 3 PM", color: T.green },
    { time: "00:09", event: "Calendar conflict detected", detail: "Wed 11 AM conflicts with Team Standup", color: T.orange },
    { time: "00:10", event: "Harmony Wellness failed", detail: "No answer", color: T.red },
    { time: "00:11", event: "Ranking updated", detail: "4 valid options found", color: T.accent },
  ];

  const statusLabels = { queued: "QUEUED", calling: "CALLING", connected: "CONNECTED", negotiating: "NEGOTIATING", done: "DONE", failed: "FAILED" };
  const statusColors = { queued: T.textMuted, calling: T.accent, connected: T.blue, negotiating: T.orange, done: T.green, failed: T.red };

  const doneCalls = calls.filter(c => c.status === "done").length;
  const totalSlots = calls.reduce((s, c) => s + c.slots, 0);

  return (
    <div style={{ padding: 28, animation: "fadeUp .5s ease" }}>
      {/* Header bar */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
        <div>
          <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>Live Campaign</h1>
          <div style={{ display: "flex", gap: 16, fontSize: 12, color: T.textDim }}>
            <span>🦷 Dentist</span>
            <span>📍 Downtown</span>
            <span>⏱ {elapsed}s elapsed</span>
            <Badge color={T.accent}>Swarm Mode</Badge>
          </div>
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          <Btn danger small>{icons.stop} Stop All</Btn>
          <Btn small onClick={onComplete}>View Results →</Btn>
        </div>
      </div>

      {/* Stats bar */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginBottom: 24 }}>
        {[
          { label: "Total Calls", value: calls.length, color: T.text },
          { label: "Active", value: calls.filter(c => ["calling", "connected", "negotiating"].includes(c.status)).length, color: T.accent },
          { label: "Completed", value: doneCalls, color: T.green },
          { label: "Slots Found", value: totalSlots, color: T.orange },
        ].map(s => (
          <Card key={s.label} style={{ padding: 14, textAlign: "center" }}>
            <div style={{ fontSize: 28, fontWeight: 700, fontFamily: mono, color: s.color }}>{s.value}</div>
            <div style={{ fontSize: 10, color: T.textMuted, letterSpacing: .5, textTransform: "uppercase", marginTop: 2 }}>{s.label}</div>
          </Card>
        ))}
      </div>

      {/* Main content: calls + logs */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 320px", gap: 16 }}>
        {/* Call cards */}
        <div>
          {calls.map(c => (
            <div key={c.id} style={{
              background: T.bg1, border: `1px solid ${c.status === "calling" || c.status === "negotiating" ? T.accent : T.border}`,
              borderRadius: T.radius, padding: 14, marginBottom: 8, animation: "fadeUp .4s ease",
              boxShadow: c.status === "calling" ? `0 0 16px ${T.accentGlow}` : "none",
            }}>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <StatusDot status={c.status} />
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600, fontSize: 14 }}>{c.name}</div>
                  <div style={{ fontSize: 11, color: T.textDim }}>⭐ {c.rating} · 🚗 {c.dist}</div>
                </div>
                <Badge color={statusColors[c.status]}>{statusLabels[c.status]}</Badge>
                {c.slots > 0 && <Badge color={T.green}>{c.slots} slots</Badge>}
                {c.conf > 0 && <span style={{ fontFamily: mono, fontSize: 11, color: T.textDim }}>{c.conf}%</span>}
              </div>

              {c.transcript && (
                <div style={{ marginTop: 8 }}>
                  <span onClick={() => setExpandedId(expandedId === c.id ? null : c.id)}
                    style={{ fontSize: 11, color: T.accentLight, cursor: "pointer" }}>
                    {expandedId === c.id ? "▾ Hide" : "▸ Show"} transcript
                  </span>
                  {expandedId === c.id && (
                    <div style={{ marginTop: 8, padding: 10, background: T.bg, borderRadius: 8, fontFamily: mono, fontSize: 11, color: T.textDim, lineHeight: 1.7, whiteSpace: "pre-wrap" }}>
                      {c.transcript}
                    </div>
                  )}
                </div>
              )}
              {c.status === "failed" && <Btn small style={{ marginTop: 8 }}>Retry</Btn>}
            </div>
          ))}
        </div>

        {/* Event log */}
        <Card style={{ padding: 14, height: "fit-content", maxHeight: 500, overflowY: "auto" }}>
          <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: 1, color: T.textMuted, marginBottom: 12, textTransform: "uppercase" }}>Event Timeline</div>
          {logs.map((l, i) => (
            <div key={i} style={{ display: "flex", gap: 8, marginBottom: 10, animation: `slideIn .3s ease ${i * .05}s both` }}>
              <span style={{ fontFamily: mono, fontSize: 10, color: T.textMuted, whiteSpace: "nowrap", marginTop: 2 }}>{l.time}</span>
              <div>
                <div style={{ fontSize: 12, color: l.color, fontWeight: 500 }}>{l.event}</div>
                <div style={{ fontSize: 11, color: T.textMuted }}>{l.detail}</div>
              </div>
            </div>
          ))}
        </Card>
      </div>
    </div>
  );
};

// ─── Page: Results ──────────────────────────────────────────────────────────
const ResultsPage = ({ onNewBooking }) => {
  const [selected, setSelected] = useState(null);
  const [confirmed, setConfirmed] = useState(false);

  const results = [
    { rank: 1, name: "Affordable Dental Group", slot: "Mon Feb 9 · 9:00 AM", dur: "30 min", rating: 4.1, dist: 8, score: 89, conf: 91, why: "Very early availability. Close proximity (8 min). Good value option." },
    { rank: 2, name: "Bright Smile Dental", slot: "Tue Feb 10 · 10:15 AM", dur: "45 min", rating: 4.7, dist: 12, score: 84, conf: 94, why: "Excellent rating (4.7★). Early availability. Reasonable distance." },
    { rank: 3, name: "City Dental Care", slot: "Thu Feb 12 · 2:30 PM", dur: "30 min", rating: 4.3, dist: 17, score: 72, conf: 78, why: "Good rating. Afternoon slot available. Moderate distance." },
    { rank: 4, name: "Affordable Dental Group", slot: "Fri Feb 13 · 3:00 PM", dur: "30 min", rating: 4.1, dist: 8, score: 65, conf: 91, why: "Very close. Later in the week but flexible timing." },
  ];

  if (confirmed) {
    const r = results[selected];
    return (
      <div style={{ padding: 28, animation: "fadeUp .4s ease", display: "flex", justifyContent: "center", paddingTop: 80 }}>
        <Card style={{ textAlign: "center", maxWidth: 420, padding: 40 }} glow>
          <div style={{ width: 64, height: 64, borderRadius: "50%", background: T.greenDim, margin: "0 auto 16px", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <span style={{ color: T.green, fontSize: 28 }}>✓</span>
          </div>
          <h2 style={{ fontSize: 22, fontWeight: 700, marginBottom: 6 }}>Appointment Booked!</h2>
          <p style={{ color: T.textDim, fontSize: 14, marginBottom: 16 }}>Your appointment has been confirmed.</p>
          <div style={{ padding: "8px 18px", background: T.bg2, borderRadius: 6, display: "inline-block", marginBottom: 20 }}>
            <span style={{ fontFamily: mono, fontSize: 17, fontWeight: 600, color: T.accentLight }}>CP-A8F2E4B1</span>
          </div>
          <div style={{ fontSize: 14, color: T.textDim, marginBottom: 4 }}>{r.name}</div>
          <div style={{ fontSize: 14, color: T.textDim, marginBottom: 20 }}>{r.slot} · {r.dur}</div>
          <div style={{ display: "flex", gap: 8, justifyContent: "center" }}>
            <Toggle checked label="Add to Google Calendar" />
          </div>
          <div style={{ marginTop: 20 }}>
            <Btn onClick={onNewBooking}>← New Booking</Btn>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div style={{ padding: 28, maxWidth: 800, animation: "fadeUp .5s ease" }}>
      <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>Best Options Found</h1>
      <p style={{ color: T.textDim, fontSize: 14, marginBottom: 24 }}>
        Found {results.length} options from 4 successful calls. Select one to confirm.
      </p>

      {/* Stats */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10, marginBottom: 24 }}>
        {[["5", "Calls Made", T.accentLight], ["4", "Successful", T.green], [`${results.length}`, "Options", T.orange]].map(([v, l, c]) => (
          <Card key={l} style={{ padding: 14, textAlign: "center" }}>
            <div style={{ fontSize: 26, fontWeight: 700, fontFamily: mono, color: c }}>{v}</div>
            <div style={{ fontSize: 10, color: T.textMuted, letterSpacing: .5, textTransform: "uppercase" }}>{l}</div>
          </Card>
        ))}
      </div>

      {/* Results */}
      {results.map((r, i) => (
        <div key={i} onClick={() => setSelected(i)} style={{
          background: T.bg1, border: `1px solid ${selected === i ? T.green : T.border}`,
          borderRadius: T.radiusLg, padding: 18, marginBottom: 10, cursor: "pointer", transition: "all .2s",
          boxShadow: selected === i ? `0 0 20px rgba(0,214,143,.1)` : "none",
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center",
              background: r.rank === 1 ? T.accent : T.bg3, fontSize: 13, fontWeight: 700,
              color: r.rank === 1 ? "#fff" : T.textMuted,
            }}>#{r.rank}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 16 }}>{r.name}</div>
              <div style={{ fontSize: 13, color: T.textDim }}>{r.slot} · {r.dur}</div>
            </div>
            <div style={{ fontFamily: mono, fontSize: 28, fontWeight: 700, color: T.accentLight }}>{r.score}</div>
          </div>
          <div style={{ display: "flex", gap: 12, marginTop: 10, fontSize: 12, color: T.textDim }}>
            <span>⭐ {r.rating}</span>
            <span>🚗 {r.dist} min</span>
            <Badge color={r.conf >= 90 ? T.green : r.conf >= 70 ? T.orange : T.red}>{r.conf}% conf</Badge>
            {r.rank === 1 && <Badge color={T.accent}>Best Match</Badge>}
          </div>
          <div style={{ marginTop: 10, padding: 10, background: T.bg, borderRadius: 8, borderLeft: `3px solid ${T.accent}`, fontSize: 12, color: T.textDim, lineHeight: 1.5 }}>
            {r.why}
          </div>
        </div>
      ))}

      {selected !== null && (
        <div style={{ display: "flex", gap: 12, marginTop: 16 }}>
          <Btn primary onClick={() => setConfirmed(true)}>✓ Confirm Booking</Btn>
          <Btn>Re-run Calls</Btn>
        </div>
      )}
    </div>
  );
};

// ─── Page: History ──────────────────────────────────────────────────────────
const HistoryPage = () => {
  const history = [
    { id: 1, service: "🦷 Dentist", date: "Feb 8, 2026", location: "Downtown", status: "Booked", mode: "DEMO", provider: "Bright Smile Dental", code: "CP-A8F2E4B1" },
    { id: 2, service: "🔧 Mechanic", date: "Feb 5, 2026", location: "Eastside", status: "Completed", mode: "DEMO", provider: "FastFix Auto", code: "CP-7B3C1D9E" },
    { id: 3, service: "💇 Salon", date: "Jan 30, 2026", location: "Midtown", status: "No Results", mode: "DEMO", provider: "—", code: "—" },
  ];
  return (
    <div style={{ padding: 28, animation: "fadeUp .5s ease" }}>
      <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 20 }}>Campaign History</h1>
      {history.map(h => (
        <Card key={h.id} style={{ marginBottom: 10, padding: 16, cursor: "pointer" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ fontSize: 24 }}>{h.service.split(" ")[0]}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 14 }}>{h.service}</div>
              <div style={{ fontSize: 12, color: T.textDim }}>{h.date} · {h.location}</div>
            </div>
            <Badge color={h.status === "Booked" ? T.green : h.status === "Completed" ? T.blue : T.textMuted}>{h.status}</Badge>
            <Pill>{h.mode}</Pill>
          </div>
          {h.provider !== "—" && (
            <div style={{ marginTop: 8, fontSize: 12, color: T.textDim }}>
              Provider: <span style={{ color: T.text }}>{h.provider}</span> · Code: <span style={{ fontFamily: mono, color: T.accentLight }}>{h.code}</span>
            </div>
          )}
        </Card>
      ))}
    </div>
  );
};

// ─── Page: Providers ────────────────────────────────────────────────────────
const ProvidersPage = () => {
  const providers = [
    { name: "Bright Smile Dental", type: "🦷 Dentist", rating: 4.7, addr: "123 Oak St", pinned: true, preferred: true },
    { name: "City Dental Care", type: "🦷 Dentist", rating: 4.3, addr: "456 Elm Ave", pinned: false, preferred: false },
    { name: "FastFix Auto Shop", type: "🔧 Mechanic", rating: 4.4, addr: "100 Industrial Pkwy", pinned: true, preferred: false },
    { name: "Luxe Hair Studio", type: "💇 Salon", rating: 4.6, addr: "42 Fashion Ave", pinned: false, preferred: true },
    { name: "Tony's Garage", type: "🔧 Mechanic", rating: 4.8, addr: "250 Workshop Dr", pinned: false, preferred: false },
  ];
  return (
    <div style={{ padding: 28, animation: "fadeUp .5s ease" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
        <h1 style={{ fontSize: 24, fontWeight: 700 }}>Saved Providers</h1>
        <Btn primary small>+ Add Provider</Btn>
      </div>
      <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
        <Pill active>All</Pill><Pill>🦷 Dentist</Pill><Pill>🔧 Mechanic</Pill><Pill>💇 Salon</Pill>
      </div>
      {providers.map((p, i) => (
        <Card key={i} style={{ marginBottom: 8, padding: 14 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ fontSize: 20 }}>{p.type.split(" ")[0]}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600, fontSize: 14 }}>{p.name}</div>
              <div style={{ fontSize: 12, color: T.textDim }}>{p.addr} · ⭐ {p.rating}</div>
            </div>
            {p.pinned && <Badge color={T.accent}>📌 Pinned</Badge>}
            {p.preferred && <Badge color={T.green}>★ Preferred</Badge>}
            <span style={{ color: T.textMuted, cursor: "pointer", fontSize: 18 }}>⋯</span>
          </div>
        </Card>
      ))}
    </div>
  );
};

// ─── Page: Settings ─────────────────────────────────────────────────────────
const SettingsPage = () => {
  const integrations = [
    { name: "OpenAI", key: "GPT-4o", status: true, desc: "LLM reasoning & extraction" },
    { name: "ElevenLabs", key: "Agent v2", status: true, desc: "Voice AI conversations" },
    { name: "Twilio", key: "+1 555-***", status: true, desc: "Outbound phone calls" },
    { name: "Google Calendar", key: "OAuth2", status: false, desc: "Calendar conflict detection" },
    { name: "Google Places", key: "API Key", status: false, desc: "Provider search" },
  ];
  return (
    <div style={{ padding: 28, animation: "fadeUp .5s ease" }}>
      <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 20 }}>Settings & Integrations</h1>

      <SectionTitle>Mode</SectionTitle>
      <Card style={{ marginBottom: 24, padding: 18 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <div style={{ fontWeight: 600, fontSize: 14 }}>Live Mode</div>
            <div style={{ fontSize: 12, color: T.textDim }}>When enabled, campaigns place real calls via Twilio.</div>
          </div>
          <Toggle label="" />
        </div>
      </Card>

      <SectionTitle>Integrations</SectionTitle>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 24 }}>
        {integrations.map(ig => (
          <Card key={ig.name} style={{ padding: 16, borderColor: ig.status ? T.greenDim : T.border }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
              <span style={{ fontWeight: 600, fontSize: 14 }}>{ig.name}</span>
              <Badge color={ig.status ? T.green : T.red}>{ig.status ? "Connected" : "Not Connected"}</Badge>
            </div>
            <div style={{ fontSize: 12, color: T.textDim, marginBottom: 10 }}>{ig.desc}</div>
            <div style={{ fontSize: 11, fontFamily: mono, color: T.textMuted, marginBottom: 10 }}>
              {ig.status ? ig.key : "No key configured"}
            </div>
            <div style={{ display: "flex", gap: 6 }}>
              <Btn small>{ig.status ? "Test" : "Connect"}</Btn>
              {ig.status && <Btn small>Re-auth</Btn>}
            </div>
          </Card>
        ))}
      </div>

      <SectionTitle>Safety</SectionTitle>
      <Card style={{ padding: 18 }}>
        <Toggle checked label="Require confirmation before live calls" />
        <div style={{ height: 12 }} />
        <Toggle label="Enable detailed logging" />
        <div style={{ height: 12 }} />
        <Toggle checked label="Never auto-book without user approval" />
      </Card>
    </div>
  );
};

// ─── App ────────────────────────────────────────────────────────────────────
export default function App() {
  const [page, setPage] = useState("booking");
  const [mode, setMode] = useState("DEMO");

  useEffect(() => {
    const el = document.createElement("style");
    el.textContent = globalCSS;
    document.head.appendChild(el);
    return () => el.remove();
  }, []);

  const renderPage = () => {
    switch (page) {
      case "booking": return <BookingPage onStart={() => setPage("campaigns")} />;
      case "campaigns": return <MonitorPage onComplete={() => setPage("results")} />;
      case "results": return <ResultsPage onNewBooking={() => setPage("booking")} />;
      case "history": return <HistoryPage />;
      case "providers": return <ProvidersPage />;
      case "settings": return <SettingsPage />;
      default: return <BookingPage onStart={() => setPage("campaigns")} />;
    }
  };

  return (
    <div style={{ display: "flex", height: "100vh", background: T.bg, overflow: "hidden" }}>
      <Sidebar active={page === "results" ? "campaigns" : page} onNav={setPage} />
      <div style={{ flex: 1, display: "flex", flexDirection: "column", overflow: "hidden" }}>
        <Topbar mode={mode} setMode={setMode} />
        <div style={{ flex: 1, overflow: "auto" }}>
          {renderPage()}
        </div>
      </div>
    </div>
  );
}
