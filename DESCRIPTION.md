# ContactsExplorer - iOS Home Assignment

## Сleanup
- **Dead and commented-out code removed** 
- **`MockGenerator` → `SampleContacts`, plus moved to the test target**

## Contact
- **Birthdays without a year no longer "6 November 1".** `birthday` is `DateComponents?` instead of `Date?`. It was inventing year 1, which also carries a Local Mean Time offset that could shift the displayed day. Formatting moved to the VM including year-less style when there's no year; verified in en/ru/he/ja.
- **The last three hardcoded strings left the model.** `"No Name"` and the `"phone"`/`"email"` fallback labels are now `String(localized:)` constants with translator comments — not the `LocalizedStringKey` the views use, since a key needs a view's environment to resolve against and `displayName` is folded for search besides. They were the only user-visible strings in the app not going through localization — and they were sitting in a model, where UI copy does not belong.
- **`LabeledValue.id` is derived from its contents instead of a stored `UUID`.** A stored one was regenerated on every fetch, so the synthesized `==` made a re-fetched `Contact` unequal to the one already on screen — `Contact: Hashable` was unstable across loads.

## ContactsListView
- **View structure** — split into sections. The view only lays out what each state looks like; logic and view state moved into the view model. Reusable parts, constants and strings extracted.
- **States** — no results, loading, permission denied and an empty address book are all handled now.
- **The empty state can refresh itself.** `.refreshable` used to live only on the `.content` branch and `loadIfNeeded` only ever runs once, so adding a contact on the device left "No Contacts" on screen with no way back. `ContentUnavailableView` does not scroll, so it is wrapped in a full-height `ScrollView` to give the gesture something to pull. The permission-denied screen deliberately keeps only its "Open Settings" button: changing that permission in Settings terminates the app, so it reloads from scratch anyway, and a second, weaker affordance next to the right one would only muddy it.
- **Search** — now the system `.searchable`. iOS 26 puts it in the bottom bar by default; can be moved back under the title, or switched custom again if there's a reason to.
- **The avatar is hidden from VoiceOver.** It is decorative in both places it is used — the name it stands for is always right beside it — so without this VoiceOver reads "ES, Emma Stone".
- **Contact row** — now a `NavigationLink`. A custom button can come back if the row ever needs more; the link gives RTL mirroring and correct VoiceOver.
- **ContactRowModel** — the list no longer touches the domain model; rows render a prepared presentation model. `isFavorite` is deliberately left out of it: it changes far more often than the list, and folding it in would rebuild every row model on each tap.

## ContactsListViewModel
- **`ContactsStore` stopped owning UI state** — deleted `LoadState`; `load()` now just fetches or throws `ContactsError.accessDenied`. One state machine - view model's `ViewState`
- **Rows mapped once per load**, not on every `body` pass. `ContactRowModel` carries a folded name and every phone number's digits, computed once, so search doesn't re-fold the whole address book on each keystroke.
- **Search** — debounced 250ms with the previous attempt cancelled; but clearing the field applies immediately. A query is classified once as a name or a number (any letter → name) rather than per contact. Diacritics are folded, so "jose" matches "José".
- **Digits-only queries search phone numbers and nothing else** — a deliberate narrowing, and the one place here where the answer is product, not engineering. The original matched the name first and fell through to the number, so "54" would surface "Studio 54"; it no longer does. The tradeoff bought a single classification per query instead of per contact, and a digits query on an address book full of numbers is far more often a phone lookup than a name lookup. Both readings are defensible, this one just isn't free — matching names as well is a one-line change in `search(for:)`, which is commented accordingly.
- **Revoked access clears the address book from memory**, in the store as well as in the view model. The view model drops its `rows` so the permission-denied screen cannot be painted over a stale list; `ContactsStore` drops `contacts` so nothing downstream — the detail screen resolves live from it — keeps serving an address book after the permission that allowed it is gone. Covered by `ContactsStoreTests`.
- **A failed refresh keeps the existing list** rather than replacing it with an error screen; only a failure with nothing loaded yet shows `.failed`.

## ContactDetailView&ContactDetailViewModel
- **View structure** — same shape as the list: `body` reduced to a `switch`, everything else in `private extension` subviews, `Metrics`/`Icons`/`Strings` extracted, `Strings` - localized.
- **`ContactDetailViewModel`** — `ViewState { unavailable, content(Contact) }`, resolved live from `store.contacts` on every read rather than cached, so there's no second copy of the store's data to keep in sync. `.unavailable` is defensive: unreachable today, just sort if "safe unwrap".
- **The view no longer touches `store` directly** — favoriting goes through the view model, matching the list.
- **`loadFullImage` moved out of the view entirely.** The `CNContactStore` call itself moved into `ContactsStore.loadFullImage(for:)`, so the store stays the one place in the app that talks to.
- **`ContactDetailView` owns its view model in `@State`, not a stored `let`.** `navigationDestination` rebuilds its destination whenever the list's body re-runs — favoriting from the detail screen is enough to do it — and a plain stored property would be replaced by a fresh view model each time, dropping the full-size photo back to the thumbnail. A crossfade between the two was tried and dropped on taste.
- **Logger kept here**, since a failed image load is otherwise completely silent. In the list an error has a visible state of its own.

## FavoritesStore
- **`FavoritesManager` → `FavoritesStore`, extracted out of `ContactsStore`.** The store was doing two unrelated jobs — fetching the address book and persisting favorites. Now each does one.
- **`UserDefaults` is injected** instead of hardcoded to `.standard`, so tests can run against their own suite rather than the app's real defaults. The storage key is deliberately unchanged — anyone who has already favorited contacts keeps them.
- **The API is id-based**, which is all favorites ever needed. That removed a linear scan through every contact on each tap, and with it a quiet failure: if the id didn't resolve, tapping the star used to do nothing at all.
- **Not done, and this is now the obvious place for it:** favorites are never pruned, so a contact deleted from the address book leaves its id behind forever. Pruning should run after a successful load — the type exists partly so that fix has somewhere to live. This is also the place to synchronize contacts. Extraction also helps to switch to any other storage.

## ContactsStore&ContactsProvider
- **`ContactsStore` split in two.** Reading contacts has to be synchronous — SwiftUI evaluates `body` without `await` — while fetching them must not be on the main thread. `SystemContactsProvider` is an `actor` that does the Contacts-framework work off the main thread. That's the fix for the original blocking `enumerateContacts`.
- **One `CNContactStore` instead of one per call.** It was being constructed at three separate call sites; Apple's guidance is to keep a single instance, since each sets up its own connection.
- **Concurrent loads join the one already running** rather than starting a second pass over the whole address book.
- **Enumeration honours cancellation** and reports a partial stop as an error instead of returning a truncated address book as if it were complete.
### Honest about the last two - Neither is reachable through today's UI. Concurrent `load()` has no path — the list isn't shown during the first load, so there's nothing to pull, and the Try Again button disappears before a second tap can land. And nothing cancels the load task: `Task { }` doesn't inherit cancellation from its parent, so `Task.isCancelled` inside the enumeration is always false. Both are kept as contracts of a shared service that shouldn't misbehave when called twice or from a cancelled context — not as fixes for live bugs. Worth knowing they're defensive for now and for future development.


## Tests
- **View model tests are the point of the protocols.** A stub `ContactsProviding` makes each outcome available on demand, so the whole state machine is now testable: contacts load into rows, an empty address book reads as empty, denied access is distinguished from a generic failure, and a failed refresh keeps the rows already on screen. None of this could be written before — every path went to the real `CNContactStore`, and checking the permission-denied branch would have meant actually revoking access.
- **The search fixes are covered**: "jose" finds "José García", "612" finds a contact by a number that isn't the one shown in its row, and "Emma123" matches nothing even though "123" appears in Emma's number.
- **`FavoritesStore` is tested against its own `UserDefaults` suite**, so the app's real defaults are never touched, and persistence is exercised for real rather than faked.
- **`ContactsStore` has tests of its own now**: losing access mid-session empties the store, a failure of any other kind leaves the loaded contacts alone, and two loads started at once make one pass over the address book rather than two.
- **`aRefetchedContactStaysEqual` pins the `LabeledValue.id` fix** — rebuilding a contact from identical values has to produce an equal, equally-hashing value, which is the property the stored `UUID` broke. The old test named "two contacts are equal" only ever compared two `LabeledValue`s; it kept its assertion and got an honest name.
- **`SampleContacts` is finally used.** It had been carried along unused since the cleanup stage; it now backs all three suites.

## OOS and to be done

- Performance at Scale (Handling thousands contacts): Currently, the app fetches and maps the entire address book into memory at once. While ContactsProvider does the heavy lifting in a background actor, mapping thousands of Contact objects to ContactRowModel and filtering them on every keystroke happens on the Main thread. To support massive corporate address books, I would introduce background mapping, chunked loading/pagination.

- Data Integrity & Storage (The Favorites Pruning issue): FavoritesStore relies on UserDefaults. It was a pragmatic choice for this limited-time task, but it results in orphaned IDs when a contact is permanently deleted from the OS. By extracting FavoritesStoring into a protocol, the app is ready for a storage swap. Next step: migrating to SwiftData or SQLite, which would allow us to solve the pruning issue robustly via database constraints, rather than manual synchronization. Also it is possible to setup BE sync for example.

- Routing & Navigation: Navigation is currently coupled directly inside the Views via NavigationLink. To make the modules truly isolated and testable, I would extract the navigation logic into a Coordinator, Router, or a centralized NavigationPath state manager.

- Observability vs. Logging: ContactDetailViewModel currently uses os.Logger for silent image loading failures. In a real-world application, local logs aren't enough to monitor app health. I would inject an AnalyticsTracking or ErrorReporting service to capture business-critical failures (like dropped permissions or parsing errors) and send them to the team's monitoring dashboards.

- Staleness & Lifecycle (No refresh after the first load): The list is fetched once on launch and after that only on pull-to-refresh. `scenePhase` is not observed, so coming back from the background shows whatever was loaded at launch, however stale — a contact added, renamed or deleted on the device in the meantime is simply not reflected. The minimal fix is a refresh on the transition back to `.active`. The better one is subscribing to `CNContactStoreDidChange`, which reacts to the address book actually changing rather than to the app being reopened.

- Test Coverage (What is here is a sample, not coverage): The existing suites were written to demonstrate what became testable once the provider moved behind a protocol — the list view model's full state machine, the search fixes, favorites persistence, the `Hashable` fix, and the store's behaviour when access is revoked. They are deliberately partial, not a complete suite. So it would make sense to finish all the tests.

- Localization (Prepared, not finished): Every user-visible string now goes through `LocalizedStringKey` in the views or `String(localized:)` in the model, so none of them are hardcoded any more — but there is no string catalog in the project, so all of it still resolves to the English literal. The next step is a real `Localizable.xcstrings` under a dedicated `Resources/Localization` group.

- Interaction (A contact card you cannot act on, and a list that is not a contacts list): Phone numbers and emails render as plain `LabeledContent` rows — you cannot tap to call, message or write, and cannot copy one. `tel:` and `mailto:` links plus a copy action are the obvious next step. On the list side there are no A–Z sections and no index scrubber, which is exactly what separates this from the system Contacts app once the address book holds a few thousand people.
