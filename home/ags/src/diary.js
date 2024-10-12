import { Item, Icon, Progression, Box, TooltipManager, ClassManager, repr_memory, Revealer, Text } from './utils.js'

var day, month, year

const days_var = Variable(0)
const hours_var = Variable(24)

setInterval(update, 60 * 60 * 1000) // every hour
Utils.monitorFile(
  '/home/pavel/sync/denik.txt',
  () => update(),
) // every time the diary is updated

const color_manager = new ClassManager([], ['yellow'])

function update() {
  Utils.execAsync(['tail', '-n1', '/home/pavel/sync/denik.txt']).then(out => {
    out = out.split(/\s+/)[1]
    const [_day, _month, _year] = out.split('.').map(Number)
    day = _day
    month = _month
    year = _year
    const next_entry_date = new Date(year, month - 1, day)
    next_entry_date.setHours(next_entry_date.getHours() + 2 + 24 + 4) // +2 for time zone, +24 as we want to represent the date of the next entry, +4 to set script's "midnight" to 4 AM

    const date_now = new Date(Date.now())
    date_now.setHours(date_now.getHours() + 2) // account for time zone

    const diff_ms = date_now - next_entry_date
    let hours
    let days
    if(diff_ms < 0) {
      hours = 0
      days = 0
    }
    else {
      hours = Math.floor(diff_ms / 1000 / 60 / 60)
      days = Math.floor(hours / 24)
      hours = hours % 24
    }
    days_var.value = days
    hours_var.value = hours

    if(days > 0)
      color_manager.set('yellow')
    else
      color_manager.reset()
  })
}

export function Diary() {
  const icon = Icon({
    label: '',
  })
  const rev = Revealer(Text(
    days_var.bind().as(v => String(Math.max(v, 1))) // max so that there is no visible 0 during the transition of reveal_child: false
  ), {
    reveal_child: days_var.bind().as(v => v > 0),
    css: 'padding-right: 1px; padding-left: 1px;',
  })
  const prog = Progression({
    value: hours_var.bind(),
    max_value: 23,
  })
  const item = Item([
    Box([
      icon,
      rev,
      prog,
    ], {
      spacing: 2,
    }),
  ])

  color_manager.add(item)
  update()

  return Widget.EventBox({
    child: item,
    on_primary_click: () =>  {
      if(days_var.value > 0)
        Utils.execAsync(['alacritty', '-e', 'python', '/home/pavel/.config/ags/scripts/update-diary.py', String(day), String(month), String(year), String(days_var.value)])
    }
  })
}
