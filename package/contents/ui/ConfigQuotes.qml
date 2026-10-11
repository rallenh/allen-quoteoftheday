/*
 * Copyright 2026  Allen Hewes
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
// Which quote categories to use (one, several or all), and the "Read more" button.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../code/feeds.js" as Feeds

KCM.SimpleKCM {
    id: quotesPage

    property var cfg_categories: []
    property alias cfg_showReadMore: showReadMore.checked

    function toggle(id, on) {
        var list = cfg_categories.slice();
        var i = list.indexOf(id);
        if (on && i < 0)
            list.push(id);
        else if (!on && i >= 0)
            list.splice(i, 1);
        // keep the feeds' own order
        cfg_categories = Feeds.FEEDS.map(f => f.id).filter(fid => list.indexOf(fid) >= 0);
    }

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Categories")
            Kirigami.FormData.isSection: true
        }

        Repeater {
            model: Feeds.FEEDS
            delegate: QQC.CheckBox {
                required property var modelData
                required property int index
                Kirigami.FormData.label: index === 0 ? i18n("Show quotes from:") : ""
                text: modelData.name
                checked: quotesPage.cfg_categories.indexOf(modelData.id) >= 0
                // at least one category stays on
                enabled: !(checked && quotesPage.cfg_categories.length === 1)
                onToggled: quotesPage.toggle(modelData.id, checked)
            }
        }

        QQC.Label {
            text: i18n("With more than one category, click ⊕ or use the mouse wheel on the widget to switch.")
            opacity: 0.75
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Button")
            Kirigami.FormData.isSection: true
        }

        QQC.CheckBox {
            id: showReadMore
            text: i18n("Show \"Read more\" (opens the author's quotes on BrainyQuote)")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        QQC.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 28
            wrapMode: Text.WordWrap
            opacity: 0.75
            text: i18n("Quotes come from BrainyQuote's public RSS feeds (personal use). Each feed is checked once a day after its daily update and cached; the widget shows the cached quote at once, even offline.")
        }
    }
}
