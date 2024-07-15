SimpleEventHook
{
  name = "linking/hijack-linking",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "select-target" },
    },
  },
  after = { "linking/prepare-link" },
  before = { "linking/link-target" },
  execute = function(event)
    local event_target = event:get_data("target")
    if event_target == nil then -- other select-target events exist that do no contain the "target" field, in that case do not interfere
      return
    end

    local properties = event_target.properties
    local event_target_class = properties["media.class"]
    if event_target_class ~= "Audio/Sink" then -- do not interfere with other classes, e.g., Audio/Source
      return
    end

    local event_target_name = properties["node.name"] -- get sink name from the event
    local target_name = Settings.get_string("target-sink") -- get sink name configured via `wpctl settings target-sink <SINK NAME>`

    -- print('event_target = ', (event_target))
    -- print('properties = ')
    -- Debug.dump_table(properties)
    -- print('event_target_name = ', (event_target_name))
    -- print('target_name = ', (target_name))
    -- print('event_target_class = ', (event_target_class))

    if event_target_name ~= target_name then -- prevent linking if the sinks do not match
      event:set_data ("target", nil)
    end
  end
}:register ()

-- add event listnere on target-sink settings change and manually trigger rescan (it seems that it only works when I'm currently setting the target to nil, but that's good enough)
Settings.subscribe("target-sink", function()
  local source = Plugin.find("standard-event-source")
  source:call ("schedule-rescan", "linking")
end)
