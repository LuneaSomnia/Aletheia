import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import Array "mo:base/Array";
import Nat "mo:base/Nat";

// CHANGED: Import our new, centralized types.
import Types "src/declarations/types";

actor {
    // --- State ---
    private var aletheianProfiles: TrieMap.TrieMap<Principal, Types.AletheianProfile> = TrieMap.empty();
    private let admin: Principal = msg.caller;

    // --- Helpers ---
    private func _isAdmin(caller: Principal): Bool {
        return caller == admin;
    };

    private func _getRankForXP(xp: Types.ReputationScore): Types.AletheianRank {
        if (xp >= 5000) { return "Master Aletheian / Elder"; }
        else if (xp >= 2000) { return "Expert Aletheian"; }
        else if (xp >= 750) { return "Senior Aletheian"; }
        else if (xp >= 250) { return "Associate Aletheian"; }
        else if (xp >= 0) { return "Junior Aletheian"; }
        else { return "Trainee Aletheian"; };
    };

    // --- Queries ---
    public query func getMyProfile(): async ?Types.AletheianProfile {
        return TrieMap.get(aletheianProfiles, msg.caller);
    };

    // --- NEW REQUIRED FUNCTION ---
    // This is needed by the AletheianDispatchCanister to find available workers.
    public query func getAvailableAletheians(limit: Nat): async [Types.AletheianProfile] {
        var results: [Types.AletheianProfile] = [];
        var count: Nat = 0;
        for ((_key, profile) in TrieMap.iter(aletheianProfiles)) {
            // Filter for Aletheians who are marked as active
            if (profile.isActive and count < limit) {
                results := Array.append(results, [profile]);
                count += 1;
            } else if (count >= limit) {
                break;
            };
        };
        return results;
    };

    // --- Updates ---
    public shared func registerAletheian(id: Principal, username: Text): async Result.Result<Types.AletheianProfile, Text> {
        if (not _isAdmin(msg.caller)) { return Result.Err("Unauthorized: Only an admin can register Aletheians."); };
        if (TrieMap.containsKey(aletheianProfiles, id)) { return Result.Err("Aletheian with this Principal already exists."); };

        // FIXED: The stats object is created directly as a value.
        let initialStats: Types.AletheianStats = {
            totalClaimsVerified = 0;
            correctClaims = 0;
            warnings = 0;
        };

        let initialProfile: Types.AletheianProfile = {
            id = id;
            username = username;
            registeredAt = Time.now();
            var xp = 0;
            var rank = "Junior Aletheian";
            var badges = [];
            var stats = initialStats;
            var isActive = true;
        };
        TrieMap.put(aletheianProfiles, id, initialProfile);
        return Result.Ok(initialProfile);
    };

    // REFACTORED: This function now correctly modifies the mutable profile fields.
    public shared func updateXP(id: Principal, xpChange: Types.ReputationScore, wasCorrect: Bool): async Result.Result<Types.AletheianRank, Text> {
        switch (TrieMap.get(aletheianProfiles, id)) {
            case (?var profile) { // Get a mutable reference
                profile.xp += xpChange;
                profile.rank := _getRankForXP(profile.xp);

                if (xpChange != 0) {
                    profile.stats.totalClaimsVerified += 1;
                    if (wasCorrect) {
                        profile.stats.correctClaims += 1;
                    };
                };
                return Result.Ok(profile.rank);
            };
            case (null) { return Result.Err("Profile not found."); };
        };
    };

    public shared func addBadge(id: Principal, badge: Types.ExpertiseBadge): async Result.Result<Null, Text> {
        if (not _isAdmin(msg.caller)) { return Result.Err("Unauthorized: Only an admin can add badges."); };
        
        switch (TrieMap.get(aletheianProfiles, id)) {
            case (?var profile) { // Get a mutable reference
                // Check if badge already exists
                var alreadyHasBadge = false;
                for (b in profile.badges.vals()) {
                    if (b == badge) { alreadyHasBadge := true; break; };
                };
                if (not alreadyHasBadge) {
                    profile.badges := Array.append(profile.badges, [badge]);
                };
                return Result.Ok(null);
            };
            case (null) { return Result.Err("Profile not found."); };
        };
    };
}