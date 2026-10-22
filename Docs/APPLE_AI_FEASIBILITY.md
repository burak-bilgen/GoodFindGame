# Apple AI feasibility for the trading game

Research date: 2026-10-22. Documentation and installed SDK inspection only; no models installed, no application code changed, and no device performance claims tested.

## Recommendation

Use optional **on-device text generation for bounded seller personality and dialogue variety** after the base catalog is richer. The user has authorized raising the minimum to **iOS 26**; preserve deterministic gameplay and fallback on every supported device. iOS 26 compatibility does not imply Apple Intelligence eligibility. Generate all factual item state, inspection outcomes, prices and bargaining decisions in the game engine before asking a model to help express them.

Apple supports on-device language generation. Current Image Playground also supports photorealistic output, but its new image model is cloud-based and the modern API is a user-controlled sheet: it does not solve automatic offline generation of an endless marketplace photo feed. A separately distributed custom diffusion model is technically possible, but it is a separate, heavier project.

## Capability and fallback

| Need | Apple technology / actual capability | Constraints | Recommended fallback |
| --- | --- | --- | --- |
| Varied, grounded listing copy and seller replies | Foundation Models `SystemLanguageModel`: on-device text; guided Swift schemas using `@Generable` / `@Guide`; custom `Tool` implementations can retrieve app data. [Apple overview](https://developer.apple.com/documentation/foundationmodels), [guided generation and tools](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models) | iOS 26+ API and eligible, enabled, ready Apple Intelligence device. Typed output constrains structure, not factual truth. Keep requests small; don't use it as a real-world product database or pricing oracle. [Apple WWDC25](https://developer.apple.com/videos/play/wwdc2025/286/) | Authored localized templates from the same item/seller state. Display immediately; optional AI decoration must never block trading. |
| Everyday product variety and categories | Models can suggest product ideas or select among allowed structured values; no documented guarantee of accurate specifications or balanced mechanics. | New categories need authored valuation, faults, repair/inspection rules and art. A generated “washing machine” cannot silently enter a system that has no appliance mechanics. | Add an authored, validated everyday-item catalog first. AI may decorate approved archetypes, not create unsupported gameplay categories at runtime. |
| Product photos via legacy ImageCreator | Programmatic generation exists from iOS 18.4; documented familiar styles include animation, illustration and sketch. | `ImageCreator` is deprecated in OS 27 in favor of the system UI. It is not a sound long-term foundation for silent photo-feed generation. | Bundled item images, grounded variants and deterministic wear/detail overlays. |
| Photorealistic Image Playground | Apple's WWDC26 explicitly documents photorealistic styles using a new Private Cloud Compute image model, with user confirmation through the system sheet. | Network/cloud dependency, system-managed usage limits, availability/settings checks. Source images are inspiration rather than strict constraints; exact product/damage fidelity isn't guaranteed. | Optional player-invoked creative feature only, if desired later; keep marketplace art available offline. [Apple WWDC26](https://developer.apple.com/videos/play/wwdc2026/375/) |
| App-owned local image/LLM model | Core ML supports bundled or downloaded/compiled models and offline inference. Apple's Stable Diffusion sample demonstrates a Swift image-generation pipeline. | We supply compatible weights, tokenizer/pipeline and storage/update handling; model-specific redistribution/use terms need review. RAM, thermal load, battery and latency require measurements. Core ML is a runtime, not a free installed photo generator. [Core ML](https://developer.apple.com/documentation/coreml), [Apple Stable Diffusion sample](https://github.com/apple-aiml-research/ml-stable-diffusion) | No required model download for basic play. Retain curated assets and templates if the download is absent, fails, or the device cannot run it comfortably. |

For new custom neural-network work on iOS 27+, also evaluate **Core AI**, which Apple now recommends for that layer. This still needs a separate path for the game's iOS 26 users. [Apple WWDC26 framework guidance](https://developer.apple.com/videos/play/wwdc2026/8121/), [Core AI model compilation](https://developer.apple.com/documentation/coreai/compiling-core-ai-models-ahead-of-time)

## Device, OS, language and installation gates

The app does not install Apple's Foundation Model weights itself. Apple manages the system assets; inspect `SystemLanguageModel.default.availability`, handling `deviceNotEligible`, `appleIntelligenceNotEnabled`, and `modelNotReady`. A device capable of running the game can still lack the model. Once available, select the explicit on-device model; the expanded Foundation Models framework also offers server providers, which must not become an accidental network dependency. [Apple SystemLanguageModel](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel), [Apple 27 platform updates](https://developer.apple.com/documentation/updates)

Apple's September 2026 support page lists iPhone 15 Pro/Pro Max and iPhone 16 models or later (including iPhone Air); iPad mini A17 Pro and M1+ iPads; and supported Apple-silicon Macs. Ordinary iPhone 15/older iPhones are not eligible. System assets use several GB and language/Siri settings affect readiness. Current supported languages include English, Turkish, German, French, Japanese and both Chinese scripts; Arabic and Hindi are absent. China mainland availability is restricted. Check exact feature availability at runtime rather than treating translation support as model support. [Apple requirements, updated September 14, 2026](https://support.apple.com/en-us/121115)

`supportsLocale(_:)` and `supportedLanguages` let the app check its chosen language. Support varies with OS/model version; supported device language does not establish support for every app language. Unsupported-language errors must fall back cleanly. [Apple multilingual Foundation Models guidance](https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models)

Local SDK evidence checked at `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/`:

- `FoundationModels.framework/Modules/FoundationModels.swiftmodule/arm64e-apple-ios.swiftinterface` marks `SystemLanguageModel` APIs iOS 26.0 and contains the three unavailability reasons and locale checks above.
- `ImagePlayground.framework/Modules/ImagePlayground.swiftmodule/arm64e-apple-ios.swiftinterface` marks `ImageCreator` introduced iOS 18.4, deprecated OS 27, with guidance to use `ImagePlaygroundViewController` or `imagePlaygroundSheet`.

### Minimal text adapter API, verified in the installed SDK

Use the iOS 26 API surface, not the new generic model-provider overloads introduced in iOS 27:

- `SystemLanguageModel.default`: explicit Apple on-device model; `availability` reports readiness and `supportsLocale(_:) -> Bool` checks the requested app locale synchronously. `supportedLanguages` is available for inspection.
- `LanguageModelSession(model: SystemLanguageModel = .default, tools: [any Tool] = [], instructions: String? = nil)` is available on iOS 26. Use the explicit model argument and no tools for the initial one-shot, snapshot-grounded feature.
- Define a tiny `@Generable` response type, then call `try await session.respond(to: prompt, generating: ListingDecoration.self, options: options)` and read `response.content`. The SDK's typed `respond` overload is `async throws` and constrains `Content: Generable`. It also accepts `includeSchemaInPrompt`, defaulting to true.
- `prewarm(promptPrefix:)` exists but is optional; do not load work solely because a user opened a screen that already has sufficient authored copy. Serialize one request per session; discard canceled/stale results and return fallback on failure.

For **Apple's system model**, OS-managed asset preparation replaces an app-owned weight download: we do not bundle or fetch these weights. For a **custom local model**, we must distribute the weights ourselves (bundle or optional download), retain/check their version, and supply the execution pipeline; Core ML/Core AI do not automatically install a model of our choice. The first version should use the system model and require no new model-download UI.

The former has a small context budget; Apple states 4096 tokens for the iOS 27 on-device model, shared by input and output. Use one listing or reply per short request, not the entire catalog/chat history. Query capability APIs when available rather than assuming future models retain the same limit. [Apple engineering lab](https://developer.apple.com/videos/play/wwdc2026/8121/)

## Preserve one authoritative item truth

These are proposed integration rules, not guarantees supplied by a model:

1. Persist the engine-generated item identity, archetype, condition, actual defects, disclosed claims, seller knowledge, known inspection facts, exact offer and bargaining outcome first.
2. Provide only facts the seller may know/reveal at that moment. Hidden faults do not enter the prompt. Return small structured output with approved dialogue/intent identifiers and bounded flavor text; do not give tools mutation powers.
3. Compose essential factual claims, money and contractual decisions deterministically. For a first version, confine free text to nonfactual personality flourishes. A schema or “do not hallucinate” instruction alone cannot verify arbitrary prose.
4. Validate allowed identifiers, lengths and locale. Reject errors/refusals, unsupported output and stale results; use the authored variant. Cache accepted decoration by item, content revision, locale and prompt version so reopening a listing doesn't change its story. Recheck revision before accepting an asynchronous result.
5. Ground photos in the same persistent identity. If a generated image invents a missing accessory, erases a crack or changes model/condition, do not use it as inspection evidence. Curated photos/controlled overlays remain the trusted visual source.

## Staged implementation

1. **Content first:** broaden authored everyday archetypes and localized seller voices, with curated product photography/variants. This helps every device immediately.
2. **Small optional text pilot:** iOS 26+ availability-gated adapter, one seller flavor/reply use case, authored fallback, cached output. No custom model download and no economy authority. Evaluate a small representative set across en/tr/de/fr, including timeouts, unavailable model, contradiction and save/reopen behavior.
3. **Decide on benefit:** keep it only if the dialogue improvement outweighs latency and maintenance; measure on an actual eligible lower-end device. Avoid repeated broad suites for an exploratory text feature.
4. **Images separately:** for the main offline feed, prefer pre-produced, editorially reviewed assets. Consider custom local diffusion only after an explicit storage/performance budget, selected model terms and a real-device prototype. Image Playground may serve an optional creative sheet, not required world generation.

No exact custom-model size, speed, license permission or photographic fidelity is promised. Apple's sample benchmarks vary substantially by model/device and are historical examples, not measurements of this game. A custom weight package must be assessed independently of the sample code's license.
