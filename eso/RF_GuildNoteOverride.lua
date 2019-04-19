-- Override: esoui/esoui/ingame/guild/guildroster_shared.lua
function ZO_GuildRosterManager:SetupEntry(control, data, selected)
    ZO_SocialList_SharedSocialSetup(control, data, selected)

    local note = GetControl(control, "Note")
    if note then
        if data.note ~= "" then
            note:SetHidden(false)

            -- TODO: If this is the Roleplay Finder guild, disallow note editing.
            if DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_NOTE_EDIT) then
                note:SetState(BSTATE_NORMAL, false)
            else
                note:SetState(BSTATE_DISABLED, true)
            end

            local guildName = GetGuildName(self.guildId)
            if (RoleplayFinder.isRoleplayFinderGuild(guildName)) then
                local _, noteText, _, playerStatus, _ = GetGuildMemberInfo(self.guildId, data.index)
                if (playerStatus ~= PLAYER_STATUS_OFFLINE) then
                    local notedata = RoleplayFinder.convertNoteToNotedata(noteText)
                    if (notedata ~= nil) then
                        -- Set IC / OOC icon
                        -- TODO get some icons
                        local todoNoteTextureFunction = IsInGamepadPreferredMode() and GetFinalGuildRankTextureLarge or GetFinalGuildRankTextureSmall
                        local noteTexture = todoNoteTextureFunction(self.guildId, data.rankIndex)

                        -- Set texture, disallow editing
                        note:SetNormalTexture(noteTexture)
                        note:SetState(BSTATE_DISABLED, true)

                        -- Set mouseover text
                        data.note = RoleplayFinder.computeDisplayText(notedata)
                    end
                else
                    note:SetHidden(true)
                end
            end
        else
            note:SetHidden(true)
        end
    end

    -- Original ZOS handling for rank; we don't care about this.
    local rank = GetControl(control, "RankIcon")
    local rankTextureFunction = IsInGamepadPreferredMode() and GetFinalGuildRankTextureLarge or GetFinalGuildRankTextureSmall
    local rankTexture = rankTextureFunction(self.guildId, data.rankIndex)
    if rankTexture then
        rank:SetHidden(false)
        rank:SetTexture(rankTexture)
    else
        rank:SetHidden(true)
    end
end