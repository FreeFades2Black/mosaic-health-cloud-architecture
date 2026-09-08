/**
 * ==============================================================================
 * MOSAIC HEALTHCARE ENTERPRISE CLOUD ARCHITECTURE & GOVERNANCE PORTAL
 * Instant Mermaid Diagram Renderer for Material for MkDocs
 * ==============================================================================
 * Resolves the issue where diagrams do not re-render upon client-side
 * SPA / PJAX instant navigation (navigation.instant) without a full page refresh.
 * Subscribes to the Material for MkDocs `document$` observable to execute
 * `mermaid.run()` immediately after any DOM replacement or palette toggle.
 */

function getMermaidTheme() {
  const scheme = document.body.getAttribute("data-md-color-scheme");
  return scheme === "slate" ? "dark" : "default";
}

function renderMermaidDiagrams() {
  if (typeof mermaid === "undefined") {
    return;
  }

  const currentTheme = getMermaidTheme();
  mermaid.initialize({
    startOnLoad: false,
    theme: currentTheme,
    securityLevel: "loose",
    fontFamily: "Roboto, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
    themeVariables: currentTheme === "dark"
      ? {
          primaryColor: "#00897b",
          primaryTextColor: "#ffffff",
          primaryBorderColor: "#4ebaaa",
          lineColor: "#80cbc4",
          secondaryColor: "#161b22",
          tertiaryColor: "#0d1117",
          edgeLabelBackground: "#161b22",
          mainBkg: "#0d1117",
          nodeBorder: "#00897b",
          clusterBkg: "#161b22",
          clusterBorder: "#30363d"
        }
      : {
          primaryColor: "#00897b",
          primaryTextColor: "#ffffff",
          primaryBorderColor: "#005b4f",
          lineColor: "#00897b",
          edgeLabelBackground: "#ffffff",
          mainBkg: "#ffffff",
          nodeBorder: "#005b4f"
        }
  });

  // Target all unrendered or fresh .mermaid code blocks
  mermaid.run({
    querySelector: ".mermaid"
  }).catch((err) => {
    console.warn("[Mosaic Architecture Portal] Mermaid render warning:", err);
  });
}

// 1. Subscribe to Material for MkDocs instant navigation observable
if (typeof document$ !== "undefined") {
  document$.subscribe(() => {
    renderMermaidDiagrams();
  });
}

// 2. DOMContentLoaded fallback
document.addEventListener("DOMContentLoaded", () => {
  renderMermaidDiagrams();
});

// 3. Window load fallback (for async CDN script completion)
window.addEventListener("load", () => {
  renderMermaidDiagrams();
});
