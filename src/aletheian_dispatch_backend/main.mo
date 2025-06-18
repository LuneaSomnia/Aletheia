import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat "mo:base/Nat";

// CHANGED: Replaced old actor definitions and local types with direct imports.
import AletheianProfileCanister "canister:aletheian_profile_backend";
import VerificationWorkflowCanister "canister:verification_workflow_backend";
import Types "src/declarations/types";

actor {
  // REMOVED: The old optional actor variables are no longer needed.
  // REMOVED: The `set_..._canister` functions are no longer needed because dfx handles linking.

  // --- Core Logic ---

  // This is the main entry point, called by the ClaimSubmissionCanister.
  public shared func dispatchNewClaim(claim: Types.Claim) : async () {
    // TODO: Authorization check to ensure only ClaimSubmissionCanister can call this.
    // if (msg.caller != ... ) { throw Error.reject("Unauthorized"); };

    // Step 1: Get a list of available Aletheians from the AletheianProfileCanister.
    // We request more than we need (20) to ensure we can find suitable candidates.
    var availableAletheians: [Types.AletheianProfile];
    try {
      // CHANGED: Call the imported actor directly.
      availableAletheians := await AletheianProfileCanister.getAvailableAletheians(20);
    } catch (e) {
      // CRITICAL: If we can't get a list of Aletheians, we can't dispatch.
      // In a production system, this should trigger an alert or add the claim to a retry queue.
      return; // Exit the function for now
    };

    if (availableAletheians.size() < 3) {
      // Not enough Aletheians online to process the claim.
      // In production, this would queue the claim for later dispatch.
      return;
    };

    // Step 2: Select the best 3 Aletheians based on a selection strategy.
    // Our current strategy: Prioritize higher-ranked Aletheians.
    // A future improvement would be to match claim type to Aletheian expertise badges.

    // Sort Aletheians by rank (a simple text sort for this example).
    Array.sort<Types.AletheianProfile>(availableAletheians, func(a, b) {
      if (a.rank > b.rank) { #gt } else if (a.rank < b.rank) { #lt } else { #eq }
    });

    // Take the top 3 Aletheians from the sorted list.
    // Using a simple loop for clarity.
    var selectedAletheianIds: [Principal] = [];
    var count: Nat = 0;
    for (aletheian in availableAletheians.vals()) {
        if (count < 3) {
            selectedAletheianIds := Array.append(selectedAletheianIds, [aletheian.id]);
            count += 1;
        } else {
            break;
        };
    };


    // Step 3: Assign the task to the selected Aletheians by calling the VerificationWorkflowCanister.
    if (selectedAletheianIds.size() == 3) {
      try {
        // CHANGED: Call the imported actor directly.
        await VerificationWorkflowCanister.assignTask(claim, selectedAletheianIds);
      } catch (e) {
        // CRITICAL: If this fails, the claim is lost in the workflow.
        // A production system needs robust error handling and retries here.
      };
    };
  };
}