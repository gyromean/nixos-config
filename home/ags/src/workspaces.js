import { Item, Text, Box } from './utils.js'
import { hywoma_status } from './hywoma.js'

function id_to_item(id, slot, label, active_id, idle_active_ids) {
  let class_names = ['workspace-indicator']
  if(active_id == id)
    class_names.push('active')
  else if(idle_active_ids.has(id))
    class_names.push('active-on-idle-monitor')
  const label_text = String(label)
  const text = Text(label_text, {
    class_names,
  })
  return Widget.EventBox({
    child: text,
    on_primary_click: _ => Utils.execAsync(['hywoma', 'select_workspace_in_slot', String(slot), label_text]).catch(logError),
  })
}

function hywoma_idle_active_ids(status) {
  const active_group = status.state.active_group
  const active_visible_by_slot = new Map(
    status.state.groups
      .find(group => group.id === active_group)
      ?.active_visible_by_slot ?? []
  )
  const attached_slots = new Set(
    status.state.slots
      .filter(slot => slot.runtime_monitor_id !== null)
      .map(slot => slot.id)
  )

  return new Set(
    status.state.workspaces
      .filter(w => w.group === active_group)
      .filter(w => attached_slots.has(w.slot))
      .filter(w => active_visible_by_slot.get(w.slot) === w.visible)
      .map(w => w.internal_id)
  )
}

function hywoma_workspaces_to_items(bar, status) {
  if(status === null)
    return []

  const present_ids = new Set(status.present_workspace_ids ?? [])
  const idle_active_ids = hywoma_idle_active_ids(status)
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
  return entries.map(w => id_to_item(w.internal_id, slot, w.visible, status.active_workspace_id, idle_active_ids))
}

export function Workspaces(bar) {
  return Item([Box(
    hywoma_status.bind().as(status => hywoma_workspaces_to_items(bar, status))
  )])
}
