#!/bin/bash

# ============================================
# DrinkTrackerWatch 构建并运行脚本
# 用法: ./run.sh [clean|build|run|all]
# ============================================

set -e

PROJECT="DrinkTrackerWatch.xcodeproj"
SCHEME="DrinkTrackerWatch"
SIMULATOR_ID="CE7640D1-A6B7-43E2-B0DC-FF70736EC65D"  # Apple Watch Series 11 (46mm)
BUNDLE_ID="com.drinking.app.watch"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 查找构建产物路径
find_app_path() {
    local app_path=$(find "$HOME/Library/Developer/Xcode/DerivedData" \
        -name "DrinkTrackerWatch.app" \
        -path "*/Debug-watchsimulator/*" \
        -not -path "*Index*" \
        2>/dev/null | head -1)
    echo "$app_path"
}

# 检查依赖
check_deps() {
    if ! command -v xcodegen &> /dev/null; then
        log_warn "xcodegen 未安装，跳过项目生成步骤"
        return 1
    fi
    return 0
}

# 生成 Xcode 项目
generate_project() {
    log_info "生成 Xcode 项目..."
    if check_deps; then
        rm -rf "$PROJECT"
        xcodegen generate
        log_success "项目已生成: $PROJECT"
    elif [ ! -d "$PROJECT" ]; then
        log_error "未找到 $PROJECT 且 xcodegen 未安装"
        exit 1
    fi
}

# 清理构建缓存
clean() {
    log_info "清理构建缓存..."
    rm -rf build/
    if [ -d "$PROJECT" ]; then
        xcodebuild -project "$PROJECT" -scheme "$SCHEME" clean 2>/dev/null || true
    fi
    log_success "清理完成"
}

# 构建项目
build() {
    log_info "🔨 正在构建 $SCHEME ..."
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=watchOS Simulator,id=$SIMULATOR_ID" \
        build 2>&1 | tail -5

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "构建成功 ✅"
    else
        log_error "构建失败 ❌"
        exit 1
    fi
}

# 启动模拟器
boot_simulator() {
    log_info "启动 Apple Watch 模拟器..."
    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
    open -a Simulator
}

# 安装并运行
install_and_run() {
    local app_path=$(find_app_path)

    if [ -z "$app_path" ]; then
        log_error "未找到构建产物"
        log_info "请先运行构建: ./run.sh build"
        exit 1
    fi

    log_info "安装应用到模拟器..."
    xcrun simctl install "$SIMULATOR_ID" "$app_path"

    log_info "启动应用..."
    xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"

    log_success "应用已启动！🎉"
}

# 显示帮助
show_help() {
    echo ""
    echo "⌚ DrinkTrackerWatch 构建运行脚本"
    echo ""
    echo "用法: ./run.sh [命令]"
    echo ""
    echo "命令:"
    echo "  gen      生成 Xcode 项目（需要 xcodegen）"
    echo "  build    构建项目"
    echo "  run      安装并运行到模拟器"
    echo "  all      生成 + 构建 + 运行（默认）"
    echo "  clean    清理构建缓存"
    echo "  help     显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  ./run.sh          # 完整流程：生成 + 构建 + 运行"
    echo "  ./run.sh build    # 仅构建"
    echo "  ./run.sh run      # 仅运行（需先构建）"
    echo "  ./run.sh clean    # 清理缓存"
    echo ""
}

# 主逻辑
cd "$(dirname "$0")"

case "${1:-all}" in
    gen)
        generate_project
        ;;
    build)
        build
        ;;
    run)
        boot_simulator
        install_and_run
        ;;
    all)
        generate_project
        build
        boot_simulator
        install_and_run
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "未知命令: $1"
        show_help
        exit 1
        ;;
esac