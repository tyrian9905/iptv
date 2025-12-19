#!/bin/bash

echo "🎬 开始处理IPTV播放列表..."
echo "======================================"

# 下载原始文件
echo "📥 下载原始文件..."
curl -s -o original.m3u "https://raw.githubusercontent.com/Healer-sys/Home/refs/heads/main/iptv/gx.m3u"

# 检查是否下载成功
if [ ! -s original.m3u ]; then
    echo "❌ 下载失败！"
    exit 1
fi

echo "✅ 下载完成，文件大小：$(wc -l < original.m3u) 行"

# 处理文件 - 添加tvg-id
echo "🔧 处理文件，添加tvg-id..."

# 创建临时文件
> processed.m3u

# 逐行处理
line_number=0
while IFS= read -r line || [[ -n "$line" ]]; do
    line_number=$((line_number + 1))
    
    # 如果是EXTINF行
    if [[ "$line" == "#EXTINF:"* ]]; then
        # 检查是否已经有tvg-id
        if [[ "$line" != *"tvg-id="* ]]; then
            # 提取频道名称（最后一个逗号后面的部分）
            channel_name=""
            
            # 使用awk提取最后一个逗号后的内容
            channel_name=$(echo "$line" | awk -F',' '{print $NF}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            if [ -n "$channel_name" ]; then
                # 生成tvg-id
                # 1. 移除特殊字符（保留中文、英文、数字、空格、下划线、短横线）
                tvg_id=$(echo "$channel_name" | sed '
                    s/[][(){}<>!@#$%^&*+=|\\;:\"\`~]/ /g
                    s/[.,?!]/ /g
                    s/°/ /g
                    s/×/x/g
                    s/【/[ /g
                    s/】/ ]/g
                    s/（/( /g
                    s/）/ )/g
                ')
                
                # 2. 多个空格合并为一个空格
                tvg_id=$(echo "$tvg_id" | tr -s ' ')
                
                # 3. 空格替换为下划线
                tvg_id=$(echo "$tvg_id" | tr ' ' '_')
                
                # 4. 转为小写
                tvg_id=$(echo "$tvg_id" | tr '[:upper:]' '[:lower:]')
                
                # 5. 移除开头的下划线
                tvg_id=$(echo "$tvg_id" | sed 's/^_*//')
                
                # 在逗号前插入tvg-id
                if [[ "$line" == *,* ]]; then
                    # 找到最后一个逗号
                    before_comma="${line%,*}"
                    after_comma=",${line##*,}"
                    line="${before_comma} tvg-id=\"${tvg_id}\"${after_comma}"
                fi
            fi
        fi
    fi
    
    # 写入处理后的行
    echo "$line" >> processed.m3u
    
    # 显示进度
    if [ $((line_number % 100)) -eq 0 ]; then
        echo "📝 已处理 $line_number 行..."
    fi
done < original.m3u

echo "✅ 处理完成！共处理 $line_number 行"

# 检查处理结果
processed_lines=$(wc -l < processed.m3u)
if [ "$processed_lines" -eq "$line_number" ]; then
    echo "📊 验证通过：输入 $line_number 行，输出 $processed_lines 行"
else
    echo "⚠️  注意：输入 $line_number 行，输出 $processed_lines 行"
fi

# 移动到iptv目录
mkdir -p iptv
mv processed.m3u iptv/gx_with_tvgid.m3u

# 显示一些示例
echo ""
echo "📋 处理示例："
echo "======================================"
head -5 iptv/gx_with_tvgid.m3u | while IFS= read -r sample; do
    if [[ "$sample" == "#EXTINF:"* ]]; then
        echo "示例: $sample"
    fi
done

# 清理临时文件
rm -f original.m3u

echo ""
echo "🎉 处理完成！文件已保存到：iptv/gx_with_tvgid.m3u"
echo "======================================"
