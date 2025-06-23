#!/bin/bash

# Godot 项目缓存清理和重新生成脚本
# 适用于 Godot 4.x 项目

echo "🧹 开始清理 Godot 项目缓存..."

# 检查是否在 Godot 项目目录中
if [ ! -f "project.godot" ]; then
    echo "❌ 错误：当前目录不是 Godot 项目目录"
    echo "请在包含 project.godot 文件的目录中运行此脚本"
    exit 1
fi

# 检查 Godot 是否已安装
if ! command -v godot &> /dev/null; then
    echo "❌ 错误：未找到 Godot 命令"
    echo "请确保 Godot 已安装并添加到 PATH 中"
    exit 1
fi

echo "📁 当前项目目录: $(pwd)"
echo "🎮 Godot 版本: $(godot --version)"

# 1. 清理 Godot 缓存目录
echo ""
echo "🗑️  第一步：清理 Godot 缓存目录..."

if [ -d ".godot" ]; then
    echo "清理 .godot/imported 目录..."
    rm -rf .godot/imported
    
    echo "清理 .godot/shader_cache 目录..."
    rm -rf .godot/shader_cache
    
    echo "清理 .godot/exported 目录..."
    rm -rf .godot/exported
    
    echo "清理编辑器临时文件..."
    rm -f .godot/scene_groups_cache.cfg
    rm -f .godot/uid_cache.bin
    rm -f .godot/global_script_class_cache.cfg
    
    echo "✅ Godot 缓存目录清理完成"
else
    echo "⚠️  .godot 目录不存在，跳过清理"
fi

# 2. 清理系统文件
echo ""
echo "🧽 第二步：清理系统文件..."

echo "清理 .DS_Store 文件..."
find . -name ".DS_Store" -delete 2>/dev/null && echo "✅ .DS_Store 文件清理完成" || echo "⚠️  未找到 .DS_Store 文件"

echo "清理临时文件..."
find . -name "*.tmp" -delete 2>/dev/null
find . -name "*~" -delete 2>/dev/null

# 3. 显示清理后的状态
echo ""
echo "📊 第三步：检查清理结果..."

if [ -d ".godot" ]; then
    CACHE_SIZE=$(du -sh .godot 2>/dev/null | cut -f1)
    echo "当前 .godot 目录大小: $CACHE_SIZE"
else
    echo "⚠️  .godot 目录已完全清理"
fi

# 4. 重新生成缓存
echo ""
echo "🔄 第四步：重新生成项目缓存..."
echo "这可能需要一些时间，请耐心等待..."

# 使用 Godot 重新导入所有资源
if godot --headless --import --skip-initial-scan=false . 2>&1; then
    echo "✅ 缓存重新生成成功"
else
    echo "⚠️  缓存重新生成过程中出现警告，但通常是正常的"
fi

# 5. 显示最终状态
echo ""
echo "📈 第五步：检查最终状态..."

if [ -d ".godot" ]; then
    FINAL_SIZE=$(du -sh .godot 2>/dev/null | cut -f1)
    echo "重新生成后 .godot 目录大小: $FINAL_SIZE"
    
    # 检查关键缓存目录
    echo ""
    echo "📂 缓存目录状态："
    [ -d ".godot/imported" ] && echo "  ✅ .godot/imported 目录已重新创建" || echo "  ❌ .godot/imported 目录未创建"
    [ -f ".godot/uid_cache.bin" ] && echo "  ✅ uid_cache.bin 已重新生成" || echo "  ❌ uid_cache.bin 未生成"
    [ -f ".godot/global_script_class_cache.cfg" ] && echo "  ✅ 全局脚本类缓存已重新生成" || echo "  ❌ 全局脚本类缓存未生成"
else
    echo "❌ .godot 目录未创建，缓存重新生成可能失败"
fi

echo ""
echo "🎉 缓存清理和重新生成完成！"
echo ""
echo "💡 建议："
echo "   1. 现在可以在 Godot 编辑器中打开项目"
echo "   2. 如果仍有问题，请尝试重启 Godot 编辑器"
echo "   3. 检查是否有资源导入错误"
echo "" 