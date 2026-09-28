import Testing
@testable import MenubarCore

@Suite struct KanataStatusTests {
    @Test func runningWhenStateLineSaysRunning() {
        let output = """
        system/local.kanata = {
        \tactive count = 1
        \tstate = running

        \tprogram = /opt/homebrew/bin/kanata
        }
        """
        #expect(KanataStatus.parse(exitCode: 0, output: output) == .running)
    }

    @Test func loadedNotRunningForAnyOtherState() {
        let output = "system/local.kanata = {\n\tstate = waiting\n}"
        #expect(KanataStatus.parse(exitCode: 0, output: output) == .loadedNotRunning)
    }

    @Test func notLoadedWhenLaunchctlExitsNonZero() {
        #expect(KanataStatus.parse(exitCode: 113, output: "Could not find service \"system/local.kanata\"") == .notLoaded)
    }

    @Test func unknownWhenOutputHasNoStateLine() {
        #expect(KanataStatus.parse(exitCode: 0, output: "system/local.kanata = {\n}") == .unknown)
    }

    @Test func isLoadedReflectsRunningAndLoadedNotRunningOnly() {
        #expect(KanataStatus.running.isLoaded)
        #expect(KanataStatus.loadedNotRunning.isLoaded)
        #expect(!KanataStatus.notLoaded.isLoaded)
        #expect(!KanataStatus.unknown.isLoaded)
    }
}
