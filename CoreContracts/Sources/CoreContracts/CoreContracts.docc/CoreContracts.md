# ``CoreContracts``

A tiny, stable set of contracts (protocols and value types) for a plugin-driven app architecture. This module defines lifecycle phases, plugin interfaces, service container contracts, UI contribution descriptors, routing, actions, and the shared `AppContext`.

## Overview

`CoreContracts` contains no concrete implementations. It provides:

- Lifecycle phases and runnable hook: ``LifecyclePhase`` and ``LifecycleRunnable``
- Plugin declaration: ``AppPlugin`` and identifiers ``PluginID``/``ViewContributionID``
- Capability modeling: ``Capability``
- Service container interfaces: ``ServiceRegistry`` and ``ServiceResolver``
- UI surfaces and descriptors: ``UISurface``, ``ViewContribution``, ``UIRegistry``
- Routing contracts: ``RouteRegistry`` and ``Router``
- Actions contracts: ``ActionRegistry``, ``ActionDispatcher``, ``ActionContext``, ``ActionResult``
- App context and configuration: ``AppContext``, ``AppConfig``, ``FeatureFlags``, ``BuildInfo``

## Topics

### Lifecycle
- ``LifecyclePhase``
- ``LifecycleRunnable``

### Plugins
- ``AppPlugin``
- ``PluginID``
- ``Capability``

### Identifiers
- ``ViewContributionID``

### Services
- ``ServiceRegistry``
- ``ServiceResolver``

### UI Composition
- ``UISurface``
- ``ViewContribution``
- ``UIRegistry``

### Routing
- ``RouteRegistry``
- ``Router``

### Actions
- ``ActionRegistry``
- ``ActionDispatcher``
- ``ActionContext``
- ``ActionResult``

### App Context
- ``AppContext``
- ``AppConfig``
- ``FeatureFlags``
- ``BuildInfo``
