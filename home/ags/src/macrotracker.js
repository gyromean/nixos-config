import { Item, Icon, Progression, Box, TooltipManager, ClassManager, repr_memory, Revealer, Text, socket } from './utils.js'

const macrotracker_binary = '/home/pavel/programy/rust/macrotracker/target/release/macrotracker'

const proteins_var = Variable(0)
const calories_var = Variable(0)
const peak_var = Variable(0) // maximum relative amount of all remaining metrics
const peak_var_repr = Variable('') // which metric it is

const tooltip = new TooltipManager()

setInterval(update, 10 * 60 * 1000) // every ten minutes
Utils.monitorFile(
    '/home/pavel/sync/macrotracker/tracker.yaml',
    () => update(),
) // every time the tracker is updated
socket.add('sleep-wake', () => {
    update()
})

const color_manager = new ClassManager([], [])

function clamp(x) {
    return Math.min(1, Math.max(0, x));
}

function update() {
    Utils.execAsync([macrotracker_binary, '--summary']).then(out => {
        // parse json
        const data = JSON.parse(out)
        const [macros_today, macros_target] = data

        // calculate relative macros and store proteins and calories
        const macros_relative = {
            calories: macros_today.calories / macros_target.calories,
            proteins: macros_today.proteins / macros_target.proteins,
            fat: macros_today.fat / macros_target.fat,
            carbs: macros_today.carbs / macros_target.carbs,
            sugar: macros_today.sugar / macros_target.sugar,
            salt: macros_today.salt / macros_target.salt,
        }
        proteins_var.value = macros_relative.proteins
        calories_var.value = macros_relative.calories

        // calculate peak metric and store its name and value
        const peak_variants = [
            [macros_relative.fat, "Fats"],
            [macros_relative.carbs, "Carbs"],
            [macros_relative.sugar, "Sugar"],
            [macros_relative.salt, "Salt"],
        ]
        const [peak_val, peak_repr] = peak_variants.reduce((acc, curr) => curr[0] > acc[0] ? curr : acc)
        peak_var.value = peak_val
        peak_var_repr.value = peak_repr

        // create tooltip
        const tooltip_content = []
        tooltip_content.push(`Proteins: ${(macros_relative.proteins * 100).toFixed()}%`)
        tooltip_content.push(`Calories: ${(macros_relative.calories * 100).toFixed()}%`)
        tooltip_content.push(`${peak_repr}: ${(peak_val * 100).toFixed()}%`)
        tooltip.set(tooltip_content)
    })
}
update()

export function Macrotracker(bar) {
    // const icon = Icon('󰿗')
    // const icon = Icon('')
    // const icon = Icon('󰉜')
    // const icon = Icon('󰒣')
    // const icon = Icon('󰿞')
    const icon = Icon('󰒦') // zatim best
    // const icon = Icon('󰩰')
    // const icon = Icon('')
    // const icon = Icon('󱅝') // taky good
    // const icon = Icon('') // taky mozna
    // const icon = Icon('󰂓') // taky mozna
    // const icon = Icon('') // taky mozna
    // const icon = Icon('󰟈')
    // const icon = Icon('') // mozna
    // const icon = Icon('󱡊')
    // const icon = Icon('󰘗')
    const prog_calories = Progression({ value: calories_var.bind().as(v => clamp(v)), max_value: 1 })
    const prog_proteins = Progression({ value: proteins_var.bind().as(v => clamp(v)), max_value: 1 })
    const prog_peak = Progression({ value: peak_var.bind().as(v => clamp(v)), max_value: 1 })
    const prog_peak_2 = Progression({ value: peak_var.bind().as(v => clamp(v - 1)), max_value: 1 })
    const prog_revealer = Revealer(prog_peak_2, {
        reveal_child: peak_var.bind().as(v => v > 1),
    })

    const prog_box = Box([
        prog_proteins,
        prog_calories,
        prog_peak,
        prog_revealer,
    ], {
        spacing: 2,
    })


    const item = Item([
        Box([
            icon,
            prog_box,
        ], {
            spacing: 4,
        }),
    ], {
        tooltip_text: tooltip.get(),
    })

    bar.add_managed_item(color_manager, item)

    return Widget.EventBox({
        child: item,
        on_primary_click: () =>  {
            Utils.execAsync(['alacritty', '-e', macrotracker_binary])
        }
    })
}
