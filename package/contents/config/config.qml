/*
 * Copyright 2026  Allen Hewes
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop-font"
        source: "ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Quotes")
        icon: "format-text-blockquote"
        source: "ConfigQuotes.qml"
    }
}
