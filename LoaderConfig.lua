---
--- 2021/11/29 10:33
--- created by Nori
---



-- **********************************************************************
-- Properties

LoaderConfig = {}

--- 密钥
local encKey = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
--- 配置文件标志名
LoaderConfig.markerName = "APS"
--- 插件文件夹名
LoaderConfig.addonFolderName = "AdvancedPVPSkill"
--- 配置文件夹名
LoaderConfig.moduleFolderName = "module"
--- hotbar文件夹名
LoaderConfig.hotbarFolderName = "hotbar"
--- macro文件夹名
LoaderConfig.macroFolderName = "macro"

--- 职业标签
LoaderConfig.jobTagList = {
    [1] = "GLA",
    [2] = "PGL",
    [3] = "MRD",
    [4] = "LNC",
    [5] = "ARC",
    [6] = "CNJ",
    [7] = "THM",
    [26] = "ACN",
    [29] = "ROG",
    [36] = "BLU",
    -- Tank
    [19] = "PLD",
    [21] = "WAR",
    [32] = "DRK",
    [37] = "GNB",
    -- Heal
    [24] = "WHM",
    [28] = "SCH",
    [33] = "AST",
    [40] = "SGE",
    -- DPS1
    [20] = "MNK",
    [22] = "DRG",
    [30] = "NIN",
    [34] = "SAM",
    [39] = "RPR",
    -- DPS2
    [23] = "BRD",
    [31] = "MCH",
    [38] = "DNC",
    -- DPS3
    [25] = "BLM",
    [27] = "SMN",
    [35] = "RDM",
}


-- **********************************************************************
-- Function

-- 获取游戏版本
function LoaderConfig.getPVEVersion()
    -- 游戏版本号
    -- local gameVersion = GetGameVersion()

    -- CN: 7012545
    local list = {
        [1] = "610", -- 6.0
        [2] = "550", -- CN
        [3] = "550", -- KR
    }
    local region = list[GetGameRegion()] or 1
    return list[region] or list[1]
end
function LoaderConfig.getPVPVersion()
    -- 游戏版本号
    -- local gameVersion = GetGameVersion()

    -- CN: 7012545
    local list = {
        [1] = "550", -- 6.0
        [2] = "550", -- CN
        [3] = "550", -- KR
    }
    local region = list[GetGameRegion()] or 1
    return list[region] or list[1]
end

--- 配置文件加密
local function stringEnc(data)
    return (
            (data:gsub('.',
                    function(x)
                        local r, b = '', x:byte()
                        for i = 8, 1, -1 do
                            r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
                        end
                        return r;
                    end
            ) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
                if (#x < 6) then
                    return ''
                end
                local c = 0
                for i = 1, 6 do
                    c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
                end
                return encKey:sub(c + 1, c + 1)
            end) .. ({ '', '==', '=' })[#data % 3 + 1]
    )
end

--- 配置文件加密
function LoaderConfig.profileEncrypt(profile)
    local list = table.deepcopy(profile)
    for i, b in pairs(profile) do
        if type(b) == "string" then
            list[i] = stringEnc(b)
        end
    end
    return list
end
