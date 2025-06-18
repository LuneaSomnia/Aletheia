import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

// CHANGED: Replaced old actor definitions with direct, modern imports.
// Dfx will automatically link these to the correct canisters from your dfx.json file.
import UserAccount "canister:user_account_backend";
import AletheianDispatch "canister:aletheian_dispatch_backend";
// CHANGED: Import our shared types file.
import Types "src/declarations/types";

actor {
    // --- State ---
    private var nextClaimId: Types.ClaimId = 0;
    // REMOVED: The old optional actor variables are no longer needed.

    // REMOVED: The `set_..._canister` functions are no longer needed because dfx handles linking.

    // --- Core Logic ---
    public shared func submitClaim(
        claimText: Text,
        claimType: Text,
        source: ?Text,
        context: ?Text
    ): async Result.Result<Types.ClaimId, Text> {
        if (Text.size(claimText) == 0) {
            return Result.Err("Claim text cannot be empty.");
        };

        let newClaim: Types.Claim = {
            id = nextClaimId;
            submitter = msg.caller;
            claimText = claimText;
            claimType = claimType;
            source = source;
            context = context;
            submittedAt = Time.now();
        };
        nextClaimId += 1;

        // --- Inter-Canister Calls (REFACTORED & SIMPLIFIED) ---
        // 1. Notify the UserAccountCanister.
        try {
            // We now call the imported actor directly. It's much cleaner!
            await UserAccount.incrementSubmittedClaimsCount(newClaim.submitter);
        } catch (e) {
            // Production logging would go here for this non-critical error.
        };

        // 2. Send the claim to the AletheianDispatchCanister.
        try {
            await AletheianDispatch.dispatchNewClaim(newClaim);
        } catch (e) {
            // This is a critical error if the dispatch fails.
            return Result.Err("Critical Error: Failed to add claim to the verification queue. Please contact support.");
        };

        return Result.Ok(newClaim.id);
    };
}