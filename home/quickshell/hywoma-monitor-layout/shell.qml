import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: root

  readonly property int columns: 3
  readonly property int cellSize: 150
  readonly property int cellGap: 14
  readonly property int monitorInset: 8
  readonly property int monitorRadius: 12
  readonly property int cellRadius: monitorRadius + monitorInset
  readonly property int monitorCardSize: cellSize - 2 * monitorInset
  readonly property int cellPitch: monitorCardSize + cellGap
  readonly property int previewWidth: monitors.count === 0 ? 0 : (layoutOrientation === "horizontal" ? 2 * monitorInset + monitors.count * monitorCardSize + (monitors.count - 1) * cellGap : cellSize)
  readonly property int previewHeight: monitors.count === 0 ? 0 : (layoutOrientation === "vertical" ? 2 * monitorInset + monitors.count * monitorCardSize + (monitors.count - 1) * cellGap : cellSize)
  readonly property int minimumPanelWidth: 760
  readonly property int minimumPanelHeight: 520
  readonly property int panelChromeHeight: detachedSlots.count > 0 ? 244 : 188
  readonly property int basePanelWidth: Math.max(minimumPanelWidth, previewWidth + 72)
  readonly property int basePanelHeight: Math.max(minimumPanelHeight, previewHeight + panelChromeHeight)
  readonly property int settingsPanelWidth: 330
  readonly property int settingsPanelGap: 18
  readonly property string fg: "#f5f5f5"
  readonly property string mutedFg: "#b8b8c0"
  readonly property string dimFg: "#8f90a0"
  readonly property string panelBorder: "#d8d8e0"
  readonly property string subtleBorder: "#4b4c5c"

  property int cursorCell: 4
  property string statusText: "Loading hywoma status..."
  property bool loadedFromHywoma: false
  property bool applying: false
  property var applyQueue: []
  property string lastApplyStdout: ""
  property string lastApplyStderr: ""
  property string lastSwapStdout: ""
  property string lastSwapStderr: ""
  property string layoutOrientation: "horizontal"
  property string originalOrientation: "horizontal"
  property bool topologyDirty: false
  property bool suppressMonitorMovementAnimation: false
  property bool settingsOpen: false
  property real settingsProgress: settingsOpen ? 1 : 0
  property int settingsMonitorIndex: -1
  property int settingsRow: 0
  property int settingsSavedWidth: 0
  property int settingsSavedHeight: 0
  property real settingsSavedRefreshRate: 0
  property real settingsSavedScale: 1
  property int settingsSavedTransform: 0
  property var scaleSteps: [1.0, 1.25, 1.333333, 1.5, 1.6, 1.75, 2.0]

  Behavior on settingsProgress { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  WlrLayershell.namespace: "hywoma-monitor-layout"

  function cellRow(cell) {
    return Math.floor(cell / columns)
  }

  function cellColumn(cell) {
    return cell % columns
  }

  function topologyCells(count, orientation) {
    if (count <= 0)
      return []
    if (count === 1)
      return [4]
    if (orientation === "vertical")
      return count === 2 ? [1, 7] : [1, 4, 7]
    return count === 2 ? [3, 5] : [3, 4, 5]
  }

  function inferOrientation(monitorList) {
    if (monitorList.length < 2)
      return "horizontal"
    const xs = monitorList.map(monitor => monitor.x)
    const ys = monitorList.map(monitor => monitor.y)
    const xSpan = Math.max(...xs) - Math.min(...xs)
    const ySpan = Math.max(...ys) - Math.min(...ys)
    return ySpan > xSpan ? "vertical" : "horizontal"
  }

  function monitorIndexAtCell(cell) {
    for (let i = 0; i < monitors.count; i++) {
      if (monitors.get(i).cell === cell)
        return i
    }
    return -1
  }

  function monitorIndexForOutput(output) {
    for (let i = 0; i < monitors.count; i++) {
      if (monitors.get(i).output === output)
        return i
    }
    return -1
  }

  function monitorIndicesInTopologyOrder() {
    const indices = []
    for (let i = 0; i < monitors.count; i++)
      indices.push(i)
    indices.sort((a, b) => {
      const monitorA = monitors.get(a)
      const monitorB = monitors.get(b)
      const axisA = layoutOrientation === "vertical" ? cellRow(monitorA.cell) : cellColumn(monitorA.cell)
      const axisB = layoutOrientation === "vertical" ? cellRow(monitorB.cell) : cellColumn(monitorB.cell)
      return axisA - axisB
    })
    return indices
  }

  function assignTopologyCells(indices, setOriginal) {
    const cells = topologyCells(indices.length, layoutOrientation)
    for (let order = 0; order < indices.length; order++) {
      monitors.setProperty(indices[order], "cell", cells[order])
      if (setOriginal)
        monitors.setProperty(indices[order], "originalCell", cells[order])
    }
  }

  function updateTopologyDirty() {
    topologyDirty = layoutOrientation !== originalOrientation
    if (topologyDirty)
      return
    for (let i = 0; i < monitors.count; i++) {
      if (monitors.get(i).cell !== monitors.get(i).originalCell) {
        topologyDirty = true
        return
      }
    }
  }

  function initializeTopologyCells() {
    const indices = []
    for (let i = 0; i < monitors.count; i++)
      indices.push(i)
    indices.sort((a, b) => {
      const monitorA = monitors.get(a)
      const monitorB = monitors.get(b)
      if (layoutOrientation === "vertical")
        return monitorA.originalY - monitorB.originalY || monitorA.originalX - monitorB.originalX
      return monitorA.originalX - monitorB.originalX || monitorA.originalY - monitorB.originalY
    })
    assignTopologyCells(indices, true)
  }

  function monitorIndexForSlot(slot) {
    for (let i = 0; i < monitors.count; i++) {
      if (monitors.get(i).slot === slot)
        return i
    }
    return -1
  }

  function selectedMonitorIndex() {
    return monitorIndexAtCell(cursorCell)
  }

  function detachedIndexForSlot(slot) {
    for (let i = 0; i < detachedSlots.count; i++) {
      if (detachedSlots.get(i).slot === slot)
        return i
    }
    return -1
  }

  function slotInfo(slot) {
    for (let i = 0; i < allSlots.count; i++) {
      if (allSlots.get(i).slot === slot)
        return allSlots.get(i)
    }
    return null
  }

  function slotForKey(key) {
    for (let i = 0; i < allSlots.count; i++) {
      const slot = allSlots.get(i)
      if (slot.key === key)
        return slot.slot
    }
    return null
  }

  function setMonitorSlot(index, slotInfo) {
    monitors.setProperty(index, "slot", slotInfo.slot)
    monitors.setProperty(index, "slotKey", slotInfo.key)
    monitors.setProperty(index, "slotLabel", slotInfo.label)
  }

  function setCursor(cell) {
    cursorCell = Math.min(8, Math.max(0, cell))
  }

  function moveCursor(dx, dy) {
    const sourceIndex = monitorIndexAtCell(cursorCell)
    const axisDelta = layoutOrientation === "vertical" ? dy : dx
    if (axisDelta === 0 || monitors.count === 0)
      return

    const indices = monitorIndicesInTopologyOrder()
    const sourceOrder = Math.max(0, indices.indexOf(sourceIndex))
    const targetOrder = Math.min(indices.length - 1, Math.max(0, sourceOrder + axisDelta))
    setCursor(monitors.get(indices[targetOrder]).cell)
  }

  function swapOrMove(dx, dy) {
    const axisDelta = layoutOrientation === "vertical" ? dy : dx
    const perpendicularDelta = layoutOrientation === "vertical" ? dx : dy
    if (perpendicularDelta !== 0 || axisDelta === 0)
      return

    const sourceIndex = monitorIndexAtCell(cursorCell)
    if (sourceIndex < 0)
      return

    const indices = monitorIndicesInTopologyOrder()
    const sourceOrder = indices.indexOf(sourceIndex)
    const targetOrder = sourceOrder + axisDelta
    if (targetOrder < 0 || targetOrder >= indices.length)
      return

    const targetIndex = indices[targetOrder]
    const sourceCell = monitors.get(sourceIndex).cell
    const targetCell = monitors.get(targetIndex).cell
    monitors.setProperty(sourceIndex, "cell", targetCell)
    monitors.setProperty(targetIndex, "cell", sourceCell)
    setCursor(targetCell)
    updateTopologyDirty()
    refreshDraftTexts()
    statusText = "Draft " + layoutOrientation + " monitor order changed."
  }

  function toggleTopology() {
    if (monitors.count < 2)
      return
    suppressMonitorMovementAnimation = true
    const selectedIndex = selectedMonitorIndex()
    const indices = monitorIndicesInTopologyOrder()
    layoutOrientation = layoutOrientation === "horizontal" ? "vertical" : "horizontal"
    assignTopologyCells(indices, false)
    updateTopologyDirty()
    if (selectedIndex >= 0)
      setCursor(monitors.get(selectedIndex).cell)
    refreshDraftTexts()
    statusText = "Draft topology: " + layoutOrientation + "."
    Qt.callLater(() => suppressMonitorMovementAnimation = false)
  }

  function assignSelectedMonitorToSlot(targetSlot) {
    if (targetSlot === null)
      return

    const sourceIndex = monitorIndexAtCell(cursorCell)
    if (sourceIndex < 0)
      return

    const sourceMonitor = monitors.get(sourceIndex)
    if (sourceMonitor.slot === targetSlot) {
      statusText = sourceMonitor.output + " already has slot " + sourceMonitor.slotKey + "."
      return
    }

    const sourceSlotInfo = slotInfo(sourceMonitor.slot)
    const targetSlotInfo = slotInfo(targetSlot)
    if (sourceSlotInfo === null || targetSlotInfo === null)
      return

    const targetIndex = monitorIndexForSlot(targetSlot)
    if (targetIndex >= 0) {
      setMonitorSlot(sourceIndex, targetSlotInfo)
      setMonitorSlot(targetIndex, sourceSlotInfo)
      statusText = "Draft slot swap: " + sourceMonitor.output + " now uses slot " + targetSlotInfo.key + "."
      return
    }

    const detachedIndex = detachedIndexForSlot(targetSlot)
    const detachedWorkspaceCount = detachedIndex >= 0 ? detachedSlots.get(detachedIndex).workspaceCount : 0
    if (detachedIndex >= 0)
      detachedSlots.remove(detachedIndex)

    setMonitorSlot(sourceIndex, targetSlotInfo)
    if (detachedWorkspaceCount > 0) {
      detachedSlots.append({
        slot: sourceSlotInfo.slot,
        slotKey: sourceSlotInfo.key,
        slotLabel: sourceSlotInfo.label,
        workspaceCount: detachedWorkspaceCount,
      })
    }
    statusText = "Draft slot assignment: " + sourceMonitor.output + " now uses detached slot " + targetSlotInfo.key + "."
  }

  function swapWithDetachedSlot(targetSlot) {
    const detachedIndex = detachedIndexForSlot(targetSlot)
    if (detachedIndex < 0) {
      const targetSlotInfo = slotInfo(targetSlot)
      statusText = "Slot " + (targetSlotInfo?.key ?? targetSlot) + " is not detached."
      return
    }
    if (changedSlotAssignments().length > 0 || physicalDraftActive()) {
      statusText = "Apply or discard the monitor draft before swapping detached workspaces."
      return
    }

    const detached = detachedSlots.get(detachedIndex)
    applying = true
    lastSwapStdout = ""
    lastSwapStderr = ""
    statusText = "Swapping workspaces with detached slot " + detached.slotKey + "..."
    swapProcess.exec(["hywoma", "swap-with-detached-slot", String(targetSlot)])
  }

  function changedSlotAssignments() {
    const changes = []
    for (let i = 0; i < monitors.count; i++) {
      const monitor = monitors.get(i)
      if (monitor.slot !== monitor.originalSlot) {
        changes.push({
          output: monitor.output,
          slot: monitor.slot,
          slotKey: monitor.slotKey,
        })
      }
    }
    return changes
  }

  function changedPhysicalLayout() {
    const changes = []
    if (!physicalDraftActive())
      return changes

    for (let i = 0; i < monitors.count; i++) {
      const monitor = monitors.get(i)
      const position = targetPositionForMonitor(monitor)
      if (monitor.hasGeometry) {
        changes.push({
          output: monitor.output,
          x: position.x,
          y: position.y,
          width: monitor.draftWidth,
          height: monitor.draftHeight,
          refreshRate: monitor.draftRefreshRate,
          scale: monitor.draftScale,
          transform: monitor.draftTransform,
        })
      } else {
        changes.push({ output: monitor.output, x: position.x, y: position.y })
      }
    }
    return changes
  }

  function applyDraft() {
    if (applying)
      return

    const slotChanges = changedSlotAssignments()
    const layoutChanges = changedPhysicalLayout()
    console.log("hywoma monitor layout draft: " + draftJson())
    if (slotChanges.length === 0 && layoutChanges.length === 0) {
      statusText = "No changes to apply."
      Qt.quit()
      return
    }

    applying = true
    applyQueue = []
    if (layoutChanges.length > 0)
      applyQueue.push({ kind: "layout", changes: layoutChanges })
    for (const change of slotChanges)
      applyQueue.push({ kind: "slot", output: change.output, slot: change.slot, slotKey: change.slotKey })
    statusText = "Applying draft changes..."
    runNextApplyCommand()
  }

  function runNextApplyCommand() {
    if (applyQueue.length === 0) {
      statusText = "Applied monitor layout draft."
      Qt.quit()
      return
    }

    const command = applyQueue[0]
    applyQueue = applyQueue.slice(1)
    lastApplyStdout = ""
    lastApplyStderr = ""
    if (command.kind === "layout") {
      const args = ["hywoma", "apply_monitor_layout"]
      for (const change of command.changes) {
        if (change.width === undefined) {
          args.push(change.output, String(change.x), String(change.y))
        } else {
          args.push(
            change.output,
            String(change.x),
            String(change.y),
            String(change.width),
            String(change.height),
            String(change.refreshRate),
            String(change.scale),
            String(change.transform)
          )
        }
      }
      statusText = "Applying physical monitor layout..."
      applyProcess.exec(args)
      return
    }

    statusText = "Assigning " + command.output + " to slot " + command.slotKey + "..."
    applyProcess.exec(["hywoma", "assign_output_to_slot", command.output, String(command.slot)])
  }

  function workspaceCountForSlot(status, slotId) {
    const workspaces = status.state?.workspaces ?? []
    const present = new Set(status.present_workspace_ids ?? [])
    let count = 0
    for (const workspace of workspaces) {
      if (workspace.slot === slotId && present.has(workspace.internal_id))
        count++
    }
    return count
  }

  function detachedWorkspaceCount(status, slotId) {
    for (const detached of status.detached_slots ?? []) {
      if (detached.slot === slotId)
        return detached.workspace_count ?? 0
    }
    return 0
  }

  function monitorInfoForOutput(status, output) {
    const monitorList = status.monitors ?? []
    for (const monitor of monitorList) {
      if (monitor.name === output)
        return monitor
    }
    return null
  }

  function monitorModeText(monitorInfo) {
    if (monitorInfo === null)
      return "missing monitor data"
    const refresh = Math.round((monitorInfo.refresh_rate ?? monitorInfo.refreshRate ?? 0) * 100) / 100
    return monitorInfo.width + "x" + monitorInfo.height + " @ " + refresh + "Hz"
  }

  function draftModeText(monitor) {
    const refresh = Math.round(monitor.draftRefreshRate * 100) / 100
    return monitor.draftWidth + "x" + monitor.draftHeight + " @ " + refresh + "Hz"
  }

  function modeString(width, height, refreshRate) {
    return width + "x" + height + "@" + Number(refreshRate).toFixed(2) + "Hz"
  }

  function parseMode(mode) {
    const match = String(mode).match(/^(\d+)x(\d+)@(\d+(?:\.\d+)?)Hz$/)
    if (match === null)
      return null
    return { width: Number(match[1]), height: Number(match[2]), refreshRate: Number(match[3]) }
  }

  function availableModesForMonitor(monitor) {
    const result = []
    let availableModes = []
    try {
      availableModes = JSON.parse(monitor.availableModesJson || "[]")
    } catch (e) {
      console.log("Failed to parse available modes for " + monitor.output + ": " + e)
    }
    for (const mode of availableModes) {
      if (parseMode(mode) !== null && result.indexOf(mode) < 0)
        result.push(mode)
    }
    const current = modeString(monitor.draftWidth, monitor.draftHeight, monitor.draftRefreshRate)
    if (result.indexOf(current) < 0)
      result.unshift(current)
    return result
  }

  function scaleText(scale) {
    return Number(scale).toFixed(6).replace(/0+$/, "").replace(/\.$/, "")
  }

  function monitorSettingsChanged(monitor) {
    return monitor.draftWidth !== monitor.originalWidth
      || monitor.draftHeight !== monitor.originalHeight
      || monitor.draftRefreshRate !== monitor.originalRefreshRate
      || monitor.draftScale !== monitor.originalScale
      || monitor.draftTransform !== monitor.originalTransform
  }

  function physicalDraftActive() {
    if (topologyDirty)
      return true
    for (let i = 0; i < monitors.count; i++) {
      if (monitorSettingsChanged(monitors.get(i)))
        return true
    }
    return false
  }

  function monitorHasDraftChanges(monitor) {
    if (monitor.slot !== monitor.originalSlot || monitorSettingsChanged(monitor))
      return true
    if (!physicalDraftActive())
      return false
    const position = targetPositionForMonitor(monitor)
    return position.x !== monitor.originalX || position.y !== monitor.originalY
  }

  function updateMonitorDraftText(index) {
    const monitor = monitors.get(index)
    monitors.setProperty(index, "modeText", draftModeText(monitor))
    const size = draftLogicalSize(monitor)
    monitors.setProperty(index, "logicalWidth", size.width)
    monitors.setProperty(index, "logicalHeight", size.height)
  }

  function refreshDraftTexts() {
    const active = physicalDraftActive()
    for (let i = 0; i < monitors.count; i++) {
      updateMonitorDraftText(i)
      const monitor = monitors.get(i)
      const position = active ? targetPositionForMonitor(monitor) : { x: monitor.originalX, y: monitor.originalY }
      monitors.setProperty(i, "layoutText", "pos " + position.x + "," + position.y + " · scale " + scaleText(monitor.draftScale))
    }
  }

  function openSettings() {
    const index = selectedMonitorIndex()
    if (index < 0)
      return
    const monitor = monitors.get(index)
    if (!monitor.hasGeometry) {
      statusText = "Mode/scale editing requires monitor geometry from hywoma status."
      return
    }
    settingsMonitorIndex = index
    settingsRow = 0
    settingsSavedWidth = monitor.draftWidth
    settingsSavedHeight = monitor.draftHeight
    settingsSavedRefreshRate = monitor.draftRefreshRate
    settingsSavedScale = monitor.draftScale
    settingsSavedTransform = monitor.draftTransform
    settingsOpen = true
    statusText = "Editing mode and scale for " + monitors.get(index).output + "."
  }

  function closeSettings(keepChanges) {
    if (!keepChanges && settingsMonitorIndex >= 0) {
      monitors.setProperty(settingsMonitorIndex, "draftWidth", settingsSavedWidth)
      monitors.setProperty(settingsMonitorIndex, "draftHeight", settingsSavedHeight)
      monitors.setProperty(settingsMonitorIndex, "draftRefreshRate", settingsSavedRefreshRate)
      monitors.setProperty(settingsMonitorIndex, "draftScale", settingsSavedScale)
      monitors.setProperty(settingsMonitorIndex, "draftTransform", settingsSavedTransform)
      refreshDraftTexts()
    }
    settingsOpen = false
    settingsMonitorIndex = -1
    settingsRow = 0
    statusText = "Draft " + layoutOrientation + " topology."
  }

  function changeSetting(delta) {
    if (!settingsOpen || settingsMonitorIndex < 0)
      return

    const monitor = monitors.get(settingsMonitorIndex)
    if (settingsRow === 0) {
      const modes = availableModesForMonitor(monitor)
      const current = modeString(monitor.draftWidth, monitor.draftHeight, monitor.draftRefreshRate)
      const currentIndex = Math.max(0, modes.indexOf(current))
      const nextMode = modes[(currentIndex + delta + modes.length) % modes.length]
      const parsed = parseMode(nextMode)
      if (parsed !== null) {
        monitors.setProperty(settingsMonitorIndex, "draftWidth", parsed.width)
        monitors.setProperty(settingsMonitorIndex, "draftHeight", parsed.height)
        monitors.setProperty(settingsMonitorIndex, "draftRefreshRate", parsed.refreshRate)
      }
    } else if (settingsRow === 1) {
      let currentIndex = 0
      let bestDistance = Number.MAX_VALUE
      for (let i = 0; i < scaleSteps.length; i++) {
        const distance = Math.abs(scaleSteps[i] - monitor.draftScale)
        if (distance < bestDistance) {
          currentIndex = i
          bestDistance = distance
        }
      }
      monitors.setProperty(settingsMonitorIndex, "draftScale", scaleSteps[(currentIndex + delta + scaleSteps.length) % scaleSteps.length])
    }
    refreshDraftTexts()
  }

  function monitorLayoutText(monitorInfo) {
    if (monitorInfo === null)
      return "hywoma status lacks geometry"
    return "pos " + monitorInfo.x + "," + monitorInfo.y + " · scale " + monitorInfo.scale
  }

  function monitorRefreshRate(monitorInfo) {
    return monitorInfo?.refresh_rate ?? monitorInfo?.refreshRate ?? 60.0
  }

  function monitorAvailableModes(monitorInfo) {
    return monitorInfo?.available_modes ?? monitorInfo?.availableModes ?? []
  }

  function logicalMonitorWidth(monitorInfo) {
    if (monitorInfo === null || monitorInfo.scale === 0)
      return 1600
    return Math.round(monitorInfo.width / monitorInfo.scale)
  }

  function logicalMonitorHeight(monitorInfo) {
    if (monitorInfo === null || monitorInfo.scale === 0)
      return 900
    return Math.round(monitorInfo.height / monitorInfo.scale)
  }

  function draftLogicalSize(monitor) {
    const rotated = Math.abs(monitor.draftTransform) % 2 === 1
    const width = rotated ? monitor.draftHeight : monitor.draftWidth
    const height = rotated ? monitor.draftWidth : monitor.draftHeight
    return {
      width: Math.round(width / monitor.draftScale),
      height: Math.round(height / monitor.draftScale),
    }
  }

  function canonicalTopologyPositions() {
    const indices = monitorIndicesInTopologyOrder()
    const result = ({})
    let maxCrossSize = 0
    for (const index of indices) {
      const size = draftLogicalSize(monitors.get(index))
      const crossSize = layoutOrientation === "vertical" ? size.width : size.height
      maxCrossSize = Math.max(maxCrossSize, crossSize)
    }

    let axisPosition = 0
    for (const index of indices) {
      const monitor = monitors.get(index)
      const size = draftLogicalSize(monitor)
      if (layoutOrientation === "vertical") {
        result[index] = {
          x: Math.round((maxCrossSize - size.width) / 2),
          y: axisPosition,
        }
        axisPosition += size.height
      } else {
        result[index] = {
          x: axisPosition,
          y: Math.round((maxCrossSize - size.height) / 2),
        }
        axisPosition += size.width
      }
    }
    return result
  }

  function targetPositionForMonitor(monitor) {
    const index = monitorIndexForOutput(monitor.output)
    return canonicalTopologyPositions()[index] ?? { x: monitor.originalX, y: monitor.originalY }
  }

  function loadFallback() {
    allSlots.clear()
    monitors.clear()
    detachedSlots.clear()

    allSlots.append({ slot: 1, key: "u", label: "left" })
    allSlots.append({ slot: 2, key: "i", label: "middle" })
    allSlots.append({ slot: 3, key: "o", label: "right" })
    layoutOrientation = "horizontal"
    originalOrientation = "horizontal"
    topologyDirty = false
    cursorCell = 4
    loadedFromHywoma = false
    statusText = "hywoma status unavailable. Start hywoma and reopen this layout picker."
  }

  function loadStatus(rawStatus) {
    const slots = rawStatus.state?.slots ?? []
    if (slots.length === 0) {
      loadFallback()
      return
    }

    allSlots.clear()
    monitors.clear()
    detachedSlots.clear()

    for (const slot of slots) {
      allSlots.append({ slot: slot.id, key: slot.key, label: slot.label })
    }

    const activeMonitors = (rawStatus.monitors ?? []).filter(monitor => !monitor.disabled)
    layoutOrientation = inferOrientation(activeMonitors)
    originalOrientation = layoutOrientation
    topologyDirty = false

    for (const slot of slots) {
      const attached = slot.runtime_monitor_id !== null && slot.attached_output !== null
      if (attached) {
        const output = slot.attached_output
        const monitorInfo = monitorInfoForOutput(rawStatus, output)
        monitors.append({
          output: output,
          device: output.startsWith("eDP") ? "laptop" : (output.startsWith("HEADLESS") ? "ipad" : "monitor"),
          slot: slot.id,
          originalSlot: slot.id,
          slotKey: slot.key,
          slotLabel: slot.label,
          workspaceCount: workspaceCountForSlot(rawStatus, slot.id),
          cell: 4,
          originalCell: 4,
          hasGeometry: monitorInfo !== null,
          originalX: monitorInfo?.x ?? 0,
          originalY: monitorInfo?.y ?? 0,
          originalWidth: monitorInfo?.width ?? 1920,
          originalHeight: monitorInfo?.height ?? 1080,
          originalRefreshRate: monitorRefreshRate(monitorInfo),
          originalScale: monitorInfo?.scale ?? 1.0,
          originalTransform: monitorInfo?.transform ?? 0,
          draftWidth: monitorInfo?.width ?? 1920,
          draftHeight: monitorInfo?.height ?? 1080,
          draftRefreshRate: monitorRefreshRate(monitorInfo),
          draftScale: monitorInfo?.scale ?? 1.0,
          draftTransform: monitorInfo?.transform ?? 0,
          logicalWidth: logicalMonitorWidth(monitorInfo),
          logicalHeight: logicalMonitorHeight(monitorInfo),
          availableModesJson: JSON.stringify(monitorAvailableModes(monitorInfo)),
          modeText: monitorModeText(monitorInfo),
          layoutText: monitorLayoutText(monitorInfo),
        })
      } else {
        const count = detachedWorkspaceCount(rawStatus, slot.id)
        if (count > 0) {
          detachedSlots.append({
            slot: slot.id,
            slotKey: slot.key,
            slotLabel: slot.label,
            workspaceCount: count,
          })
        }
      }
    }

    initializeTopologyCells()
    cursorCell = monitors.count > 0 ? monitors.get(0).cell : 4
    for (let i = 0; i < monitors.count; i++) {
      if (monitors.get(i).slot === rawStatus.focused_slot) {
        cursorCell = monitors.get(i).cell
        break
      }
    }

    loadedFromHywoma = true
    statusText = (rawStatus.monitors ?? []).length > 0
      ? "Draft " + layoutOrientation + " topology."
      : "Monitor geometry unavailable; mode/scale editing is disabled for this session."
  }

  function draftJson() {
    const result = []
    for (let i = 0; i < monitors.count; i++) {
      const monitor = monitors.get(i)
      result.push({
        output: monitor.output,
        orientation: layoutOrientation,
        slot: monitor.slot,
        originalSlot: monitor.originalSlot,
        slotKey: monitor.slotKey,
        cell: monitor.cell,
        originalCell: monitor.originalCell,
        row: cellRow(monitor.cell),
        column: cellColumn(monitor.cell),
        targetPosition: targetPositionForMonitor(monitor),
        draftWidth: monitor.draftWidth,
        draftHeight: monitor.draftHeight,
        draftRefreshRate: monitor.draftRefreshRate,
        draftScale: monitor.draftScale,
        draftTransform: monitor.draftTransform,
        modeText: monitor.modeText,
        layoutText: monitor.layoutText,
      })
    }
    return JSON.stringify(result)
  }

  ListModel { id: allSlots }
  ListModel { id: monitors }
  ListModel { id: detachedSlots }

  Process {
    id: statusProcess
    command: ["hywoma", "status"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.loadStatus(JSON.parse(this.text))
        } catch (e) {
          console.log("Failed to parse hywoma status: " + e)
          root.loadFallback()
        }
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text.length > 0)
          console.log("hywoma status stderr: " + this.text)
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0)
        root.loadFallback()
    }
  }

  Process {
    id: applyProcess
    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text.length > 0) {
          root.lastApplyStdout = this.text
          console.log("hywoma apply stdout: " + this.text)
        }
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text.length > 0) {
          root.lastApplyStderr = this.text
          console.log("hywoma apply stderr: " + this.text)
        }
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        applying = false
        const details = root.lastApplyStderr.trim() || root.lastApplyStdout.trim()
        statusText = details.length > 0 ? details : "Failed to apply monitor layout draft. See quickshell log."
        return
      }
      root.runNextApplyCommand()
    }
  }

  Process {
    id: swapProcess
    stdout: StdioCollector {
      onStreamFinished: {
        root.lastSwapStdout = this.text
        if (this.text.length > 0)
          console.log("hywoma detached swap stdout: " + this.text)
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        root.lastSwapStderr = this.text
        if (this.text.length > 0)
          console.log("hywoma detached swap stderr: " + this.text)
      }
    }
    onExited: function(exitCode) {
      if (exitCode === 0) {
        Qt.quit()
        return
      }
      root.applying = false
      const details = root.lastSwapStderr.trim() || root.lastSwapStdout.trim()
      root.statusText = details.length > 0 ? details : "Failed to swap detached workspaces. See quickshell log."
    }
  }

  Rectangle {
    anchors.fill: parent
    color: "#00000099"

    Item {
      id: keyTarget
      anchors.fill: parent
      focus: true
      Component.onCompleted: forceActiveFocus()

      Keys.onPressed: function(event) {
        if (root.applying) {
          event.accepted = true
          return
        }

        const shifted = (event.modifiers & Qt.ShiftModifier) !== 0
        const controlled = (event.modifiers & Qt.ControlModifier) !== 0
        if (root.settingsOpen) {
          if (event.key === Qt.Key_Escape) {
            root.closeSettings(false)
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.closeSettings(true)
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_H) {
            root.changeSetting(-1)
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_L) {
            root.changeSetting(1)
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_J) {
            root.settingsRow = Math.min(1, root.settingsRow + 1)
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_K) {
            root.settingsRow = Math.max(0, root.settingsRow - 1)
            event.accepted = true
            return
          }
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_Escape) {
          Qt.quit()
          event.accepted = true
          return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.applyDraft()
          event.accepted = true
          return
        }

        if (!shifted && event.key === Qt.Key_R) {
          root.openSettings()
          event.accepted = true
          return
        }

        if (!shifted && event.key === Qt.Key_T) {
          root.toggleTopology()
          event.accepted = true
          return
        }

        if (controlled && !shifted && event.key === Qt.Key_U) {
          root.swapWithDetachedSlot(root.slotForKey("u"))
          event.accepted = true
          return
        }
        if (controlled && !shifted && event.key === Qt.Key_I) {
          root.swapWithDetachedSlot(root.slotForKey("i"))
          event.accepted = true
          return
        }
        if (controlled && !shifted && event.key === Qt.Key_O) {
          root.swapWithDetachedSlot(root.slotForKey("o"))
          event.accepted = true
          return
        }

        if (!controlled && !shifted && event.key === Qt.Key_U) {
          root.assignSelectedMonitorToSlot(root.slotForKey("u"))
          event.accepted = true
          return
        }
        if (!controlled && !shifted && event.key === Qt.Key_I) {
          root.assignSelectedMonitorToSlot(root.slotForKey("i"))
          event.accepted = true
          return
        }
        if (!controlled && !shifted && event.key === Qt.Key_O) {
          root.assignSelectedMonitorToSlot(root.slotForKey("o"))
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_H) {
          shifted ? root.swapOrMove(-1, 0) : root.moveCursor(-1, 0)
          event.accepted = true
        } else if (event.key === Qt.Key_L) {
          shifted ? root.swapOrMove(1, 0) : root.moveCursor(1, 0)
          event.accepted = true
        } else if (event.key === Qt.Key_K) {
          shifted ? root.swapOrMove(0, -1) : root.moveCursor(0, -1)
          event.accepted = true
        } else if (event.key === Qt.Key_J) {
          shifted ? root.swapOrMove(0, 1) : root.moveCursor(0, 1)
          event.accepted = true
        }
      }
    }

    Rectangle {
      id: panel
      width: root.basePanelWidth + root.settingsProgress * (root.settingsPanelWidth + root.settingsPanelGap)
      height: root.basePanelHeight
      x: Math.round((parent.width - width) / 2)
      y: Math.round((parent.height - height) / 2)
      radius: 22
      color: "#1F1F28"
      border.width: 2
      border.color: root.panelBorder
      clip: true

      ColumnLayout {
        width: root.basePanelWidth - 48
        height: parent.height - 48
        x: 24
        y: 24
        spacing: 18

        RowLayout {
          Layout.fillWidth: true
          spacing: 14

          Rectangle {
            Layout.preferredWidth: 50
            Layout.preferredHeight: 50
            radius: 10
            color: "#2C2C3A"

            Text {
              anchors.centerIn: parent
              text: "󰍹"
              color: root.fg
              font.pixelSize: 22
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
              text: "Monitor layout"
              color: root.fg
              font.pixelSize: 20
              font.bold: true
            }

            Text {
              text: root.statusText
              color: root.mutedFg
              font.pixelSize: 13
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 2
          color: "#2C2C3A"
        }

        Item { Layout.fillHeight: true }

        Rectangle {
          Layout.alignment: Qt.AlignHCenter
          Layout.preferredWidth: root.previewWidth
          Layout.preferredHeight: root.previewHeight
          radius: root.cellRadius
          color: monitors.count > 0 ? "#252532" : "transparent"
          border.width: monitors.count > 0 ? 1 : 0
          border.color: "#3d3d4d"

          Repeater {
            model: monitors

            Rectangle {
              id: monitorCell

              required property string output
              required property string device
              required property int slot
              required property int originalSlot
              required property string slotKey
              required property string slotLabel
              required property int workspaceCount
              required property int cell
              required property int originalCell
              required property bool hasGeometry
              required property int originalX
              required property int originalY
              required property int originalWidth
              required property int originalHeight
              required property real originalRefreshRate
              required property real originalScale
              required property int originalTransform
              required property int draftWidth
              required property int draftHeight
              required property real draftRefreshRate
              required property real draftScale
              required property int draftTransform
              required property int logicalWidth
              required property int logicalHeight
              required property string availableModesJson
              required property string modeText
              required property string layoutText

              readonly property int topologyOrder: root.topologyCells(monitors.count, root.layoutOrientation).indexOf(cell)
              readonly property bool selected: cell === root.cursorCell

              x: root.monitorInset + (root.layoutOrientation === "horizontal" ? topologyOrder * root.cellPitch : 0)
              y: root.monitorInset + (root.layoutOrientation === "vertical" ? topologyOrder * root.cellPitch : 0)
              width: root.monitorCardSize
              height: root.monitorCardSize
              radius: root.monitorRadius
              color: selected ? "#34548a" : "#2C2C3A"
              border.width: 2
              border.color: selected ? "#7aa2f7" : root.subtleBorder

              Behavior on x {
                enabled: root.loadedFromHywoma && !root.suppressMonitorMovementAnimation
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
              }
              Behavior on y {
                enabled: root.loadedFromHywoma && !root.suppressMonitorMovementAnimation
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
              }
              Behavior on color { ColorAnimation { duration: 140 } }
              Behavior on border.color { ColorAnimation { duration: 140 } }

              Rectangle {
                  width: 10
                  height: 10
                  radius: 5
                  anchors.top: parent.top
                  anchors.right: parent.right
                  anchors.topMargin: 9
                  anchors.rightMargin: 9
                  visible: root.monitorHasDraftChanges(monitorCell)
                  color: "#7aa2f7"
                  border.width: 1
                  border.color: root.fg
              }

              ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 5

                  Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: device === "laptop" ? "󰌢" : (device === "ipad" ? "󰓶" : "󰍹")
                    color: root.fg
                    font.pixelSize: 26
                  }

                  Text {
                    Layout.fillWidth: true
                    text: output
                    color: root.fg
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideRight
                  }

                  Text {
                    Layout.fillWidth: true
                    text: "slot " + slotKey + " · " + workspaceCount + " ws"
                    color: root.mutedFg
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 12
                    elide: Text.ElideRight
                  }

                  Text {
                    Layout.fillWidth: true
                    text: modeText
                    color: root.dimFg
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 12
                  }

                  Text {
                    Layout.fillWidth: true
                    text: layoutText
                    color: root.dimFg
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 11
                  }
              }
            }
          }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: detachedSlots.count > 0 ? 42 : 0
          visible: detachedSlots.count > 0
          spacing: 10

          Text {
            text: "Detached"
            color: root.mutedFg
            font.pixelSize: 13
          }

          Repeater {
            model: detachedSlots

            Rectangle {
              required property int slot
              required property string slotKey
              required property string slotLabel
              required property int workspaceCount

              Layout.preferredWidth: 156
              Layout.preferredHeight: 34
              radius: 10
              color: detachedMouse.containsMouse ? "#50313d" : "#3a2730"
              border.width: 1
              border.color: "#e06c75"

              Text {
                anchors.centerIn: parent
                text: "Ctrl+" + slotKey + " swap · " + workspaceCount + " ws"
                color: "#ffb4b4"
                font.pixelSize: 12
              }


              MouseArea {
                id: detachedMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.swapWithDetachedSlot(slot)
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4

          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "hjkl cursor   Shift+axis reorder   t orientation   r mode/scale"
            color: root.mutedFg
            font.pixelSize: 13
          }

          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "u/i/o slots   Ctrl+u/i/o detached swap   Enter apply   Esc discard"
            color: root.mutedFg
            font.pixelSize: 13
          }
        }
      }
      Rectangle {
        id: settingsPanel
        width: root.settingsPanelWidth
        height: panel.height - 48
        x: root.basePanelWidth + root.settingsPanelGap - 24
        y: 24
        z: panel.z + 1
        radius: 16
        visible: root.settingsOpen || root.settingsProgress > 0.001
        opacity: root.settingsProgress
        color: "transparent"
        border.width: 0

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 16

        Text {
          Layout.fillWidth: true
          text: root.settingsMonitorIndex >= 0 ? monitors.get(root.settingsMonitorIndex).output + " settings" : "Monitor settings"
          color: root.fg
          font.pixelSize: 20
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          text: "h/l change   j/k select   Enter keep   Esc cancel"
          color: root.mutedFg
          font.pixelSize: 12
          wrapMode: Text.WordWrap
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 1
          color: "#3d3d4d"
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 74
          radius: 14
          color: root.settingsRow === 0 ? "#34548a" : "#2C2C3A"
          border.width: 1
          border.color: root.settingsRow === 0 ? "#7aa2f7" : root.subtleBorder

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text {
              text: "Mode"
              color: root.mutedFg
              font.pixelSize: 12
            }

            Text {
              Layout.fillWidth: true
              text: root.settingsMonitorIndex >= 0 ? root.draftModeText(monitors.get(root.settingsMonitorIndex)) : "-"
              color: root.fg
              font.pixelSize: 16
              font.bold: true
              elide: Text.ElideRight
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 74
          radius: 14
          color: root.settingsRow === 1 ? "#34548a" : "#2C2C3A"
          border.width: 1
          border.color: root.settingsRow === 1 ? "#7aa2f7" : root.subtleBorder

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text {
              text: "Scale"
              color: root.mutedFg
              font.pixelSize: 12
            }

            Text {
              Layout.fillWidth: true
              text: root.settingsMonitorIndex >= 0 ? root.scaleText(monitors.get(root.settingsMonitorIndex).draftScale) : "-"
              color: root.fg
              font.pixelSize: 16
              font.bold: true
            }
          }
        }

        Item { Layout.fillHeight: true }

        Text {
          Layout.fillWidth: true
          text: "Changes stay in the draft until main Enter applies them."
          color: root.dimFg
          font.pixelSize: 12
          wrapMode: Text.WordWrap
        }
      }
      }
    }
  }
}
