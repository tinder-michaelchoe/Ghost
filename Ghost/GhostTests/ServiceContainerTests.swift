//
//  ServiceContainerTests.swift
//  GhostTests
//
//  Created by mexicanpizza on 12/30/25.
//

import Foundation
import Testing
@testable import Ghost
@testable import CoreContracts

// MARK: - Test Protocols

protocol ServiceA {
    var identifier: String { get }
}

protocol ServiceB {
    var identifier: String { get }
}

protocol ServiceC {
    var identifier: String { get }
}

protocol ServiceD {
    var identifier: String { get }
}

// MARK: - Test Implementations

final class MockServiceA: ServiceA {
    let identifier: String
    init(identifier: String = "ServiceA") {
        self.identifier = identifier
    }
}

final class MockServiceB: ServiceB {
    let identifier: String
    let serviceA: ServiceA?

    init(identifier: String = "ServiceB", serviceA: ServiceA? = nil) {
        self.identifier = identifier
        self.serviceA = serviceA
    }
}

final class MockServiceC: ServiceC {
    let identifier: String
    let serviceA: ServiceA?
    let serviceB: ServiceB?

    init(identifier: String = "ServiceC", serviceA: ServiceA? = nil, serviceB: ServiceB? = nil) {
        self.identifier = identifier
        self.serviceA = serviceA
        self.serviceB = serviceB
    }
}

final class MockServiceD: ServiceD {
    let identifier: String
    init(identifier: String = "ServiceD") {
        self.identifier = identifier
    }
}


// MARK: - Basic Registration Tests

@MainActor
@Suite("ServiceContainer Basic Registration")
struct ServiceContainerBasicTests {

    @Test("Register and resolve a service")
    func registerAndResolve() {
        let container = ServiceContainer()

        container.register(ServiceA.self) {
            MockServiceA(identifier: "TestA")
        }

        let resolved = container.resolve(ServiceA.self)
        #expect(resolved != nil)
        #expect(resolved?.identifier == "TestA")
    }

    @Test("Resolve unregistered service returns nil")
    func resolveUnregisteredReturnsNil() {
        let container = ServiceContainer()

        let resolved = container.resolve(ServiceA.self)
        #expect(resolved == nil)
    }

    @Test("Service instances are cached (singleton)")
    func serviceInstancesAreCached() {
        let container = ServiceContainer()
        var callCount = 0

        container.register(ServiceA.self) {
            callCount += 1
            return MockServiceA(identifier: "Instance-\(callCount)")
        }

        let first = container.resolve(ServiceA.self)
        let second = container.resolve(ServiceA.self)

        #expect(callCount == 1, "Factory should only be called once")
        #expect(first?.identifier == second?.identifier)
    }

    @Test("Multiple services can be registered")
    func multipleServicesRegistered() {
        let container = ServiceContainer()

        container.register(ServiceA.self) { MockServiceA(identifier: "A") }
        container.register(ServiceB.self) { MockServiceB(identifier: "B") }
        container.register(ServiceC.self) { MockServiceC(identifier: "C") }

        #expect(container.resolve(ServiceA.self)?.identifier == "A")
        #expect(container.resolve(ServiceB.self)?.identifier == "B")
        #expect(container.resolve(ServiceC.self)?.identifier == "C")
    }

    @Test("Overwriting registration replaces factory")
    func overwritingRegistration() {
        let container = ServiceContainer()

        container.register(ServiceA.self) { MockServiceA(identifier: "First") }
        container.register(ServiceA.self) { MockServiceA(identifier: "Second") }

        let resolved = container.resolve(ServiceA.self)
        #expect(resolved?.identifier == "Second")
    }
}

// MARK: - Dependency Registration Tests

@MainActor
@Suite("ServiceContainer Dependency Registration")
struct ServiceContainerDependencyTests {

    @Test("Register with single dependency")
    func registerWithSingleDependency() {
        let container = ServiceContainer()

        container.register(ServiceA.self) {
            MockServiceA(identifier: "DependencyA")
        }

        container.register(ServiceB.self, dependencies: (ServiceA.self)) { serviceA in
            MockServiceB(identifier: "ServiceB-with-\(serviceA.identifier)", serviceA: serviceA)
        }

        let resolved = container.resolve(ServiceB.self) as? MockServiceB
        #expect(resolved != nil)
        #expect(resolved?.identifier == "ServiceB-with-DependencyA")
        #expect(resolved?.serviceA?.identifier == "DependencyA")
    }

    @Test("Register with multiple dependencies")
    func registerWithMultipleDependencies() {
        let container = ServiceContainer()

        container.register(ServiceA.self) { MockServiceA(identifier: "A") }
        container.register(ServiceB.self) { MockServiceB(identifier: "B") }

        container.register(ServiceC.self, dependencies: (ServiceA.self, ServiceB.self)) { serviceA, serviceB in
            MockServiceC(identifier: "C-\(serviceA.identifier)-\(serviceB.identifier)", serviceA: serviceA, serviceB: serviceB)
        }

        let resolved = container.resolve(ServiceC.self) as? MockServiceC
        #expect(resolved != nil)
        #expect(resolved?.identifier == "C-A-B")
        #expect(resolved?.serviceA?.identifier == "A")
        #expect(resolved?.serviceB?.identifier == "B")
    }

    @Test("Dependency chain resolution")
    func dependencyChainResolution() {
        let container = ServiceContainer()

        // A has no dependencies
        container.register(ServiceA.self) { MockServiceA(identifier: "BaseA") }

        // B depends on A
        container.register(ServiceB.self, dependencies: (ServiceA.self)) { serviceA in
            MockServiceB(identifier: "B-from-\(serviceA.identifier)", serviceA: serviceA)
        }

        // C depends on B (which depends on A)
        container.register(ServiceC.self, dependencies: (ServiceB.self)) { serviceB in
            MockServiceC(identifier: "C-from-\(serviceB.identifier)", serviceB: serviceB)
        }

        let resolved = container.resolve(ServiceC.self) as? MockServiceC
        #expect(resolved != nil)
        #expect(resolved?.identifier == "C-from-B-from-BaseA")
    }

    @Test("Dependencies are resolved only once (cached)")
    func dependenciesAreCached() {
        let container = ServiceContainer()
        var serviceACallCount = 0

        container.register(ServiceA.self) {
            serviceACallCount += 1
            return MockServiceA(identifier: "A-\(serviceACallCount)")
        }

        container.register(ServiceB.self, dependencies: (ServiceA.self)) { serviceA in
            MockServiceB(serviceA: serviceA)
        }

        container.register(ServiceC.self, dependencies: (ServiceA.self)) { serviceA in
            MockServiceC(serviceA: serviceA)
        }

        _ = container.resolve(ServiceB.self)
        _ = container.resolve(ServiceC.self)

        #expect(serviceACallCount == 1, "ServiceA factory should only be called once")
    }
}

// MARK: - Validation Tests

@Suite("ServiceContainer Validation")
struct ServiceContainerValidationTests {

    @Test("Empty container validates successfully")
    func emptyContainerValidates() {
        let container = ServiceContainer()
        let errors = container.validate()
        #expect(errors.isEmpty)
    }

    @Test("Container with no dependencies validates successfully")
    func noDependenciesValidates() {
        let container = ServiceContainer()

        container.register(ServiceA.self) { MockServiceA() }
        container.register(ServiceB.self) { MockServiceB() }

        let errors = container.validate()
        #expect(errors.isEmpty)
    }

    @Test("Container with satisfied dependencies validates successfully")
    func satisfiedDependenciesValidate() {
        let container = ServiceContainer()

        container.register(ServiceA.self) { MockServiceA() }
        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            MockServiceB(serviceA: a)
        }

        let errors = container.validate()
        #expect(errors.isEmpty)
    }

    @Test("Missing dependency is detected")
    func missingDependencyDetected() {
        let container = ServiceContainer()

        // Register B with dependency on A, but don't register A
        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            MockServiceB(serviceA: a)
        }

        let errors = container.validate()
        #expect(errors.count == 1)

        if case .missingDependency(let service, let missing) = errors.first {
            #expect(service.contains("ServiceB"))
            #expect(missing.contains("ServiceA"))
        } else {
            Issue.record("Expected missingDependency error")
        }
    }

    @Test("Multiple missing dependencies are detected")
    func multipleMissingDependenciesDetected() {
        let container = ServiceContainer()

        // Register C with dependencies on A and B, but don't register either
        container.register(ServiceC.self, dependencies: (ServiceA.self, ServiceB.self)) { a, b in
            MockServiceC(serviceA: a, serviceB: b)
        }

        let errors = container.validate()
        #expect(errors.count == 2)

        let missingServices = errors.compactMap { error -> String? in
            if case .missingDependency(_, let missing) = error {
                return missing
            }
            return nil
        }

        #expect(missingServices.contains { $0.contains("ServiceA") })
        #expect(missingServices.contains { $0.contains("ServiceB") })
    }

    @Test("Cyclic dependency A->B->A is detected")
    func cyclicDependencyTwoServices() {
        let container = ServiceContainer()

        // A depends on B
        container.register(ServiceA.self, dependencies: (ServiceB.self)) { b in
            MockServiceA()
        }

        // B depends on A - creates cycle
        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            MockServiceB()
        }

        let errors = container.validate()
        let cycleErrors = errors.filter {
            if case .cyclicDependency = $0 { return true }
            return false
        }

        #expect(!cycleErrors.isEmpty, "Should detect cyclic dependency")
    }

    @Test("Cyclic dependency A->B->C->A is detected")
    func cyclicDependencyThreeServices() {
        let container = ServiceContainer()

        container.register(ServiceA.self, dependencies: (ServiceC.self)) { c in
            MockServiceA()
        }

        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            MockServiceB()
        }

        container.register(ServiceC.self, dependencies: (ServiceB.self)) { b in
            MockServiceC()
        }

        let errors = container.validate()
        let cycleErrors = errors.filter {
            if case .cyclicDependency = $0 { return true }
            return false
        }

        #expect(!cycleErrors.isEmpty, "Should detect cyclic dependency in chain")
    }

    @Test("ServiceValidationError descriptions are meaningful")
    func errorDescriptions() {
        let missingError = ServiceValidationError.missingDependency(service: "MyService", missing: "MissingDep")
        #expect(missingError.description.contains("MyService"))
        #expect(missingError.description.contains("MissingDep"))

        let cycleError = ServiceValidationError.cyclicDependency(service: "ServiceA", cycle: ["ServiceA", "ServiceB", "ServiceA"])
        #expect(cycleError.description.contains("ServiceA"))
        #expect(cycleError.description.contains("ServiceB"))
    }

    @Test("ServiceValidationError equality")
    func errorEquality() {
        let error1 = ServiceValidationError.missingDependency(service: "A", missing: "B")
        let error2 = ServiceValidationError.missingDependency(service: "A", missing: "B")
        let error3 = ServiceValidationError.missingDependency(service: "A", missing: "C")

        #expect(error1 == error2)
        #expect(error1 != error3)

        let cycleError1 = ServiceValidationError.cyclicDependency(service: "A", cycle: ["A", "B"])
        let cycleError2 = ServiceValidationError.cyclicDependency(service: "A", cycle: ["A", "B"])

        #expect(cycleError1 == cycleError2)
        #expect(error1 != cycleError1)
    }
}

// MARK: - Edge Cases Tests

@MainActor
@Suite("ServiceContainer Edge Cases")
struct ServiceContainerEdgeCaseTests {

    @Test("Registration order does not matter for resolution")
    func registrationOrderIndependent() {
        let container = ServiceContainer()

        // Register B first (depends on A)
        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            MockServiceB(identifier: "B-\(a.identifier)", serviceA: a)
        }

        // Register A second
        container.register(ServiceA.self) { MockServiceA(identifier: "A") }

        let resolved = container.resolve(ServiceB.self) as? MockServiceB
        #expect(resolved?.identifier == "B-A")
    }

    @Test("No-dependency and dependency registrations can coexist")
    func noDependencyAndDependencyCoexist() {
        let container = ServiceContainer()

        // No-dependency registration
        container.register(ServiceA.self) {
            MockServiceA(identifier: "Simple-A")
        }

        // Registration with dependencies
        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            MockServiceB(identifier: "B-\(a.identifier)", serviceA: a)
        }

        let resolvedA = container.resolve(ServiceA.self)
        let resolvedB = container.resolve(ServiceB.self) as? MockServiceB

        #expect(resolvedA?.identifier == "Simple-A")
        #expect(resolvedB?.identifier == "B-Simple-A")
    }

    @Test("Diamond dependency pattern")
    func diamondDependency() {
        // A is depended on by both B and C
        // D depends on both B and C
        //
        //      A
        //     / \
        //    B   C
        //     \ /
        //      D

        let container = ServiceContainer()
        var aCreationCount = 0

        container.register(ServiceA.self) {
            aCreationCount += 1
            return MockServiceA(identifier: "A-\(aCreationCount)")
        }

        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            MockServiceB(identifier: "B-\(a.identifier)", serviceA: a)
        }

        container.register(ServiceC.self, dependencies: (ServiceA.self)) { a in
            MockServiceC(identifier: "C-\(a.identifier)", serviceA: a)
        }

        container.register(ServiceD.self, dependencies: (ServiceB.self, ServiceC.self)) { b, c in
            MockServiceD(identifier: "D-\(b.identifier)-\(c.identifier)")
        }

        let errors = container.validate()
        #expect(errors.isEmpty, "Diamond dependency should be valid")

        let resolved = container.resolve(ServiceD.self)
        #expect(resolved != nil)
        #expect(aCreationCount == 1, "A should only be created once even in diamond pattern")
    }

    @Test("Self-dependency is detected as cycle")
    func selfDependency() {
        let container = ServiceContainer()

        // A depends on itself
        container.register(ServiceA.self, dependencies: (ServiceA.self)) { a in
            MockServiceA()
        }

        let errors = container.validate()
        #expect(!errors.isEmpty, "Self-dependency should be detected")
    }
}

// MARK: - Topological Resolution Order Tests

@MainActor
@Suite("ServiceContainer Topological Resolution Order")
struct ServiceContainerTopologicalOrderTests {

    @Test("Dependencies are resolved before dependents in linear chain")
    func linearChainResolutionOrder() {
        // A <- B <- C (C depends on B, B depends on A)
        let container = ServiceContainer()
        var resolutionOrder: [String] = []

        container.register(ServiceA.self) {
            resolutionOrder.append("A")
            return MockServiceA(identifier: "A")
        }

        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            resolutionOrder.append("B")
            return MockServiceB(identifier: "B", serviceA: a)
        }

        container.register(ServiceC.self, dependencies: (ServiceB.self)) { b in
            resolutionOrder.append("C")
            return MockServiceC(identifier: "C", serviceB: b)
        }

        // Resolve C - should resolve A, then B, then C
        _ = container.resolve(ServiceC.self)

        #expect(resolutionOrder == ["A", "B", "C"], "Expected A -> B -> C order, got \(resolutionOrder)")
    }

    @Test("Dependencies resolved before dependents in diamond pattern")
    func diamondPatternResolutionOrder() {
        //      A
        //     / \
        //    B   C
        //     \ /
        //      D
        // Expected order: A first, then B and C (either order), then D

        let container = ServiceContainer()
        var resolutionOrder: [String] = []

        container.register(ServiceA.self) {
            resolutionOrder.append("A")
            return MockServiceA(identifier: "A")
        }

        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            resolutionOrder.append("B")
            return MockServiceB(identifier: "B", serviceA: a)
        }

        container.register(ServiceC.self, dependencies: (ServiceA.self)) { a in
            resolutionOrder.append("C")
            return MockServiceC(identifier: "C", serviceA: a)
        }

        container.register(ServiceD.self, dependencies: (ServiceB.self, ServiceC.self)) { b, c in
            resolutionOrder.append("D")
            return MockServiceD(identifier: "D")
        }

        // Resolve D
        _ = container.resolve(ServiceD.self)

        // A must come before B and C
        let aIndex = resolutionOrder.firstIndex(of: "A")!
        let bIndex = resolutionOrder.firstIndex(of: "B")!
        let cIndex = resolutionOrder.firstIndex(of: "C")!
        let dIndex = resolutionOrder.firstIndex(of: "D")!

        #expect(aIndex < bIndex, "A should be resolved before B")
        #expect(aIndex < cIndex, "A should be resolved before C")
        #expect(bIndex < dIndex, "B should be resolved before D")
        #expect(cIndex < dIndex, "C should be resolved before D")
        #expect(dIndex == resolutionOrder.count - 1, "D should be resolved last")
    }

    @Test("Multiple shared dependencies resolved once in correct order")
    func sharedDependenciesOrder() {
        // A is shared by B, C, and D
        // D depends on B and C
        let container = ServiceContainer()
        var resolutionOrder: [String] = []

        container.register(ServiceA.self) {
            resolutionOrder.append("A")
            return MockServiceA(identifier: "A")
        }

        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            resolutionOrder.append("B")
            return MockServiceB(identifier: "B", serviceA: a)
        }

        container.register(ServiceC.self, dependencies: (ServiceA.self)) { a in
            resolutionOrder.append("C")
            return MockServiceC(identifier: "C", serviceA: a)
        }

        container.register(ServiceD.self, dependencies: (ServiceB.self, ServiceC.self)) { b, c in
            resolutionOrder.append("D")
            return MockServiceD(identifier: "D")
        }

        _ = container.resolve(ServiceD.self)

        // A should appear exactly once
        let aCount = resolutionOrder.filter { $0 == "A" }.count
        #expect(aCount == 1, "A should be resolved exactly once, was resolved \(aCount) times")

        // Each service should appear exactly once
        #expect(resolutionOrder.count == 4, "Expected 4 resolutions, got \(resolutionOrder.count)")
    }

    @Test("Independent services do not affect resolution order")
    func independentServicesOrder() {
        // A <- B, C is independent
        let container = ServiceContainer()
        var resolutionOrder: [String] = []

        container.register(ServiceA.self) {
            resolutionOrder.append("A")
            return MockServiceA(identifier: "A")
        }

        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            resolutionOrder.append("B")
            return MockServiceB(identifier: "B", serviceA: a)
        }

        container.register(ServiceC.self) {
            resolutionOrder.append("C")
            return MockServiceC(identifier: "C")
        }

        // Resolve B - should only resolve A and B, not C
        _ = container.resolve(ServiceB.self)

        #expect(resolutionOrder == ["A", "B"], "Expected only A -> B, got \(resolutionOrder)")
        #expect(!resolutionOrder.contains("C"), "C should not be resolved when resolving B")
    }

    @Test("Deep dependency chain resolves in correct order")
    func deepChainOrder() {
        // A <- B <- C <- D (D at the end of chain)
        let container = ServiceContainer()
        var resolutionOrder: [String] = []

        container.register(ServiceA.self) {
            resolutionOrder.append("A")
            return MockServiceA(identifier: "A")
        }

        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            resolutionOrder.append("B")
            return MockServiceB(identifier: "B", serviceA: a)
        }

        container.register(ServiceC.self, dependencies: (ServiceB.self)) { b in
            resolutionOrder.append("C")
            return MockServiceC(identifier: "C", serviceB: b)
        }

        container.register(ServiceD.self, dependencies: (ServiceC.self)) { c in
            resolutionOrder.append("D")
            return MockServiceD(identifier: "D")
        }

        _ = container.resolve(ServiceD.self)

        #expect(resolutionOrder == ["A", "B", "C", "D"], "Expected A -> B -> C -> D order, got \(resolutionOrder)")
    }

    @Test("Resolving intermediate node only resolves its dependencies")
    func intermediateNodeResolution() {
        // A <- B <- C <- D
        // Resolving B should only resolve A and B
        let container = ServiceContainer()
        var resolutionOrder: [String] = []

        container.register(ServiceA.self) {
            resolutionOrder.append("A")
            return MockServiceA(identifier: "A")
        }

        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            resolutionOrder.append("B")
            return MockServiceB(identifier: "B", serviceA: a)
        }

        container.register(ServiceC.self, dependencies: (ServiceB.self)) { b in
            resolutionOrder.append("C")
            return MockServiceC(identifier: "C", serviceB: b)
        }

        container.register(ServiceD.self, dependencies: (ServiceC.self)) { c in
            resolutionOrder.append("D")
            return MockServiceD(identifier: "D")
        }

        // Resolve B only
        _ = container.resolve(ServiceB.self)

        #expect(resolutionOrder == ["A", "B"], "Expected only A -> B, got \(resolutionOrder)")
    }

    @Test("Previously resolved dependencies are not re-resolved")
    func cachedDependenciesNotReResolved() {
        // A <- B, A <- C
        // Resolve B first, then C - A should only be resolved once
        let container = ServiceContainer()
        var resolutionOrder: [String] = []

        container.register(ServiceA.self) {
            resolutionOrder.append("A")
            return MockServiceA(identifier: "A")
        }

        container.register(ServiceB.self, dependencies: (ServiceA.self)) { a in
            resolutionOrder.append("B")
            return MockServiceB(identifier: "B", serviceA: a)
        }

        container.register(ServiceC.self, dependencies: (ServiceA.self)) { a in
            resolutionOrder.append("C")
            return MockServiceC(identifier: "C", serviceA: a)
        }

        // Resolve B first
        _ = container.resolve(ServiceB.self)
        #expect(resolutionOrder == ["A", "B"])

        // Now resolve C - A should not be resolved again
        _ = container.resolve(ServiceC.self)
        #expect(resolutionOrder == ["A", "B", "C"], "A should not be resolved again, got \(resolutionOrder)")
    }
}

// MARK: - Thread Safety Tests

@MainActor
@Suite("ServiceContainer Thread Safety")
struct ServiceContainerThreadSafetyTests {

    @Test("Concurrent resolution returns same instance")
    func concurrentResolution() async {
        let container = ServiceContainer()
        var creationCount = 0
        let lock = NSLock()

        container.register(ServiceA.self) {
            lock.lock()
            creationCount += 1
            lock.unlock()
            return MockServiceA(identifier: "Concurrent")
        }

        // Resolve concurrently from multiple tasks
        await withTaskGroup(of: ServiceA?.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    await container.resolve(ServiceA.self)
                }
            }

            var results: [ServiceA?] = []
            for await result in group {
                results.append(result)
            }

            // All results should be non-nil and the same instance
            #expect(results.allSatisfy { $0 != nil })
        }

        // Factory should only be called once due to caching
        #expect(creationCount == 1, "Factory should only be called once despite concurrent access")
    }

    @Test("Concurrent registration and resolution")
    func concurrentRegistrationAndResolution() async {
        let container = ServiceContainer()

        await withTaskGroup(of: Void.self) { group in
            // Register services concurrently
            for i in 0..<10 {
                group.addTask {
                    await container.register(ServiceA.self) {
                        MockServiceA(identifier: "A-\(i)")
                    }
                }
            }

            // Resolve concurrently
            for _ in 0..<10 {
                group.addTask {
                    _ = await container.resolve(ServiceA.self)
                }
            }
        }

        // Should not crash and should resolve something
        let resolved = container.resolve(ServiceA.self)
        #expect(resolved != nil)
    }
}
