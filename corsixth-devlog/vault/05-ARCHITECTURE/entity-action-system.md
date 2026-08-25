# Entity Action System

## Overview
CorsixTH uses a hierarchical action system where humanoids (patients, staff, visitors) have action queues that determine their behavior.

## Core Architecture

### Humanoid → Actions → State Machine
```
Humanoid
  ├── action_queue: array of HumanoidAction
  ├── current_action: HumanoidAction (head of queue)
  └── mood: current mood state
```

### Action Base Class (`humanoid_action.lua`)
```lua
class "HumanoidAction"
function HumanoidAction:HumanoidAction(name)
  self.name = name
  self.next_action = nil
  self.must_happen = false
  self.high_priority = false
end

function HumanoidAction:start() end
function HumanoidAction:tick() end
function HumanoidAction:interrupt() end
function HumanoidAction:finish() end
```

### Action Queue Processing (`humanoid.lua`)
```lua
function Humanoid:tick()
  if #self.action_queue > 0 then
    local action = self.action_queue[1]
    action:tick()
    if action.finished then
      table.remove(self.action_queue, 1)
    end
  end
end
```

### Key Action Types

#### Walk Action (`walk.lua`)
- Pathfinding integration via `TH.pathfinder`
- Handles interruptions (pickup, call)

#### Use Object Action (`use_object.lua`)
- Multi-phase: begin → use → finish
- Supports prolonged usage
- Handles multiple users (multi_use_object)

#### Seek Room Action (`seek_room.lua`)
- Finds appropriate room for entity
- Handles queueing for room entry

#### Seek Staff Room Action (`seek_staffroom.lua`)
- Fatigue-driven
- Finds nearest staff room

#### Idle Action (`idle.lua`)
- Configurable duration and direction
- Used between tasks

#### Spawn Action (`spawn.lua`)
- Patient spawning at map edge
- Handles despawning

## Calls Dispatcher (`calls_dispatcher.lua`)
Event-driven communication between systems:
```lua
CallsDispatcher:dispatch(call_type, data)
CallsDispatcher:register(callback, call_types)
```

## Cross-References
- [[world-entity-flow]] - How actions call destroyEntity
- [[save-load-migrations]] - Action queue persistence
- Area: [[01-CODEBASE/01-entity-iteration]], [[01-CODEBASE/04-patient-lifecycle]], [[01-CODEBASE/05-staff-training]]
