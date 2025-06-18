import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import Array "mo:base/Array";

// CHANGED: Replaced old actor definitions and local types with direct imports.
import FactLedger "canister:fact_ledger_backend";
import EscalationCanister "canister:escalation_backend"; // Assuming this will be the name
import ReputationLogicCanister "canister:reputation_logic_backend"; // Assuming this will be the name
import Types "src/declarations/types";


actor {
    // --- Type Aliases for Internal Use ---
    // These types are specific to this canister's internal state management.
    type VerificationStatus = {
        #Pending;
        #InProgress;
        #ConsensusReached;
        #Disagreement;
        #Escalated;
        #Complete;
    };

    type VerificationTask = {
        claim: Types.Claim;
        assignedAletheians: [Principal];
        var status: VerificationStatus; // Made mutable for easy updating
        var findings: TrieMap.TrieMap<Principal, Types.AletheianFinding>;
    };

    // --- Canister State ---
    private var activeTasks: TrieMap.TrieMap<Types.ClaimId, VerificationTask> = TrieMap.empty();
    private let dispatchCanisterPrincipal: Principal = msg.caller; // The deployer is initially considered the authorized principal

    // REMOVED: The old optional actor variables and `set_...` functions are no longer needed.

    // --- Core Logic ---

    // Entry point for this canister, called by AletheianDispatchCanister.
    public shared func assignTask(claim: Types.Claim, assignedAletheians: [Principal]) : async () {
        // Authorization: Ensure caller is the authorized AletheianDispatchCanister
        // In a real system, you might have a list of authorized principals.
        // For now, we trust the deployer or a principal set by an admin.
        // if (msg.caller != dispatchCanisterPrincipal) { return; };

        let newTask: VerificationTask = {
            claim = claim;
            assignedAletheians = assignedAletheians;
            var status = #Pending;
            var findings = TrieMap.empty<Principal, Types.AletheianFinding>();
        };

        activeTasks.put(claim.id, newTask);
    };

    // Called by an Aletheian's frontend when they submit their analysis.
    public shared func submitFinding(claimId: Types.ClaimId, finding: Types.AletheianFinding) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        switch (activeTasks.get(claimId)) {
            case (null) { return Result.Err("Task with this ID does not exist."); };
            case (?var task) {
                // Validation checks (same as before)
                if (not Array.contains(task.assignedAletheians, caller)) { return Result.Err("Unauthorized: You are not assigned to this task."); };
                if (task.findings.containsKey(caller)) { return Result.Err("You have already submitted a finding for this task."); };
                if (task.status == #Complete or task.status == #Escalated) { return Result.Err("This task is already closed."); };

                // Store the finding
                task.findings.put(caller, finding);
                task.status := #InProgress;

                // Check for consensus now that a new finding is in.
                await _checkConsensus(claimId);

                return Result.Ok("Finding submitted successfully.");
            };
        };
    };

    // --- Private Helper Functions ---
    private func _checkConsensus(claimId: Types.ClaimId) : async () {
        switch (activeTasks.get(claimId)) {
            case (null) { return; };
            case (?var task) {
                if (task.findings.size() != 3) { return; };

                let findingsArray = TrieMap.values(task.findings);
                let verdict1 = findingsArray[0].classification.primaryVerdict;
                let verdict2 = findingsArray[1].classification.primaryVerdict;
                let verdict3 = findingsArray[2].classification.primaryVerdict;
                
                if (verdict1 == verdict2 and verdict2 == verdict3) {
                    // --- CONSENSUS REACHED ---
                    task.status := #ConsensusReached;

                    // Simplified Synthesis Logic
                    let synthesizedClassification: Types.ClaimClassification = {
                        primaryVerdict = verdict1;
                        secondaryTags = findingsArray[0].classification.secondaryTags;
                    };
                    
                    try {
                        // Call FactLedger directly
                        await FactLedger.addVerifiedFact(
                            task.claim.claimText,
                            task.claim.submitter,
                            synthesizedClassification,
                            findingsArray[0].evidence, // Simplified evidence
                            task.assignedAletheians
                        );
                        // Call ReputationLogic directly
                        await ReputationLogicCanister.processVerificationResult(task.assignedAletheians, []);
                        
                        task.status := #Complete;
                    } catch (e) {
                        // Production logging for critical failure
                    };
                } else {
                    // --- DISAGREEMENT ---
                    task.status := #Disagreement;
                    try {
                        // Call EscalationCanister directly
                        await EscalationCanister.escalateClaim(task.claim, task.findings);
                        task.status := #Escalated;
                    } catch (e) {
                        // Production logging for critical failure
                    };
                };
            };
        };
    };
}