# Fish Logger

A fishing log for iPhone. I start a trip when I get to the water, tap a fish tile when something comes in, and put the phone back in my pocket. Later I can scroll back by day and see what worked: which spots, which hours, what the pressure was doing.

Everything works offline. Weather fills in when there's signal, and the phone's own barometer covers pressure when there isn't. The moon and sunrise math runs on the phone.

## Running it

Open `FishLogger.xcodeproj` in Xcode 16 or newer. CI builds it with Xcode 26.6. Pick an iPhone simulator and press Run. Cmd+U runs the tests.

To put it on your own phone, plug the phone in, open the FishLogger target, go to Signing & Capabilities, and pick your Apple ID under Team. If Xcode says the bundle identifier is taken, change `ca.katsumaonishi.FishLogger` to anything unique. With a free Apple ID the app stops opening after 7 days and you reinstall it from Xcode. The paid developer program ($99 USD a year, about $139 CAD) removes that limit and is needed for TestFlight or the App Store.

The simulator has no camera or barometer. Photo ID falls back to the photo library there, and pressure falls back to the weather service.

To try the stats without fishing first, go to Settings and tap Add sample trips. That adds 20 made-up trips around southern Ontario lakes. Delete sample trips removes them.

## First launch

The app asks two things: where you fish and what you fish for. Where is a list of 19 regions, from British Columbia and Ontario down to Texas and Florida, or Use my location to pick one from GPS. What is a grid of kinds of fish: walleye and perch, bass, panfish, trout, inshore, offshore, and so on. Kinds your regions don't have are left off, so nobody in Saskatchewan gets asked about tuna. Both can be skipped, and skipping means all of North America and a bit of everything.

The answers decide which fish show up in lists and which tiles the quick log starts with. A Florida angler doesn't scroll past lake trout, and an Ontario one doesn't see peacock bass. Search still finds every species, with the ones from other regions listed after, so an odd catch can always be logged. Change both later in Settings, Your fishing.

## How logging works

Today tab, Start fishing. The spot name fills in from GPS: a nearby spot you've fished before if there is one, otherwise the lake or town name. Water body and method default to last time. One more tap starts the trip.

Each fish is one tap on its tile. Favourites come first, then what you catch most, then the usual fish for your region. The order is fixed for the whole trip so a tile never moves under your thumb; a new species goes on the end. A bar shows up for 6 seconds with Size, Photo, and Undo, and stays put while VoiceOver is on. Size is optional. Long-press a tile to log 2, 3, or 5 at once.

Size buttons show the length range for that species, so "Large" means the same thing every trip. A large walleye is 55 to 70 cm. You can also enter exact length and weight in the catch editor. When you enter a length but no weight, the app estimates weight from the species' standard length-weight curve and labels it as an estimate.

If you never press Start, the first fish starts a trip anyway, with last trip's water and method. If a trip is still running the next morning, Today asks whether you're still fishing before logging into it.

## Photo ID

There are three ways to identify a fish, and they fall back in order:

1. Claude. Add an Anthropic API key in Settings, Photo ID (get one at console.anthropic.com). The photo is sent only when you tap Identify with Claude, never just for picking it. The request names your regions so the answer leans toward fish you can actually catch there. It uses `claude-opus-5-5` by default; the model is editable in Settings. Each ID costs a few cents of API credit.
2. Your own Core ML model, if you add one. Train an image classifier in Create ML with one folder of photos per species, named with the species id (`walleye`, `northern_pike`, `smallmouth_bass`, and so on; ids are in `FishLogger/Species/SpeciesCatalog+Data.swift`). Name the output `FishClassifier.mlmodel` and drop it into the `FishLogger` folder. Xcode picks it up on the next build.
3. The checklist. Tap the features you can see, like a white tip on the tail or whiskers, and the list narrows to fish from your regions. The best matches stay pinned at the bottom. Works with no signal.

You always confirm the species before anything is logged.

## Siri and the Action Button

"Log a walleye in Fish Logger", "Start fishing in Fish Logger", and "End my trip in Fish Logger" all work without opening the app. On an iPhone with an Action Button, set it to the Log a Catch shortcut in the Shortcuts app and logging becomes one press.

## Accessibility

Settings has light, dark, or match iPhone; text size separate from the system setting; four button sizes for wet or gloved hands; high contrast; haptics on or off; and a left-handed layout. Everything has VoiceOver labels and follows Dynamic Type.

## Data

Trips, catches, and photos live on the phone in SwiftData. Nothing syncs anywhere. Settings, Export CSV gives one row per catch with the trip's conditions alongside, for a spreadsheet or R.

Weather comes from Open-Meteo, which is free for non-commercial use and needs no key. Trips logged offline can be filled in later from the trip's page in the Trips tab, up to 92 days back. If this ever ships as a paid app, Open-Meteo needs a commercial plan.

Species data covers 177 game fish across Canada and the US, each tagged with the regions where people actually catch it: freshwater and sea-run fish, inshore fish like redfish, snook and fluke, offshore fish like mahi and tuna, and bottom fish from cod to rockfish. Where a fact couldn't be confirmed it was left out, so a few regions are probably missing fish they have. It isn't a regulations guide. In Ontario, check the Ontario Fishing Regulations Summary before keeping anything; elsewhere, your province or state's version.

## Code

- `FishLogger/Models`: SwiftData models. `Trip` has many `FishCatch`, which has many `CatchPhoto`. Measurements are stored in cm, kg, °C, hPa, km/h, and metres, and converted only for display.
- `FishLogger/Services`: `CatchLogger` does every write (start trip, log fish, end trip) so the Today tab, photo ID, and Siri behave the same. Also GPS, barometer, weather, and the moon and sun math.
- `FishLogger/Features`: one folder per tab plus the catch editor and photo ID.
- `FishLogger/Intents`: Siri and Shortcuts.
- `FishLoggerTests`: Swift Testing. CI runs them on every pull request with the newest Xcode on GitHub's macOS runner.

Minimum iOS is 17.0.
