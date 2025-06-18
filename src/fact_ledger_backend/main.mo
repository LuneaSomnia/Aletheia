import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import TrieMap "mo:base/TrieMap";
import Hash "mo:base/Hash";
import Array "mo:base/Array";

// ... rest of your code ...

shared({ caller = initializer }) actor class() {
  // --- Types specific to the FactLedger ---

  public type ClaimId = Nat;
  public type AletheianId = Principal;
  public type UserId = Principal;
  public type Timestamp = Time.Time;
  public type EvidenceLink = Text;

  public type ClaimClassification = {
    primaryVerdict : Text;
    secondaryTags : [Text];
    explanation : Text;
  };

  public type ClaimVersion = {
    version : Nat;
    classification : ClaimClassification;
    evidence : [EvidenceLink];
    verifiedBy : [AletheianId];
    timestamp : Timestamp;
    notes : Text;
  };

  public type VerifiedFact = {
    claimId : ClaimId;
    originalClaimText : Text;
    originalSubmitterId : UserId;
    versions : [ClaimVersion];
    createdAt : Timestamp;
    updatedAt : Timestamp;
  };

  // --- Canister State ---

private var verifiedFacts : TrieMap.TrieMap<ClaimId, VerifiedFact> = TrieMap.TrieMap<ClaimId, VerifiedFact>(Nat.equal, Hash.hash);


  private var nextClaimId : ClaimId = 0;
  private let admin : Principal = initializer;

  // --- Authorization Helper ---
  private func isAuthorized(caller : Principal) : Bool {
    return caller == admin;
  };

  // --- Query Methods (Read-only) ---

  public query func getVerifiedFact(id : ClaimId) : async ?VerifiedFact {
    return verifiedFacts.get(id);
  };

  public query func getLatestVersion(id : ClaimId) : async ?ClaimVersion {
    switch (verifiedFacts.get(id)) {
      case (?fact) {
        if (fact.versions.size() > 0) {
          return ?fact.versions[fact.versions.size() - 1];
        } else {
          return null;
        }
      };
      case null { return null; }
    }
  };

  public query func getFactCount() : async Nat {
    return verifiedFacts.size();
  };

  // --- Update Methods (Write data) ---

  public shared({ caller }) func addVerifiedFact(
    originalClaimText : Text,
    originalSubmitterId : UserId,
    initialClassification : ClaimClassification,
    initialEvidence : [EvidenceLink],
    verifyingAletheians : [AletheianId]
  ) : async Result.Result<ClaimId, Text> {
    if (not isAuthorized(caller)) { return #err("Unauthorized: Caller is not an authorized canister."); };

    let timestamp = Time.now();
    let claimId = nextClaimId;
    nextClaimId += 1;

    let firstVersion : ClaimVersion = {
      version = 1;
      classification = initialClassification;
      evidence = initialEvidence;
      verifiedBy = verifyingAletheians;
      timestamp = timestamp;
      notes = "Initial verification.";
    };

    let newFact : VerifiedFact = {
      claimId = claimId;
      originalClaimText = originalClaimText;
      originalSubmitterId = originalSubmitterId;
      versions = [firstVersion];
      createdAt = timestamp;
      updatedAt = timestamp;
    };

    verifiedFacts.put(claimId, newFact);
    return #ok(claimId);
  };

  public shared({ caller }) func updateVerifiedFact(
    claimId : ClaimId,
    newClassification : ClaimClassification,
    newEvidence : [EvidenceLink],
    verifyingAletheians : [AletheianId],
    updateNotes : Text
  ) : async Result.Result<Nat, Text> {
    if (not isAuthorized(caller)) { return #err("Unauthorized: Caller is not an authorized canister."); };

    switch (verifiedFacts.get(claimId)) {
      case (?existingFact) {
        let timestamp = Time.now();
        let nextVersionNum = existingFact.versions.size() + 1;

        let newVersion : ClaimVersion = {
          version = nextVersionNum;
          classification = newClassification;
          evidence = newEvidence;
          verifiedBy = verifyingAletheians;
          timestamp = timestamp;
          notes = updateNotes;
        };

        let updatedVersions = Array.append<ClaimVersion>(existingFact.versions, [newVersion]);
        let updatedFact : VerifiedFact = {
          claimId = existingFact.claimId;
          originalClaimText = existingFact.originalClaimText;
          originalSubmitterId = existingFact.originalSubmitterId;
          versions = updatedVersions;
          createdAt = existingFact.createdAt;
          updatedAt = timestamp;
        };

        verifiedFacts.put(claimId, updatedFact);
        return #ok(nextVersionNum);
      };
      case null {
        return #err("Fact not found. Cannot update a non-existent fact.");
      }
    }
  };
}