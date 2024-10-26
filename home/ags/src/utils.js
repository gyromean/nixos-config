function isObject(o) {
  return typeof o === 'object' && !Array.isArray(o) && o !== null
}

function isArray(a) {
  return Array.isArray(a)
}

export function merge(defaults, overwrite) {
  if(defaults === undefined)
    return overwrite

  if(isArray(defaults) && isArray(overwrite))
    return defaults.concat(overwrite)

  if(isObject(defaults) && isObject(overwrite)) {
    for(const key in overwrite)
      defaults[key] = merge(defaults[key], overwrite[key])
    return defaults
  }

  return overwrite
}

export function select_icon(icons, start, end, request, prefer_periodic=true) {
  if(request <= start)
    return icons.at(0)
  if(request >= end)
    return icons.at(-1)
  request -= start
  let interval_size = end - start
  if(prefer_periodic === null)
    prefer_periodic = icons.length % 2 == 0
  if(prefer_periodic)
    interval_size += 1
  let index = Math.floor(request / (interval_size / icons.length))
  return icons.at(index)
}

// TODO: asi budu potrebovat metodu na pridani a odebrani objektu, kdyz to pojede na vice monitorech (odebrat protoze se mi treba odpoji secondary display (ipad))
export class ClassManager {
  constructor(objs, classes) {
    if(Array.isArray(objs))
      this.objs = objs
    else
      this.objs = [objs]
    this.classes = classes
    this.timeout_handle = null
    this.current_cls = null
  }
  set(cls_set, reset_ms = null) {
    this.current_cls = cls_set
    this.#clear_classes()
    for(let obj of this.objs)
      obj.toggleClassName(cls_set, true)
    this.#kill_timeout()
    if(reset_ms !== null)
      this.timeout_handle = setTimeout(() => {
        this.#clear_classes()
      }, reset_ms)
  }
  set_with_timeout(cls_set, reset_ms = 1000) {
    this.set(cls_set, reset_ms)
  }
  reset() {
    this.#clear_classes()
    this.#kill_timeout()
    this.current_cls = null
  }
  add(obj) {
    this.objs.push(obj)
    if(this.current_cls !== null)
      this.set(this.current_cls)
  }
  #clear_classes() {
    for(let obj of this.objs)
      for(let cls of this.classes)
        obj.toggleClassName(cls, false)
  }
  #kill_timeout() {
    if(this.timeout_handle !== null)
      clearTimeout(this.timeout_handle)
  }
}

function center(str, len) {
  const spaces = len - str.length
  const left = Math.floor(spaces / 2)
  const right = Math.ceil(spaces / 2)
  return ' '.repeat(left) + str + ' '.repeat(right)
}

function center_array(array) {
  const max_len = Math.max(...array.map(s => s.length))
  return array.map(s => center(s, max_len))
}

export class TooltipManager {
  constructor(default_tooltip = '', center = true) {
    this.var = Variable('')
    this.set(default_tooltip, center)
  }
  set(tooltip = '', center = true) {
    if(!Array.isArray(tooltip))
      tooltip = [tooltip]
    tooltip = tooltip.map(String)
    if(center)
      tooltip = center_array(tooltip)
    this.tooltip = tooltip
    this.var.value = this.repr()
  }
  repr() {
    return this.tooltip.map(val => ` ${val} `).join('\n')
  }
  get() {
    return this.var.bind()
  }
}

export function round_to_decimals(val, decimals = 2) {
  let mul = Math.pow(10, decimals)
  return Math.round(val * mul) / mul
}

const KIBI = 1024
const MEBI = Math.pow(1024, 2)
const GIBI = Math.pow(1024, 3)

export function repr_memory(val) {
  if(val >= GIBI)
    return `${round_to_decimals(val / GIBI)} GiB`
  else if(val >= MEBI)
    return `${round_to_decimals(val / MEBI)} MiB`
  else if(val >= KIBI)
    return `${round_to_decimals(val / KIBI)} KiB`
  else
    return `${round_to_decimals(val)} B`
}

class Socket {
  constructor(socket_path = '/tmp/ags-bar.sock') {
    this.path = socket_path
    this.callbacks = []
    Utils.exec(['rm', this.path])
    this.proc = Utils.subprocess(
      ['nc', '-lkU', socket_path],
      msg => {
        this.#process_message(msg)
      },
      err => logError(err),
    )
  }

  #process_message(msg) {
    const index = msg.indexOf(' ')
    let msg_processed
    if(index == -1)
      msg_processed = ''
    else
      msg_processed = msg.substr(index + 1)

    for(const [string_match, callback] of this.callbacks)
      if(msg.startsWith(string_match))
        callback(msg_processed)
  }

  add(string_match, callback) {
    this.callbacks.push([string_match, callback])
  }
}

export const socket = new Socket()

///////////////////////////

export class Bar {
  constructor(data) {
    this.monitor = data.monitor
    this.left = data.left || []
    this.center = data.center || []
    this.right = data.right || []

    this.managed_classes = []

    this.#construct_widget()
  }

  #section_builder(items, hpack) {
    // TODO: je tady ten this vpohode
    // TODO: bacha, aby se tohle volalo v moment, kdy uz jsou vsechny ostatni udaje ready, protoze ty widgety tam muzou connectit ty classy (a nebo to mozna actually nevadi? hlavne aby byly ty fieldy pro class managery uz ready
    return Section(items.map(f => f(this)), { hpack })
  }

  #construct_widget() {
    this.widget = Widget.Window({
      name: `bar-${this.monitor}`,
      class_name: 'bar',
      monitor: this.monitor,
      anchor: ['top', 'left', 'right'],
      exclusivity: 'exclusive',
      child: Widget.CenterBox({
        start_widget: this.#section_builder(this.left, 'start'),
        center_widget: this.#section_builder(this.center, 'center'),
        end_widget: this.#section_builder(this.right, 'end'),
      }),
    })
  }

  get_widget() {
    return this.widget
  }

  add_managed_item(manager, item) {
    manager.add(item)
    this.managed_classes.push({
      manager,
      item,
    })
  }

  remove_class() {
    // TODO: implement
  }

  // TODO: funkce na removal (neco jako destruktor), ktera odlinkuje vsechny managed classy
}

///////////////////////////

export function Item(items, opts = {}) {
  return Widget.Box(merge({
    children: items,
    spacing: 8,
    class_names: ['item'],
  }, opts))
}

export function Section(items, opts = {}) {
  let children_ret = []
  if(items.length > 0) {
    children_ret.push(items[0])
    for(let i = 1; i < items.length; i++) {
      children_ret.push(Separator())
      children_ret.push(items[i])
    }
  }
  return Widget.Box(merge({
    children: children_ret,
    spacing: 0,
    class_names: ['section'],
  }, opts))
}

export function Separator() {
  return Widget.Separator({
    vertical: true,
  })
}

export function Icon(opts = {}) {
  return Widget.Label(merge({
    class_names: ['icon'],
  }, opts))
}

export function Progression(opts = {}) {
  return Widget.LevelBar(merge({
    bar_mode: 'continuous',
    vertical: true,
    inverted: true,
    min_value: 0,
    max_value: 100,
    value: 60,
    width_request: 4,
    height_request: 15,
    class_names: ['progression'],
  }, opts))
}

export function Box(items, opts = {}) {
  return Widget.Box(merge({
    children: items,
    spacing: 0,
  }, opts))
}

export function Revealer(child, opts = {}) {
  return Widget.Revealer(merge({
    reveal_child: false,
    transition_duration: 500,
    transition: 'slide_right',
    child,
  }, opts))
}

export function Text(text, opts = {}) {
  return Widget.Label(merge({
    label: text,
    class_names: ['text'],
  }, opts))
}
