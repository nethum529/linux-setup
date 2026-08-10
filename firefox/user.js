// --- moz-mac requirements ---
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("layout.css.backdrop-filter.enabled", true);
user_pref("gfx.webrender.all", true);

// --- Force dark on Linux/KDE (no portal dark-mode signal) ---
// 1 = treat OS as dark; flips Firefox's auto-theme to dark and makes
// prefers-color-scheme:dark match, so moz-mac uses its dark branch.
user_pref("ui.systemUsesDarkTheme", 1);

// --- Let KWin/Klassy decorate Firefox (SSD) so Klassy's traffic-light
// buttons show up. Trade-off: KWin draws its titlebar above the tabs
// instead of tabs sitting in the titlebar Chrome/Safari-style.
user_pref("browser.tabs.inTitlebar", 0);

// --- Compact density (like Chrome) ---
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);

// --- Fast new-window Home: kill the ad/discovery machinery so the page paints
// instantly. Keeps pinned top-site tiles and the wallpaper; only removes the
// billboard ad, promo card, and the per-newtab network fetch (merino).
user_pref("browser.newtabpage.activity-stream.newtabAdSize.billboard", false);
user_pref("browser.newtabpage.activity-stream.discoverystream.promoCard.enabled", false);
user_pref("browser.newtabpage.activity-stream.discoverystream.merino-provider.ohttp.enabled", false);
user_pref("browser.newtabpage.activity-stream.discoverystream.sponsored-collections.enabled", false);

// --- Vertical tabs + sidebar (promoted from prefs.js for portability) ---
user_pref("sidebar.revamp", true);
user_pref("sidebar.verticalTabs", true);
