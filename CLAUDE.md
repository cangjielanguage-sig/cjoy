# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

CJoy is a Cangjie (仓颉) framework. Use `cjpm` (Cangjie Package Manager) for all build operations.

### Build and Test
```bash
# Build the project
cjpm build

# Run all tests
cjpm test

# Run a specific test file (HLT - high level test)
cjpm test --target src/test/route_test.cj

# Run internal tests within a module (LHT - low level test)
cjpm test --target src/framework/route_test.cj
```

### Run Examples
```bash
cd examples
cjpm run --name examples.simple
cjpm run --name examples.macros
cjpm run --name examples.rest
cjpm run --name examples.tls
```

## Architecture Overview

CJoy is a web framework built on top of Cangjie SDK's HTTP module. It uses a macro-driven architecture for code generation, enabling zero-reflection, high-performance runtime behavior.

### Core Layers

1. **Engine Layer** (`src/framework/engine.cj`)
   - `Joy`: Main engine instance, wraps `net.http.Server`
   - `JoyConfig`: Configuration for engine (remote IP headers, debug, case-insensitive routes, etc.)
   - `JoyContext`: Request/response context passed to handlers

2. **Routing Layer** (`src/framework/route.cj`, `src/framework/tree.cj`)
   - Compressed prefix tree (TreeNode) for efficient route matching
   - `JoyRouters`: Router interface with methods like `get()`, `post()`, `use()`, `group()`
   - `JoyRouteGroup`: Implements `JoyRouters`, manages middleware stacks and route registration
   - `TreeRouteDistributor`: Implements SDK's `HttpRequestDistributor`/`HttpRequestHandler` for request dispatch

3. **Handler Layer** (`src/framework/handler.cj`)
   - `JoyRequestHandler`: Interface for request handlers
   - `JoyRequestHandlerFunc`: Type alias for handler functions
   - `JoyHandlers`: Registry for macro-generated handlers (used with `JoyHandlers.registerTo(joy)`)
   - `JoyMiddlewareHandler`: Interface for middleware

### Macro System

CJoy's power comes from its extensive macro system. Macros generate code at compile-time, eliminating runtime reflection:

- **All macros are re-exported** through `src/macros/macros.cj` which imports from:
  - `cjoy.log.macros.*`
  - `cjoy.framework.macros.*`
  - `cjoy.ioc.macros.*`
  - `cjoy.bind.macros.*`
  - `cjoy.eventbus.macros.*`
  - `cjoy.json.macros.*`
  - `cjoy.mcp.macros.*`
  - `cjoy.schedule.macros.*`
  - `cjoy.validation.macros.*`

#### Key Macro Categories

**Route Handler Macros** (`src/framework/macros/`):
- `@Get[path = "...", produce="json"]`, `@Post`, `@Put`, `@Delete`, `@Patch`, `@Head`
- `@Handler[method = "GET,PUT", path = "..."]`
- Parameter binding macros: `@PathParam`, `@QueryParam`, `@PostFormParam`, `@HeaderParam`, `@CookieParam`, `@BodyParam`, `@ContextParam`
- `@Middleware[groups = "/a/b"]` for middleware functions

**IoC Macros** (`src/ioc/macros/`):
- `@Component[name="...", scope="singleton|prototype", extends=[...]]`: Registers a class as a bean
- `@Controller[path = "/api"]`: Component that exposes RESTful APIs
- `@Autowired(name="...")`: Injects beans into constructor parameters
- `@Value(value="${config.key}")`: Binds config values to fields

**JSON Macros** (`src/json/macros/`):
- `@Json`: Annotates class/struct for JSON serialization/deserialization
- `@JsonField[name="...", omitempty=true, ignore=false]`: Field-level JSON configuration
- `@ToJson`: Converts object to `JsonSerializable`

**Validation Macros** (`src/validation/macros/`):
- `@Valid`: Generates `validate()` method for class/struct
- `@Validated`: Wraps function to validate parameters
- Constraint macros: `@Size`, `@Length`, `@NotEmpty`, `@NotBlank`, `@NumberRange`, `@Pattern`, `@Email`, `@IPV4`, etc.

**Event Bus Macros** (`src/eventbus/macros/`):
- `@SubscribeEvent[name="...", pattern="...", priority=0]`: Subscribes to events

**Schedule Macros** (`src/schedule/macros/`):
- `@Scheduled[name="...", cron="* * * * *"]`: Registers scheduled jobs

**MCP Macros** (`src/mcp/macros/`):
- `@Tool`, `@Resource`, `@Prompt`: Expose capabilities to LLMs

### IoC Container

CJoy provides a lightweight IoC container (`src/ioc/`):
- `ApplicationContext`: Interface for bean management
- `BeanFactoryManager`: Manages bean factories and lifecycle
- `BeanLifecycle`: Interface for `afterInit()` and `beforeDestroy()` callbacks

### Directory Structure Principles

- Large features get their own `src/` subdirectory (e.g., `src/json`, `src/validation`)
- Public APIs go in `api/` subdirectory within features (e.g., `src/json/api` would be for public JSON utilities, but currently JSON utilities are in `src/json/` directly)
- Macros are defined in `macros/` subdirectories; macro definitions in `macros.cj`, implementation in separate files
- `src/test/` contains high-level tests (HLT); `*_test.cj` in each module are low-level tests (LHT)
- Keep classes non-public unless necessary; expose minimal API surface
- Related classes can coexist in one file but should have single responsibilities

### Key Dependencies

- `cjoy.context`: Context and service container
- `cjoy.log`: Logging with `JoyCreateLogger`, `JoyLogDebug`, `JoyLogInfo`, etc.
- `cjoy.bind`: Parameter binding utilities
- `cjoy.framework`: Core web framework
- `cjoy.fs`: File system utilities (imported but not exported in main package)

### Registering Macro-Generated Handlers

When using handler macros (`@Get`, `@Post`, etc.), you must register them:

```cangjie
main(): Int64 {
    let joy = Joy.default()
    JoyHandlers.registerTo(joy)  // Critical: registers all macro-generated handlers
    joy.run("127.0.0.1", 18881)
    return 0
}
```

### Commit Message Format

Follow conventional commits (English):
- `feat:`: New feature
- `fix:`: Bug fix
- `docs:`: Documentation
- `style:`: Formatting (no code changes)
- `refactor:`: Code refactoring
- `upgrade/boost/perform:`: Performance improvements
- `test:`: Test changes
- `chore:`: Build/tooling changes
- `revert:`: Revert previous commit
- `version:`: Version management

All code contributions must include test coverage that does not decrease overall coverage. Exported functions must have English documentation. Use Chinese for internal code comments.
