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

    if #proposals > 0 then
        for _, proposal in ipairs(proposals) do
            formspec = formspec .. minetest.formspec_escape(proposal.title .. " by " .. proposal.author) .. ","
        end
        formspec = formspec:sub(1, -2)
    end

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

local function show_add_comment_formspec(player_name, proposal_index)
    local formspec = "size[8,4]" ..
                     "textarea[0.5,0.5;7.5,2;comment;Leave your comment (max 380 characters);]" ..
                     "button[3,3.5;2,1;submit_comment;Submit]" ..
                     "field[0,0;0,0;proposal_index;;" .. proposal_index .. "]"  -- Hidden field to pass proposal index

    minetest.show_formspec(player_name, "vote_changes:add_comment", formspec)
end

local function show_edit_comment_formspec(player_name, proposal_index, commenter)
    local proposal = proposals[proposal_index]
    local comment = proposal.comments[commenter] or ""
    local formspec = "size[8,4]" ..
                     "textarea[0.5,0.5;7.5,2;edit_comment;Edit your comment (max 380 characters);" .. minetest.formspec_escape(comment) .. "]" ..
                     "button[3,3.5;2,1;submit_edit_comment;Submit]" ..
                     "field[0,0;0,0;proposal_index;;" .. proposal_index .. "]" ..
                     "field[0,0;0,0;commenter;;" .. commenter .. "]"  -- Hidden fields

    minetest.show_formspec(player_name, "vote_changes:edit_comment", formspec)
end



-- Function to show proposal details and voting options
local function show_proposal_details(player_name, proposal_index)
    local proposal = proposals[proposal_index]
    if not proposal then return end

    proposal.comments = proposal.comments or {}
    local player_has_privilege = minetest.check_player_privs(player_name, {proposals_admin=true})
    local is_author = proposal.author == player_name
    local has_commented = proposal.comments[player_name] ~= nil

    local formspec = "size[12,12]" ..
                     "label[0.5,0.5;" .. minetest.formspec_escape(proposal.title) .. " by " .. proposal.author .. "]" ..
                     "textarea[0.5,1.5;11,2;;" .. minetest.formspec_escape(proposal.description) .. ";]" ..
                     "label[0.5,4;Votes: Yes(" .. proposal.votes.yes .. ") No(" .. proposal.votes.no .. ") Abstain(" .. proposal.votes.abstain .. ")]" ..
                     "button[0.5,5;2,1;vote_yes;Vote Yes]" ..
                     "button[3,5;2,1;vote_no;Vote No]" ..
                     "button[5.5,5;2,1;vote_abstain;Abstain]" ..
                     "label[0.5,6;Comments:]"

    -- Construct comments string with proper escaping and formatting
    local comments_str = ""
    for commenter, comment in pairs(proposal.comments) do
        -- Escape each comment and add it to the string
        comments_str = comments_str .. minetest.formspec_escape(commenter .. ":\n" .. comment) .. "\n\n"
    end
    -- Remove the last newline characters
    comments_str = comments_str:gsub("\n\n$", "")

    -- Comments textarea with a scrollbar
    formspec = formspec .. "scroll_container[0.5,6.5;11,3;scrollbar;vertical]" ..
                           "textarea[0.25,0.25;10.5,4;;;" .. comments_str .. ";true]" ..
                           "scroll_container_end[]"

    -- Edit and Delete Comment buttons only if the player has commented
    if has_commented then
        formspec = formspec .. "button[0.5,10;3,1;edit_comment;Edit Comment]" ..
                               "button[4,10;3,1;delete_comment;Delete Comment]"
    end

    -- Add Comment button only if the player has not commented and is not the author
    if not has_commented and not is_author then
        formspec = formspec .. "button[0.5,10;3,1;add_comment;Add Comment]"
    end

    -- Edit and Delete Proposal buttons if the player has privileges or is the author
    if player_has_privilege or is_author then
        formspec = formspec .. "button[0.5,11;3,1;edit_proposal;Edit Proposal]" ..
                               "button[4,11;3,1;delete_proposal;Delete Proposal]"
    end

    formspec = formspec .. "button[9,11;3,1;back;Back]"

    minetest.show_formspec(player_name, "vote_changes:proposal_" .. proposal_index, formspec)
end


-- Function to show the edit proposal formspec
local function show_edit_proposal_formspec(player_name, proposal_index)
    local proposal = proposals[proposal_index]
    if not proposal then return end

    local formspec = "size[8,4]" ..
                     "field[0.5,1;7,1;edit_proposal_title;Title;" .. minetest.formspec_escape(proposal.title) .. "]" ..
                     "textarea[0.5,2;7,2;edit_proposal_description;Description;" .. minetest.formspec_escape(proposal.description) .. "]" ..
                     "button[3,3.5;2,1;submit_edit;Submit]" ..
                     "field[0,0;0,0;proposal_index;;" .. proposal_index .. "]"  -- Hidden field to pass proposal index

    minetest.show_formspec(player_name, "vote_changes:edit_proposal", formspec)
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
            local is_author_or_admin = is_author or player_has_privilege

            if fields.edit_proposal and is_author_or_admin then
                show_edit_proposal_formspec(player_name, proposal_index)
            elseif fields.back then
                show_formspec(player_name)
            elseif fields.delete_proposal and is_author_or_admin then
                table.remove(proposals, proposal_index)
                save_proposals()
                show_formspec(player_name)
            elseif fields.vote_yes or fields.vote_no or fields.vote_abstain then
                if proposal.votes_cast[player_name] then
                    proposal.votes[proposal.votes_cast[player_name]] = proposal.votes[proposal.votes_cast[player_name]] - 1
                end
                if fields.vote_yes then
                    proposal.votes.yes = proposal.votes.yes + 1
                    proposal.votes_cast[player_name] = 'yes'
                elseif fields.vote_no then
                    proposal.votes.no = proposal.votes.no + 1
                    proposal.votes_cast[player_name] = 'no'
                elseif fields.vote_abstain then
                    proposal.votes.abstain = proposal.votes.abstain + 1
                    proposal.votes_cast[player_name] = 'abstain'
                end
                save_proposals()
                show_proposal_details(player_name, proposal_index)
            elseif fields.add_comment and player_name ~= proposal.author and not proposal.comments[player_name] then
                show_add_comment_formspec(player_name, proposal_index)
            else
                for field_name, _ in pairs(fields) do
                    if field_name:find("edit_comment_") then
                        local commenter = field_name:match("edit_comment_(.+)")
                        if commenter and (commenter == player_name or player_has_privilege) and proposal.comments[commenter] then
                            show_edit_comment_formspec(player_name, proposal_index, commenter)
                            break
                        end
                    elseif field_name:find("delete_comment_") then
                        local commenter = field_name:match("delete_comment_(.+)")
                        if commenter and (commenter == player_name or player_has_privilege) and proposal.comments[commenter] then
                            proposal.comments[commenter] = nil
                            save_proposals()
                            show_proposal_details(player_name, proposal_index)
                            break
                        end
                    end
                end
            end
        end
    elseif formname == "vote_changes:add_proposal" and fields.submit_proposal then
        if fields.proposal_title ~= "" and fields.proposal_description ~= "" then
            table.insert(proposals, {
                title = fields.proposal_title,
                description = fields.proposal_description,
                author = player_name,
                votes = { yes = 0, no = 0, abstain = 0 },
                votes_cast = {},
                comments = {}
            })
            save_proposals()
            show_formspec(player_name)
        end
    elseif formname == "vote_changes:edit_proposal" then
        local proposal_index = tonumber(fields.proposal_index)
        local proposal = proposals[proposal_index]
        if proposal and (proposal.author == player_name or minetest.check_player_privs(player_name, {proposals_admin=true})) then
            if fields.edit_proposal_title ~= "" and fields.edit_proposal_description ~= "" then
                proposal.title = fields.edit_proposal_title
                proposal.description = fields.edit_proposal_description
                proposal.comments = proposal.comments or {}
                save_proposals()
                show_proposal_details(player_name, proposal_index)
            end
        end
    elseif formname == "vote_changes:add_comment" then
        local proposal_index = tonumber(fields.proposal_index)
        local proposal = proposals[proposal_index]
        if proposal and player_name ~= proposal.author and not proposal.comments[player_name] then
            if fields.comment and fields.comment ~= "" and string.len(fields.comment) <= 380 then
                proposal.comments[player_name] = fields.comment
                save_proposals()
                show_proposal_details(player_name, proposal_index)
            end
        end
    elseif formname == "vote_changes:edit_comment" then
        local proposal_index = tonumber(fields.proposal_index)
        local commenter = fields.commenter
        local proposal = proposals[proposal_index]
        if proposal and commenter and proposal.comments[commenter] and (commenter == player_name or player_has_privilege) then
            if fields.edit_comment and fields.edit_comment ~= "" and string.len(fields.edit_comment) <= 380 then
                proposal.comments[commenter] = fields.edit_comment
                save_proposals()
                show_proposal_details(player_name, proposal_index)
            end
        end
    end
end)




