import { Item, Text, Icon, Box, Revealer, ClassManager } from './utils.js'
import { hywoma_status, current_hywoma_status } from './hywoma.js'

const additional_workspaces_var = Variable(0)
const detached_slots_var = Variable(0)
const workspace_name_var = Variable('Main')
const color_manager = new ClassManager([], ['blue'])
const detached_color_manager = new ClassManager([], ['yellow'])

function set_workspace_group(name, workspace_count) {
  workspace_name_var.value = name
  additional_workspaces_var.value = workspace_count - 1
  if(workspace_count > 1)
    color_manager.set('blue')
  else
    color_manager.reset()
}

function set_detached_slots(count) {
  detached_slots_var.value = count
  if(count > 0)
    detached_color_manager.set('yellow')
  else
    detached_color_manager.reset()
}

function set_hywoma_group(status) {
  if(status === null)
    return

  set_detached_slots(status.detached_slots?.length ?? 0)
  const groups = status.state.groups
  const active_group = groups.find(group => group.id === status.state.active_group)
  if(active_group !== undefined)
    set_workspace_group(active_group.name, groups.length)
}

hywoma_status.connect('changed', ({ value }) => set_hywoma_group(value))
// Apply an already-received snapshot when this widget is constructed. Without this, the label can
// stay on the default until the next daemon event.
set_hywoma_group(current_hywoma_status())

export function WorkspaceGroups(bar) {
  const detached_slots = Text(detached_slots_var.bind().as(num => `-${num}`))
  detached_color_manager.add(detached_slots)

  const detached_rev = Revealer(detached_slots, {
    reveal_child: detached_slots_var.bind().as(v => v > 0),
    css: 'padding-left: 4px; padding-right: 4px;',
  })

  const icon = Icon('󰍺')
  color_manager.add(icon)

  const additional_workspaces = Text(additional_workspaces_var.bind().as(num => `+${Math.max(num, 1)}`))
  color_manager.add(additional_workspaces)

  const rev = Revealer(additional_workspaces, {
    reveal_child: additional_workspaces_var.bind().as(v => v > 0),
    css: 'padding-left: 4px; padding-right: 4px;',
  })

  const workspace_name = Text(workspace_name_var.bind())

  const item = Item([
    Box([
      detached_rev,
      icon,
      rev,
      workspace_name,
    ], {
      spacing: 4,
    }),
  ])

  return item
}
