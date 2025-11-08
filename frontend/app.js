console.log("APP_JS_VERSION=2025-11-07-WS-FIX");
// ---------- Helpers & DOM ----------
const $ = (id) => document.getElementById(id);

const authPanel = $("auth");
const chatPanel = $("chat");
const messagesDiv = $("messages");
const usernameInput = $("username");
const passwordInput = $("password");
const authMsg = $("authMsg");

const signupBtn = $("signupBtn");
const loginBtn = $("loginBtn");
const logoutBtn = $("logoutBtn");
const chatInput = $("chatInput");
const sendBtn = $("sendBtn");

const API = location.origin + "/api";

// ---------- Auth & WS State ----------
let token = localStorage.getItem("token") || "";
let ws = null;               // current WebSocket instance
let shouldReconnect = false; // only auto-reconnect while authenticated
let connecting = false;      // guard to avoid concurrent socket creation

// ---------- UI ----------
function showAuth() {
  authPanel.classList.remove("hidden");
  chatPanel.classList.add("hidden");
}

function showChat() {
  authPanel.classList.add("hidden");
  chatPanel.classList.remove("hidden");
}

// ---------- HTTP ----------
async function callAPI(path, method = "GET", body) {
  const headers = {"Content-Type": "application/json"};
  if (token) headers["Authorization"] = "Bearer " + token;
  const res = await fetch(API + path, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined
  });
  if (!res.ok) throw new Error((await res.json()).detail || ("HTTP " + res.status));
  return res.json();
}

// ---------- Messages ----------
function addMessage(m) {
  const el = document.createElement("div");
  el.className = "message" + (m.is_bot ? " bot" : "");
  const meta = document.createElement("div");
  meta.className = "meta";
  meta.textContent = `${m.username || "unknown"} • ${new Date(m.created_at).toLocaleString()}`;
  const body = document.createElement("div");
  body.textContent = m.content;
  el.appendChild(meta);
  el.appendChild(body);
  messagesDiv.appendChild(el);
  messagesDiv.scrollTop = messagesDiv.scrollHeight;
}

async function loadMessages() {
  const data = await callAPI("/messages");
  messagesDiv.innerHTML = "";
  for (const m of data.messages) addMessage(m);
}

// ---------- WebSocket Management ----------
function connectWS() {
  // Guard: do not create another socket if one is open/connecting
  if (connecting) return;
  if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) return;

  const proto = location.protocol === "https:" ? "wss" : "ws";
  connecting = true;
  ws = new WebSocket(`${proto}://${location.host}/ws`);

  // (Optional) debug logs:
  // console.log("[WS] connecting...");

  ws.onopen = () => {
    // console.log("[WS] open");
    connecting = false;
  };

  ws.onmessage = (ev) => {
    try {
      const data = JSON.parse(ev.data);
      if (data.type === "message") addMessage(data.message);
    } catch (_) {
      // ignore malformed frames
    }
  };

  ws.onclose = (ev) => {
    // console.log("[WS] close", ev.code, ev.reason);
    ws = null;
    connecting = false;
    // Auto-reconnect only while authenticated (disabled on logout)
    if (shouldReconnect) setTimeout(connectWS, 2000);
  };

  ws.onerror = () => {
    // console.log("[WS] error", e);
    connecting = false;
  };
}

// Ensure socket is closed when user closes/refreshes the tab
window.addEventListener("beforeunload", () => {
  try {
    shouldReconnect = false;
    if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) {
      ws.close(1000, "unload"); // normal closure
    }
  } catch {}
});

// ---------- Auth Flows ----------
signupBtn.onclick = async (e) => {
  if (e?.preventDefault) e.preventDefault();
  try {
    const out = await callAPI("/signup", "POST", {
      username: usernameInput.value.trim(),
      password: passwordInput.value
    });
    token = out.token;
    localStorage.setItem("token", token);

    await loadMessages();

    shouldReconnect = true; // enable WS auto-reconnect when authenticated
    connectWS();
    showChat();
  } catch (err) {
    authMsg.textContent = err.message;
  }
};

loginBtn.onclick = async (e) => {
  if (e?.preventDefault) e.preventDefault();
  try {
    const out = await callAPI("/login", "POST", {
      username: usernameInput.value.trim(),
      password: passwordInput.value
    });
    token = out.token;
    localStorage.setItem("token", token);

    await loadMessages();

    shouldReconnect = true;
    connectWS();
    showChat();
  } catch (err) {
    authMsg.textContent = err.message;
  }
};

logoutBtn.onclick = (e) => {
  // Prevent form submit/page reload swallowing close() frame
  if (e?.preventDefault) e.preventDefault();

  // 1) Stop future auto-reconnects
  shouldReconnect = false;

  // 2) Close current WS gracefully so server runs disconnect()
  const current = ws;
  if (current && (current.readyState === WebSocket.OPEN || current.readyState === WebSocket.CONNECTING)) {
    try { current.close(1000, "logout"); } catch {}
  }
  ws = null;
  connecting = false;

  // 3) Clear auth state
  token = "";
  localStorage.removeItem("token");

  // 4) Switch UI
  showAuth();
};

// ---------- Sending ----------
sendBtn.onclick = async (e) => {
  if (e?.preventDefault) e.preventDefault();
  const text = chatInput.value.trim();
  if (!text) return;
  chatInput.value = "";
  await callAPI("/messages", "POST", { content: text });
};

// ---------- Initial boot ----------
if (token) {
  loadMessages()
    .then(() => {
      shouldReconnect = true;
      connectWS();
      showChat();
    })
    .catch(() => showAuth());
} else {
  showAuth();
}