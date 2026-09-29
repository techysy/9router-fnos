#!/bin/bash
# cmd/lib.sh — fnOS 生命周期脚本公用函数
#
# 被 cmd/main、cmd/install_callback、cmd/upgrade_callback 等 source。
# 只放"无副作用、可重复调用"的定位/工具函数；不做任何 install/build 决策。
#
# 设计约定：
#   - 每个函数只读 TRIM_* / APP_* 环境、只输出结果，不写文件、不 exit（调用方决定失败处理）
#   - 卷路径一律从实际目录推导，不写死 /vol4（见 9fe0945 的初衷）
#   - 抽出来是为了消除 install_callback / upgrade_callback 之间的逻辑漂移

# 9router_resolve_data_dir — 数据目录
# 优先 TRIM_PKGVAR（fnOS 注入）；否则从 APP_DIR/home 软链或 APP_DIR 推导卷，
# 不写死具体卷。回显路径。
9router_resolve_data_dir() {
    local app_name="$1" app_dir="$2" vol="" app_home=""
    if [ -n "${TRIM_PKGVAR:-}" ]; then
        printf '%s\n' "${TRIM_PKGVAR}"
        return 0
    fi
    if [ -L "${app_dir}/home" ]; then
        app_home="$(readlink -f "${app_dir}/home")"
        vol="$(printf '%s' "${app_home}" | sed -n 's#^\(/vol[^/]*\)/.*#\1#p')"
    fi
    if [ -z "${vol}" ]; then
        vol="$(printf '%s' "${app_dir}" | sed -n 's#^\(/vol[^/]*\)/.*#\1#p')"
    fi
    if [ -n "${vol}" ]; then
        printf '%s\n' "${vol}/@appdata/${app_name}"
    else
        printf '%s\n' "${app_dir}/var"
    fi
}

# 9router_find_server_dir — 定位 server 目录
# 兼容两种部署布局：${APP_DIR}/server 与 ${APP_DIR}/target/server。回显路径，找不到回显空串。
9router_find_server_dir() {
    local app_dir="$1" cand=""
    for cand in "${app_dir}/server" "${app_dir}/target/server"; do
        if [ -d "${cand}" ]; then
            printf '%s\n' "${cand}"
            return 0
        fi
    done
    return 0
}

# 9router_find_node_bin — 定位 nodejs_v24 的 node 可执行文件
# 候选：fnOS 标准软链 /var/apps/nodejs_v24/target，其次从数据目录卷推导 @appcenter。
# 回显路径，找不到回显空串。
9router_find_node_bin() {
    local data_dir="$1" vol="" cand=""
    vol="$(printf '%s' "${data_dir}" | sed -n 's#^\(/vol[^/]*\)/.*#\1#p')"
    for cand in "/var/apps/nodejs_v24/target/bin/node" "${vol}/@appcenter/nodejs_v24/bin/node"; do
        if [ -x "${cand}" ]; then
            printf '%s\n' "${cand}"
            return 0
        fi
    done
    return 0
}

# 9router_fix_initial_password — 把上游开发占位值 change-me 修正为默认密码
# 无论是否重建 server 都应在 SRC_DIR 就绪后调用（这是 install/upgrade 漂移的修复点）。
9router_fix_initial_password() {
    local src_dir="$1" log="$2" envf=""
    for envf in "${src_dir}/.env" "${src_dir}/.env.example"; do
        if [ -f "${envf}" ] && grep -q '^INITIAL_PASSWORD=change-me' "${envf}" 2>/dev/null; then
            sed -i 's/^INITIAL_PASSWORD=change-me.*/INITIAL_PASSWORD=123456/' "${envf}" 2>/dev/null || true
            echo "[$(date '+%F %T')] fixed INITIAL_PASSWORD=change-me -> 123456 in ${envf}" >> "${log}"
        fi
    done
}

# 9router_link_node_modules — node_modules 兜底软链
# 仅当 SRC_DIR 缺 node_modules、且另一布局的 target/server 有、且两者不是同一目录时执行
# （同一目录时 ln -s 会创建自引用链接）。
9router_link_node_modules() {
    local src_dir="$1" app_dir="$2" log="$3" target_nm="${app_dir}/target/server/node_modules"
    if [ "${src_dir}" = "${app_dir}/target/server" ]; then
        return 0
    fi
    if [ ! -d "${src_dir}/node_modules" ] && [ -d "${target_nm}" ]; then
        ln -s "${target_nm}" "${src_dir}/node_modules" 2>/dev/null || true
        echo "[$(date '+%F %T')] linked node_modules from target" >> "${log}"
    fi
}

# 9router_has_build_artifact — 是否已含构建产物（x86 离线版应命中）
9router_has_build_artifact() {
    local src_dir="$1" app_dir="$2" check=""
    for check in \
        "${src_dir}/.next-cli-build" \
        "${src_dir}/.next" \
        "${app_dir}/target/server/.next-cli-build" \
        "${app_dir}/target/server/.next"
    do
        [ -d "${check}" ] && return 0
    done
    return 1
}

# 9router_online_build — 在线构建（all 变体安装时跑）
# 返回码：0 成功 / 1 失败。失败细节写 log。调用方决定是否 exit 1。
9router_online_build() {
    local src_dir="$1" data_dir="$2" log="$3" node_bin="" rc=0

    node_bin="$(9router_find_node_bin "${data_dir}")"
    if [ -z "${node_bin}" ]; then
        echo "[$(date '+%F %T')] ERROR: nodejs_v24 not found; cannot build 9router" >> "${log}"
        return 1
    fi
    export PATH="$(dirname "${node_bin}"):${PATH}"
    export HOME="${data_dir}"
    # 低内存设备（R2S 等 1GB）降低并发与堆峰值
    export npm_config_jobs=1
    export NODE_OPTIONS="--max-old-space-size=1024"

    cd "${src_dir}" || return 1

    # 注意：$? 必须紧接命令取，不能跨命令替换（$(date) 会覆盖它）
    echo "[$(date '+%F %T')] npm install..." >> "${log}"
    rc=0
    timeout 1800 npm install --no-audit --no-fund >> "${log}" 2>&1 || rc=$?
    echo "[$(date '+%F %T')] npm install exit=${rc}" >> "${log}"
    [ "${rc}" -eq 0 ] || return 1

    echo "[$(date '+%F %T')] next build (NEXT_DIST_DIR=.next-cli-build)..." >> "${log}"
    rc=0
    timeout 3600 env NEXT_DIST_DIR=.next-cli-build npm run build >> "${log}" 2>&1 || rc=$?
    echo "[$(date '+%F %T')] next build exit=${rc}" >> "${log}"
    [ "${rc}" -eq 0 ] || return 1

    if [ -d "${src_dir}/.next-cli-build" ]; then
        echo "[$(date '+%F %T')] online build OK: .next-cli-build present" >> "${log}"
        return 0
    fi
    echo "[$(date '+%F %T')] ERROR: online build did not produce .next-cli-build" >> "${log}"
    return 1
}
