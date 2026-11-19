import Foundation
import Testing
@testable import Desk

@MainActor
struct BillingTests {
    @Test func nagsFollowTheIntervalLadderPerContext() {
        let paywall = PaywallService()
        let start = Date(timeIntervalSince1970: 1_000)
        #expect(paywall.shouldNag(context: 1, now: start))
        #expect(!paywall.shouldNag(context: 1, now: start))
        #expect(!paywall.shouldNag(context: 1, now: start.addingTimeInterval(119)))
        #expect(paywall.shouldNag(context: 1, now: start.addingTimeInterval(120)))
        #expect(!paywall.shouldNag(context: 1, now: start.addingTimeInterval(719)))
        #expect(paywall.shouldNag(context: 1, now: start.addingTimeInterval(720)))
        #expect(!paywall.shouldNag(context: 1, now: start.addingTimeInterval(1_319)))
        #expect(paywall.shouldNag(context: 1, now: start.addingTimeInterval(1_320)))
        #expect(paywall.shouldNag(context: 2, now: start.addingTimeInterval(1_320)))
    }
}
