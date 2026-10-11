# Quote of the Day (Plasma 6 desktop widget)

A daily quote on the KDE Plasma desktop from BrainyQuote's quote-of-the-day RSS feeds (Today's, Art, Funny,
Love, Nature). Cache-first: each feed is fetched at most once a day, after its daily update, and stored locally,
so the quote is shown instantly at login, even offline. Flat and see-through; the text colour is picked for
contrast with the wallpaper.

Modelled on the Rainmeter skin "PIA Quote of the Day".

- Plugin ID: `org.allen.quoteoftheday`
- License: GPL-2.0-or-later (code). Quotes © BrainyQuote, shown for personal use via their public RSS feeds;
  this repository contains no quotes.

## Features
- Categories: pick one, several or all on the Quotes settings page. With more than one, click ⊕ or use the
  mouse wheel to switch.
- Header (feed title), author (bold), quote (regular weight by default; Medium/SemiBold/Bold selectable; wraps), "Read more" at the bottom right (opens the author's
  quotes on BrainyQuote).
- One font family and size (header, author and button scale with the quote size); width in characters.
- Text colour: automatic contrast against the wallpaper (white/black or tinted), custom, or theme colour.

## Network behaviour (BrainyQuote terms: personal use, no scraping)
- Only the RSS feeds are read, never web pages; one request per feed per day, sent with the user-agent
  `AllenQuoteOfTheDay/0.1 (KDE Plasma widget; personal RSS reader, once a day)`.
- Feeds switch at midnight US Eastern; the widget checks shortly after 05:00 UTC, only for feeds whose cached
  quote is older. A failed check is retried after an hour. Nothing else is downloaded (no icons).
- Cache: QML LocalStorage (`~/.local/share/plasmashell/QML/OfflineStorage/`).

## Install
```sh
kpackagetool6 -t Plasma/Applet -i org.allen.quoteoftheday-v0.1.0.plasmoid   # first install (-u to upgrade)
systemctl --user restart plasma-plasmashell
```
or from a clone: `kpackagetool6 -t Plasma/Applet -i package`. Then right-click the desktop → **Add or Manage
Widgets…** → **Quote of the Day**.

## Build and release
```sh
cd package && zip -r ../org.allen.quoteoftheday-v0.1.0.plasmoid . && cd ..
```
Release: bump `"Version"` in `package/metadata.json` (and the version in the user-agent in `ui/main.qml`), commit,
`git tag -a v0.x.y -m "…"`, build, `git push origin main v0.x.y`.

## To consider
- A font picker filtered to families that have Medium/SemiBold faces (Hack Nerd Font has only Regular and Bold;
  similar monospace Nerd Fonts with in-between weights: JetBrainsMono, FiraCode/FiraMono, BlexMono (IBM Plex Mono),
  CaskaydiaMono, GeistMono, AtkynsonMono). Would be a lazy, searchable list built from `fc-list` when "Choose…" is
  clicked (not a ComboBox of all fonts, which is slow).
