/*
 * Copyright 2026  Allen Hewes
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */

// Quote of the Day (modelled on the Rainmeter skin "PIA Quote of the Day"): BrainyQuote's daily quote feeds,
// cache-first. Cached quotes are shown at once; each feed is fetched at most once a day, after its daily
// publication, and only while its cached quote is older than that. Sizes derive from the quote font.

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/feeds.js" as Feeds
import "../code/cache.js" as Cache
import "../code/contrast.js" as Contrast

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground | PlasmaCore.Types.ConfigurableBackground
    preferredRepresentation: fullRepresentation

    // ---- categories ----
    readonly property var categories: Plasmoid.configuration.categories.length > 0 ? Plasmoid.configuration.categories : ["quotebr"]
    readonly property string current: categories.indexOf(Plasmoid.configuration.currentCategory) >= 0
                                      ? Plasmoid.configuration.currentCategory : categories[0]
    property var quotes: ({})          // id -> { feedTitle, author, quote, link, pubDate }
    readonly property var entry: quotes[current] || null

    function step(delta) {
        var i = categories.indexOf(current);
        var next = categories[(i + delta + categories.length) % categories.length];
        Plasmoid.configuration.currentCategory = next;
    }

    // ---- text colour (same model as the Wunderground fork and Month Calendar) ----
    readonly property int textColorMode: Plasmoid.configuration.textColorMode
    property color autoTextColor: Plasmoid.configuration.autoContrastColor !== "" ? Plasmoid.configuration.autoContrastColor : Kirigami.Theme.textColor
    readonly property color primaryColor: textColorMode === 1 ? Plasmoid.configuration.customPrimaryColor
                                        : textColorMode === 2 ? autoTextColor
                                        : Kirigami.Theme.textColor
    readonly property bool lightBackground: Contrast.luminance(primaryColor) < 0.4
    // Rainmeter: quote and header at ~59 % on a dark wallpaper; stronger on light ones so they stay readable
    readonly property real softAlpha: lightBackground ? 0.85 : 0.63

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // ---- fonts: everything is measured from the quote font (Rainmeter: quote 18 pt, header/author 10 pt) ----
    readonly property string fontFamily: Plasmoid.configuration.fontFamily !== "" ? Plasmoid.configuration.fontFamily : Kirigami.Theme.defaultFont.family
    readonly property real quotePointSize: Plasmoid.configuration.fontPointSize
    readonly property real smallPointSize: Math.max(6, quotePointSize * 0.56)
    FontMetrics { id: quoteMetrics; font.family: root.fontFamily; font.pointSize: root.quotePointSize; font.bold: true }

    // ---- loading: cache first, network once a day ----
    function loadCache() {
        var q = {};
        for (var i = 0; i < Feeds.FEEDS.length; i++) {
            var cached = Cache.load("quote|" + Feeds.FEEDS[i].id);
            if (cached && cached.value)
                q[Feeds.FEEDS[i].id] = cached.value;
        }
        quotes = q;
    }

    property var queue: []
    property bool fetchFailed: false

    function refreshStale() {
        var now = new Date();
        var q = [];
        for (var i = 0; i < categories.length; i++) {
            if (Feeds.isStale(quotes[categories[i]], now))
                q.push(categories[i]);
        }
        queue = q;
        fetchFailed = false;
        fetchNext();
    }

    function fetchNext() {
        if (queue.length === 0) {
            retryTimer.running = fetchFailed;   // try again in an hour only if something failed
            return;
        }
        var id = queue[0];
        queue = queue.slice(1);
        var f = Feeds.feed(id);
        if (!f) {
            fetchNext();
            return;
        }
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            var parsed = xhr.status === 200 ? Feeds.parse(xhr.responseText) : null;
            if (parsed) {
                var q = Object.assign({}, root.quotes);
                q[id] = parsed;
                root.quotes = q;
                Cache.save("quote|" + id, parsed);
            } else {
                root.fetchFailed = true;
            }
            gapTimer.start();   // a short pause between feeds
        };
        xhr.open("GET", f.url);
        // Identify ourselves honestly (BrainyQuote's terms: personal use, their public RSS feeds, no scraping)
        xhr.setRequestHeader("User-Agent", "AllenQuoteOfTheDay/0.1 (KDE Plasma widget; personal RSS reader, once a day)");
        xhr.send();
    }

    Timer { id: gapTimer; interval: 1500; onTriggered: root.fetchNext() }
    Timer { id: startupTimer; interval: Plasmoid.configuration.startupDelay * 1000; running: true; onTriggered: root.refreshStale() }
    Timer { id: retryTimer; interval: 60 * 60 * 1000; onTriggered: root.refreshStale() }
    Timer {
        id: dailyTimer
        running: true
        interval: Feeds.msUntilNextPublication(new Date()) + Math.floor(Math.random() * 10 * 60 * 1000)
        onTriggered: {
            root.refreshStale();
            interval = Feeds.msUntilNextPublication(new Date()) + Math.floor(Math.random() * 10 * 60 * 1000);
            start();
        }
    }

    // A newly ticked category gets its quote without waiting for the next day
    onCategoriesChanged: if (!startupTimer.running) refreshStale()

    Component.onCompleted: loadCache()

    // ---- automatic text colour: analyse the wallpaper once, not per frame ----
    Kirigami.ImageColors {
        id: wallpaperColors
        onPaletteChanged: root.updateAutoContrast()
    }

    function analyseWallpaper() {
        if (textColorMode !== 2)
            return;
        var wallpaper = Plasmoid.containment ? Plasmoid.containment.wallpaperGraphicsObject : null;
        if (!wallpaper)
            return;
        wallpaperColors.source = wallpaper;
        wallpaperColors.update();
    }

    function updateAutoContrast() {
        var palette = wallpaperColors.palette;
        if (!palette || palette.length === 0)
            return;
        var background = wallpaperColors.average;
        var colour;
        if (Plasmoid.configuration.autoContrastStyle === 1) {
            var tint = palette[0].color;
            for (var i = 1; i < palette.length; i++) {
                if (palette[i].color.hslSaturation > tint.hslSaturation)
                    tint = palette[i].color;
            }
            colour = Contrast.tinted(background, tint);
        } else {
            colour = Contrast.blackOrWhite(background);
        }
        var hex = Contrast.toHex(colour);
        autoTextColor = hex;
        if (Plasmoid.configuration.autoContrastColor !== hex)
            Plasmoid.configuration.autoContrastColor = hex;
    }

    Timer {
        id: wallpaperTimer
        interval: 30 * 1000
        repeat: true
        running: root.textColorMode === 2
        onTriggered: {
            root.analyseWallpaper();
            interval = 30 * 60 * 1000;
        }
    }

    Connections {
        target: Plasmoid.containment
        ignoreUnknownSignals: true
        function onWallpaperGraphicsObjectChanged() {
            wallpaperTimer.interval = 5 * 1000;
            wallpaperTimer.restart();
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onAutoContrastStyleChanged() { root.analyseWallpaper(); }
        function onTextColorModeChanged() { root.analyseWallpaper(); }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Next Category")
            icon.name: "go-next"
            enabled: root.categories.length > 1
            onTriggered: root.step(1)
        },
        PlasmaCore.Action {
            text: i18n("Open Quote Page")
            icon.name: "internet-web-browser"
            enabled: root.entry !== null && root.entry.link !== ""
            onTriggered: Qt.openUrlExternally(root.entry.link)
        }
    ]

    fullRepresentation: Item {
        id: area

        readonly property real gap: quoteMetrics.height * 0.6
        readonly property real buttonSize: quoteMetrics.height * 1.5
        readonly property real contentWidth: Plasmoid.configuration.widthChars * quoteMetrics.averageCharacterWidth

        implicitWidth: view.implicitWidth
        implicitHeight: view.implicitHeight
        Layout.preferredWidth: view.implicitWidth
        Layout.preferredHeight: view.implicitHeight
        Layout.minimumWidth: view.implicitWidth
        Layout.minimumHeight: view.implicitHeight

        // Mouse wheel moves through the categories in use
        WheelHandler {
            enabled: root.categories.length > 1
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function (event) {
                root.step(event.angleDelta.y < 0 ? 1 : -1);
            }
        }

        RowLayout {
            id: view
            anchors.centerIn: parent
            spacing: area.gap

            // ⊕ : next category (a local glyph, nothing downloaded)
            Rectangle {
                id: nextButton
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: area.gap * 0.3
                implicitWidth: area.buttonSize
                implicitHeight: area.buttonSize
                radius: width / 2
                color: "transparent"
                border.width: Math.max(1.5, quoteMetrics.height * 0.07)
                border.color: root.withAlpha(root.primaryColor, nextMouse.containsMouse ? 1.0 : 0.59)
                visible: root.categories.length > 1

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    text: "+"
                    font.family: root.fontFamily
                    font.pointSize: root.quotePointSize
                    font.bold: true
                    color: parent.border.color
                }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.step(1)
                }
                PlasmaCore.ToolTipArea {
                    anchors.fill: parent
                    mainText: i18n("Next: %1", Feeds.feed(root.categories[(root.categories.indexOf(root.current) + 1) % root.categories.length]).name)
                }
            }

            ColumnLayout {
                Layout.preferredWidth: area.contentWidth
                Layout.minimumWidth: area.contentWidth
                Layout.maximumWidth: area.contentWidth
                spacing: area.gap * 0.35

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: area.gap * 0.25

                        // "Today's Quote", "Funny Quote of the Day", ... (small, letter-spaced)
                        PlasmaComponents.Label {
                            text: root.entry ? root.entry.feedTitle : Feeds.feed(root.current).name
                            font.family: root.fontFamily
                            font.pointSize: root.smallPointSize
                            font.letterSpacing: root.smallPointSize * 0.2
                            color: root.withAlpha(root.primaryColor, root.softAlpha)
                        }
                        // Author: bold, full colour
                        PlasmaComponents.Label {
                            text: root.entry ? root.entry.author : ""
                            visible: text !== ""
                            font.family: root.fontFamily
                            font.pointSize: root.smallPointSize
                            font.bold: true
                            color: root.primaryColor
                        }
                    }

                }

                // The quote
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.entry ? root.entry.quote : i18n("The first quote arrives shortly…")
                    wrapMode: Text.WordWrap
                    font.family: root.fontFamily
                    font.pointSize: root.entry ? root.quotePointSize : root.smallPointSize
                    font.bold: root.entry !== null
                    color: root.withAlpha(root.primaryColor, root.softAlpha)
                }

                // Footer: "Read more" at the bottom right, like a footnote
                RowLayout {
                    Layout.fillWidth: true
                    visible: Plasmoid.configuration.showReadMore && root.entry !== null && root.entry.link !== ""
                    Item { Layout.fillWidth: true }
                    // "Read more": an outlined pill; opens the quote's page
                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: readMoreLabel.implicitWidth + quoteMetrics.height * 0.9
                        implicitHeight: readMoreLabel.implicitHeight + quoteMetrics.height * 0.35
                        radius: height / 2
                        color: "transparent"
                        border.width: Math.max(1, quoteMetrics.height * 0.05)
                        border.color: root.withAlpha(root.primaryColor, readMoreMouse.containsMouse ? 1.0 : root.softAlpha)

                        PlasmaComponents.Label {
                            id: readMoreLabel
                            anchors.centerIn: parent
                            text: i18n("Read more")
                            font.family: root.fontFamily
                            font.pointSize: root.smallPointSize
                            font.letterSpacing: root.smallPointSize * 0.2
                            font.bold: readMoreMouse.containsMouse
                            color: parent.border.color
                        }
                        PlasmaCore.ToolTipArea {
                            anchors.fill: parent
                            mainText: i18n("More quotes by %1 on BrainyQuote", root.entry ? root.entry.author : "")
                            subText: root.entry ? root.entry.link : ""
                        }
                        MouseArea {
                            id: readMoreMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(root.entry.link)
                        }
                    }
                }
            }
        }
    }
}
