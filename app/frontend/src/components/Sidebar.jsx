import React, { memo } from "react";
import { Image, FolderDown, MessageSquare, Mic, Settings, Terminal, ChevronDown, ChevronUp, Trash2, Volume2 } from "lucide-react";

function formatSidebarDate(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  const dateStr = date.toLocaleDateString();
  const timeStr = date.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit', hour12: true });
  return `${dateStr} ${timeStr}`;
}

function Sidebar({ 
  collapsed = false,
  activeTab, 
  setActiveTab, 
  specs,
  conversations = [],
  activeConversationId,
  setActiveConversationId,
  showHistory,
  setShowHistory,
  onDeleteConversation,
  speechTranscriptions = [],
  selectedSpeechTranscript,
  setSelectedSpeechTranscript,
  showSpeechHistory,
  setShowSpeechHistory,
  onDeleteSpeechTranscription,
  ttsOutputs = [],
  selectedTtsOutput,
  setSelectedTtsOutput,
  showTtsHistory,
  setShowTtsHistory,
  onDeleteTtsOutput
}) {
  return (
    <div className={`sidebar ${collapsed ? "collapsed" : ""}`}>
      <div>
        {/* Sidebar Header */}
        <div className="sidebar-logo">
          <img className="sidebar-logo-icon" src="/logo.png" alt="Sansursuz Lokal AI Studyosu - DD:YZ logosu" />
          <span className="sidebar-logo-text">Sansursuz Lokal AI Studyosu - DD:YZ</span>
        </div>

        {/* Sidebar Navigation Links (Material 3 style) */}
        <div className="nav-list">
          <div
            className={`nav-item ${activeTab === "generator" ? "active" : ""}`}
            onClick={() => setActiveTab("generator")}
          >
            <Image size={20} />
            <span>Gorsel Uretici</span>
          </div>

          <div className="nav-item-wrapper" style={{ display: "flex", flexDirection: "column" }}>
            <div
              className={`nav-item ${activeTab === "chat" ? "active" : ""}`}
              onClick={() => setActiveTab("chat")}
              style={{ display: "flex", justifyContent: "space-between", alignItems: "center", width: "100%", boxSizing: "border-box" }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                <MessageSquare size={20} />
                <span>Metin Sohbeti</span>
              </div>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setShowHistory(!showHistory);
                }}
                style={{
                  background: "none",
                  border: "none",
                  color: "inherit",
                  cursor: "pointer",
                  padding: "4px",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  borderRadius: "50%",
                  transition: "background-color 0.2s"
                }}
                className="history-toggle-arrow"
                title={showHistory ? "Hide Chat History" : "Show Chat History"}
              >
                {showHistory ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
              </button>
            </div>

            {/* Sidebar Chat History List */}
            {showHistory && (
              <div 
                className="sidebar-history-list" 
                style={{ 
                  paddingLeft: "14px", 
                  marginTop: "6px", 
                  marginBottom: "6px",
                  display: "flex", 
                  flexDirection: "column", 
                  gap: "4px", 
                  maxHeight: "220px", 
                  overflowY: "auto",
                  borderLeft: "2px solid var(--border-color)"
                }}
              >
                {conversations.length === 0 ? (
                  <div style={{ padding: "8px 12px", fontSize: "0.78rem", color: "var(--md-sys-color-outline)", opacity: 0.8 }}>
                    No saved chats
                  </div>
                ) : (
                  conversations.map((conv) => {
                    const isActive = activeConversationId === conv.id;
                    return (
                      <div
                        key={conv.id}
                        onClick={() => {
                          setActiveConversationId(conv.id);
                          setActiveTab("chat");
                        }}
                        style={{
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "space-between",
                          padding: "6px 8px 6px 10px",
                          borderRadius: "var(--md-shape-corner-small)",
                          fontSize: "0.78rem",
                          cursor: "pointer",
                          background: isActive ? "var(--md-sys-color-secondary-container)" : "transparent",
                          color: isActive ? "var(--md-sys-color-on-secondary-container)" : "var(--md-sys-color-on-surface-variant)",
                          border: isActive ? "1px solid var(--md-sys-color-outline-variant)" : "1px solid transparent",
                          transition: "background 0.2s"
                        }}
                        className="sidebar-history-item"
                        title={conv.title}
                      >
                        <span style={{
                          overflow: "hidden",
                          textOverflow: "ellipsis",
                          whiteSpace: "nowrap",
                          flex: 1,
                          fontWeight: isActive ? 600 : 400
                        }}>
                          {conv.title}
                        </span>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            onDeleteConversation(conv.id, e);
                          }}
                          style={{
                            background: "none",
                            border: "none",
                            color: "var(--md-sys-color-outline)",
                            cursor: "pointer",
                            padding: "2px",
                            marginLeft: "6px",
                            display: "flex",
                            alignItems: "center"
                          }}
                          className="sidebar-history-delete"
                          title="Delete Conversation"
                        >
                          <Trash2 size={12} />
                        </button>
                      </div>
                    );
                  })
                )}
              </div>
            )}
          </div>

          <div className="nav-item-wrapper" style={{ display: "flex", flexDirection: "column" }}>
            <div
              className={`nav-item ${activeTab === "speech" ? "active" : ""}`}
              onClick={() => setActiveTab("speech")}
              style={{ display: "flex", justifyContent: "space-between", alignItems: "center", width: "100%", boxSizing: "border-box" }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                <Mic size={20} />
                <span>Konusma Yazici</span>
              </div>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setShowSpeechHistory(!showSpeechHistory);
                }}
                style={{
                  background: "none",
                  border: "none",
                  color: "inherit",
                  cursor: "pointer",
                  padding: "4px",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  borderRadius: "50%",
                  transition: "background-color 0.2s"
                }}
                className="history-toggle-arrow"
                title={showSpeechHistory ? "Hide Transcriptions" : "Show Transcriptions"}
              >
                {showSpeechHistory ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
              </button>
            </div>

            {showSpeechHistory && (
              <div
                className="sidebar-history-list"
                style={{
                  paddingLeft: "14px",
                  marginTop: "6px",
                  marginBottom: "6px",
                  display: "flex",
                  flexDirection: "column",
                  gap: "4px",
                  maxHeight: "220px",
                  overflowY: "auto",
                  borderLeft: "2px solid var(--border-color)"
                }}
              >
                {speechTranscriptions.length === 0 ? (
                  <div style={{ padding: "8px 12px", fontSize: "0.78rem", color: "var(--md-sys-color-outline)", opacity: 0.8 }}>
                    No saved transcriptions
                  </div>
                ) : (
                  speechTranscriptions.map((item) => {
                    const itemId = item.filename || item.metadata || item.textFile;
                    const isActive = selectedSpeechTranscript && (selectedSpeechTranscript.filename || selectedSpeechTranscript.metadata || selectedSpeechTranscript.textFile) === itemId;
                    const title = item.displayName || item.sourceFilename || item.textFile || item.filename || "Transcript";
                    const date = formatSidebarDate(item.modifiedAt || item.createdAt);
                    return (
                      <div
                        key={itemId}
                        onClick={() => {
                          setSelectedSpeechTranscript(item);
                          setActiveTab("speech");
                        }}
                        style={{
                          display: "flex",
                          flexDirection: "row",
                          alignItems: "center",
                          justifyContent: "space-between",
                          padding: "7px 8px 7px 10px",
                          borderRadius: "var(--md-shape-corner-small)",
                          fontSize: "0.78rem",
                          cursor: "pointer",
                          background: isActive ? "var(--md-sys-color-secondary-container)" : "transparent",
                          color: isActive ? "var(--md-sys-color-on-secondary-container)" : "var(--md-sys-color-on-surface-variant)",
                          border: isActive ? "1px solid var(--md-sys-color-outline-variant)" : "1px solid transparent",
                          transition: "background 0.2s"
                        }}
                        className="sidebar-history-item"
                        title={title}
                      >
                        <div style={{ display: "flex", flexDirection: "column", gap: "2px", flex: 1, minWidth: 0 }}>
                          <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", fontWeight: isActive ? 600 : 400 }}>
                            {title}
                          </span>
                          {date && (
                            <span style={{ fontSize: "0.68rem", opacity: 0.72, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                              {date}
                            </span>
                          )}
                        </div>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            onDeleteSpeechTranscription?.(item, e);
                          }}
                          style={{
                            background: "none",
                            border: "none",
                            color: "var(--md-sys-color-outline)",
                            cursor: "pointer",
                            padding: "2px",
                            marginLeft: "6px",
                            display: "flex",
                            alignItems: "center"
                          }}
                          className="sidebar-history-delete"
                          title="Delete Transcription"
                        >
                          <Trash2 size={12} />
                        </button>
                      </div>
                    );
                  })
                )}
              </div>
            )}
          </div>

          <div className="nav-item-wrapper" style={{ display: "flex", flexDirection: "column" }}>
            <div
              className={`nav-item ${activeTab === "tts" ? "active" : ""}`}
              onClick={() => setActiveTab("tts")}
              style={{ display: "flex", justifyContent: "space-between", alignItems: "center", width: "100%", boxSizing: "border-box" }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                <Volume2 size={20} />
                <span>Metinden Sese</span>
              </div>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setShowTtsHistory(!showTtsHistory);
                }}
                style={{
                  background: "none",
                  border: "none",
                  color: "inherit",
                  cursor: "pointer",
                  padding: "4px",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  borderRadius: "50%",
                  transition: "background-color 0.2s"
                }}
                className="history-toggle-arrow"
                title={showTtsHistory ? "Hide TTS Outputs" : "Show TTS Outputs"}
              >
                {showTtsHistory ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
              </button>
            </div>

            {showTtsHistory && (
              <div
                className="sidebar-history-list"
                style={{
                  paddingLeft: "14px",
                  marginTop: "6px",
                  marginBottom: "6px",
                  display: "flex",
                  flexDirection: "column",
                  gap: "4px",
                  maxHeight: "220px",
                  overflowY: "auto",
                  borderLeft: "2px solid var(--border-color)"
                }}
              >
                {ttsOutputs.length === 0 ? (
                  <div style={{ padding: "8px 12px", fontSize: "0.78rem", color: "var(--md-sys-color-outline)", opacity: 0.8 }}>
                    No saved audio
                  </div>
                ) : (
                  ttsOutputs.map((item) => {
                    const itemId = item.filename || item.metadata || item.audioFile;
                    const isActive = selectedTtsOutput && (selectedTtsOutput.filename || selectedTtsOutput.metadata || selectedTtsOutput.audioFile) === itemId;
                    const title = item.displayName || item.text || item.audioFile || item.filename || "TTS Output";
                    const date = formatSidebarDate(item.modifiedAt || item.createdAt);
                    return (
                      <div
                        key={itemId}
                        onClick={() => {
                          setSelectedTtsOutput(item);
                          setActiveTab("tts");
                        }}
                        style={{
                          display: "flex",
                          flexDirection: "row",
                          alignItems: "center",
                          justifyContent: "space-between",
                          padding: "7px 8px 7px 10px",
                          borderRadius: "var(--md-shape-corner-small)",
                          fontSize: "0.78rem",
                          cursor: "pointer",
                          background: isActive ? "var(--md-sys-color-secondary-container)" : "transparent",
                          color: isActive ? "var(--md-sys-color-on-secondary-container)" : "var(--md-sys-color-on-surface-variant)",
                          border: isActive ? "1px solid var(--md-sys-color-outline-variant)" : "1px solid transparent",
                          transition: "background 0.2s"
                        }}
                        className="sidebar-history-item"
                        title={title}
                      >
                        <div style={{ display: "flex", flexDirection: "column", gap: "2px", flex: 1, minWidth: 0 }}>
                          <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", fontWeight: isActive ? 600 : 400 }}>
                            {title}
                          </span>
                          {date && (
                            <span style={{ fontSize: "0.68rem", opacity: 0.72, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                              {date}
                            </span>
                          )}
                        </div>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            onDeleteTtsOutput?.(item, e);
                          }}
                          style={{
                            background: "none",
                            border: "none",
                            color: "var(--md-sys-color-outline)",
                            cursor: "pointer",
                            padding: "2px",
                            marginLeft: "6px",
                            display: "flex",
                            alignItems: "center"
                          }}
                          className="sidebar-history-delete"
                          title="Delete TTS Output"
                        >
                          <Trash2 size={12} />
                        </button>
                      </div>
                    );
                  })
                )}
              </div>
            )}
          </div>

          <div
            className={`nav-item ${activeTab === "models" ? "active" : ""}`}
            onClick={() => setActiveTab("models")}
          >
            <FolderDown size={20} />
            <span>Model Yoneticisi</span>
          </div>

          <div
            className={`nav-item ${activeTab === "settings" ? "active" : ""}`}
            onClick={() => setActiveTab("settings")}
          >
            <Settings size={20} />
            <span>Ayarlar</span>
          </div>
        </div>
      </div>

      {/* Sidebar Footer with Host Telemetry System Specs */}
      <div className="sidebar-footer">
        <div className="sidebar-specs-header">
          <Terminal size={12} />
          <span>Bilgisayar Ozellikleri</span>
        </div>
        <div className="sidebar-specs-item" title={specs.cpu_name}>
          CPU: {specs.cpu_name}
        </div>
        <div className="sidebar-specs-item" title={specs.gpu_name}>
          GPU: {specs.gpu_name}
        </div>
        <div className="sidebar-specs-item">
          Memory: {specs.ram_total_gb.toFixed(0)} GB RAM ({specs.cpu_cores_physical} Cores)
        </div>
        <div className="sidebar-specs-os">
          OS: {specs.os_name}
        </div>
      </div>
    </div>
  );
}

export default memo(Sidebar);
