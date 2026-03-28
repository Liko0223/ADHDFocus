const params = new URLSearchParams(window.location.search);
const blockedURL = params.get("url") || "";
const modeName = params.get("modeName") || "";
const remainingSeconds = parseInt(params.get("remainingSeconds") || "0");
const allowedSites = (params.get("allowedSites") || "").split(",").filter(Boolean);

// Reason text
let host = "";
try { host = new URL(blockedURL).hostname; } catch (e) {}
document.getElementById("reason").textContent =
  host + " 不在「" + modeName + "」的允许列表中";

// Timer
if (remainingSeconds > 0) {
  document.getElementById("timerBox").style.display = "block";
  const minutes = Math.floor(remainingSeconds / 60);
  const seconds = remainingSeconds % 60;
  document.getElementById("timerValue").textContent =
    String(minutes).padStart(2, "0") + ":" + String(seconds).padStart(2, "0");
}

// Suggestions
if (allowedSites.length > 0) {
  document.getElementById("suggestions").style.display = "block";
  const container = document.getElementById("suggestionLinks");
  allowedSites.slice(0, 4).forEach(function(site) {
    const a = document.createElement("a");
    a.href = "https://" + site;
    a.textContent = site;
    a.className = "suggestion-link";
    container.appendChild(a);
  });
}

// "回到工作" — go to Google (safe page)
document.getElementById("goBackBtn").addEventListener("click", function() {
  window.location.href = "https://www.google.com";
});

// "允许 5 分钟" — temp allow then navigate
document.getElementById("allowBtn").addEventListener("click", function() {
  chrome.runtime.sendMessage({
    type: "temp_allow",
    url: blockedURL,
    minutes: 5
  }, function() {
    setTimeout(function() {
      window.location.href = blockedURL;
    }, 300);
  });
});
