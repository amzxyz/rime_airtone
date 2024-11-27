local WordFrequencyFilter = {}

-- 初始化函数
function WordFrequencyFilter.init(env)
    -- 获取用户数据目录路径
    local user_data_dir = rime_api.get_user_data_dir()
    local dict_path = user_data_dir .. "/cn_dicts/large.dict.yaml"

    -- 打开字典文件
    local file = io.open(dict_path, "r")
    if not file then
        log.error("无法打开字典文件: " .. dict_path)
        return
    end

    -- 读取文件内容并解析
    local word_frequencies = {}
    for line in file:lines() do
        -- 去除每行前后的空白字符
        line = line:match("^%s*(.-)%s*$")

        -- 跳过空行或注释行
        if line == "" or line:match("^#") then
            goto continue
        end

        -- 使用制表符分割行
        local fields = {}
        for field in string.gmatch(line, "[^\t]+") do
            table.insert(fields, field)
        end

        -- 检查是否有至少三个字段
        if #fields >= 3 then
            local text = fields[1]
            local weight = fields[3]
            word_frequencies[text] = tonumber(weight)
        end

        ::continue::
    end

    file:close()
    env.word_frequencies = word_frequencies  -- 保存词频数据到环境变量

    -- 保存配置到环境变量，以便在过滤函数中使用
    env.config = env.engine.schema.config
    env.is_radical_mode = false  -- 初始化部件组字模式标志

    log.info("词频过滤初始化完成")
end

-- 获取单字的词频
function WordFrequencyFilter.get_word_frequency(word, env)
    return env.word_frequencies[word] or 0  -- 如果没有找到词频，返回 0
end

-- 检查输入是否匹配排除模式
function WordFrequencyFilter.is_excluded_input(input, config)
    local patterns = {
        config:get_string("recognizer/patterns/radical_lookup") or "^az[a-z]+$",
        config:get_string("recognizer/patterns/reverse_stroke") or "^ab[A-Za-z]*$",
        "^/customregex[0-9]*$",
    }

    for _, pattern in ipairs(patterns) do
        if input:match(pattern) then
            return true
        end
    end
    return false
end

-- 检查是否激活部件组字模式
function WordFrequencyFilter.update_radical_mode(env)
    local context = env.engine.context
    local input = context.input

    if input:len() == 0 then
        env.is_radical_mode = false  -- 当输入被清空时，退出部件拆字模式
    elseif input:find("^az") or input:find("^ab") then
        env.is_radical_mode = true  -- 激活部件组字模式
    else
        env.is_radical_mode = false  -- 其他情况退出模式
    end
end

-- 过滤候选词
function WordFrequencyFilter.filter_candidates(input, env)
    local context = env.engine.context
    local config = env.config

    -- 更新部件组字模式
    WordFrequencyFilter.update_radical_mode(env)

    -- 每次过滤时读取最新的开关状态和阈值
    local word_frequency_switch = context:get_option("word_frequency")  -- 获取布尔值开关
    local frequency_threshold = tonumber(config:get_string("word_frequency_filter") or "0")

    for cand in input:iter() do
        local word = cand.text

        if env.is_radical_mode then
            -- 在部件组字模式下，直接保留所有候选词
            yield(cand)
        elseif utf8.len(word) == 1 then
            -- 如果是单字，检查词频
            local word_frequency = WordFrequencyFilter.get_word_frequency(word, env)

            if word_frequency_switch then
                -- 启用词频过滤
                if word_frequency == 0 or word_frequency >= frequency_threshold then
                    -- 词频符合要求，保留该候选词
                    yield(cand)
                end
                -- 否则不保留该候选词
            else
                -- 未启用词频过滤，直接保留
                yield(cand)
            end
        else
            -- 非单字候选词，直接保留
            yield(cand)
        end
    end
end

-- 主入口函数
function WordFrequencyFilter.func(input, env)
    WordFrequencyFilter.filter_candidates(input, env)
end

return WordFrequencyFilter
