const RULES_URL = "http://localhost:52836/rules";
const POLL_INTERVAL = 2000;

let currentRules = null;
let tempAllowed = {}; // host -> expiry timestamp

async function fetchRules() {
  try {
    const response = await fetch(RULES_URL);
    const rules = await response.json();
    currentRules = rules;
    chrome.storage.local.set({ rules: currentRules });
  } catch (e) {
    currentRules = null;
    chrome.storage.local.set({ rules: null });
  }
}

function isURLBlocked(url, rules) {
  if (!rules || !rules.active || rules.onBreak) return false;

  let host;
  try {
    host = new URL(url).hostname.toLowerCase();
  } catch {
    return false;
  }

  // Check temp allow
  if (tempAllowed[host] && Date.now() < tempAllowed[host]) {
    return false;
  }
  // Clean expired
  if (tempAllowed[host] && Date.now() >= tempAllowed[host]) {
    delete tempAllowed[host];
  }

  for (const pattern of rules.allowedURLs || []) {
    if (host === pattern || host.endsWith("." + pattern)) return false;
  }

  for (const pattern of rules.blockedURLs || []) {
    if (host === pattern || host.endsWith("." + pattern)) return true;
  }

  return rules.defaultPolicy === "block";
}

// Block on navigation
chrome.webNavigation.onBeforeNavigate.addListener((details) => {
  if (details.frameId !== 0) return;
  if (isURLBlocked(details.url, currentRules)) {
    redirectToBlocked(details.tabId, details.url);
  }
});

// Also check when tab finishes loading
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status !== "complete" || !tab.url) return;
  if (tab.url.startsWith("chrome") || tab.url.startsWith("chrome-extension")) return;
  if (isURLBlocked(tab.url, currentRules)) {
    redirectToBlocked(tabId, tab.url);
  }
});

function redirectToBlocked(tabId, url) {
  const params = new URLSearchParams({
    url: url,
    modeName: currentRules.modeName || "",
    remainingSeconds: String(currentRules.remainingSeconds || 0),
    allowedSites: (currentRules.allowedURLs || []).join(",")
  });
  chrome.tabs.update(tabId, {
    url: chrome.runtime.getURL("blocked.html") + "?" + params.toString()
  });
}

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === "get_rules") {
    sendResponse(currentRules);
  } else if (message.type === "temp_allow") {
    // Allow this URL's host for N minutes
    try {
      const host = new URL(message.url).hostname.toLowerCase();
      const minutes = message.minutes || 5;
      tempAllowed[host] = Date.now() + minutes * 60 * 1000;
      sendResponse({ ok: true });
    } catch {
      sendResponse({ ok: false });
    }
  } else if (message.type === "go_back") {
    // Close the blocked tab or navigate to a safe page
    if (sender.tab) {
      chrome.tabs.remove(sender.tab.id);
    }
  }
  return true; // keep message channel open for async sendResponse
});

// Start polling
fetchRules();
setInterval(fetchRules, POLL_INTERVAL);

// Load cached rules on startup
chrome.storage.local.get("rules", (result) => {
  if (result.rules) currentRules = result.rules;
});
