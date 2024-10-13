import { Item, Icon, Text } from './utils.js'

const date = Variable(['', ''], {
  poll: [1000, ['date', '+%H:%M:%S %d.%m.'], out => out.split(' ')],
})

// TODO: dodelat ikonu hodin kde se to bude fr otacet?
export function DateModule() {
  return Item([
    Icon({
      label: '',
    }),
    Text(date.bind().as(item => item[0])),
    Icon({
      // label: '',
      label: '',
    }),
    Text(date.bind().as(item => item[1])),
  ])
}
