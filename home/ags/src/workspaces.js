const hyprland = await Service.import("hyprland")
import { Item, Icon, Text, Box, socket, unpack_id } from './utils.js'

var workspace_group_number = 0
var prev_workspace_group_number = 0

socket.add('workspace-group', msg => {
  prev_workspace_group_number = workspace_group_number
  workspace_group_number = JSON.parse(msg)[0]
  set_workspaces()
})

const workspaces = Variable([])

function set_workspaces() {
  workspaces.setValue(hyprland.workspaces)
}

Utils.merge([hyprland.bind('active'), hyprland.bind('workspaces')], () => {
  setTimeout(set_workspaces, 20) // NOTE: add a small delay for the update of the workspaces to complete
})
set_workspaces()

const id_to_number = id => unpack_id(id)[0]

function id_to_item(id) {
  const active_id = hyprland.active.workspace.id
  let class_names = ['workspace-indicator']
  if(active_id == id)
    class_names.push('active')
  const text = Text(String(id_to_number(id)), {
    class_names,
  })
  return Widget.EventBox({
    child: text,
    on_primary_click: _ => hyprland.messageAsync(`dispatch workspace ${id}`),
  })
}

function workspaces_to_items(ws, bar, group_number) {
  return ws
    .filter(w => w.monitorID === bar.monitor) // only active monitor
    .map(({ id }) => id) // unpack id
    .filter(id => unpack_id(id)[2] == group_number) // only active group
    .sort((a, b) => Number(a) - Number(b)) // ascending order
    .map(id_to_item) // transform to widgets
}

export function Workspaces(bar) {
  return Item([Box(
    workspaces.bind().as(ws => {
      let ret = workspaces_to_items(ws, bar, workspace_group_number)
      if(ret.length > 0)
        return ret
      return workspaces_to_items(ws, bar, prev_workspace_group_number)
    })
  )])
}
