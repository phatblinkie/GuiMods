//////// Modified to hide the OverviewTiles page
//////// Modified to substitute flow overview pages

import QtQuick 1.1

import Qt.labs.components.native 1.0
import com.victron.velib 1.0
import "utils.js" as Utils

PageStackWindow {
	id: rootWindow

	gpsConnected: gpsFix.value === 1
	onCompletedChanged: checkAlarm()
	initialPage: PageMain {}

	property VeQuickItem gpsService: VeQuickItem { uid: "dbus/com.victronenergy.system/GpsService" }
	property VeQuickItem gpsFix: VeQuickItem { uid: Utils.path("dbus/", gpsService.value, "/Fix") }
	property bool completed: false
	property bool showAlert: NotificationCenter.alert
	property bool alarm: NotificationCenter.alarm
//////// added for GuiMods flow pages
    property bool overviewsLoaded: defaultOverview.valid && generatorOverview.valid && mobileOverview.valid && startWithMenu.valid && mobileOverviewEnhanced.valid && guiModsFlowOverview.valid && generatorOverviewEnhanced.valid
	property string bindPrefix: "com.victronenergy.settings"

	property bool isNotificationPage: pageStack.currentPage && pageStack.currentPage.title === qsTr("Notifications")
	property bool isOverviewPage: pageStack.currentPage && pageStack.currentPage.model === overviewModel;
	property bool isOfflineFwUpdatePage: pageStack.currentPage && pageStack.currentPage.objectName === "offlineFwUpdatePage";


//////// modified for GuiMods pages
    property string hubOverviewType: theSystem.systemType.valid ?
                        withoutGridMeter.value === 1 ? "Hub" : theSystem.systemType.value : "unknown"
    property string currentHubOverview: "OverviewHub.qml"
    property string currentMobileOverview: ""
    property string currentGeneratorOverview: ""


	// Keep track of the current view (menu/overview) to show as default next time the
	// CCGX is restarted
	onIsOverviewPageChanged: startWithMenu.setValue(isOverviewPage ? 0 : 1)

    // Add the correct OverviewGridParallelEnhanced page
//////// modified for OverviewHubEnhanced page
    onHubOverviewTypeChanged: selectHubOverview ()

    VBusItem
    {
        id: guiModsFlowOverview
        bind: "com.victronenergy.settings/Settings/GuiMods/FlowOverview"
        onValueChanged: selectHubOverview ()
    }

    // base a new hub selection on the hub type and the enhanced flow overview flag
    function selectHubOverview ()
    {
        var newHubOverview = currentHubOverview
		// Victron stock overviews with automatic selection
        if (guiModsFlowOverview.value == 0)
        {
            switch(hubOverviewType){
            case "Hub":
            case "Hub-1":
            case "Hub-2":
            case "Hub-3":
            case "unknown":
                newHubOverview = "OverviewHub.qml"
                break;
            case "Hub-4":
            case "ESS":
                newHubOverview = "OverviewGridParallel.qml"
                break;
            default:
                break;
            }
        }
		// Gui Mods simple flow
		else if (guiModsFlowOverview.value === 1)
        {
			newHubOverview = "OverviewHubEnhanced.qml"
		}
		// Gui Mods complex flow (AC coupled or DC coupled)
		else
		{
			newHubOverview = "OverviewFlowComplex.qml"
        }

        if (newHubOverview != currentHubOverview)
        {
            replaceOverview(currentHubOverview, newHubOverview);
            currentHubOverview = newHubOverview
        }

        // Workaround the QTBUG-17012 (only the first sentence in each case of Switch Statement can be executed)
        // by adding a return statement
        return
    }

	VBusItem {
		id: generatorOverview
		bind: "com.victronenergy.settings/Settings/Relay/Function"
		onValueChanged: selectGeneratorOverview ()
	}

    VBusItem
    {
        id: generatorOverviewEnhanced
        bind: "com.victronenergy.settings/Settings/GuiMods/UseEnhancedGeneratorOverview"
        onValueChanged: selectGeneratorOverview ()
    }

	VBusItem {
		id: fischerPandaGenOverview
		bind: "com.victronenergy.settings/Settings/Services/FischerPandaAutoStartStop"
		onValueChanged: extraOverview("OverviewGeneratorFp.qml", value === 1)
	}
	function selectGeneratorOverview ()
	{
        var newGeneratorOverview
        if (generatorOverview.value === 1)
        {
            if (generatorOverviewEnhanced.value === 1)
				newGeneratorOverview = "OverviewGeneratorRelayEnhanced.qml"
            else
				newGeneratorOverview = "OverviewGeneratorRelay.qml"
            if (currentGeneratorOverview === "")
                extraOverview (newGeneratorOverview, true)
            else
                replaceOverview (currentGeneratorOverview, newGeneratorOverview)
			currentGeneratorOverview = newGeneratorOverview
        }
        else
        {
            // hide existing generator overview if any
            if (currentGeneratorOverview != "")
            {
                extraOverview (currentGeneratorOverview, false)
				currentGeneratorOverview  = ""
            }
        }
	}

//////// handle OverviewMobileEnhanced page
    VBusItem
    {
        id: mobileOverview
        bind: "com.victronenergy.settings/Settings/Gui/MobileOverview"
        onValueChanged: selectMobileOverview ()
    }
    VBusItem
    {
        id: mobileOverviewEnhanced
        bind: "com.victronenergy.settings/Settings/GuiMods/UseEnhancedMobileOverview"
        onValueChanged: selectMobileOverview ()
    }

    // base a new mobile overview selection on the the mobile overview and enhanced mobile overview flags
    function selectMobileOverview ()
    {
        var newMobileOverview
        if (mobileOverview.value === 1)
        {
            if (mobileOverviewEnhanced.value === 1)
                newMobileOverview = "OverviewMobileEnhanced.qml"
            else
                newMobileOverview = "OverviewMobile.qml"
            if (currentMobileOverview === "")
                extraOverview (newMobileOverview, true)
            else
                replaceOverview (currentMobileOverview, newMobileOverview)
                currentMobileOverview = newMobileOverview
        }
        else
        {
            // hide existing mobile overview if any
            if (currentMobileOverview != "")
            {
                extraOverview (currentMobileOverview, false)
                currentMobileOverview = ""
            }
        }
    }

//////// show/hide the OverviewTiles page
    VBusItem
    {
        id: showOverviewTiles
        bind: "com.victronenergy.settings/Settings/GuiMods/ShowTileOverview"
        onValueChanged: extraOverview ("OverviewTiles.qml", value === 1)
    }

//////// show/hide the OverviewRelays page
    VBusItem {
        id: showOverviewRelays
        bind: "com.victronenergy.settings/Settings/GuiMods/ShowRelayOverview"
        onValueChanged: extraOverview ("OverviewRelays.qml", value === 1)
    }

	VBusItem {
		id: startWithMenu
		bind: "com.victronenergy.settings/Settings/Gui/StartWithMenuView"
	}

	VBusItem {
		id: withoutGridMeter
		bind: "com.victronenergy.settings/Settings/CGwacs/RunWithoutGridMeter"
	}


	VBusItem {
		id: defaultOverview
		bind: "com.victronenergy.settings/Settings/Gui/DefaultOverview"
	}

	// Note: finding a firmware image on the storage device is error 4 for vrm storage
	// since it should not be used for logging. That fact is used here to determine if
	// there is a firmware image.
	Connections {
		target: storageEvents
		onVrmStorageError: {
			if (error === 4) {
				setTopPage(offlineFwUpdates)
			}
		}
	}

	onAlarmChanged: {
		if (completed)
			checkAlarm()
	}

	// always keep track of system information
	HubData {
		id: theSystem
	}

	// note: used for leaving the overviews as well
	function backToMainMenu()
	{
		pageStack.pop(initialPage);
	}

	Toast {
		id: toast
		transform: Scale {
			xScale: screen.scaleX
			yScale: screen.scaleY
			origin.x: toast.width / 2
			origin.y: toast.height / 2
		}
	}

	SignalToaster {}

	ToolbarHandlerPages {
		id: mainToolbarHandler
		isDefault: true
	}

	ToolBarLayout {
		id: mbTools
		height: parent.height

		Item {
			anchors.verticalCenter: parent.verticalCenter
			anchors.left: mbTools.left
			height: mbTools.height
			width: 200

			MouseArea {
				anchors.fill: parent
				onClicked: {
					if (pageStack.currentPage)
						pageStack.currentPage.toolbarHandler.leftAction(true)
				}
			}

			Row {
				anchors.centerIn: parent

				MbIcon {
					anchors.verticalCenter: parent.verticalCenter
					iconId: pageStack.currentPage ? pageStack.currentPage.leftIcon : ""
				}

				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: pageStack.currentPage ? pageStack.currentPage.leftText : ""
					color: "white"
					font.bold: true
					font.pixelSize: 16
				}
			}
		}

		MbIcon {
			id: centerScrollIndicator

			anchors {
				horizontalCenter: parent.horizontalCenter
				verticalCenter: mbTools.verticalCenter
			}
			iconId: pageStack.currentPage ? pageStack.currentPage.scrollIndicator : ""
		}

		Item {
			anchors.verticalCenter: parent.verticalCenter
			height: mbTools.height
			anchors.right: mbTools.right
			width: 200

			MouseArea {
				anchors.fill: parent
				onClicked: {
					if (pageStack.currentPage)
						pageStack.currentPage.toolbarHandler.rightAction(true)
				}
			}

			Row {
				anchors.centerIn: parent

				MbIcon {
					iconId: pageStack.currentPage ? pageStack.currentPage.rightIcon : ""
					anchors.verticalCenter: parent.verticalCenter
				}

				Text {
					text: pageStack.currentPage ? pageStack.currentPage.rightText : ""
					anchors.verticalCenter: parent.verticalCenter
					color: "white"
					font.bold: true
					font.pixelSize: 16
				}
			}
		}
	}

    Component.onCompleted: {
        completed = true
    }

	ListModel {
		id: overviewModel
		ListElement {
			pageSource: "OverviewHub.qml"
		}
//////// (commented out) -- added dynamically above
//		ListElement {
//		pageSource: "OverviewTiles.qml"
//		}
	}

	Component {
		id: overviewComponent
		PageFlow {
			// Display default overview when loaded
			defaultIndex: getDefaultOverviewIndex()
			// Store the current overview page as default
			onCurrentIndexChanged: if (active) defaultOverview.setValue(overviewModel.get(currentIndex).pageSource.replace(".qml", ""))
			model: overviewModel
		}
	}

	// When all the related settings items are valid, show the overview page if was the last oppened page
	// before restarting
	Timer {
		interval: 2000
		running: completed && overviewsLoaded && startWithMenu.valid
        onTriggered:
        {
//////// modified for OverviewGridParallelEnhanced page
            selectHubOverview ()
            if (startWithMenu.value === 0) showOverview()
        }
	}

	function getDefaultOverviewIndex()
	{
		if(!defaultOverview.valid)
			return 0
		for (var i = 0; i < overviewModel.count; i++){
			if (overviewModel.get(i).pageSource.replace(".qml", "") === defaultOverview.value) {
				return i
			}
		}
		return 0
	}

	Component {
		id: noticationsComponent
		PageNotifications {}
	}

	Component {
		id: offlineFwUpdates
		PageSettingsFirmwareOffline { checkOnCompleted: true}

	}

	// Add or remove extra overviews. for example, generator overview
	// shouldn't be shown if the start/stop functionality is not enabled.
	// Index parameter is optional, usefull to keep an order.
	function extraOverview(name, show, index)
	{
		var i = 0
		if (show) {
			if (index !== undefined) {
				if (overviewModel.get(index).pageSource === name)
					return
				// First append the page
				overviewModel.append({"pageSource": name})
				// Then move all the pages behind index
				overviewModel.move(index, overviewModel.count - 2, overviewModel.count - 2)
			} else {
				for (i = 0; i < overviewModel.count; i++)
					if (overviewModel.get(i).pageSource === name)
						// Don't append if already exists
						return
				overviewModel.append({"pageSource": name})
			}
		} else {
			for (i = 0; i < overviewModel.count; i++)
				if (overviewModel.get(i).pageSource === name)
					overviewModel.remove(i)
		}
	}

//////// Modified to append page if oldPage not found
    function replaceOverview(oldPage, newPage)
    {
        for (var i = 0; i < overviewModel.count; i++)
        {      
            if (overviewModel.get(i).pageSource === oldPage)
            {         
                overviewModel.get(i).pageSource = newPage
                return
            }
        }
        // here if oldPage wasn't found -- append the new page
        overviewModel.append({"pageSource": newPage})
    }

	// Central mover for the ball animation on the overviews
	// Instead of using a timer per line, using a central one
	// reduces the CPU usage a little bit and makes the animations
	// smoother.
	Timer {
		id: mover
		property double pos: _counter / _loops
		property int _counter
		property int _loops: 13

		interval: 100
		running: true
		repeat: true
		onTriggered: if (_counter >= (_loops - 1)) _counter = 0; else _counter++
	}

	// If an overview or notifications is active, the new page will replace it
	// instead to be pushed. This way we prevent an unwanted stackpage depth
	// increment everytime another page wants to be on top.
	function setTopPage(page)
	{
		if (isNotificationPage || isOverviewPage || isOfflineFwUpdatePage)
			rootWindow.pageStack.replace(page);
		else
			rootWindow.pageStack.push(page);
	}

	function spuriousKeyPress()
	{
		return !pageStack.currentPage || !pageStack.currentPage.active
	}

	function showOverview()
	{
		if (spuriousKeyPress() || isOverviewPage)
			return
		setTopPage(overviewComponent)
	}

	function showPageNotifications()
	{
		if (spuriousKeyPress() || isNotificationPage)
			return
		setTopPage(noticationsComponent)
	}

	function checkAlarm()
	{
		if (alarm)
			showPageNotifications()
	}
}
