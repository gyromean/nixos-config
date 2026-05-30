const hywoma_binary = 'hywoma'

export const hywoma_status = Variable(null)
let events_restart_timeout = null

export function current_hywoma_status() {
  return hywoma_status.value
}

function process_line(line) {
  if(line.length === 0)
    return

  try {
    hywoma_status.value = JSON.parse(line)
  } catch(err) {
    logError(err)
  }
}

function load_initial_status() {
  Utils.execAsync([hywoma_binary, 'status'])
    .then(out => {
      hywoma_status.value = JSON.parse(out)
    })
    .catch(_ => {})
}

function schedule_events_restart() {
  if(events_restart_timeout !== null)
    return

  events_restart_timeout = setTimeout(() => {
    events_restart_timeout = null
    load_initial_status()
    start_events()
  }, 1000)
}

function start_events() {
  Utils.subprocess(
    // Use hywoma's own stdout bridge instead of nc/Gio Unix sockets. The bridge can exit when the
    // daemon is restarted, so reconnect instead of leaving AGS with a stale snapshot.
    [hywoma_binary, 'events'],
    process_line,
    error => {
      print(`[hywoma] events failed: ${error}`)
      schedule_events_restart()
    },
  )
}

load_initial_status()
start_events()
