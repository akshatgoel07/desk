import AppKit
import CoreData
import ImageIO
import UniformTypeIdentifiers

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: seed <fixtures-dir> <media-dir>\n".utf8))
    exit(2)
}
let fixturesRoot = URL(fileURLWithPath: arguments[1], isDirectory: true)
let mediaRoot = URL(fileURLWithPath: arguments[2], isDirectory: true)

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("seed: \(message)\n".utf8))
    exit(1)
}

func storeURL(_ fixture: String) -> URL {
    let folder = fixturesRoot.appendingPathComponent(fixture, isDirectory: true)
    try? FileManager.default.removeItem(at: folder)
    do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
    catch { fail("cannot create \(folder.path)") }
    return folder.appendingPathComponent("store.sqlite")
}

func frame(_ x: CGFloat, _ top: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    CGRect(x: x, y: 720 - top - height, width: width, height: height)
}

func display(_ text: String) -> NoteBlock { NoteBlock(style: .display, text: text) }
func headline(_ text: String) -> NoteBlock { NoteBlock(style: .headline, text: text) }
func subheader(_ text: String) -> NoteBlock { NoteBlock(style: .subheader, text: text) }
func body(_ text: String) -> NoteBlock { NoteBlock(style: .body, text: text) }
func item(_ text: String) -> NoteBlock { NoteBlock(style: .list, text: text) }
func task(_ text: String, _ checked: Bool = false) -> NoteBlock { NoteBlock(style: .task, text: text, checked: checked) }
func rich(_ style: NoteBlockStyle, _ runs: [NoteRun]) -> NoteBlock {
    var block = NoteBlock(style: style)
    block.runs = runs
    return block
}

struct Card {
    var blocks: [NoteBlock]
    var frame: CGRect
    var image: ImageAttachment? = nil
}

func image(_ file: String, name: String? = nil) -> ImageAttachment {
    let url = mediaRoot.appendingPathComponent(file)
    guard let data = try? Data(contentsOf: url), let attachment = ImageAttachment(data: data, name: name ?? file) else {
        fail("cannot read image \(url.path)")
    }
    return attachment
}

func imageCard(_ attachment: ImageAttachment, x: CGFloat, top: CGFloat, scale: CGFloat = 1) -> Card {
    let size = attachment.cardSize
    return Card(blocks: [], frame: frame(x, top, size.width * scale, size.height * scale), image: attachment)
}

@MainActor
func write(_ cards: [Card], to store: NoteStore, space: UUID = SpaceRecord.firstID, startOrder: Int = 0) {
    for (index, card) in cards.enumerated() {
        let content = NoteContent(blocks: card.blocks)
        let record = NoteRecord(id: UUID(), text: content.plainText, frame: card.frame,
                                order: startOrder + index, spaceID: space, image: card.image,
                                content: card.image == nil ? content : nil)
        if case .failure(let error) = store.insert(record) { fail(error.message) }
    }
}

func weeklyBoard() -> [Card] {
    [
        Card(blocks: [display("Week of Nov 17"),
                      task("Send Q4 invoice to Halvorsen & Co ($4,250.00)", true),
                      task("Renew car insurance, due Nov 28 ($612.40)"),
                      task("Book dentist for Maya"),
                      task("Return library books", true)],
             frame: frame(72, 70, 212, 116)),
        Card(blocks: [display("Kitchen remodel budget"),
                      headline("Quotes"),
                      item("Cabinets, Nordline: $8,900"),
                      item("Quartz countertop, 42 sq ft: $3,150"),
                      item("Rivera Plumbing: $1,275"),
                      item("Electrical, Kim & Sons: $940"),
                      rich(.body, [NoteRun("Total so far "), NoteRun("$14,265", marks: [.bold]),
                                   NoteRun(" of "), NoteRun("$16,000", marks: [.highlight])])],
             frame: frame(72, 204, 212, 242)),
        Card(blocks: [display("Wi-Fi: Fennwick-5G"), body("Password is on the fridge. Guest network: Fennwick-Guest.")],
             frame: frame(72, 464, 212, 140)),
        Card(blocks: [display("1:1 with Priya, Nov 18"),
                      subheader("Roadmap"),
                      item("Ship offline mode before the Dec 12 freeze"),
                      item("Hire one more iOS engineer in Q1"),
                      subheader("Follow ups"),
                      task("Share the churn dashboard with finance"),
                      task("Draft the on-call rotation for January")],
             frame: frame(302, 70, 212, 242)),
        Card(blocks: [display("Grocery run"),
                      item("Oat milk x2"), item("Sourdough loaf"), item("Basmati rice, 1 kg"),
                      item("Eggs, dozen"), item("Baby spinach"), item("Parmesan"), item("Lemons x4"),
                      body("Budget: $85")],
             frame: frame(302, 330, 212, 116)),
        Card(blocks: [], frame: frame(302, 464, 140, 200)),
        Card(blocks: [display("Lisbon trip"),
                      body("Mar 14 to Mar 18"),
                      item("TAP TP 202, Mar 14, 07:55 from Newark"),
                      item("Memmo Alfama, 4 nights, EUR 780"),
                      item("Tram 28 early, before 9:00"),
                      item("Dinner at Taberna da Rua das Flores")],
             frame: frame(532, 70, 212, 200)),
        Card(blocks: [display("Reading list"),
                      task("The Overstory, Richard Powers", true),
                      task("Four Thousand Weeks, Oliver Burkeman"),
                      task("A Psalm for the Wild-Built, Becky Chambers"),
                      task("The Design of Everyday Things, Don Norman")],
             frame: frame(532, 288, 212, 160)),
        Card(blocks: [display("Gift ideas"),
                      item("Dad: Moka pot, 6 cup ($38)"),
                      item("Sam: Climbing gym day pass ($24)"),
                      item("Ana: Risograph print from Tiny Press ($55)")],
             frame: frame(532, 466, 212, 140)),
        Card(blocks: [display("Standup, Tue"),
                      body("Payments retry fix is in review. Blocked on the staging certificate.")],
             frame: frame(762, 70, 212, 116)),
        Card(blocks: [display("Newsletter ideas"),
                      body("Issue 41: what we learned moving 2.3 million photos to the new storage tier."),
                      body("Issue 42: reader questions about export formats."),
                      rich(.body, [NoteRun("Ask Jordan for the "), NoteRun("migration charts", marks: [.underline], link: "https://example.com/charts"),
                                   NoteRun(" before Friday.")])],
             frame: frame(762, 204, 212, 260)),
        Card(blocks: [display("We shape our tools and thereafter our tools shape us.")],
             frame: frame(762, 482, 212, 116))
    ]
}

func longNotes() -> [Card] {
    let minutes = (1...36).map { index -> NoteBlock in
        body("\(index). The team reviewed the vendor contract for the Reno fulfillment center and agreed to revisit the penalty clause, the delivery windows, and the rate card for peak season before the next steering meeting on December \(index % 28 + 1).")
    }
    let inventory = (1...120).map { index in item(String(format: "SKU-%05d  Walnut shelf bracket, matte black, qty %d", 40_000 + index * 7, index % 9 + 1)) }
    return [
        Card(blocks: [display("Steering committee minutes, Q4 planning")] + minutes,
             frame: frame(48, 60, 212, 560)),
        Card(blocks: [display("Draft: Proposal to consolidate the three regional warehouses in Fresno, Sparks, and Ogden into a single fulfillment center in Reno with same day carrier pickup")],
             frame: frame(290, 60, 212, 242)),
        Card(blocks: [display("Shared links"),
                      body("https://drive.example.com/files/d/1aZx9QwErTyUiOpAsDfGhJkLzXcVbNm0123456789abcdefghijklmnopqrstuvwxyz/view?usp=sharing&resourcekey=0-AbCdEfGhIjKlMnOpQrStUv")],
             frame: frame(290, 320, 212, 140)),
        Card(blocks: [display("Inventory count, aisle 14")] + inventory,
             frame: frame(532, 60, 460, 300)),
        Card(blocks: [display("Supercalifragilisticexpialidociouslylongunbrokenheadingwithoutanyspaces")],
             frame: frame(532, 380, 212, 116)),
        Card(blocks: [display("Note")] + (1...14).map { _ in body("") } + [body("Hidden text far below the fold.")],
             frame: frame(774, 380, 212, 160))
    ]
}

func taskLists() -> [Card] {
    let moveOut: [(String, Bool)] = [
        ("Book the freight elevator for Dec 6, 8:00 to 12:00", true), ("Order 30 medium boxes", true),
        ("Forward mail to 418 Larkin St, Apt 3B", true), ("Cancel Comcast, account 8774 1021 3345", false),
        ("Patch nail holes in the hallway", false), ("Deep clean the oven", false),
        ("Return the parking fob to the front desk", false), ("Take meter photos for gas and power", false),
        ("Schedule the walk through with Dana", true), ("Ask for the $2,400 deposit by check", false)
    ]
    return [
        Card(blocks: [display("Move out checklist")] + moveOut.map { task($0.0, $0.1) },
             frame: frame(72, 70, 212, 280)),
        Card(blocks: [display("Sprint 47"),
                      subheader("In progress"),
                      task("DESK-1182 Image paste keeps EXIF orientation"),
                      task("DESK-1190 Space menu keyboard focus"),
                      subheader("Done"),
                      task("DESK-1174 Retry button after load failure", true),
                      task("DESK-1177 Save banner contrast", true),
                      task("DESK-1179 Undo after space delete", true)],
             frame: frame(302, 70, 212, 242)),
        Card(blocks: [display("Packing, Lisbon"),
                      item("Passport, expires 2029"), item("EU plug adapter x2"), item("Rain shell"),
                      item("Walking shoes"), item("Camera and two batteries")],
             frame: frame(532, 70, 212, 200)),
        Card(blocks: [display("All done"),
                      task("File 2025 taxes", true), task("Renew passport", true), task("Back up photo library", true)],
             frame: frame(762, 70, 212, 140)),
        Card(blocks: [display("Nothing checked yet"),
                      task("Call the landlord about the leak"), task("Pick up dry cleaning, ticket 4471"),
                      task("Pay water bill, $64.18")],
             frame: frame(532, 290, 212, 140))
    ]
}

func rotatedPhoto() -> ImageAttachment {
    let url = mediaRoot.appendingPathComponent("coast-landscape.jpg")
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fail("cannot read \(url.path)") }
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else { fail("jpeg encoder") }
    CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: 6,
                                                    kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary)
    guard CGImageDestinationFinalize(destination),
          let attachment = ImageAttachment(data: data as Data, name: "IMG_5530.JPG") else { fail("cannot encode rotated photo") }
    return attachment
}

func imageBoard() -> [Card] {
    let landscape = image("coast-landscape.jpg", name: "IMG_5512.JPG")
    let portrait = image("hills-portrait.jpg", name: "IMG_5519.JPG")
    let panorama = image("dunes-panorama.jpg", name: "PANO_20251102_171455.jpg")
    let zebra = image("zebra.png", name: "zebra.png")
    let sunflower = image("sunflower.heic", name: "Sunflower.heic")
    let icon = image("leaf-icon.png", name: "leaf-icon.png")
    return [
        imageCard(landscape, x: 48, top: 60),
        imageCard(portrait, x: 392, top: 60),
        imageCard(rotatedPhoto(), x: 634, top: 60),
        imageCard(panorama, x: 48, top: 330),
        imageCard(zebra, x: 392, top: 420, scale: 0.6),
        imageCard(sunflower, x: 590, top: 420, scale: 0.6),
        imageCard(icon, x: 790, top: 420),
        Card(blocks: [display("Moodboard: spring catalog"),
                      body("Warm coast light, soft hills, one animal shot for the kids range.")],
             frame: frame(876, 60, 180, 160)),
        Card(blocks: [display("Photo credits"), item("IMG_5512: Coast, Nov 2"), item("PANO: Dunes at dusk")],
             frame: frame(876, 238, 180, 116))
    ]
}

func workload() -> [Card] {
    let clients = ["Brightline Studio", "Halvorsen & Co", "Northwind Dental", "Pike Street Bakery", "Okafor Legal", "Tidewater Yoga"]
    let people = ["Priya", "Marcus", "Ana", "Jordan", "Lena", "Tomas", "Wen", "Grace"]
    let months = ["Sep", "Oct", "Nov", "Dec"]
    let templates: [(Int) -> String] = [
        { "Invoice #2025-\(String(format: "%04d", 300 + $0 * 7)): \(clients[$0 % clients.count]), $\(String(format: "%.2f", Double(480 + $0 * 113) + 0.5))" },
        { "1:1 with \(people[$0 % people.count]), \(months[$0 % months.count]) \($0 % 27 + 1)" },
        { "Call \(people[($0 + 3) % people.count]) about the \(["lease renewal", "contract", "launch date", "budget"][$0 % 4])" },
        { "Electric bill: $\(String(format: "%.2f", 96.4 + Double($0) * 1.37)), due \(months[$0 % months.count]) \($0 % 26 + 2)" },
        { "Sprint \(30 + $0 / 4) retro" },
        { "Recipe: \(["miso glazed salmon", "shakshuka", "dal makhani", "lemon orzo", "pho ga", "mushroom risotto"][$0 % 6])" },
        { "Refund request #\(88_000 + $0 * 41), $\(String(format: "%.2f", 19.99 + Double($0 % 9) * 10))" },
        { "Reading notes: chapter \($0 % 24 + 1)" },
        { "Mortgage quote \($0 % 5 + 1): \(String(format: "%.3f", 5.875 + Double($0 % 6) * 0.125))%" },
        { "Interview loop: \(["Staff designer", "iOS engineer", "Data analyst", "Support lead"][$0 % 4]), candidate \($0 % 9 + 1)" }
    ]
    let images = [image("coast-landscape.jpg", name: "IMG_5512.JPG"), image("hills-portrait.jpg", name: "IMG_5519.JPG"),
                  image("zebra.png", name: "zebra.png"), image("sunflower.heic", name: "Sunflower.heic"),
                  image("dunes-panorama.jpg", name: "PANO_20251102_171455.jpg")]
    var cards: [Card] = []
    for index in 0..<100 {
        let column = CGFloat(index % 10)
        let row = CGFloat(index / 10)
        let x = -720 + column * 236
        let top = -560 + row * 272
        if index % 8 == 3 {
            cards.append(imageCard(images[(index / 8) % images.count], x: x, top: top, scale: 0.6))
            continue
        }
        let height: CGFloat = [116, 140, 200, 242][index % 4]
        var blocks = [display(templates[index % templates.count](index))]
        if index % 3 == 0 { blocks.append(body("Owner: \(people[index % people.count]). Updated Nov \(index % 18 + 1).")) }
        if index % 4 == 1 { blocks += [task("First pass", true), task("Review with team"), task("Send out")] }
        if index % 5 == 2 { blocks += [item("$\(120 + index * 37).00 estimate"), item("Net 30")] }
        cards.append(Card(blocks: blocks, frame: frame(x, top, 212, height)))
    }
    return cards
}

@MainActor
func seedStore(_ fixture: String, _ build: (NoteStore) -> Void) {
    let url = storeURL(fixture)
    let store = NoteStore(storeURL: url)
    if case .failure(let error) = store.loadSpaces() { fail(error.message) }
    build(store)
    print("seeded \(fixture)")
}

@MainActor
func insertSpace(_ store: NoteStore, _ name: String, _ order: Int) -> UUID {
    let space = SpaceRecord(name: name, order: order)
    if case .failure(let error) = store.insertSpace(space) { fail(error.message) }
    return space.id
}

func makeObject(_ entity: String, in context: NSManagedObjectContext, _ values: [String: Any]) -> NSManagedObject {
    guard let description = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[entity] else { fail("no entity \(entity)") }
    let object = NSManagedObject(entity: description, insertInto: context)
    for (key, value) in values { object.setValue(value, forKey: key) }
    return object
}

func itemValues(_ card: Card, order: Int) -> [String: Any] {
    [
        "identifier": UUID(), "canvasIdentifier": SpaceRecord.firstID, "kind": "note",
        "pointX": Double(card.frame.minX), "pointY": Double(card.frame.minY),
        "width": Double(card.frame.width), "height": Double(card.frame.height),
        "rotation": 0.0, "zIndex": Int64(order), "isHiddenFromFolders": false,
        "text": card.blocks.map(\.text).joined(separator: "\n")
    ]
}

func rawStore(_ fixture: String, model: NSManagedObjectModel, _ build: (NSManagedObjectContext) throws -> Void) {
    let url = storeURL(fixture)
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    do {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        try build(context)
        try context.save()
    } catch {
        fail("\(fixture): \(error.localizedDescription)")
    }
    print("seeded \(fixture)")
}

MainActor.assumeIsolated {
    seedStore("typical") { write(weeklyBoard(), to: $0) }
    seedStore("long-notes") { write(longNotes(), to: $0) }
    seedStore("tasks") { write(taskLists(), to: $0) }
    seedStore("images") { write(imageBoard(), to: $0) }
    seedStore("workload-100") { write(workload(), to: $0) }

    seedStore("spaces") { store in
        if case .failure(let error) = store.renameSpace(id: SpaceRecord.firstID, name: "Home") { fail(error.message) }
        write(weeklyBoard(), to: store)
        let work = insertSpace(store, "Work", 1)
        write(Array(taskLists().prefix(2)), to: store, space: work)
        let trip = insertSpace(store, "Lisbon trip", 2)
        write([weeklyBoard()[6], taskLists()[2]], to: store, space: trip)
        let remodel = insertSpace(store, "Kitchen remodel", 3)
        write([weeklyBoard()[1]], to: store, space: remodel)
        _ = insertSpace(store, "Reading", 4)
    }

    seedStore("first-space-empty") { store in
        let work = insertSpace(store, "Work", 1)
        write(Array(weeklyBoard().prefix(6)), to: store, space: work)
        let trip = insertSpace(store, "Lisbon trip", 2)
        write([weeklyBoard()[6]], to: store, space: trip)
    }

    seedStore("broken-image") { store in
        write(Array(weeklyBoard().prefix(4)) + [imageCard(image("coast-landscape.jpg", name: "IMG_5512.JPG"), x: 532, top: 70)], to: store)
    }
    let brokenURL = fixturesRoot.appendingPathComponent("broken-image/store.sqlite")
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: CoreDataStack.makeModel())
    do {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: brokenURL)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let request = NSFetchRequest<NSManagedObject>(entityName: "Item")
        request.predicate = NSPredicate(format: "kind == %@", "image")
        for object in try context.fetch(request) {
            let bytes = object.value(forKey: "imageData") as? Data ?? Data()
            object.setValue(bytes.prefix(48), forKey: "imageData")
        }
        try context.save()
    } catch {
        fail("broken-image: \(error.localizedDescription)")
    }

    rawStore("upgraded-store", model: CoreDataStack.makeModel(includeSpaces: false, includeImages: false, includeNoteBlocks: false)) { context in
        for (index, card) in weeklyBoard().enumerated() where !card.blocks.isEmpty {
            _ = makeObject("Item", in: context, itemValues(card, order: index))
        }
    }

    let newer = CoreDataStack.makeModel()
    let label = NSAttributeDescription()
    label.name = "colorLabel"
    label.attributeType = .stringAttributeType
    label.isOptional = true
    newer.entitiesByName["Item"]?.properties.append(label)
    rawStore("newer-version", model: newer) { context in
        let space = makeObject("Space", in: context, ["id": SpaceRecord.firstID, "name": "Space01", "order": Int64(0)])
        for (index, card) in weeklyBoard().prefix(4).enumerated() {
            var values = itemValues(card, order: index)
            values["colorLabel"] = "amber"
            let item = makeObject("Item", in: context, values)
            item.setValue(space, forKey: "space")
            item.setValue(try JSONEncoder().encode(NoteContent(blocks: card.blocks)), forKey: "noteContent")
        }
    }
}
