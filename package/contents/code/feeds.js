/*
 * Copyright 2026  Allen Hewes
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
// BrainyQuote's quote-of-the-day RSS feeds (one new quote per feed per day, published at 05:00 UTC)
// and a small parser for the first item of a feed.

.pragma library

var FEEDS = [
    { id: "quotebr", name: "Today's Quote", url: "https://www.brainyquote.com/link/quotebr.rss" },
    { id: "quotear", name: "Art", url: "https://www.brainyquote.com/link/quotear.rss" },
    { id: "quotefu", name: "Funny", url: "https://www.brainyquote.com/link/quotefu.rss" },
    { id: "quotelo", name: "Love", url: "https://www.brainyquote.com/link/quotelo.rss" },
    { id: "quotena", name: "Nature", url: "https://www.brainyquote.com/link/quotena.rss" }
];

// The daily publication time (UTC hour) and a margin before fetching.
var PUBLISH_HOUR_UTC = 5;
var PUBLISH_MARGIN_MINUTES = 5;

function feed(id) {
    for (var i = 0; i < FEEDS.length; i++) {
        if (FEEDS[i].id === id)
            return FEEDS[i];
    }
    return null;
}

function decode(text) {
    return text.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
               .replace(/<[^>]+>/g, "")
               .replace(/&quot;/g, "\"").replace(/&#39;|&apos;/g, "'").replace(/&amp;/g, "&")
               .replace(/&lt;/g, "<").replace(/&gt;/g, ">")
               .replace(/&#(\d+);/g, function (m, n) { return String.fromCharCode(parseInt(n, 10)); })
               .replace(/\s+/g, " ").trim();
}

function tag(xml, name) {
    var m = new RegExp("<" + name + "[^>]*>([\\s\\S]*?)</" + name + ">", "i").exec(xml);
    return m ? decode(m[1]) : "";
}

/** Parse an RSS document; returns { feedTitle, author, quote, link, pubDate } of the first item, or null. */
function parse(xml) {
    var itemStart = xml.search(/<item[\s>]/i);
    if (itemStart < 0)
        return null;
    var channel = xml.slice(0, itemStart);
    var itemEnd = xml.indexOf("</item>", itemStart);
    var item = xml.slice(itemStart, itemEnd < 0 ? xml.length : itemEnd);
    var quote = tag(item, "description");
    if (quote === "")
        return null;
    return {
        feedTitle: tag(channel, "title"),
        author: tag(item, "title"),
        quote: quote,
        link: tag(item, "link"),
        pubDate: tag(item, "pubDate")
    };
}

/** The most recent publication moment (05:00 UTC today, or yesterday if it's earlier than that). */
function lastPublication(now) {
    var t = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), PUBLISH_HOUR_UTC, 0, 0));
    if (now < t)
        t = new Date(t.getTime() - 24 * 3600 * 1000);
    return t;
}

/** True when the cached entry is older than the latest publication (a newer quote should exist). */
function isStale(entry, now) {
    if (!entry || !entry.pubDate)
        return true;
    var published = Date.parse(entry.pubDate);
    if (isNaN(published))
        return true;
    return published < lastPublication(now).getTime();
}

/** Milliseconds until the next publication plus a margin (when to look for new quotes). */
function msUntilNextPublication(now) {
    var next = lastPublication(now).getTime() + 24 * 3600 * 1000 + PUBLISH_MARGIN_MINUTES * 60 * 1000;
    return Math.max(60 * 1000, next - now.getTime());
}
