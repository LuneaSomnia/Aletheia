import { AuthClient } from "@dfinity/auth-client";
import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory as claim_submission_idl } from "../../../.dfx/local/canisters/claim_submission_backend/claim_submission_backend.did.js";

const canisterId = process.env.CANISTER_ID_CLAIM_SUBMISSION_BACKEND;

let authClient;
let backendActor;

// --- DOM Elements ---
const claimForm = document.getElementById("claim-form");
const submitButton = document.getElementById("submitButton");
const formStatus = document.getElementById("form-status");

// --- Initialization ---
const init = async () => {
  authClient = await AuthClient.create();
  // We must be authenticated to submit a claim
  if (!(await authClient.isAuthenticated())) {
    // In a real app, you might redirect to the main login page.
    // For this standalone canister, we'll prompt login.
    await authClient.login({
      identityProvider: "https://identity.ic0.app/#authorize",
      onSuccess: setupActor,
    });
  } else {
    setupActor();
  }
};

// --- Setup Actor ---
const setupActor = () => {
  const identity = authClient.getIdentity();
  const agent = new HttpAgent({ identity });

  backendActor = Actor.createActor(claim_submission_idl, {
    agent,
    canisterId,
  });

  // Enable the form now that we are authenticated and have an actor
  claimForm.addEventListener("submit", handleFormSubmit);
};

// --- Form Handling ---
const handleFormSubmit = async (e) => {
  e.preventDefault(); // Prevent default browser form submission
  
  // Disable button to prevent multiple submissions
  submitButton.disabled = true;
  submitButton.innerText = "Submitting...";
  formStatus.innerText = "";

  // Get form data
  const claimType = document.getElementById("claim-type").value;
  const claimText = document.getElementById("claim-text").value;
  const source = document.getElementById("claim-source").value;
  const context = document.getElementById("claim-context").value;

  // The ? syntax for Motoko optionals is handled by agent-js
  // An empty string will be treated as `null` or `None`.
  const optionalSource = source ? [source] : [];
  const optionalContext = context ? [context] : [];

  try {
    const result = await backendActor.submitClaim(
      claimText,
      claimType,
      optionalSource,
      optionalContext
    );

    if (result.Ok) {
      formStatus.innerText = `Successfully submitted! Your Claim ID is: ${result.Ok}. You will be notified upon verification.`;
      claimForm.reset(); // Clear the form
    } else {
      formStatus.innerText = `Error: ${result.Err}`;
    }
  } catch (error) {
    console.error("Failed to submit claim:", error);
    formStatus.innerText = "A critical error occurred. Please try again later.";
  } finally {
    // Re-enable the button
    submitButton.disabled = false;
    submitButton.innerText = "Submit Claim";
  }
};

// --- Start the application ---
init();