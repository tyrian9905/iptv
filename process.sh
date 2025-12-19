#!/bin/bash

echo "🎬 开始处理IPTV播放列表..."
echo "======================================"

# 1. 下载原始文件，指定UTF-8编码
echo "📥 下载原始文件..."
curl -s -o original.m3u "https://raw.githubusercontent.com/Healer-sys/Home/refs/heads/main/iptv/gx.m3u"

# 转换为UTF-8编码（确保中文正确处理）
if command -v iconv &> /dev/null; then
    iconv -f utf-8 -t utf-8 original.m3u > original_utf8.m3u
    mv original_utf8.m3u original.m3u
fi

# 检查文件
if [ ! -s original.m3u ]; then
    echo "❌ 下载失败！"
    exit 1
fi

lines=$(wc -l < original.m3u)
echo "✅ 下载完成，文件大小：$lines 行"

# 2. 处理文件
echo "🔧 处理文件，添加tvg-id..."
> processed.m3u

# 使用 while 循环逐行处理
while IFS= read -r line || [[ -n "$line" ]]; do
    # 跳过空行
    if [ -z "$line" ]; then
        echo "" >> processed.m3u
        continue
    fi
    
    # 如果是 EXTINF 行
    if [[ "$line" == "#EXTINF:"* ]]; then
        # 检查是否已经有 tvg-id
        if [[ "$line" != *"tvg-id="* ]]; then
            # 使用 sed 提取频道名称（最后一个逗号后的内容）
            channel_name=$(echo "$line" | sed 's/.*,//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            if [ -n "$channel_name" ]; then
                # 生成 tvg-id：使用简单方法处理中文
                # 只保留中文、英文、数字、空格，其他字符替换为空格
                tvg_id=$(echo "$channel_name" | sed '
                    # 移除方括号和括号
                    s/$$//g                     s/$$//g
                    s/(//g
                    s/)//g
                    # 替换标点符号为空格
                    s/[[:punct:]]/ /g
                    # 合并多个空格
                    s/[[:space:]]\+/ /g
                    # 去掉首尾空格
                    s/^[[:space:]]*//
                    s/[[:space:]]*$//
                    # 空格替换为下划线
                    s/ /_/g
                    # 转为小写
                    s/.*/\L&/
                ')
                
                # 如果 tvg_id 为空或只有下划线，使用默认值
                if [ -z "$tvg_id" ] || [ "$tvg_id" = "_" ]; then
                    tvg_id="channel"
                fi
                
                # 在最后一个逗号前插入 tvg-id
                # 找到最后一个逗号的位置
                if [[ "$line" == *,* ]]; then
                    # 使用 sed 插入
                    new_line=$(echo "$line" | sed "s/,/ tvg-id=\"$tvg_id\",/")
                    echo "$new_line" >> processed.m3u
                else
                    # 没有逗号，直接添加
                    echo "$line tvg-id=\"$tvg_id\"" >> processed.m3u
                fi
            else
                # 没有频道名称
                echo "$line tvg-id=\"unknown\"" >> processed.m3u
            fi
        else
            # 已经有 tvg-id，直接输出
            echo "$line" >> processed.m3u
        fi
    else
        # 不是 EXTINF 行，直接输出
        echo "$line" >> processed.m3u
    fi
done < original.m3u

echo "✅ 处理完成！"

# 3. 检查处理结果
processed_lines=$(wc -l < processed.m3u)
echo "📊 输入: $lines 行，输出: $processed_lines 行"

if [ "$lines" -eq "$processed_lines" ]; then
    echo "✅ 行数匹配成功"
else
    echo "⚠️  行数不匹配，可能存在处理问题"
fi

# 4. 保存到目录
mkdir -p iptv
mv processed.m3u iptv/gx_with_tvgid.m3u

# 5. 显示示例
echo ""
echo "📋 处理示例（前5个频道）："
echo "======================================"
grep -A1 "^#EXTINF:" iptv/gx_with_tvgid.m3u | head -10 | while read -r line; do
    if [[ "$line" == "#EXTINF:"* ]]; then
        echo "频道: $line"
    fi
done

# 清理
rm -f original.m3u

echo ""
echo "🎉 处理完成！文件已保存到：iptv/gx_with_tvgid.m3u"
echo "======================================"
