import QtQuick 2.9
import QtQuick.Controls 2.2

import StreamingPreferences 1.0

ScrollView {
    id: settingsPage
    objectName: "Settings"

    StreamingPreferences {
        id: prefs
    }

    Component.onDestruction: {
        prefs.save()
    }

    Column {
        padding: 10
        id: settingsColumn1
        width: settingsPage.width / 2 - padding

        GroupBox {
            id: basicSettingsGroupBox
            width: (parent.width - 2 * parent.padding)
            padding: 12
            title: "<font color=\"skyblue\">Basic Settings</font>"
            font.pointSize: 12

            Column {
                anchors.fill: parent
                spacing: 5

                Label {
                    width: parent.width
                    id: resFPStitle
                    text: qsTr("Resolution and FPS")
                    font.pointSize: 12
                    wrapMode: Text.Wrap                    
                    color: "white"
                }

                Label {
                    width: parent.width
                    id: resFPSdesc
                    text: qsTr("Setting values too high for your PC may cause lag, stuttering, or errors")
                    font.pointSize: 9
                    wrapMode: Text.Wrap
                    color: "white"
                }

                Row {
                    spacing: 5

                    ComboBox {
                        // ignore setting the index at first, and actually set it when the component is loaded
                        Component.onCompleted: {
                            // load the saved width/height, and iterate through the ComboBox until a match is found
                            // and set it to that index.
                            var saved_width = prefs.width
                            var saved_height = prefs.height
                            currentIndex = 0
                            for (var i = 0; i < resolutionComboBox.count; i++) {
                                var el_width = parseInt(resolutionListModel.get(i).video_width);
                                var el_height = parseInt(resolutionListModel.get(i).video_height);
                                if (saved_width === el_width && saved_height === el_height) {
                                    currentIndex = i
                                }
                            }
                        }

                        id: resolutionComboBox
                        font.pointSize: 9
                        textRole: "text"
                        model: ListModel {
                            id: resolutionListModel
                            ListElement {
                                text: "720p"
                                video_width: "1280"
                                video_height: "720"
                            }
                            ListElement {
                                text: "1080p"
                                video_width: "1920"
                                video_height: "1080"
                            }
                            ListElement {
                                text: "1440p"
                                video_width: "2560"
                                video_height: "1440"
                            }
                            ListElement {
                                text: "4K"
                                video_width: "3840"
                                video_height: "2160"
                            }
                        }
                        // ::onActivated must be used, as it only listens for when the index is changed by a human
                        onActivated : {
                            prefs.width = parseInt(resolutionListModel.get(currentIndex).video_width)
                            prefs.height = parseInt(resolutionListModel.get(currentIndex).video_height)

                            prefs.bitrateKbps = prefs.getDefaultBitrate(prefs.width, prefs.height, prefs.fps);
                            slider.value = prefs.bitrateKbps
                        }
                    }

                    ComboBox {
                        // ignore setting the index at first, and actually set it when the component is loaded
                        Component.onCompleted: {
                            // Get the max supported FPS on this system
                            var max_fps = prefs.getMaximumStreamingFrameRate();

                            // Use 64 as the cutoff for adding a separate option to
                            // handle wonky displays that report just over 60 Hz.
                            if (max_fps > 64) {
                                fpsListModel.append({"text": max_fps+" FPS", "video_fps": ""+max_fps})
                            }

                            var saved_fps = prefs.fps
                            currentIndex = 0
                            for (var i = 0; i < fpsComboBox.count; i++) {
                                var el_fps = parseInt(fpsListModel.get(i).video_fps);
                                if (el_fps === saved_fps) {
                                    currentIndex = i
                                }
                            }
                        }

                        id: fpsComboBox
                        font.pointSize: 9
                        textRole: "text"
                        model: ListModel {
                            id: fpsListModel
                            ListElement {
                                text: "30 FPS"
                                video_fps: "30"
                            }
                            ListElement {
                                text: "60 FPS"
                                video_fps: "60"
                            }
                            // A higher value may be added at runtime
                            // based on the attached display refresh rate
                        }
                        // ::onActivated must be used, as it only listens for when the index is changed by a human
                        onActivated : {
                            prefs.fps = parseInt(fpsListModel.get(currentIndex).video_fps)

                            prefs.bitrateKbps = prefs.getDefaultBitrate(prefs.width, prefs.height, prefs.fps);
                            slider.value = prefs.bitrateKbps
                        }
                    }
                }

                Label {
                    width: parent.width
                    id: bitrateTitle
                    text: qsTr("Video bitrate: ")
                    font.pointSize: 12
                    wrapMode: Text.Wrap
                    color: "white"
                }

                Label {
                    width: parent.width
                    id: bitrateDesc
                    text: qsTr("Lower bitrate to reduce lag and stuttering. Raise bitrate to increase image quality.")
                    font.pointSize: 9
                    wrapMode: Text.Wrap
                    color: "white"
                }

                Slider {
                    id: slider
                    wheelEnabled: true

                    value: prefs.bitrateKbps

                    stepSize: 500
                    from : 500
                    to: 150000

                    snapMode: "SnapOnRelease"
                    width: Math.min(bitrateDesc.implicitWidth, parent.width)

                    onValueChanged: {
                        bitrateTitle.text = "Video bitrate: " + (value / 1000.0) + " Mbps"
                        prefs.bitrateKbps = value
                    }
                }

                CheckBox {
                    id: fullScreenCheck
                    text: "<font color=\"white\">Full-screen</font>"
                    font.pointSize:  12
                    checked: prefs.fullScreen
                    onCheckedChanged: {
                        prefs.fullScreen = checked
                    }
                }
            }
        }

        GroupBox {

            id: audioSettingsGroupBox
            width: (parent.width - 2 * parent.padding)
            padding: 12
            title: "<font color=\"skyblue\">Audio Settings</font>"
            font.pointSize: 12

            Column {
                anchors.fill: parent
                spacing: 5

                Label {
                    width: parent.width
                    id: resAudioTitle
                    text: qsTr("Audio configuration")
                    font.pointSize: 12
                    wrapMode: Text.Wrap
                    color: "white"
                }

                ComboBox {
                    // ignore setting the index at first, and actually set it when the component is loaded
                    Component.onCompleted: {
                        var saved_audio = prefs.audioConfig
                        currentIndex = 0
                        for(var i = 0; i < audioListModel.count; i++) {
                            var el_audio= audioListModel.get(i).val;
                          if(saved_audio === el_audio) {
                              currentIndex = i
                          }
                        }
                    }

                    id: audioComboBox
                    width: Math.min(bitrateDesc.implicitWidth, parent.width)
                    font.pointSize: 9
                    textRole: "text"
                    model: ListModel {
                        id: audioListModel
                        ListElement {
                            text: "Autodetect"
                            val: StreamingPreferences.AC_AUTO
                        }
                        ListElement {
                            text: "Stereo"
                            val: StreamingPreferences.AC_FORCE_STEREO
                        }
                        ListElement {
                            text: "5.1 surround sound"
                            val: StreamingPreferences.AC_FORCE_SURROUND
                        }
                    }
                    // ::onActivated must be used, as it only listens for when the index is changed by a human
                    onActivated : {
                        prefs.audioConfig = audioListModel.get(currentIndex).val
                    }
                }

            }
        }
    }

    Column {
        padding: 10
        anchors.left: settingsColumn1.right
        id: settingsColumn2
        width: settingsPage.width / 2 - padding

        GroupBox {
            id: gamepadSettingsGroupBox
            width: (parent.width - parent.padding)
            padding: 12
            title: "<font color=\"skyblue\">Gamepad Settings</font>"
            font.pointSize: 12

            Column {
                anchors.fill: parent
                spacing: 5

                CheckBox {
                    id: multiControllerCheck
                    text: "<font color=\"white\">Multiple controller support</font>"
                    font.pointSize:  12
                    checked: prefs.multiController
                    onCheckedChanged: {
                        prefs.multiController = checked
                    }
                }
            }
        }

        GroupBox {
            id: hostSettingsGroupBox
            width: (parent.width - parent.padding)
            padding: 12
            title: "<font color=\"skyblue\">Host Settings</font>"
            font.pointSize: 12

            Column {
                anchors.fill: parent
                spacing: 5

                CheckBox {
                    id: optimizeGameSettingsCheck
                    text: "<font color=\"white\">Optimize game settings</font>"
                    font.pointSize:  12
                    checked: prefs.gameOptimizations
                    onCheckedChanged: {
                        prefs.gameOptimizations = checked
                    }
                }

                CheckBox {
                    id: audioPcCheck
                    text: "<font color=\"white\">Play audio on host PC</font>"
                    font.pointSize:  12
                    checked: prefs.playAudioOnHost
                    onCheckedChanged: {
                        prefs.playAudioOnHost = checked
                    }
                }
            }
        }

        GroupBox {
            id: advancedSettingsGroupBox
            width: (parent.width - parent.padding)
            padding: 12
            title: "<font color=\"skyblue\">Advanced Settings</font>"
            font.pointSize: 12

            Column {
                anchors.fill: parent
                spacing: 5

                Label {
                    width: parent.width
                    id: resVDSTitle
                    text: qsTr("Video decoder")
                    font.pointSize: 12
                    wrapMode: Text.Wrap
                    color: "white"
                }

                ComboBox {
                    // ignore setting the index at first, and actually set it when the component is loaded
                    Component.onCompleted: {
                        var saved_vds = prefs.videoDecoderSelection
                        currentIndex = 0
                        for(var i = 0; i < decoderListModel.count; i++) {
                            var el_vds = decoderListModel.get(i).val;
                          if(saved_vds === el_vds) {
                              currentIndex = i
                          }
                        }
                    }

                    id: decoderComboBox
                    width: Math.min(bitrateDesc.implicitWidth, parent.width)
                    font.pointSize: 9
                    textRole: "text"
                    model: ListModel {
                        id: decoderListModel
                        ListElement {
                            text: "Automatic (Recommended)"
                            val: StreamingPreferences.VDS_AUTO
                        }
                        ListElement {
                            text: "Force software decoding"
                            val: StreamingPreferences.VDS_FORCE_SOFTWARE
                        }
                        ListElement {
                            text: "Force hardware decoding"
                            val: StreamingPreferences.VDS_FORCE_HARDWARE
                        }
                    }
                    // ::onActivated must be used, as it only listens for when the index is changed by a human
                    onActivated : {
                        prefs.videoDecoderSelection = decoderListModel.get(currentIndex).val
                    }
                }

                Label {
                    width: parent.width
                    id: resVCCTitle
                    text: qsTr("Video codec")
                    font.pointSize: 12
                    wrapMode: Text.Wrap
                    color: "white"
                }

                ComboBox {
                    // ignore setting the index at first, and actually set it when the component is loaded
                    Component.onCompleted: {
                        var saved_vcc = prefs.videoCodecConfig
                        currentIndex = 0
                        for(var i = 0; i < codecListModel.count; i++) {
                            var el_vcc = codecListModel.get(i).val;
                          if(saved_vcc === el_vcc) {
                              currentIndex = i
                          }
                        }
                    }

                    id: codecComboBox
                    width: Math.min(bitrateDesc.implicitWidth, parent.width)
                    font.pointSize: 9
                    textRole: "text"
                    model: ListModel {
                        id: codecListModel
                        ListElement {
                            text: "Automatic (Recommended)"
                            val: StreamingPreferences.VCC_AUTO
                        }
                        ListElement {
                            text: "Force H.264"
                            val: StreamingPreferences.VCC_FORCE_H264
                        }
                        ListElement {
                            text: "Force HEVC"
                            val: StreamingPreferences.VCC_FORCE_HEVC
                        }
                        // HDR seems to be broken in GFE 3.14.1, and even when that's fixed
                        // we'll probably need to gate this feature on OS support in our
                        // renderers.
                        /* ListElement {
                            text: "Force HEVC HDR"
                            val: StreamingPreferences.VCC_FORCE_HEVC_HDR
                        } */
                    }
                    // ::onActivated must be used, as it only listens for when the index is changed by a human
                    onActivated : {
                        prefs.videoCodecConfig = codecListModel.get(currentIndex).val
                    }
                }

            }
        }
    }
}
