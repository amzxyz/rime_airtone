-- 欢迎使用带声调的拼音词库
-- https://github.com/amzxyz/rime_feisheng
--本lua通过定义一个不直接上屏的引导符号搭配26字母实现快速符号输入，并在双击引导符时候实现上一次输入的符号
-- 定义正则表达式匹配符号模式
local single_symbol_pattern = "^'([a-z])$"  -- 匹配 'q、'w 等符号输入
local double_symbol_pattern = "^''$"  -- 匹配双引号输入，用于触发重复上屏

-- 定义符号映射表
local mapping = {
    q = "“",
    w = "？",
    e = "（",
    r = "）",
    t = "~",
    y = "·",
    u = "『",
    i = "』",
    o = "〖",
    p = "〗",
    a = "！",
    s = "……",
    d = "、",
    f = "“",
    g = "”",
    h = "‘",
    j = "’",
    k = "——",
    l = "%",
    [";"] = "；",  -- 单引号对应的符号
    z = "。”",
    x = "？”",
    c = "！”",
    v = "【",
    b = "】",
    n = "《",
    m = "》"
}

-- 记录上次上屏的符号内容
local last_commit = ""

-- 初始化符号输入的状态
local function init(env)
    env.waiting_for_symbols = false  -- 初始状态
end

-- 处理符号输入的逻辑
local function processor(key_event, env)
    local engine = env.engine
    local context = engine.context
    local input = context.input  -- 当前输入的字符串

    -- 检查当前输入是否匹配双引号模式，重复上次符号
    if string.match(input, double_symbol_pattern) then
        if last_commit ~= "" then
            engine:commit_text(last_commit)  -- 上屏上次符号
            context:clear()  -- 清空输入
            return 1  -- 捕获事件
        end
    end

    -- 检查当前输入是否匹配单引号符号模式
    local match = string.match(input, single_symbol_pattern)
    if match then
        local symbol = mapping[match]  -- 获取匹配的符号
        if symbol then
            engine:commit_text(symbol)  -- 上屏符号
            last_commit = symbol  -- 保存上次上屏的符号
            context:clear()  -- 清空输入
            return 1  -- 捕获事件
        end
    end

    return 2  -- 未处理事件，继续传播
end

-- 导出到 RIME
return { init = init, func = processor }
