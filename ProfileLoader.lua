---
--- 2021/10/14 1:31
--- created by Nori
---


-- **********************************************************************
-- Local Properties

local markerName = LoaderConfig.markerName
local addonFolderName = LoaderConfig.addonFolderName
local moduleFolderName = LoaderConfig.moduleFolderName

-- 获取私有模块中的文件列表
local paf = GetPrivateModuleFunctions()

-- 职业名称表
local jobNameList = LoaderConfig.jobTagList

-- 版本控制
local pveVersion = LoaderConfig.getPVEVersion()
local pvpVersion = LoaderConfig.getPVPVersion()

-- 用于暂存配置文件
local skillInfoList = { PVE = {}, PVP = {} }

-- **********************************************************************
-- Global Properties

ProfileLoader = {}


-- **********************************************************************
-- Local Function

--- 清除profile缓存
local function clearProfileCache()
    -- PVE
    if table.valid(Settings.Global.pve_mcr_profiles) then
        for jobId, jobProfileList in pairs(Settings.Global.pve_mcr_profiles) do
            for profileName, _ in pairs(jobProfileList) do
                local profileMarkerName = string.totable(profileName, "_")[1]
                if markerName == profileMarkerName then
                    Settings.Global.pve_mcr_profiles[jobId][profileName] = nil
                end
            end
        end
    end
    -- PVP
    if table.valid(Settings.Global.pvp_mcr_profiles) then
        for jobId, jobProfileList in pairs(Settings.Global.pvp_mcr_profiles) do
            for profileName, _ in pairs(jobProfileList) do
                local profileMarkerName = string.totable(profileName, "_")[1]
                if markerName == profileMarkerName then
                    Settings.Global.pvp_mcr_profiles[jobId][profileName] = nil
                end
            end
        end
    end
end

--- 获取Profile所属职业ID
local function getProfileJobId(profileName)
    local profileJobName = string.totable(profileName, "_")[3]
    if profileJobName then
        for jobId, jobName in pairs(jobNameList) do
            if string.contains(profileJobName, jobName) then
                return jobId
            end
        end
    end
    d("[ProfileLoader] - fileName:" .. profileName .. "无法确认Profile所属职业ID！")
    return nil
end

--- 获取Profile类型（PVE/PVP）
local function getProfileType(profileName)
    if table.valid(jobNameList) then
        local profileType = string.totable(profileName, "_")
        if table.valid(string.totable(profileName, "_")) then
            profileType = profileType[1]
            if profileType then
                if profileType == "PVE" then
                    return "PVE"
                elseif profileType == "PVP" then
                    return "PVP"
                end
            end
        else
            ml_error("无法获取配置文件的类型")
        end
    end
    d("[ProfileLoader] - fileName:" .. profileName .. "无法确认Profile类型！")
    return nil
end

--- 获取Profile版本
local function getProfileVersion(profileName)
    local profileVersion = string.totable(profileName, "_")
    if table.valid(profileVersion) and profileVersion[2] then
        return profileVersion[2]
    end
    return nil
end

--- 获取加密模块中配置文件的标识
--- @param profileName string 本地文件比paf中的加密文件名称少个'.'，所以在读取本地文件时，请在结尾加个'.'
local function getPafProfileRemark(profileName)
    local remark = "Default"
    local profileRemark = string.totable(profileName, "_")[4]
    if profileRemark then
        remark = string.sub(profileRemark, 1, string.len(profileRemark) - 1)
    end
    return remark
end

--- 加载paf中的配置文件
local function pafload(fileInfo)
    local loadedString = paf.ReadModuleFile(fileInfo)
    if type(loadedString) == "string" then
        local filefunc = loadstring(loadedString)
        if type(filefunc) == "function" then
            return filefunc()
        end
    end
end

--- 读取配置文件
local function getProfile()
    if table.valid(paf) then
        -- 获取data文件夹下的文件
        local profileList = paf.GetModuleFiles(moduleFolderName)
        -- 遍历文件读取profile
        if table.valid(profileList) then
            for _, profile in pairs(profileList) do

                -- ******************************
                d("[ProfileLoader] - 当前配置文件:" .. profile.f)
                -- 通过配置文件名称(profile.f)获取信息

                -- 配置文件类型
                local profileType = getProfileType(profile.f)
                -- 配置文件版本
                local profileVersion = getProfileVersion(profile.f)
                -- 获取profile对应的职业ID
                local jobId = getProfileJobId(profile.f)
                -- 获取profile标识
                local profileRemark = getPafProfileRemark(profile.f)
                if not profileType then
                    d("[ProfileLoader] - 无法确认配置文件类型")
                end
                if not profileVersion then
                    d("[ProfileLoader] - 无法确认配置文件版本")
                end
                if not jobId then
                    d("[ProfileLoader] - 无法确认配置文件职业ID")
                end
                if not profileRemark then
                    d("[ProfileLoader] - 无法确认配置文件标识")
                end
                d("[ProfileLoader] - "
                        .. " 类型:" .. tostring(profileType)
                        .. " 版本:" .. tostring(profileVersion)
                        .. " 职业:" .. tostring(jobId)
                        .. " 标识:" .. tostring(profileRemark))
                -- ******************************

                -- ******************************
                -- 取出配置文件信息(pafload(profile.f))
                if profileType == "PVE" and pveVersion == profileVersion then
                    -- 初始化
                    if not skillInfoList.PVE[jobId] then
                        skillInfoList.PVE[jobId] = {}
                    end
                    skillInfoList.PVE[jobId][profileRemark] = pafload(profile)
                elseif profileType == "PVP" and pvpVersion == profileVersion then
                    -- 初始化
                    if not skillInfoList.PVP[jobId] then
                        skillInfoList.PVP[jobId] = {}
                    end
                    skillInfoList.PVP[jobId][profileRemark] = pafload(profile)
                end
                -- ******************************
            end
        end
    else
        -- 获取data文件夹下的profile
        local path = GetLuaModsPath() .. addonFolderName .. "\\" .. moduleFolderName
        local profileList = FolderList(path)
        -- 遍历data文件夹下的profile
        if table.valid(profileList) then
            for _, profile in pairs(profileList) do
                -- ******************************
                -- 识别配置文件名称(profile)获取信息

                -- 配置文件类型
                local profileType = getProfileType(profile)
                -- 配置文件版本
                local profileVersion = getProfileVersion(profile)
                -- 获取profile对应的职业ID
                local jobId = getProfileJobId(profile)
                -- 获取profile标识
                local profileRemark = getPafProfileRemark(profile)
                d("[ProfileLoader] - 当前配置文件:" .. profile
                        .. " 类型:" .. tostring(profileType)
                        .. " 版本:" .. tostring(profileVersion)
                        .. " 职业:" .. tostring(jobId)
                        .. " 标识:" .. tostring(profileRemark))
                -- ******************************

                -- ******************************
                -- 读取当前游戏版本的配置文件(persistence.load)
                if profileType == "PVE" and pveVersion == profileVersion then
                    -- 初始化
                    if not skillInfoList.PVE[jobId] then
                        skillInfoList.PVE[jobId] = {}
                    end
                    skillInfoList.PVE[jobId][profileRemark] = persistence.load(path .. "\\" .. profile)
                elseif profileType == "PVP" and pvpVersion == profileVersion then
                    -- 初始化
                    if not skillInfoList.PVP[jobId] then
                        skillInfoList.PVP[jobId] = {}
                    end
                    skillInfoList.PVP[jobId][profileRemark] = persistence.load(path .. "\\" .. profile)
                end
                -- ******************************
            end
        end
    end
end

--- 添加PVE配置文件
local function addPveProfile()
    -- 生成MCR加载函数和配置名称
    local data = {}
    for jobId, _ in pairs(skillInfoList.PVE) do
        data[jobId] = {}
        -- 创建方法
        if table.valid(skillInfoList.PVE[jobId]) then
            for profileRemark, _ in pairs(skillInfoList.PVE[jobId]) do
                table.insert(
                        data[jobId],
                        {
                            func_string = "MCRLoad_PVE_" .. jobNameList[jobId] .. "_" .. profileRemark,
                            name = markerName .. "_" .. jobNameList[jobId] .. "_" .. profileRemark,
                        }
                )
            end
        end
    end

    -- 初始化
    if not Settings.Global.pve_mcr_profiles then
        Settings.Global.pve_mcr_profiles = {}
    end
    -- 更新配置文件列表信息
    local changed
    for jobId, k in pairs(data) do
        if not Settings.Global.pve_mcr_profiles[jobId] then
            Settings.Global.pve_mcr_profiles[jobId] = {}
            changed = true
        end
        local pveProfiles = Settings.Global.pve_mcr_profiles[jobId]
        for _, b in pairs(k) do
            if not pveProfiles[b.name] or pveProfiles[b.name].name ~= b.name or pveProfiles[b.name].func_string ~= b.func_string then
                changed = true
                Settings.Global.pve_mcr_profiles[jobId][b.name] = b
            end
        end
    end
    if changed then
        Settings.Global.pve_mcr_profiles = Settings.Global.pve_mcr_profiles
    end
end

--- 添加PVP配置文件
local function addPvpProfile()
    -- 生成MCR加载函数和配置名称
    local data = {}
    for jobId, _ in pairs(skillInfoList.PVP) do
        data[jobId] = {}
        -- 创建方法
        if table.valid(skillInfoList.PVP[jobId]) then
            for profileRemark, _ in pairs(skillInfoList.PVP[jobId]) do
                table.insert(
                        data[jobId],
                        {
                            func_string = "MCRLoad_PVP_" .. jobNameList[jobId] .. "_" .. profileRemark,
                            name = markerName .. "_" .. jobNameList[jobId] .. "_" .. profileRemark,
                        }
                )
            end
        end
    end

    -- 初始化
    if not Settings.Global.pvp_mcr_profiles then
        Settings.Global.pvp_mcr_profiles = {}
    end
    -- 更新配置文件列表信息
    local changed
    for jobId, k in pairs(data) do
        if not Settings.Global.pvp_mcr_profiles[jobId] then
            Settings.Global.pvp_mcr_profiles[jobId] = {}
            changed = true
        end
        local pvpProfiles = Settings.Global.pvp_mcr_profiles[jobId]
        for _, b in pairs(k) do
            if not pvpProfiles[b.name] or pvpProfiles[b.name].name ~= b.name or pvpProfiles[b.name].func_string ~= b.func_string then
                changed = true
                Settings.Global.pvp_mcr_profiles[jobId][b.name] = b
            end
        end
    end
    if changed then
        Settings.Global.pvp_mcr_profiles = Settings.Global.pvp_mcr_profiles
    end
end

--- 数据处理
local function dataHandle(profileType)
    -- 加密并加载配置文件
    for jobId, jobSkillInfoList in pairs(ProfileLoader.skillInfoList) do
        if table.valid(jobSkillInfoList) then
            for profileRemark, _ in pairs(jobSkillInfoList) do
                local func = loadstring(""
                        .. "local tmp_skillInfoList = table.deepcopy(ProfileLoader.skillInfoList) " .. "\n"
                        .. "function MCRLoad_" .. profileType .. "_" .. jobNameList[jobId] .. "_" .. profileRemark .. "(ver) " .. "\n"
                        .. "    if MadaoCombat2 then " .. "\n"
                        .. "        if not tmp_skillInfoList[" .. jobId .. "][\"" .. profileRemark .. "\"].profile then" .. "\n"
                        .. "            local prof = table.deepcopy(tmp_skillInfoList[" .. jobId .. "][\"" .. profileRemark .. "\"])" .. "\n"
                        .. "            tmp_skillInfoList[" .. jobId .. "][\"" .. profileRemark .. "\"] = { profile = prof }" .. "\n"
                        .. "        end " .. "\n"
                        .. "        if not tmp_skillInfoList[" .. jobId .. "][\"" .. profileRemark .. "\"].encoded then " .. "\n"
                        .. "            tmp_skillInfoList[" .. jobId .. "][\"" .. profileRemark .. "\"].encoded = true " .. "\n"
                        .. "            tmp_skillInfoList[" .. jobId .. "][\"" .. profileRemark .. "\"].profile = LoaderConfig.profileEncrypt(tmp_skillInfoList[" .. jobId .. "][\"" .. profileRemark .. "\"].profile) " .. "\n"
                        .. "        end " .. "\n"
                        .. "        return table.deepcopy(tmp_skillInfoList[" .. jobId .. "][\"" .. profileRemark .. "\"].profile), tmp_skillInfoList[" .. jobId .. "][\"" .. profileRemark .. "\"].filter, \"" .. markerName .. "\", tmp_skillInfoList[" .. jobId .. "][\"" .. profileRemark .. "\"].big_cd " .. "\n"
                        .. "    end " .. "\n"
                        .. "end "
                )
                func()
            end
        end
    end
end

--- 生成MCR加载函数
local function generateMCRLoadFunc()
    -- 创建全局变量用于生成MCR加载函数
    ProfileLoader.skillInfoList = skillInfoList.PVE
    -- 动态生成加载方法
    dataHandle("PVE")

    -- 创建全局变量用于生成MCR加载函数
    ProfileLoader.skillInfoList = skillInfoList.PVP
    -- 动态生成加载方法
    dataHandle("PVP")

    -- 清除全局加密方法和技能信息
    ProfileLoader = nil
end


-- **********************************************************************
-- Global Function


-- **********************************************************************
-- Handler


-- **********************************************************************
-- Main

-- 清除配置文件缓存
clearProfileCache()

-- 获取配置文件
getProfile()

-- 添加配置文件
addPveProfile()
addPvpProfile()

-- 生成MCR加载函数
generateMCRLoadFunc()
