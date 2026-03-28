(function() {
  chrome.runtime.sendMessage({ type: "get_rules" }, function(rules) {
    // Rules are handled by background script
  });
})();
