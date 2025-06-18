// src/declarations/types.mo
// This file is the single source of truth for data structures passed between canisters.
module {
  // --- Primitive Aliases for Clarity ---
  public type ClaimId = Nat;
  public type EvidenceLink = Text;
  public type Principal = Principal.Principal;
  public type Timestamp = Time.Time;
  public type ReputationScore = Int; // Represents Experience Points (XP)
  public type AletheianRank = Text;  // e.g., "Trainee", "Junior", "Senior"
  public type ExpertiseBadge = Text; // e.g., "Health & Medicine"

  // --- Main Data Structures ---

  // The detailed classification for a claim.
  public type ClaimClassification = {
      primaryVerdict: Text;
      secondaryTags: [Text];
  };

  // The verdict submitted by a single Aletheian for a claim.
  public type AletheianFinding = {
      classification: ClaimClassification;
      rationale: Text;
      evidence: [EvidenceLink];
      submittedAt: Timestamp;
  };

  // The initial claim submitted by a user.
  public type Claim = {
      id: ClaimId;
      submitter: Principal;
      claimText: Text;
      claimType: Text;
      source: ?Text;
      context: ?Text;
      submittedAt: Timestamp;
  };

  // Statistics for an Aletheian's performance.
  public type AletheianStats = {
      totalClaimsVerified: Nat;
      correctClaims: Nat;
      warnings: Nat;
  };

  // User-configurable settings.
  public type UserSettings = {
      notificationPreferences: NotificationPreferences;
  };
  public type NotificationPreferences = {
      claimUpdates: Bool;
      learningReminders: Bool;
      platformAnnouncements: Bool;
  };

  // The complete profile for a standard user.
  public type UserProfile = {
      id: Principal;
      var username: ?Text;
      registeredAt: Timestamp;
      var settings: UserSettings;
      var submittedClaimsCount: Nat;
      var learningProgressReference: ?Text;
  };

  // The complete profile for a fact-checker.
  public type AletheianProfile = {
      id: Principal;
      username: Text;
      registeredAt: Timestamp;
      var xp: ReputationScore;
      var rank: AletheianRank;
      var badges: [ExpertiseBadge];
      var stats: AletheianStats;
      var isActive: Bool;
  };
}
