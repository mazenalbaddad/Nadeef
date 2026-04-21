import Testing
@testable import Nadeef

@Suite("WeakBox")
struct WeakBoxTests {
    
    private class Dummy {
        let id: Int
        init(id: Int) { self.id = id }
    }
    
    @Test func holdsValueWhileStronglyReferenced() {
        let strong = Dummy(id: 1)
        let box = WeakBox(value: strong)
        #expect(box.value?.id == 1)
    }
    
    @Test func releasesWhenStrongHolderDrops() {
        var box: WeakBox<Dummy>
        do {
            let strong = Dummy(id: 2)
            box = WeakBox(value: strong)
            #expect(box.value != nil)
        }
        #expect(box.value == nil, "WeakBox must not keep its value alive")
    }
    
    @Test func initWithNilIsNil() {
        let box = WeakBox<Dummy>(value: nil)
        #expect(box.value == nil)
    }
}
