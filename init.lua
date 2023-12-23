-- Register proposals_admin privilege
minetest.register_privilege("proposals_admin", {
    description = "Allows the player to administer proposals",
    give_to_singleplayer = false,
    give_to_admin = true
})

local proposals = {}

-- Load and deserialize proposals from mod storage
local mod_storage = minetest.get_mod_storage()
local stored_proposals = mod_storage:get_string("proposals")
if stored_proposals and stored_proposals ~= "" then
    proposals = minetest.deserialize(stored_proposals) or {}
end

-- Function to save proposals to mod storage
local function save_proposals()
    mod_storage:set_string("proposals", minetest.serialize(proposals))
end

-- Function to check if a player has already voted on a proposal
local function has_voted(player_name, proposal)
    return proposal.votes_cast and proposal.votes_cast[player_name]
end

-- Function to show the main formspec to a player
local function show_formspec(player_name)
    local formspec = "size[10,8]" ..
                     "label[0.5,0.5;Vote on Changes]" ..
                     "textlist[0.5,1;9,4;proposals;"

    for i, proposal in ipairs(proposals) do
        formspec = formspec .. minetest.formspec_escape(proposal.title .. " by " .. proposal.author) .. ","
    end

    formspec = formspec:sub(1, -2)  -- Remove last comma
    formspec = formspec .. "]" ..
               "button[0.5,6;3,1;add_proposal;Add Proposal]" ..
               "button_exit[6.5,6;3,1;exit;Exit]"

    minetest.show_formspec(player_name, "vote_changes:main", formspec)
end

-- Function to show the add proposal formspec
local function show_add_proposal_formspec(player_name)
    local formspec = "size[8,4]" ..
                     "field[0.5,1;7,1;proposal_title;Title;]" ..
                     "textarea[0.5,2;7,2;proposal_description;Description;]" ..
                     "button[3,3.5;2,1;submit_proposal;Submit]"
    minetest.show_formspec(player_name, "vote_changes:add_proposal", formspec)
end

-- Function to show proposal details and voting options, with delete button for the author
local function show_proposal_details(player_name, proposal_index)
    local proposal = proposals[proposal_index]
    if not proposal then return end

    local player_has_privilege = minetest.check_player_privs(player_name, {proposals_admin=true})
    local is_author = proposal.author == player_name

    local formspec = "size[8,7]" ..
                     "label[0.5,0.5;" .. minetest.formspec_escape(proposal.title) .. " by " .. proposal.author .. "]" ..
                     "textarea[0.5,1.5;7.5,2;;" .. minetest.formspec_escape(proposal.description) .. ";]" ..
                     "label[0.5,4;Votes: Yes(" .. proposal.votes.yes .. ") No(" .. proposal.votes.no .. ") Abstain(" .. proposal.votes.abstain .. ")]"

    if not has_voted(player_name, proposal) then
        formspec = formspec .. "button[0.5,5;2,1;vote_yes;Vote Yes]" ..
                               "button[3,5;2,1;vote_no;Vote No]" ..
                               "button[5.5,5;2,1;vote_abstain;Abstain]"
    end

    if is_author or player_has_privilege then
        formspec = formspec .. "button[2.5,6;3,1;delete_proposal;Delete Proposal]"
    end

    minetest.show_formspec(player_name, "vote_changes:proposal_" .. proposal_index, formspec)
end


-- Register the /vote_changes command
minetest.register_chatcommand("proposals", {
    description = "Open the voting interface",
    func = function(name)
        show_formspec(name)
        return true
    end,
})

-- Handle formspec submissions
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local player_name = player:get_player_name()

    if formname == "vote_changes:main" then
        if fields.add_proposal then
            show_add_proposal_formspec(player_name)
        elseif fields.proposals then
            local event = minetest.explode_textlist_event(fields.proposals)
            if event.type == "CHG" then
                show_proposal_details(player_name, event.index)
            end
        end
    elseif formname:find("vote_changes:proposal_") then
        local proposal_index = tonumber(formname:match("proposal_(%d+)"))
        local proposal = proposals[proposal_index]
        if proposal then
            local player_has_privilege = minetest.check_player_privs(player_name, {proposals_admin=true})
            local is_author = proposal.author == player_name
    
            if fields.delete_proposal and (is_author or player_has_privilege) then
                table.remove(proposals, proposal_index)
                save_proposals()
                show_formspec(player_name)
            elseif not has_voted(player_name, proposal) then
                if fields.vote_yes then
                    proposal.votes.yes = proposal.votes.yes + 1
                elseif fields.vote_no then
                    proposal.votes.no = proposal.votes.no + 1
                elseif fields.vote_abstain then
                    proposal.votes.abstain = proposal.votes.abstain + 1
                end
                proposal.votes_cast = proposal.votes_cast or {}
                proposal.votes_cast[player_name] = true
                save_proposals()
                show_formspec(player_name)
            end
        end
    elseif formname == "vote_changes:add_proposal" and fields.submit_proposal then
        if fields.proposal_title ~= "" and fields.proposal_description ~= "" then
            table.insert(proposals, {
                title = fields.proposal_title,
                description = fields.proposal_description,
                author = player_name,
                votes = { yes = 0, no = 0, abstain = 0 },
                votes_cast = {}
            })
            save_proposals()
            show_formspec(player_name)
        end
    end
end)
