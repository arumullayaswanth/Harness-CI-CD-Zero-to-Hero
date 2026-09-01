// Episode 11 — Harness Code Repository demo app
// A tiny Express API. The app is intentionally simple so the focus
// stays on Harness Code Repo: branches, PRs, code reviews, branch rules.
const express = require("express");

const app = express();
const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.json({
    message: "Hello from Harness Code Repository!",
    episode: 11,
    feature: "Git hosting + PR + Code Review + Branch Rules",
  });
});

app.get("/health", (req, res) => {
  res.json({ status: "healthy" });
});

app.get("/version", (req, res) => {
  res.json({ version: process.env.APP_VERSION || "1.0.0" });
});

// Only start the server when run directly (so tests can import the app)
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
