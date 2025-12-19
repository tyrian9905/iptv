#!/bin/bash

echo "开始处理IPTV文件..."
echo "=========================="

# 下载文件
echo "下载原始文件..."
curl -s "https://raw.githubusercontent.com/Healer-sys/Home/refs/heads/main/iptv/gx.m3u" -o input.m3u

# 检查文件编码，确保是UTF-8
if command -v file &> /dev/null; then
    encoding=$(file -b --mime-encoding input.m3u)
    echo "文件编码: $encoding"
    
    if [ "$encoding" != "utf-8" ] && command -v iconv &> /dev/null; then
        echo "转换编码为UTF-8..."
        iconv -f "$encoding" -t utf-8 input.m3u > input_utf8.m3u
        mv input_utf8.m3u input.m3u
    fi
fi

# 使用 AWK 处理
echo "处理中..."
awk '
BEGIN {
    print "开始处理M3U文件..."
    FS = ","
}
/^#EXTINF:/ {
    if ($0 !~ /tvg-id=/) {
        # 获取频道名称（最后一个字段）
        channel_name = $NF
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", channel_name)
        
        # 清理频道名称，生成tvg-id
        tvg_id = channel_name
        
        # 移除特殊字符，但保留中文字符
        # 使用字符范围匹配
        gsub(/[][(){}\\/|~!@#$%^&*+=;:"`<>.,?°×]/, "", tvg_id)
        
        # 替换空格为下划线
        gsub(/[[:space:]]+/, "_", tvg_id)
        
        # 转换为小写
        tvg_id = tolower(tvg_id)
        
        # 如果tvg_id为空，使用默认值
        if (tvg_id == "" || tvg_id == "_") {
            tvg_id = "channel_" NR
        }
        
        # 重建行
        line_before = substr($0, 1, length($0) - length(channel_name) - 1)
        print line_before " tvg-id=\"" tvg_id "\"," channel_name
        next
    }
}
{ print }
' input.m3u > output.m3u

# 检查结果
input_lines=$(wc -l < input.m3u)
output_lines=$(wc -l < output.m3u)

echo "处理完成!"
echo "输入行数: $input_lines"
echo "输出行数: $output_lines"

if [ $input_lines -ne $output_lines ]; then
    echo "警告: 行数不匹配!"
    echo "显示前几行差异..."
    head -5 input.m3u
    echo "---"
    head -5 output.m3u
fi

# 保存文件
mkdir -p iptv
mv output.m3u iptv/gx_processed.m3u

# 显示一些示例
echo ""
echo "处理示例:"
echo "=========================="
echo "原始行示例:"
grep "^#EXTINF:" input.m3u | head -3
echo ""
echo "处理后示例:"
grep "^#EXTINF:" iptv/gx_processed.m3u | head -3

# 清理
rm -f input.m3u

echo ""
echo "文件已保存: iptv/gx_processed.m3u"
echo "=========================="
