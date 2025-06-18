import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import Text "mo:base/Text";

// CHANGED: Import our new, centralized types.
import Types "src/declarations/types";

actor {
    // --- State ---
    // The state now uses the imported UserProfile type.
    private var userProfiles: TrieMap.TrieMap<Principal, Types.UserProfile> = TrieMap.empty();

    // --- Queries ---
    public query func getMyProfile(): async ?Types.UserProfile {
        return TrieMap.get(userProfiles, msg.caller);
    };

    // --- Updates ---
    public shared func registerOrLoginUser(): async Types.UserProfile {
        switch (TrieMap.get(userProfiles, msg.caller)) {
            case (?existingProfile) {
                return existingProfile;
            };
            case (null) {
                let defaultSettings: Types.UserSettings = {
                    notificationPreferences = {
                        claimUpdates = true;
                        learningReminders = true;
                        platformAnnouncements = true;
                    };
                };
                let newProfile: Types.UserProfile = {
                    id = msg.caller;
                    var username = null;
                    registeredAt = Time.now();
                    var settings = defaultSettings;
                    var submittedClaimsCount = 0;
                    var learningProgressReference = null;
                };
                userProfiles.put(msg.caller, newProfile);
                return newProfile;
            };
        };
    };

    // REFACTORED: This function is now more efficient.
    public shared func updateMySettings(newSettings: Types.UserSettings): async Result.Result<Text, Text> {
        switch (userProfiles.get(msg.caller)) {
            case (?var profile) { // Use 'var' to get a mutable reference
                profile.settings := newSettings; // Directly update the settings field
                return Result.Ok("Settings updated successfully.");
            };
            case (null) {
                return Result.Err("Profile not found. Cannot update settings.");
            };
        };
    };

    // REFACTORED: This function is now more efficient.
    public shared func updateMyUsername(newUsername: Text): async Result.Result<Text, Text> {
        if (Text.size(newUsername) < 3) { return Result.Err("Username must be at least 3 characters long."); };
        if (Text.size(newUsername) > 20) { return Result.Err("Username must be 20 characters or less."); };

        switch (userProfiles.get(msg.caller)) {
            case (?var profile) { // Use 'var' to get a mutable reference
                profile.username := ?newUsername; // Directly update the username field
                return Result.Ok("Username updated successfully.");
            };
            case (null) {
                return Result.Err("Profile not found. Cannot update username.");
            };
        };
    };

    // --- Inter-Canister Function ---
    // REFACTORED: This function is now more efficient.
    public shared func incrementSubmittedClaimsCount(userId: Principal): async Bool {
        // TODO: In a later phase, add authorization to ensure only the
        // ClaimSubmissionCanister can call this function.

        switch (userProfiles.get(userId)) {
            case (?var profile) { // Use 'var' to get a mutable reference
                profile.submittedClaimsCount += 1; // Directly increment the count
                return true;
            };
            case (null) {
                return false;
            };
        };
    };
}