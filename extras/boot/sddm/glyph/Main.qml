// Glyph sign-in screen for SDDM. Plain QtQuick so it runs on the Qt5 and Qt6 greeter.
import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1440; height: 900
    color: config.view
    property string font: "IBM Plex Mono"
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property var userNames: []
    property var userReal: []
    property var sessionNames: []
    property string msg: ""

    function uname(i) { return userNames[i] || "" }
    function shown(i) { return (userReal[i] && userReal[i] !== "") ? userReal[i] : uname(i) }
    function initial(i) { var s = shown(i); return s.length ? s.charAt(0).toUpperCase() : "?" }
    function doLogin() { msg = "Signing in…"; sddm.login(uname(userIndex), pw.text, sessionIndex) }

    Connections {
        target: sddm
        function onLoginFailed() { msg = "Wrong password, try again"; pw.text = ""; pw.forceActiveFocus() }
    }

    // collect names from the models
    Repeater { model: userModel; delegate: Item { Component.onCompleted: {
        var a = root.userNames.slice(); a[index] = model.name; root.userNames = a
        var b = root.userReal.slice(); b[index] = model.realName; root.userReal = b } } }
    Repeater { model: sessionModel; delegate: Item { Component.onCompleted: {
        var a = root.sessionNames.slice(); a[index] = model.name; root.sessionNames = a } } }

    // fine scan lines over the background
    Column { anchors.fill: parent; opacity: 0.18; spacing: 3
        Repeater { model: Math.ceil(root.height / 4); Rectangle { width: root.width; height: 1; color: config.lo }
        } }

    Text { x: 24; y: 18; text: "DEBIAN · GLYPH"; color: config.dim; font.family: root.font; font.pixelSize: 13; font.letterSpacing: 1 }
    Text { id: clock; anchors.right: parent.right; anchors.rightMargin: 24; y: 18; color: config.dim; font.family: root.font; font.pixelSize: 13
        function tick() { text = Qt.formatDateTime(new Date(), "ddd d MMM · hh:mm") }
        Component.onCompleted: tick() }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.tick() }

    // the sign-in box
    Rectangle { x: box.x + 8; y: box.y + 8; width: box.width; height: box.height; color: config.lo }
    Rectangle {
        id: box
        width: 440; height: content.height + bar.height + 48
        anchors.centerIn: parent
        color: config.win; border.color: config.title; border.width: 1

        Rectangle { id: bar; width: parent.width; height: 28; color: config.title
            Column { anchors.fill: parent; anchors.topMargin: 3; spacing: 2
                Repeater { model: 8; Rectangle { width: bar.width; height: 1; color: config.tink; opacity: 0.35 } } }
            Rectangle { x: 8; y: 5; width: tl.width + 20; height: 19; color: config.title; border.color: config.tink; border.width: 1
                Text { id: tl; anchors.centerIn: parent; text: "■ SIGN IN"; color: config.tink; font.family: root.font; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1 } }
        }

        Column {
            id: content
            x: 24; y: bar.height + 24; width: parent.width - 48; spacing: 18

            Row { spacing: 14
                Rectangle { width: 56; height: 56; color: "transparent"; border.color: config.dim
                    Text { anchors.centerIn: parent; text: root.initial(root.userIndex); color: config.text; font.family: root.font; font.pixelSize: 22; font.bold: true } }
                Column { anchors.verticalCenter: parent.verticalCenter; spacing: 4
                    Text { text: root.shown(root.userIndex); color: config.text; font.family: root.font; font.pixelSize: 18; font.bold: true }
                    Text { text: root.msg !== "" ? root.msg : "Welcome back"; color: root.msg.indexOf("Wrong") === 0 ? config.rose : config.dim; font.family: root.font; font.pixelSize: 13 } }
            }

            Flow { width: parent.width; spacing: 8; visible: root.userNames.length > 1 && root.userNames.length <= 6
                Repeater { model: root.userNames.length
                    Rectangle { width: ur.width + 16; height: 36; color: config.view
                        border.color: index === root.userIndex ? config.amber : config.hi
                        Row { id: ur; x: 4; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                            Rectangle { width: 28; height: 28; color: config.title
                                Text { anchors.centerIn: parent; text: root.initial(index); color: config.tink; font.family: root.font; font.pixelSize: 13; font.bold: true } }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: root.shown(index); color: config.text; font.family: root.font; font.pixelSize: 13 } }
                        MouseArea { anchors.fill: parent; onClicked: { root.userIndex = index; root.msg = ""; pw.text = ""; pw.forceActiveFocus() } } } } }

            Rectangle { width: parent.width; height: 34; color: config.view; border.color: config.hi; visible: root.userNames.length > 6
                Text { anchors.verticalCenter: parent.verticalCenter; x: 10; text: "‹"; color: config.text; font.family: root.font; font.pixelSize: 16; font.bold: true }
                Text { anchors.centerIn: parent; text: "Other user: " + root.shown(root.userIndex); color: config.text; font.family: root.font; font.pixelSize: 13 }
                Text { anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 10; text: "›"; color: config.text; font.family: root.font; font.pixelSize: 16; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: { var n = root.userNames.length; root.userIndex = (mouse.x < width / 2) ? (root.userIndex + n - 1) % n : (root.userIndex + 1) % n; root.msg = ""; pw.forceActiveFocus() } } }

            Column { width: parent.width; spacing: 6
                Text { text: "Password"; color: config.dim; font.family: root.font; font.pixelSize: 12 }
                Rectangle { width: parent.width; height: 40; color: config.lo; border.color: pw.activeFocus ? config.amber : config.hi
                    TextInput { id: pw; anchors.fill: parent; anchors.margins: 10; verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password; passwordCharacter: "•"; color: config.text; font.family: root.font; font.pixelSize: 14
                        selectionColor: config.title; selectedTextColor: config.tink; focus: true; clip: true
                        Keys.onReturnPressed: root.doLogin(); Keys.onEnterPressed: root.doLogin() }
                    Text { anchors.fill: parent; anchors.margins: 10; verticalAlignment: Text.AlignVCenter; visible: pw.text === ""
                        text: "type your password, then Enter"; color: config.hi; font.family: root.font; font.pixelSize: 14 } } }

            Rectangle { width: parent.width; height: 34; color: config.view; border.color: config.hi
                Text { anchors.verticalCenter: parent.verticalCenter; x: 10; text: "Session"; color: config.dim; font.family: root.font; font.pixelSize: 12 }
                Text { anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 10
                    text: (root.sessionNames[root.sessionIndex] || "") + "  ▸"; color: config.text; font.family: root.font; font.pixelSize: 13; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, root.sessionNames.length) } }

            Rectangle { id: go; width: parent.width; height: 48; color: ma.containsMouse ? config.amber : config.title; border.color: config.lo; border.width: 2
                Column { anchors.fill: parent; anchors.margins: 2; opacity: 0.25; spacing: 2
                    Repeater { model: 14; Rectangle { width: go.width - 4; height: 1; color: config.tink } } }
                Text { anchors.centerIn: parent; text: "SIGN IN ▸"; color: config.tink; font.family: root.font; font.pixelSize: 14; font.bold: true; font.letterSpacing: 1 }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: root.doLogin() } }
        }
    }

    // power, bottom right
    Row { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 20; spacing: 8
        Repeater { model: [["RESTART", 1], ["SHUT DOWN", 2]]
            Rectangle { width: pt.width + 24; height: 32; color: pm.containsMouse ? config.hov : config.view; border.color: modelData[1] === 2 ? config.amber : config.hi
                visible: modelData[1] === 1 ? sddm.canReboot : sddm.canPowerOff
                Text { id: pt; anchors.centerIn: parent; text: modelData[0]; color: modelData[1] === 2 ? config.amber : config.text; font.family: root.font; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1 }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: modelData[1] === 1 ? sddm.reboot() : sddm.powerOff() } } } }

    Component.onCompleted: pw.forceActiveFocus()
}
