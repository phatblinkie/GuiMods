// This file has been modified:
//   Show mixed case text names in tile title even when not in compact display
//   A sliver of the level bar remains when the tank is empty so there is some indication of empty
//   Show actual level in addition to percentage
//   reduce tile height when needed, mainly to fit on Flow overview page
//   changes in prevous versions have been restored to stock

import QtQuick 1.1
import "utils.js" as Utils
//// add to display of remaining volume
import "tanksensor.js" as TankSensor

Tile {
	id: root

//// add to allow displaying remaining volume
    property VBusItem remainingItem: VBusItem { id: remainingItem; bind: Utils.path(bindPrefix, "/Remaining"); decimals: 0 }
    property VBusItem volumeUnit: VBusItem { bind: "com.victronenergy.settings/Settings/System/VolumeUnit" }
    property VBusItem capacityItem: VBusItem { bind: Utils.path (bindPrefix, "/Capacity") }
    property real capacity: capacityItem.valid ? TankSensor.volumeConvertFromSI (volumeUnit.value, capacityItem.value) : 0

//// small tile height threshold
    property bool squeeze: height < 50

    property string bindPrefix: serviceName
    property string pumpBindPrefix
    property VBusItem levelItem: VBusItem { id: levelItem; bind: Utils.path(bindPrefix, "/Level"); decimals: 0; unit: "%" }
    property VBusItem fluidTypeItem: VBusItem { id: fluidTypeItem; bind: Utils.path(bindPrefix, "/FluidType") }
    property VBusItem customNameItem: VBusItem { id: customNameItem; bind: Utils.path(bindPrefix, "/CustomName") }
    property VBusItem pumpStateItem: VBusItem { id: pumpStateItem; bind: Utils.path(pumpBindPrefix, "/State") }
    property VBusItem pumpActiveService: VBusItem { id: pumpActiveService; bind: Utils.path(pumpBindPrefix, "/ActiveTankService") }

    property alias valueBarColor: valueBar.color
    property alias level: levelItem.value
    property int fullWarningLevel: ([2, 5].indexOf(fluidTypeItem.value) > -1) ? 80 : -1
    property int emptyWarningLevel: !([2, 5].indexOf(fluidTypeItem.value) > -1) ? 20 : -1

    property variant fluidTypes: [qsTr("Fuel"), qsTr("Fresh water"), qsTr("Waste water"), qsTr("Live well"), qsTr("Oil"), qsTr("Black water")]
    property string tankName: customNameItem.valid && customNameItem.value !== "" ? customNameItem.value : fluidTypeItem.valid ? fluidTypes[fluidTypeItem.value] : "TANK"

    property variant fluidColor: ["#1abc9c", "#4aa3df", "#95a5a6", "#dcc6e0", "#f1a9a0", "#7f8c8d"]
    property bool blink: true
    property bool compact: false

//// add to allow %, units, both in tank bar
    property VBusItem tankBarFormatItem: VBusItem { bind: Utils.path (settingsPrefix, "/Settings/GuiMods/TankBarFormat") }
	property int tankBarFormat: tankBarFormatItem.valid ? tankBarFormatItem.value : 0

///// modified to keep mixed case names
    title: compact ? "" : tankName
    color: fluidTypeItem.valid ? fluidColor[fluidTypeItem.value] : "#4aa3df"

    Timer {
        interval: 1000
        running: pumpActiveService.value === bindPrefix && pumpStateItem.value === 1
        repeat: true
        onTriggered: blink = !blink
        onRunningChanged: if (!running) blink = true
    }

    function doScroll()
    {
        tankText.doScroll()
    }

    function warning()
    {
        if (fullWarningLevel != -1 && level >= fullWarningLevel)
            return true
        if (emptyWarningLevel != -1 && level <= emptyWarningLevel)
            return true
        return false
    }

    values: Item {
        width: root.width - 8
//// modified to squeeze bar height if space is tight
        height: compact ? root.height : squeeze ? 17 : 21

        MarqueeEnhanced {
            id: tankText
//// modified to give bar more horizontal space
            width: parent.width - barWindow.width
            height: compact ? 13 : parent.height
            text: compact ? tankName : ""
            textHorizontalAlignment: Text.AlignLeft
            visible: compact
            scroll: false
            anchors {
//// modified to give move bar over title's line if space is tight
                verticalCenter: parent.verticalCenter; verticalCenterOffset: compact ? -9 : squeeze ? -4 : 0
            }
        }

        Rectangle {
			id: barWindow
            color: "#95a5a6"
            border { width:1; color: "white" }
			width:
			{
				if (compact)
				{
					// extra space to display % and units
					if (tankBarFormat == 0)
						return (root.width - 5) * 0.7
					// m3 requires additional space
					else if (volumeUnit.value == 0)
					{
						var tempWidth = (root.width - 5) * 0.7
						return Math.min (tempWidth, 60)
					}
					else
						return (root.width - 5) * 0.5
				}
				else
					return root.width - 10
			}
            height: compact ? 13 : parent.height
            anchors {
//// modified to give move bar over title's line if space is tight
                verticalCenter: parent.verticalCenter; verticalCenterOffset: compact ? -9 : squeeze ? -4 : 0
				right: parent.right; rightMargin: 1
            }

            Rectangle {
                id: valueBar
//// modified to always show a sliver of a bar even if tank is empty
                width: Math.max (root.level / 100 * parent.width - 2, 2)
                height: parent.height - 1
                color: warning() ? "#e74c3c" : "#34495e"
                opacity: blink ? 1 : 0.5
                anchors {
                    verticalCenter: parent.verticalCenter;
                    left: parent.left; leftMargin: 1
                }
            }

            Text {
                font.pixelSize: 12
                font.bold: true
//// include actual level in display
				text:
                {
					var levelText = ""
                    var remainingText = ""

					// show percentage - force percentage if no capacity
					if (tankBarFormat == 0 || tankBarFormat == 1 || capacity == 0)
					{
						if (levelItem.valid)
							levelText = levelItem.text
						else
							levelText = "?"
					}

					// show units
					if ((tankBarFormat == 0 || tankBarFormat == 2) && capacity != 0)
					{
						if (remainingItem.valid)
						{
							var remaining = TankSensor.volumeConvertFromSI(volumeUnit.value, remainingItem.value)
							var fmt = TankSensor.getVolumeFormat(volumeUnit.value)
							if (fmt.unit == "gal")
								fmt.unit = "g"
							// show only one significant digit for 0 value
							if (remaining == 0)
								fmt.precision = 0
							// increase precision if less than 2 significant digits at full capacity
							else if (capacity * Math.pow (10, fmt.precision) < 10)
								fmt.precision += 1
							remainingText = remaining.toFixed(fmt.precision) + fmt.unit
						}
						else
							remainingText = "?"
					}
					switch (tankBarFormat)
					{
						default: return levelText + " " + remainingText; break;
						case 1: return levelText; break;
						case 2: return remainingText; break;
					}
                }
				anchors.centerIn: parent
                color: "white"
            }
        }
    }
}

