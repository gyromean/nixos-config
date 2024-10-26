import { Item, Text, Icon, Box, socket, Revealer, ClassManager } from './utils.js'

const additional_workspaces_var = Variable(0)
const workspace_name_var = Variable('Main')

const color_manager = new ClassManager([], ['blue'])

socket.add('workspace-group', msg => {
  const [_, name, workspace_count] = JSON.parse(msg)
  workspace_name_var.value = name
  additional_workspaces_var.value = workspace_count - 1
  if(workspace_count > 1)
    color_manager.set('blue')
  else
    color_manager.reset()
})

export function WorkspaceGroups(bar) {
  const icon = Icon('󰍺')

  const additional_workspaces = Text(additional_workspaces_var.bind().as(num => `+${Math.max(num, 1)}`))

  bar.add_managed_item(color_manager, icon)
  bar.add_managed_item(color_manager, additional_workspaces)

  const rev = Revealer(additional_workspaces, {
    reveal_child: additional_workspaces_var.bind().as(v => v > 0),
    css: 'padding-left: 4px; padding-right: 4px;',
  })

  const workspace_name = Text(workspace_name_var.bind())

  const item = Item([
    Box([
      icon,
      rev,
      workspace_name,
    ], {
      spacing: 4,
    }),
  ])

  return item
}
