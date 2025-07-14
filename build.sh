#!/bin/bash

# homelab-butler Docker构建脚本
# 用法: ./build.sh [选项]

set -e  # 遇到错误时退出

# 默认配置
DEFAULT_IMAGE_NAME="homelab-butler"
DEFAULT_TAG="latest"
DEFAULT_PLATFORM="linux/amd64"
DEFAULT_BUILDER="multiarch"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
homelab-butler Docker构建脚本

用法: $0 [选项]

选项:
    -n, --name NAME          镜像名称 (默认: $DEFAULT_IMAGE_NAME)
    -t, --tag TAG           镜像标签 (默认: $DEFAULT_TAG)
    -p, --platform PLATFORM 目标平台 (默认: $DEFAULT_PLATFORM)
    --builder BUILDER       Buildx构建器名称 (默认: $DEFAULT_BUILDER)
    --multi-platform        构建多平台镜像 (linux/amd64,linux/arm64)
    --no-cache              不使用构建缓存
    --pull                  构建前拉取最新基础镜像
    --push                  构建后推送到仓库
    --registry REGISTRY     Docker仓库地址
    --use-buildx            强制使用docker buildx (推荐)
    -v, --verbose           详细输出
    -h, --help              显示此帮助信息

示例:
    $0                                          # 使用默认设置构建x86镜像
    $0 -n my-app -t v1.0.0                    # 指定镜像名和标签
    $0 --use-buildx                           # 强制使用buildx构建x86镜像
    $0 --multi-platform --push               # 构建多平台镜像并推送
    $0 -p linux/arm64                        # 构建ARM64架构镜像
    $0 --no-cache --pull --use-buildx        # 使用buildx，不使用缓存
    $0 --registry registry.example.com --multi-platform --push  # 多平台推送到指定仓库

EOF
}

# 检查Docker是否可用
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker未安装或不在PATH中"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "无法连接到Docker守护进程，请确保Docker正在运行"
        exit 1
    fi
}

# 检查并设置Docker Buildx
check_buildx() {
    # 检查buildx是否可用
    if ! docker buildx version &> /dev/null; then
        print_error "Docker Buildx不可用，请更新Docker到最新版本"
        exit 1
    fi
    
    # 如果强制使用buildx或平台不是当前架构，则使用buildx
    local current_arch=$(uname -m)
    if [[ "$USE_BUILDX" == "true" ]] || [[ "$PLATFORM" == *"amd64"* && "$current_arch" == "arm64" ]] || [[ "$MULTI_PLATFORM" == "true" ]]; then
        USE_BUILDX="true"
        print_info "将使用Docker Buildx进行跨平台构建"
        
        # 检查构建器是否存在，不存在则创建
        if ! docker buildx inspect "$BUILDER" &> /dev/null; then
            print_info "创建多平台构建器: $BUILDER"
            if docker buildx create --name "$BUILDER" --driver docker-container --bootstrap; then
                print_success "构建器 '$BUILDER' 创建成功"
            else
                print_error "构建器创建失败"
                exit 1
            fi
        fi
        
        # 使用指定的构建器
        docker buildx use "$BUILDER"
        print_info "正在使用构建器: $BUILDER"
    else
        USE_BUILDX="false"
        print_info "将使用标准Docker构建"
    fi
}

# 检查Dockerfile是否存在
check_dockerfile() {
    if [[ ! -f "Dockerfile" ]]; then
        print_error "当前目录下未找到Dockerfile"
        exit 1
    fi
}

# 获取Git信息（如果可用）
get_git_info() {
    if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
        GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")
    else
        GIT_COMMIT="unknown"
        GIT_BRANCH="unknown"
        GIT_TAG=""
    fi
}

# 构建Docker镜像
build_image() {
    local full_image_name="${REGISTRY:+$REGISTRY/}$IMAGE_NAME:$TAG"
    
    print_info "开始构建Docker镜像..."
    print_info "镜像名称: $full_image_name"
    
    # 设置平台
    local build_platform="$PLATFORM"
    if [[ "$MULTI_PLATFORM" == "true" ]]; then
        build_platform="linux/amd64,linux/arm64"
        print_info "多平台构建: $build_platform"
    else
        print_info "平台: $build_platform"
    fi
    
    print_info "Git提交: $GIT_COMMIT"
    print_info "Git分支: $GIT_BRANCH"
    [[ -n "$GIT_TAG" ]] && print_info "Git标签: $GIT_TAG"
    
    # 构建Docker命令
    local docker_cmd
    if [[ "$USE_BUILDX" == "true" ]]; then
        docker_cmd="docker buildx build"
    else
        docker_cmd="docker build"
    fi
    
    # 添加平台参数
    docker_cmd+=" --platform $build_platform"
    
    # 添加标签
    docker_cmd+=" -t $full_image_name"
    
    # 如果有Git标签，添加额外的标签
    if [[ -n "$GIT_TAG" ]]; then
        local git_tag_image="${REGISTRY:+$REGISTRY/}$IMAGE_NAME:$GIT_TAG"
        docker_cmd+=" -t $git_tag_image"
        print_info "附加标签: $git_tag_image"
    fi
    
    # 添加构建参数
    docker_cmd+=" --build-arg GIT_COMMIT=$GIT_COMMIT"
    docker_cmd+=" --build-arg GIT_BRANCH=$GIT_BRANCH"
    docker_cmd+=" --build-arg BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    
    # 添加选项
    [[ "$NO_CACHE" == "true" ]] && docker_cmd+=" --no-cache"
    [[ "$PULL" == "true" ]] && docker_cmd+=" --pull"
    
    # Buildx特有选项
    if [[ "$USE_BUILDX" == "true" ]]; then
        if [[ "$PUSH" == "true" ]] || [[ "$MULTI_PLATFORM" == "true" ]]; then
            docker_cmd+=" --push"
            print_info "将直接推送到仓库（Buildx模式）"
        else
            docker_cmd+=" --load"
            print_info "将加载到本地Docker（Buildx模式）"
        fi
    fi
    
    # 添加构建上下文
    docker_cmd+=" ."
    
    # 执行构建
    if [[ "$VERBOSE" == "true" ]]; then
        print_info "执行命令: $docker_cmd"
    fi
    
    if eval "$docker_cmd"; then
        print_success "镜像构建成功: $full_image_name"
        
        # 仅在非推送模式下显示本地镜像信息
        if [[ "$USE_BUILDX" != "true" ]] || [[ "$PUSH" != "true" && "$MULTI_PLATFORM" != "true" ]]; then
            print_info "镜像信息:"
            docker images "$full_image_name" --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}" 2>/dev/null || print_info "镜像已推送到仓库，本地不可见"
        fi
    else
        print_error "镜像构建失败"
        exit 1
    fi
}

# 推送镜像
push_image() {
    # 如果使用buildx且已经在构建时推送，则跳过
    if [[ "$USE_BUILDX" == "true" ]] && ([[ "$PUSH" == "true" ]] || [[ "$MULTI_PLATFORM" == "true" ]]); then
        print_info "镜像已在构建时推送（Buildx模式）"
        return 0
    fi
    
    local full_image_name="${REGISTRY:+$REGISTRY/}$IMAGE_NAME:$TAG"
    
    print_info "推送镜像到仓库..."
    
    if docker push "$full_image_name"; then
        print_success "镜像推送成功: $full_image_name"
        
        # 如果有Git标签，也推送Git标签版本
        if [[ -n "$GIT_TAG" ]]; then
            local git_tag_image="${REGISTRY:+$REGISTRY/}$IMAGE_NAME:$GIT_TAG"
            if docker push "$git_tag_image"; then
                print_success "Git标签镜像推送成功: $git_tag_image"
            else
                print_warning "Git标签镜像推送失败: $git_tag_image"
            fi
        fi
    else
        print_error "镜像推送失败"
        exit 1
    fi
}

# 主函数
main() {
    # 解析命令行参数
    IMAGE_NAME="$DEFAULT_IMAGE_NAME"
    TAG="$DEFAULT_TAG"
    PLATFORM="$DEFAULT_PLATFORM"
    BUILDER="$DEFAULT_BUILDER"
    NO_CACHE="false"
    PULL="false"
    PUSH="false"
    REGISTRY=""
    VERBOSE="false"
    USE_BUILDX="false"
    MULTI_PLATFORM="false"
    
            while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                IMAGE_NAME="$2"
                shift 2
                ;;
            -t|--tag)
                TAG="$2"
                shift 2
                ;;
            -p|--platform)
                PLATFORM="$2"
                shift 2
                ;;
            --builder)
                BUILDER="$2"
                shift 2
                ;;
            --multi-platform)
                MULTI_PLATFORM="true"
                USE_BUILDX="true"
                shift
                ;;
            --use-buildx)
                USE_BUILDX="true"
                shift
                ;;
            --no-cache)
                NO_CACHE="true"
                shift
                ;;
            --pull)
                PULL="true"
                shift
                ;;
            --push)
                PUSH="true"
                shift
                ;;
            --registry)
                REGISTRY="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 执行检查
    check_docker
    check_dockerfile
    check_buildx
    get_git_info
    
    # 构建镜像
    build_image
    
    # 推送镜像（如果需要）
    if [[ "$PUSH" == "true" ]]; then
        if [[ -z "$REGISTRY" ]]; then
            print_warning "未指定仓库地址，将推送到Docker Hub"
        fi
        push_image
    fi
    
    print_success "所有操作完成!"
}

# 脚本入口
main "$@" 