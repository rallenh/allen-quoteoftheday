/*
 * Copyright 2026  Allen Hewes
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
// Font, size, width and text colour.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQControls

KCM.SimpleKCM {
    id: generalPage

    property string cfg_fontFamily
    property alias cfg_fontPointSize: fontPointSize.value
    property alias cfg_widthChars: widthChars.value
    property int cfg_textColorMode
    property string cfg_customPrimaryColor
    property int cfg_autoContrastStyle
    property string cfg_autoContrastColor

    Kirigami.FormLayout {

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Font")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Font family:")
            spacing: Kirigami.Units.smallSpacing
            QQC.Label {
                text: cfg_fontFamily === "" ? i18n("System font (%1)", Kirigami.Theme.defaultFont.family) : cfg_fontFamily
                font.family: cfg_fontFamily === "" ? Kirigami.Theme.defaultFont.family : cfg_fontFamily
            }
            QQC.Button {
                text: i18n("Choose…")
                icon.name: "preferences-desktop-font"
                onClicked: {
                    fontDialogLoader.active = true;
                    fontDialogLoader.item.open();
                }
            }
            QQC.Button {
                text: i18n("System font")
                enabled: cfg_fontFamily !== ""
                onClicked: cfg_fontFamily = ""
            }
        }

        QQC.SpinBox {
            id: fontPointSize
            Kirigami.FormData.label: i18n("Quote size (points):")
            from: 6
            to: 96
            editable: true
        }

        QQC.SpinBox {
            id: widthChars
            Kirigami.FormData.label: i18n("Width (characters):")
            from: 16
            to: 200
            editable: true
        }

        QQC.Label {
            text: i18n("The header, author and button scale with the quote size; the quote wraps within the width.")
            opacity: 0.75
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Colour")
            Kirigami.FormData.isSection: true
        }

        QQC.ButtonGroup { id: colorModeGroup }

        QQC.RadioButton {
            Kirigami.FormData.label: i18n("Text colour:")
            text: i18n("Automatic: best contrast with the wallpaper")
            checked: cfg_textColorMode === 2
            QQC.ButtonGroup.group: colorModeGroup
            onToggled: if (checked) cfg_textColorMode = 2
        }

        RowLayout {
            enabled: cfg_textColorMode === 2
            Layout.leftMargin: Kirigami.Units.gridUnit
            spacing: Kirigami.Units.largeSpacing
            QQC.RadioButton {
                text: i18n("White or black")
                checked: cfg_autoContrastStyle === 0
                onToggled: if (checked) cfg_autoContrastStyle = 0
            }
            QQC.RadioButton {
                text: i18n("Tinted from the wallpaper")
                checked: cfg_autoContrastStyle === 1
                onToggled: if (checked) cfg_autoContrastStyle = 1
            }
        }

        QQC.Label {
            visible: cfg_textColorMode === 2 && cfg_autoContrastColor !== ""
            Layout.leftMargin: Kirigami.Units.gridUnit
            text: i18n("Current automatic colour: %1", cfg_autoContrastColor)
            opacity: 0.75
        }

        RowLayout {
            QQC.RadioButton {
                text: i18n("Custom:")
                checked: cfg_textColorMode === 1
                QQC.ButtonGroup.group: colorModeGroup
                onToggled: if (checked) cfg_textColorMode = 1
            }
            KQControls.ColorButton {
                enabled: cfg_textColorMode === 1
                color: cfg_customPrimaryColor
                showAlphaChannel: false
                dialogTitle: i18n("Text colour")
                onAccepted: function (colour) { cfg_customPrimaryColor = colour.toString(); }
            }
        }

        QQC.RadioButton {
            text: i18n("Plasma theme colour")
            checked: cfg_textColorMode === 0
            QQC.ButtonGroup.group: colorModeGroup
            onToggled: if (checked) cfg_textColorMode = 0
        }
    }

    Loader {
        id: fontDialogLoader
        active: false
        sourceComponent: Component {
            Dialogs.FontDialog {
                title: i18n("Choose a Font")
                currentFont.family: cfg_fontFamily === "" ? Kirigami.Theme.defaultFont.family : cfg_fontFamily
                onAccepted: cfg_fontFamily = selectedFont.family
            }
        }
    }
}
