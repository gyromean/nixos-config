const hyprland = await Service.import("hyprland")
import { Item, Text, Box } from './utils.js'
import { hywoma_status } from './hywoma.js'

const workspaces = Variable([])

function has_hywoma_workspaces(status) {
  return status !== null && status.state.workspaces.length > 0
}

function set_workspaces() {
  workspaces.setValue(hyprland.workspaces)
}

Utils.merge([hyprland.bind('active'), hyprland.bind('workspaces')], () => {
  // In opaque mode, hywoma is the authoritative source for labels and active ID. Rendering directly
  // on Hyprland events caused flicker because Hyprland may report the new workspace before hywoma's
  // active ID snapshot arrives.
  if(!has_hywoma_workspaces(hywoma_status.value))
    setTimeout(set_workspaces, 20) // NOTE: add a small delay for the update of the workspaces to complete
})
hywoma_status.connect('changed', () => {
  // Hyprland destroys empty workspaces asynchronously after a switch. The second refresh lets AGS
  // drop empty workspace indicators after destroyworkspacev2/present_workspace_ids settle.
  setTimeout(set_workspaces, 20)
  setTimeout(set_workspaces, 120)
})
set_workspaces()

function id_to_item(id, label, active_id) {
  let class_names = ['workspace-indicator']
  if(active_id == id)
    class_names.push('active')
  const label_text = String(label)
  const text = Text(label_text, {
    class_names,
  })
  return Widget.EventBox({
    child: text,
    on_primary_click: _ => hyprland.messageAsync(`dispatch workspace ${id}`),
  })
}

function hywoma_workspaces_to_items(ws, bar, status) {
  if(status === null)
    return []

  const present_ids = new Set(status.present_workspace_ids ?? ws.map(w => w.id))
  const active_group = status.state.active_group
  const monitor_slot = status.state.slots.find(slot => slot.runtime_monitor_id === bar.hypr_monitor_id)
  if(monitor_slot === undefined)
    return []
  const slot = monitor_slot.id
  const entries = status.state.workspaces
    .filter(w => w.group === active_group)
    .filter(w => w.slot === slot)
    // Keep stable mappings in hywoma, but display only workspaces Hyprland currently has plus the
    // active workspace. This avoids showing empty allocated mappings after leaving a workspace.
    .filter(w => present_ids.has(w.internal_id) || w.internal_id === status.active_workspace_id)
    .sort((a, b) => a.visible - b.visible)
  return entries.map(w => id_to_item(w.internal_id, w.visible, status.active_workspace_id))
}

export function Workspaces(bar) {
  return Item([Box(
    Utils.merge([workspaces.bind(), hywoma_status.bind()], (ws, status) => {
      return hywoma_workspaces_to_items(ws, bar, status)
    })
  )])
}
