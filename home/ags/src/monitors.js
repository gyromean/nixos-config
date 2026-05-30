import Gdk from 'gi://Gdk'

function by_position(a, b) {
  const ax = a.x ?? a.geometry?.x ?? 0
  const bx = b.x ?? b.geometry?.x ?? 0
  const ay = a.y ?? a.geometry?.y ?? 0
  const by = b.y ?? b.geometry?.y ?? 0
  if(ax !== bx)
    return ax - bx
  return ay - by
}

function gdk_monitors() {
  const display = Gdk.Display.get_default()
  const count = display?.get_n_monitors() ?? 0
  const monitors = []
  for(let index = 0; index < count; index++) {
    const geometry = display.get_monitor(index).get_geometry()
    monitors.push({ index, geometry })
  }
  return monitors.sort(by_position)
}

function physical_hypr_monitors(hyprland) {
  return hyprland.monitors
    .filter(monitor => !monitor.name.startsWith('HEADLESS-'))
    .sort(by_position)
}

export function physical_monitor_bindings(hyprland) {
  const gdks = gdk_monitors()
  const used_gdk_indexes = new Set()

  return physical_hypr_monitors(hyprland).map((hypr_monitor, fallback_index) => {
    let gdk = gdks.find(candidate => {
      if(used_gdk_indexes.has(candidate.index))
        return false
      const geometry = candidate.geometry
      return hypr_monitor.x === geometry.x && hypr_monitor.y === geometry.y
    })
    if(gdk === undefined)
      gdk = gdks.find(candidate => !used_gdk_indexes.has(candidate.index)) ?? gdks[fallback_index]
    if(gdk !== undefined)
      used_gdk_indexes.add(gdk.index)

    return {
      monitor: gdk?.index ?? fallback_index,
      hypr_monitor_id: hypr_monitor.id,
      name: hypr_monitor.name,
      x: hypr_monitor.x,
      y: hypr_monitor.y,
    }
  })
}

export function physical_monitor_signature(hyprland) {
  return physical_monitor_bindings(hyprland)
    .map(binding => `${binding.hypr_monitor_id}:${binding.monitor}:${binding.name}:${binding.x}:${binding.y}`)
    .join('|')
}
