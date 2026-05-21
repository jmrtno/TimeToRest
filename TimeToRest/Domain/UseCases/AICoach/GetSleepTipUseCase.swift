import FoundationModels

// MARK: - GetSleepTipUseCase
/// A use case that retrieves a personalised sleep tip using the on-device AI model.
///
/// Use cases represent the application's business rules and orchestrate the flow
/// of data between entities and repositories. They are the entry points to the
/// domain layer from the presentation layer.
///
/// ## Design Principles
/// - Single Responsibility: Each use case handles one specific business operation
/// - Dependency Injection: Repositories and services are injected via initializer
/// - Framework Independence: No UI or infrastructure dependencies
/// - Testability: Easy to unit test with mock dependencies
///
/// ## Usage
/// ```swift
/// let useCase = GetSleepTipUseCase()
/// let tip = await useCase.execute()
/// ```
struct GetSleepTipUseCase {

    // MARK: - Generable

    @Generable
    struct SleepTip {
        @Guide(description: "A single, concise tip to prepare for a restful sleep")
        var tip: String
    }

    // MARK: - Execute

    /// Executes the use case and returns a sleep tip string.
    ///
    /// Checks model availability before attempting generation. Returns a
    /// descriptive message if the AI Coach is unavailable for any reason.
    ///
    /// - Returns: A sleep tip or a user-friendly error message.
    func execute() async -> String {
        switch SystemLanguageModel.default.availability {
        case .available:
            break
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence is not enabled. Please enable it in Settings > Apple & Siri."
            case .deviceNotEligible:
                return "AI Coach is not available on this device."
            case .modelNotReady:
                return "AI Coach is getting ready. Please try again in a moment."
            @unknown default:
                return "AI Coach is temporarily unavailable."
            }
        }

        do {
            let instructions = """
                You're a Sleep Optimisation Coach. Provide exactly one concise, \
                actionable tip in one or two short sentences. Address the user in the \
                second person ("you") and use a warm, encouraging tone. Each time you \
                respond, try to cover a different aspect of sleep hygiene to maximize \
                variety. Avoid repeating the same topics consecutively.
                """
            let session = LanguageModelSession(instructions: instructions)
            let prompt = """
                Give one single practical tip that a person should follow before going \
                to bed to ensure a restful night's sleep. Choose from these diverse \
                categories: screen time and blue light, breathing exercises and \
                meditation, room temperature and ventilation, lighting and darkness, \
                mattress and pillow comfort, evening wind-down routines, caffeine and \
                alcohol timing, exercise timing, noise reduction, aromatherapy, \
                journaling before bed, reading habits, shower or bath timing, \
                stretching or yoga, mindful eating in the evening, phone placement, \
                sleep schedule consistency, napping guidelines, stress management \
                techniques, or any other evidence-based sleep habit. Keep it to a \
                couple of lines.
                """
            let response = try await session.respond(to: prompt, generating: SleepTip.self)
            return response.content.tip
        } catch {
            return "Unable to load AI Coach tips. Make sure your iPhone and Siri are set to the same language in Settings."
        }
    }
}
