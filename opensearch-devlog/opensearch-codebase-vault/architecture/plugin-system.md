---
type: architecture
tags: [opensearch, plugin, extension]
---

# Plugin System

How plugins extend OpenSearch's core functionality.

## Plugin Lifecycle

```
Discovery → Loading → Registration → Initialization → Shutdown
```

1. **Discovery**: Node finds installed plugins in `plugins/` directory
2. **Loading**: Plugin classes loaded via Java classloader
3. **Registration**: Plugin registers actions, transports, settings
4. **Initialization**: Plugin starts its services
5. **Shutdown**: Plugin cleans up on node stop

## What Plugins Can Register

- REST actions (API endpoints)
- Transport actions (node-to-node handlers)
- Settings (configuration)
- Script engines
- Analysis plugins
- Repositories (snapshot storage)
- Discovery providers
- Network filters

## Plugin Types

| Type | Example | Purpose |
|------|---------|---------|
| Module | `lang-painless` | Bundled with OpenSearch |
| Plugin | `repository-s3` | Installed separately |
| Sandbox | `analytics-engine` | Experimental, disabled by default |

## How Plugins Register

From `plugin-descriptors.properties`:

```properties
description=My Plugin
version=1.0.0
name=my-plugin
classname=com.example.MyPlugin
java.version=21
```

The plugin class extends `Plugin` and overrides registration methods:

```java
public class MyPlugin extends Plugin {
    @Override
    public List<ActionHandler<? extends Action, TransportAction>> getActions() {
        return List.of(new ActionHandler<>(MyAction.INSTANCE, MyTransportAction.class));
    }
}
```

## Key Classes

| Class | Role |
|-------|------|
| `Plugin` | Base class for all plugins |
| `ActionPlugin` | Plugin that registers actions |
| `RepositoryPlugin` | Plugin that provides snapshot repositories |
| `ScriptPlugin` | Plugin that provides script engines |

## Related

- [[server]] — where plugins live
- [[sandbox]] — sandbox plugins
- [[modules]] — built-in modules (special plugins)
- [[transport-layer]] — plugins register transport handlers
