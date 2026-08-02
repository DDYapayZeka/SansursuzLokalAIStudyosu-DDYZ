import React, { memo, useState, useRef, useEffect } from "react";
import { Square, RefreshCw, Sun, Moon, Palette, Check, PanelLeftClose, PanelLeft } from "lucide-react";
import { THEMES } from "../themes";

const truncateModelName = (name) => {
  if (!name || typeof name !== "string") return "";
  let cleanName = name;
  if (name.includes("--")) {
    const parts = name.split("--");
    cleanName = parts[parts.length - 1];
  }
  if (cleanName.length > 25) {
    return cleanName.substring(0, 22) + "...";
  }
  return cleanName;
};

function TopStatusBar({ 
  telemetry, 
  serverRunning, 
  activeModel, 
  isLlmLoaded = false, 
  onStopServer, 
  isStoppingServer = false, 
  theme, 
  setTheme,
  sidebarVisible,
  onToggleSidebar
}) {
  const [showThemeMenu, setShowThemeMenu] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    function handleClickOutside(event) {
      if (menuRef.current && !menuRef.current.contains(event.target)) {
        setShowThemeMenu(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const formatGb = (value, { allowZero = false } = {}) => {
    const number = Number(value);
    if (!Number.isFinite(number) || number < 0) return "--";
    if (number === 0 && !allowZero) return "--";
    return number.toFixed(number >= 10 ? 0 : 1);
  };

  const getStatusText = () => {
    if (isLlmLoaded) return "Model Yuklu (Metin)";
    if (activeModel) return "Model Yuklu (Gorsel)";
    if (serverRunning) return "Sunucu Calisiyor";
    return "Yerel Mod";
  };

  const getStatusClass = () => {
    if (activeModel || isLlmLoaded) return "status-indicator";
    if (serverRunning) return "status-indicator busy";
    return "status-indicator offline";
  };

  const isDark = (theme || "dark").startsWith("dark");

  return (
    <div className="top-status-bar">
      <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
        <button
          onClick={onToggleSidebar}
          className="sidebar-toggle-btn"
          title={sidebarVisible ? "Yan Menuyu Daralt" : "Yan Menuyu Genislet"}
        >
          {sidebarVisible ? <PanelLeftClose size={18} /> : <PanelLeft size={18} />}
        </button>

        <div className="current-model-info">
          <div className={getStatusClass()}></div>
          <span style={{ fontWeight: 600, fontSize: "0.95rem" }}>
            {getStatusText()}
          </span>
          {(activeModel || (typeof isLlmLoaded === "string" && isLlmLoaded)) && (
            <>
              <span style={{ color: "var(--md-sys-color-outline-variant)" }}>|</span>
              <span 
                style={{ color: "var(--md-sys-color-primary)", fontWeight: 700 }}
                title={activeModel || isLlmLoaded}
              >
                {truncateModelName(activeModel || isLlmLoaded)}
              </span>
            </>
          )}
        </div>
      </div>

      <div className="telemetry-group" style={{ position: "relative" }}>
        <button
          className="theme-toggle-btn"
          onClick={() => setTheme(isDark ? "light" : "dark")}
          title={`${isDark ? "acik" : "koyu"} temaya gec`}
        >
          {isDark ? <Sun size={18} /> : <Moon size={18} />}
        </button>

        <div ref={menuRef} style={{ position: "relative", display: "inline-block" }}>
          <button
            className={`theme-toggle-btn ${showThemeMenu ? "active" : ""}`}
            onClick={() => setShowThemeMenu(!showThemeMenu)}
            title="Ozel bir renk temasi secin"
            style={{ marginRight: "12px" }}
          >
            <Palette size={18} />
          </button>
          
          {showThemeMenu && (
            <div className="theme-dropdown-menu">
              <div className="theme-dropdown-header">Tema Sec</div>
              <div className="theme-dropdown-divider"></div>
              {THEMES.map((t) => {
                const isActive = theme === t.id;
                return (
                  <button
                    key={t.id}
                    className={`theme-dropdown-item ${isActive ? "active" : ""}`}
                    onClick={() => {
                      setTheme(t.id);
                      setShowThemeMenu(false);
                    }}
                  >
                    <div style={{ display: "flex", alignItems: "center", gap: "8px", width: "100%" }}>
                      <div style={{ display: "flex", gap: "2px" }}>
                        <div style={{ width: "8px", height: "8px", borderRadius: "50%", background: t.primary }} />
                        <div style={{ width: "8px", height: "8px", borderRadius: "50%", background: t.secondary }} />
                      </div>
                      <span className="theme-name-text">{t.name}</span>
                      {isActive && <Check size={12} style={{ marginLeft: "auto", color: "var(--md-sys-color-primary)" }} />}
                    </div>
                  </button>
                );
              })}
            </div>
          )}
        </div>

        {serverRunning && (
          <button
            className="m3-btn m3-btn-error"
            style={{ height: "34px", padding: "0 14px" }}
            onClick={onStopServer}
            disabled={isStoppingServer}
            title="Yerel model sunucusunu durdur"
          >
            {isStoppingServer ? <RefreshCw className="progress-spinner" size={14} /> : <Square size={14} />}
            <span>{isStoppingServer ? "Durduruluyor" : "Sunucuyu Durdur"}</span>
          </button>
        )}

        {/* CPU Telemetry Chip */}
        <div className="telemetry-chip" title="CPU Utilization">
          <span>CPU: {Number.isFinite(Number(telemetry.cpu_usage)) ? telemetry.cpu_usage : "--"}%</span>
        </div>

        {/* RAM Telemetry Chip */}
        <div className="telemetry-chip" title="System Memory Usage">
          <span>RAM: {formatGb(telemetry.ram_used_gb)} / {formatGb(telemetry.ram_total_gb)} GB</span>
        </div>

        {/* GPU VRAM Telemetry Chip */}
        {telemetry.vram_total_gb > 0 && (
          <div className="telemetry-chip" title={`${telemetry.gpu_name} VRAM`}>
            <span>VRAM: {formatGb(telemetry.vram_used_gb, { allowZero: true })} / {formatGb(telemetry.vram_total_gb)} GB</span>
          </div>
        )}
      </div>
    </div>
  );
}

export default memo(TopStatusBar);
