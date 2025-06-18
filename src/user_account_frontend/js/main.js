// frontend/js/main.js

import { AuthClient } from "@dfinity/auth-client";
import { Actor, HttpAgent } from "@dfinity/agent";
// Import the auto-generated declarations for our backend canister
import { idlFactory as user_account_idl } from "../../../.dfx/local/canisters/user_account_backend/user_account_backend.did.js";

// Get the canister ID from the Vite environment variables
const canisterId = process.env.CANISTER_ID_USER_ACCOUNT_BACKEND;

let authClient;
let backendActor;

// --- DOM Elements (Identical to previous response) ---
const loginButton = document.getElementById("loginButton");
const loginView = document.getElementById("login-view");
const appView = document.getElementById("app-view");
const principalDisplay = document.getElementById("principal-display");
const loginStatus = document.getElementById("login-status");
const profileUsername = document.getElementById("profile-username");
const profileRegisteredAt = document.getElementById("profile-registeredAt");
const profileClaimsCount = document.getElementById("profile-claimsCount");
const usernameInput = document.getElementById("username-input");
const updateUsernameButton = document.getElementById("updateUsernameButton");
const profileStatus = document.getElementById("profile-status");
const tabs = document.querySelectorAll('.glass-tab');
const tabContents = document.querySelectorAll('.content-pane');

// --- Initialization (Identical to previous response) ---
const init = async () => {
  authClient = await AuthClient.create();
    if (await authClient.isAuthenticated()) {
        handleAuthenticated(authClient);
          }
            loginButton.onclick = async () => {
                loginStatus.innerText = "Logging in...";
                    await authClient.login({
                          identityProvider: "https://identity.ic0.app/#authorize",
                                onSuccess: () => handleAuthenticated(authClient),
                                      onError: (error) => { loginStatus.innerText = `Login failed: ${error}`; },
                                          });
                                            };
                                              tabs.forEach(tab => {
                                                  tab.addEventListener('click', () => {
                                                        tabs.forEach(t => t.classList.remove('active'));
                                                              tabContents.forEach(c => c.classList.remove('active'));
                                                                    tab.classList.add('active');
                                                                          document.getElementById(tab.dataset.tab + '-content').classList.add('active');
                                                                              });
                                                                                });
                                                                                  updateUsernameButton.onclick = updateUsername;
                                                                                  };

                                                                                  // --- Authentication and UI Handling ---
                                                                                  const handleAuthenticated = async (client) => {
                                                                                    const identity = client.getIdentity();
                                                                                      const agent = new HttpAgent({ identity });

                                                                                        backendActor = Actor.createActor(user_account_idl, {
                                                                                            agent,
                                                                                                canisterId,
                                                                                                  });

                                                                                                    loginView.style.display = "none";
                                                                                                      appView.style.display = "block";
                                                                                                        principalDisplay.innerText = identity.getPrincipal().toText();

                                                                                                          const profile = await backendActor.registerOrLoginUser();
                                                                                                            updateUI(profile);
                                                                                                            };

                                                                                                            // --- UI Update Function (Identical to previous response) ---
                                                                                                            const updateUI = (profile) => {
                                                                                                              if (profile.username && profile.username.length > 0) {
                                                                                                                  profileUsername.innerText = profile.username[0];
                                                                                                                    } else {
                                                                                                                        profileUsername.innerText = "Not set";
                                                                                                                          }
                                                                                                                            const registeredDate = new Date(Number(profile.registeredAt) / 1000000);
                                                                                                                              profileRegisteredAt.innerText = registeredDate.toLocaleDateString();
                                                                                                                                profileClaimsCount.innerText = profile.submittedClaimsCount.toString();
                                                                                                                                };

                                                                                                                                // --- Backend Interaction Functions (Identical to previous response) ---
                                                                                                                                async function updateUsername() {
                                                                                                                                    const newUsername = usernameInput.value;
                                                                                                                                        if (!newUsername || newUsername.length < 3) {
                                                                                                                                                profileStatus.innerText = "Please enter a username with at least 3 characters.";
                                                                                                                                                        return;
                                                                                                                                                            }
                                                                                                                                                                profileStatus.innerText = "Updating...";
                                                                                                                                                                    const result = await backendActor.updateMyUsername(newUsername);
                                                                                                                                                                        if (result.Ok) {
                                                                                                                                                                                profileStatus.innerText = result.Ok;
                                                                                                                                                                                        profileUsername.innerText = newUsername;
                                                                                                                                                                                                usernameInput.value = "";
                                                                                                                                                                                                    } else {
                                                                                                                                                                                                            profileStatus.innerText = `Error: ${result.Err}`;
                                                                                                                                                                                                                }
                                                                                                                                                                                                                }

                                                                                                                                                                                                                // --- Start the application ---
                                                                                                                                                                                                                init();