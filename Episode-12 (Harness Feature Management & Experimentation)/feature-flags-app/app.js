// Episode 12 — Harness Feature Management & Experimentation (FME) demo app
// FME is the Split-based product. We use the Split SDK (@splitsoftware/splitio).
// The "new_checkout_banner" flag is evaluated with getTreatment -> "on" / "off".
// Toggle targeting rules in Harness FME and the app changes LIVE, no redeploy.
const express = require("express");
const { SplitFactory } = require("@splitsoftware/splitio");

const app = express();
const PORT = process.env.PORT || 3000;

// ← CHANGE: FME server-side SDK key (from Harness Secret Manager / env, never hardcode)
const FME_SDK_KEY = process.env.HARNESS_FME_SDK_KEY || "localhost";

// Create the Split factory once (singleton) and reuse the client everywhere
const factory = SplitFactory({
    core: { authorizationKey: FME_SDK_KEY },
});
const client = factory.client();

let sdkReady = false;
client.on(client.Event.SDK_READY, () => {
    sdkReady = true;
    console.log("FME SDK ready");
});

// Evaluate the flag for a given user key. Returns "on" / "off" / "control".
function evaluateBanner(userKey) {
    // control = SDK not ready / flag not found → treat as OFF (safe default)
    return client.getTreatment(userKey, "new_checkout_banner");
}

app.get("/", (req, res) => {
    const userKey = req.query.user || "anonymous";
    const treatment = sdkReady ? evaluateBanner(userKey) : "control";
    const showBanner = treatment === "on";

    res.send(`
    <html><body style="font-family: sans-serif; text-align:center; padding:40px;">
      <h1>Online Store</h1>
      ${showBanner
            ? '<div style="background:#0a7;color:#fff;padding:20px;border-radius:8px;">🎉 NEW: Faster one-click checkout is here!</div>'
            : "<p>Welcome to the store.</p>"
        }
      <p><small>new_checkout_banner treatment = <b>${treatment}</b> (user: ${userKey})</small></p>
    </body></html>
  `);
});

app.get("/health", (req, res) => res.json({ status: "healthy" }));

if (require.main === module) {
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}

module.exports = app;
