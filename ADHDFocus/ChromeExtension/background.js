const NATIVE_HOST = "com.lilinke.adhdfocus";
let currentRules = null;
let nativePort = null;

function connectToNativeHost() {
  nativePort = chrome.runtime.connectNative(NATIVE_HOST);

  nativePort.onMessage.addListener((message) => {
    if (message.type === "rules_update") {
      currentRules = message.data;
      chrome.storage.local.set({ rules: currentRules });
    }
  });

  nativePort.onDisconnect.addListener(() => {
    nativePort = null;
    currentRules = null;
    chrome.storage.local.set({ rules: null });
    setTimeout(connectToNativeHost, 5000);
  });

  nativePort.postMessage({ type: "get_rules" });
}

function isURLBlocked(url, rules) {
  if (!rules || !rules.active || rules.onBreak) return false;

  let host;
  try {
    host = new URL(url).hostname.toLowerCase();
  } catch {
    return false;
  }

  for (const pattern of rules.allowedURLs || []) {
    if (host === pattern || host.endsWith("." + pattern)) return false;
  }

  for (const pattern of rules.blockedURLs || []) {
    if (host === pattern || host.endsWith("." + pattern)) return true;
  }

  return rules.defaultPolicy === "block";
}

chrome.webNavigation.onBeforeNavigate.addListener((details) => {
  if (details.frameId !== 0) return;

  const rules = currentRules;
  if (isURLBlocked(details.url, rules)) {
    const params = new URLSearchParams({
      url: details.url,
      modeName: rules.modeName || "",
      remainingSeconds: String(rules.remainingSeconds || 0),
      allowedSites: (rules.allowedURLs || []).join(",")
    });
    chrome.tabs.update(details.tabId, {
      url: chrome.runtime.getURL("blocked.html") + "?" + params.toString()
    });
  }
});

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === "get_rules") {
    sendResponse(currentRules);
  }
});

connectToNativeHost();

chrome.storage.local.get("rules", (result) => {
  if (result.rules) currentRules = result.rules;
});
