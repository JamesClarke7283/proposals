
# Proposals

## Overview

`proposals` introduces a dynamic and interactive way for players to engage in the decision-making process on a server. It allows players to propose changes, vote on them, and manage their proposals. This is designed to foster community involvement and ensure that players have a voice in server developments.

## Features

- **Create Proposals**: Players can create proposals, each consisting of a title and a detailed description.
- **Vote on Proposals**: Every player can cast their vote on any proposal, choosing between 'Yes', 'No', or 'Abstain'.
- **View Proposals**: Players can view all active proposals along with their details and current vote counts.
- **Delete Proposals**: Proposal authors can delete their proposals. Additionally, players with administrative privileges can delete any proposal.
- **Automatic Updates**: The list of proposals and vote counts are updated in real-time, reflecting the latest changes made by players.
- **Admin Privilege**: A specific privilege (`proposals_admin`) is available for server administrators or designated players, allowing them to manage all proposals effectively.

## Usage

### Commands

- `/proposals`: This command opens the main interface of the `proposals` mod. Here, players can view all active proposals, vote, and access options to create or delete proposals.

### Creating a Proposal

1. Use the `/proposals` command to open the mod interface.
2. Click on the 'Add Proposal' button to open the proposal creation form.
3. Enter a title and a detailed description for the new proposal.
4. Click 'Submit' to add the proposal to the list.

### Voting on a Proposal

1. Open the main interface with `/proposals`.
2. Click on a proposal title to view its details.
3. Choose 'Vote Yes', 'Vote No', or 'Abstain' to cast your vote.

### Deleting a Proposal

- As the author of a proposal, open the proposal's details and click 'Delete Proposal'.
- As an admin (with `proposals_admin` privilege), you can delete any proposal using the same method.

## Administrative Privilege

- **Privilege Name**: `proposals_admin`
- This privilege allows designated players to delete any proposal, regardless of the author.

To grant this privilege to a player, use the Minetest command: `/grant <playername> proposals_admin`.