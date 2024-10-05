-- 欢迎使用带声调的拼音词库
-- @amzxyz
-- https://github.com/amzxyz/rime_feisheng
-- https://github.com/amzxyz/rime_wanxiang_pinyin
--本lua通过定义一个不直接上屏的引导符号搭配26字母实现快速符号输入，并在双击引导符时候实现上一次输入的符号
-- 使用方式加入到函数 - lua_processor@*quick_symbol_repeat 下面，方案文件配置recognizer/patterns/quick_symbol_repeat: "^'.*$"
-- 定义符号映射表
-- 记录上次上屏的内容
-- 欢迎使用带声调的拼音词库
-- @amzxyz
-- https://github.com/amzxyz/rime_feisheng
-- https://github.com/amzxyz/rime_wanxiang_pinyin
--本lua通过定义一个不直接上屏的引导符号搭配26字母实现快速符号输入，并在双击引导符时候实现上一次输入的符号
-- 使用方式加入到函数 - lua_processor@*quick_symbol_repeat 下面，方案文件配置recognizer/patterns/quick_symbol_repeat: "^'.*$"
-- 定义26字母符号映射表
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
    z = "。”",
    x = "？”",
    c = "！”",
    v = "【",
    b = "】",
    n = "《",
    m = "》"
}

-- 记录上次上屏的内容
local last_commit = ""

-- 初始化符号输入的状态
local function init(env)
    -- 读取 RIME 配置文件中的引导符号模式
    local config = env.engine.schema.config
    local quick_symbol_pattern = config:get_string("recognizer/patterns/quick_symbol_repeat") or "^'.*$"

    -- 提取配置值中的第二个字符作为引导符
    local quick_symbol = string.sub(quick_symbol_pattern, 2, 2) or "'"
    
    -- 生成单引导符和双引导符模式
    env.single_symbol_pattern = "^" .. quick_symbol .. "([a-zA-Z])$"
    env.double_symbol_pattern = "^" .. quick_symbol .. quick_symbol .. "$"

    -- 捕获上屏事件，保存上一次上屏的文本到 last_commit
    env.engine.context.commit_notifier:connect(function(ctx)
        last_commit = ctx:get_commit_text()  -- 保存提交的文本到全局变量
    end)
end

-- 处理符号输入和双引号 ;; 触发重复上屏的逻辑
local function processor(key_event, env)
    local engine = env.engine
    local context = engine.context
    local input = context.input  -- 当前输入的字符串

    -- 1. 检查是否输入的编码为双引导符，触发重复上屏
    if string.match(input, env.double_symbol_pattern) then
        if last_commit ~= "" then
            engine:commit_text(last_commit)  -- 上屏上次的符号或文本
            context:clear()  -- 清空输入
            return 1  -- 捕获事件，处理完成
        end
    end

    -- 2. 检查当前输入是否匹配单引导符符号模式 'q、'w 等
    local match = string.match(input, env.single_symbol_pattern)
    if match then
        local symbol = mapping[match]  -- 获取匹配的符号
        if symbol then
            engine:commit_text(symbol)  -- 上屏符号
            last_commit = symbol  -- 保存上次上屏的符号到全局变量
            context:clear()  -- 清空输入
            return 1  -- 捕获事件，处理完成
        end
    end

    return 2  -- 未处理事件，继续传播
end

-- 导出到 RIME
return { init = init, func = processor }

