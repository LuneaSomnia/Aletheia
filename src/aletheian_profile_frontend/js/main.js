import { AuthClient } from "@dfinity/auth-client";
import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory as aletheian_profile_idl } from "../../../.dfx/local/canisters/aletheian_profile_backend/aletheian_profile_backend.did.js";

const canisterId = process.env.CANISTER_ID_ALETHEIAN_PROFILE_BACKEND;

let authClient;
let backendActor;

// --- DOM Elements ---
const loginButton = document.getElementById("loginButton");
const loginView = document.getElementById("login-view");
const appView = document.getElementById("app-view");
const loginStatus = document.getElementById("login-status");

const headerUsername = document.getElementById("header-username");
const headerPrincipal = document.getElementById("header-principal");
const dashboardUsername = document.querySelector(".dashboard-username");

const statRank = document.getElementById("stat-rank");
const statXp = document.getElementById("stat-xp");
const statBadges = document.getElementById("stat-badges");

const statTotalClaims = document.getElementById("stat-total-claims");
const statCorrectClaims = document.getElementById("stat-correct-claims");
const statAccuracy = document.getElementById("stat-accuracy");
const statWarnings = document.getElementById("stat-warnings");

const tabs = document.querySelectorAll('.glass-tab');
const tabContents = document.querySelectorAll('.content-pane');

// --- Initialization ---
const init = async () => {
  authClient = await AuthClient.create();
  if (await authClient.isAuthenticated()) {
    handleAuthenticated(authClient);
  }
  loginButton.onclick = async () => {
    loginStatus.innerText = "Authenticating...";
    await authClient.login({
      identityProvider: "https://identity.ic0.app/#authorize",
      onSuccess: () => handleAuthenticated(authClient),
      onError: (error) => { loginStatus.innerText = `Login failed: ${error}`; },
    });
  };
  // Tab switching logic (same as before)
};

// --- Authentication and UI Handling ---
const handleAuthenticated = async (client) => {
  const identity = client.getIdentity();
  const agent = new HttpAgent({ identity });

  backendActor = Actor.createActor(aletheian_profile_idl, {
    agent,
    canisterId,
  });

  const profileResult = await backendActor.getMyProfile();

  if (profileResult.Ok) {
    loginView.style.display = "none";
    appView.style.display = "block";
    updateUI(profileResult.Ok);
  } else {
    // This user is not a registered Aletheian
    loginStatus.innerText = `Authentication failed: ${profileResult.Err}. This portal is for registered Aletheians only.`;
    // Consider logging them out
    // await authClient.logout();
  }
};

// --- UI Update Function ---
const updateUI = (profile) => {
  const principalShort = profile.id.toText().substring(0, 5) + '...' + profile.id.toText().substring(58);
  headerUsername.innerText = profile.username;
  headerPrincipal.innerText = `(${principalShort})`;
  dashboardUsername.innerText = profile.username;

  statRank.innerText = profile.rank;
  statXp.innerText = profile.xp.toString();

  // Populate Badges
  statBadges.innerHTML = ''; // Clear existing badges
  if (profile.badges.length > 0) {
    profile.badges.forEach(badgeText => {
      const badgeElement = document.createElement('span');
      badgeElement.className = 'badge';
      badgeElement.innerText = badgeText;
      statBadges.appendChild(badgeElement);
    });
  } else {
    statBadges.innerText = 'No badges earned yet.';
  }

  // Populate Stats
  const total = Number(profile.stats.totalClaimsVerified);
  const correct = Number(profile.stats.correctClaims);
  statTotalClaims.innerText = total;
  statCorrectClaims.innerText = correct;
  statWarnings.innerText = Number(profile.stats.warnings);
  if (total > 0) {
    const accuracy = (correct / total) * 100;
    statAccuracy.innerText = accuracy.toFixed(2) + '%';
  } else {
    statAccuracy.innerText = 'N/A';
  }
};

// --- Start the application ---
init();