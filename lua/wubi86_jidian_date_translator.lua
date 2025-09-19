function simpleNumberToChinese(num)
    local chineseNumbers = {"零", "一", "二", "三", "四", "五", "六", "七", "八", "九"}
    
    if num <= 10 then
        return chineseNumbers[num + 1]
    elseif num < 20 then
        return "十" .. (num > 10 and chineseNumbers[num - 10 + 1] or "")
    else
        local tens = math.floor(num / 10)
        local units = num % 10
        return chineseNumbers[tens + 1] .. "十" .. (units > 0 and chineseNumbers[units + 1] or "")
    end
end


function wubi86_jidian_date_translator(input, seg)

    -- 日期格式说明：

    -- %a	abbreviated weekday name (e.g., Wed)
    -- %A	full weekday name (e.g., Wednesday)
    -- %b	abbreviated month name (e.g., Sep)
    -- %B	full month name (e.g., September)
    -- %c	date and time (e.g., 09/16/98 23:48:10)
    -- %d	day of the month (16) [01-31]
    -- %H	hour, using a 24-hour clock (23) [00-23]
    -- %I	hour, using a 12-hour clock (11) [01-12]
    -- %M	minute (48) [00-59]
    -- %m	month (09) [01-12]
    -- %p	either "am" or "pm" (pm)
    -- %S	second (10) [00-61]
    -- %w	weekday (3) [0-6 = Sunday-Saturday]
    -- %W	week number in year (48) [01-52]
    -- %x	date (e.g., 09/16/98)
    -- %X	time (e.g., 23:48:10)
    -- %Y	full year (1998)
    -- %y	two-digit year (98) [00-99]
    -- %%	the character `%´

    -- 输入完整日期
    if (input == "datetime") then
        yield(Candidate("date", seg.start, seg._end, os.date("%Y-%m-%d %H:%M:%S"), ""))
    end

    -- 输入日期
    if (input == "date") then
        --- Candidate(type, start, end, text, comment)
        yield(Candidate("date", seg.start, seg._end, os.date("%Y-%m-%d"), ""))
        yield(Candidate("date", seg.start, seg._end, os.date("%Y.%m.%d"), ""))
        yield(Candidate("date", seg.start, seg._end, os.date("%Y/%m/%d"), ""))
        yield(Candidate("date", seg.start, seg._end, os.date("%Y年%m月%d日"), ""))
        yield(Candidate("date", seg.start, seg._end, os.date("%Y%m%d"), ""))
        yield(Candidate("date", seg.start, seg._end, os.date("%m-%d-%Y"), ""))
        yield(Candidate("date", seg.start, seg._end, os.date("%m/%d/%Y"), ""))
    end

    -- 输入时间
    if (input == "time") then
        local current_time = os.date("*t")
        local year, month, day = current_time.year, current_time.month, current_time.day
        local hour, minute, second = current_time.hour, current_time.min, current_time.sec
        
        -- 12小时制转换
        local am_pm = hour >= 12 and "下午" or "上午"
        local hour_12 = hour % 12
        if hour_12 == 0 then hour_12 = 12 end
        
        -- 时辰计算
        local chinese_hour = math.floor(hour / 2) + 1
        local chinese_periods = {
            "子时(夜半)", "丑时(鸡鸣)", "寅时(平旦)", "卯时(日出)", 
            "辰时(食时)", "巳时(隅中)", "午时(日中)", "未时(日昳)", 
            "申时(晡时)", "酉时(日入)", "戌时(黄昏)", "亥时(人定)"
        }
        local current_chinese_period = chinese_periods[chinese_hour]
        
        -- 固定宽度用于右对齐
        local fixed_width = 15
        
        -- 所有时间格式（统一使用 string.format）
        local time_formats = {
            -- 纯时间格式
            string.format("%02d%02d%02d", hour, minute, second),
            string.format("%04d%02d%02d%02d%02d%02d", year, month, day, hour, minute, second),
            -- 24小时制时间格式
            string.format("%02d:%02d", hour, minute),
            string.format("%02d点%02d分", hour, minute),
            string.format("%02d:%02d:%02d", hour, minute, second),
            string.format("%02d点%02d分%02d秒", hour, minute, second),
            -- 12小时制时间格式
            string.format("%s%02d:%02d", am_pm, hour_12, minute),
            string.format("%s%02d点%02d分", am_pm, hour_12, minute),
            string.format("%s%02d:%02d:%02d", am_pm, hour_12, minute, second),
            string.format("%s%02d点%02d分%02d秒", am_pm, hour_12, minute, second),
        }
        
        -- 生成候选词
        for i, time_format in ipairs(time_formats) do
            local comment = string.rep(" ", fixed_width - #current_chinese_period) .. current_chinese_period
            yield(Candidate("time", seg.start, seg._end, time_format, comment))
        end
    end

    -- 输入星期
    -- -- @JiandanDream
    -- -- https://github.com/KyleBing/rime-wubi86-jidian/issues/54
    if (input == "week") then
        local weekTab = {'日', '一', '二', '三', '四', '五', '六'}
        yield(Candidate("week", seg.start, seg._end, "周"..weekTab[tonumber(os.date("%w")+1)], ""))
        yield(Candidate("week", seg.start, seg._end, "星期"..weekTab[tonumber(os.date("%w")+1)], ""))
        yield(Candidate("week", seg.start, seg._end, "礼拜"..weekTab[tonumber(os.date("%w")+1)], ""))
        yield(Candidate("week", seg.start, seg._end, os.date("%A"), ""))
        yield(Candidate("week", seg.start, seg._end, os.date("%a"), "缩写"))
        local weekNum = os.date("%W") + 1
        yield(Candidate("week", seg.start, seg._end, os.date("%W")+1, "周数"))
        yield(Candidate("week", seg.start, seg._end, "第"..(os.date("%W")+1).."周", "周数"))
        yield(Candidate("week", seg.start, seg._end, "第"..simpleNumberToChinese(weekNum).."周", "周数"))
        yield(Candidate("week", seg.start, seg._end, os.date("%Y年").."第"..(os.date("%W")+1).."周", "周数"))
        yield(Candidate("week", seg.start, seg._end, os.date("%Y年").."第"..simpleNumberToChinese(weekNum).."周", "周数"))

    end

    -- 输入月份英文
    if (input == "month") then
        yield(Candidate("month", seg.start, seg._end, os.date("%B"), ""))
        yield(Candidate("month", seg.start, seg._end, os.date("%b"), "缩写"))
    end
end

return wubi86_jidian_date_translator
