/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.config

import std.collection.{Map}
import cjoy.bind.JoyBindable

/*
 * 配置管理器接口。
 *
 * config的键支持env变量和一个用`.`分隔的多层键，例如：
 *
 * - 单级键：
 *   - abc
 *   - cdf
 * - 多级键：
 *   - a.b.c
 * - 数组键：
 *   - a[0]，a[1]
 *   - a.b[0].c，a.b[1].c
 * -env变量：
 *   - HOME, USER
 *
 * 如果密钥包含大写字母，它将被转换为下划线+小写，例如：
 *
 * - aBc->a_bc
 * - aBC->a_bc
 */
public interface Config {
    /**
     * 如果键存在则返回 true
     *
     * @param key 配置键
     * @return 如果键存在则返回 true
     */
    func hashKey(key: String): Bool

    /**
     * 根据键获取值
     *
     * @param key 配置键
     * @return 配置值
     */
    func getValue(key: String): ?String

    /**
     * 根据键获取值（带默认值）
     *
     * @param key 配置键
     * @param defaultValue 默认值
     * @return 配置值
     */
    func getValue(key: String, defaultValue: String): String

    /**
     * 将配置绑定到对象
     *
     * @param key 配置键
     * @return 绑定的对象
     */
    func bind<T>(key: String): ?T where T <: JoyBindable<T>

    /**
     * 将配置值解析为字符串，例如：${host}:${port} -> 127.0.0.1:18881
     *
     * @param exp 带占位符的表达式字符串
     * @return 解析后的字符串
     */
    func resolve(exp: String): String

    /**
     * 添加配置加载器
     *
     * @param loaders 要添加的配置加载器
     */
    func addLoader(loaders: Array<ConfigLoader>): Unit
}

/**
 * 配置加载器，由用户实现扩展不同配置文件类型加载。
 */
public interface ConfigLoader {
    /**
     * 将配置加载到映射中
     *
     * @return 加载的配置
     */
    func load(): Map<String, Any>

    /**
     * 高优先级将覆盖低优先级的配置项值
     *
     * @return 优先级值
     */
    prop priority: Int
}

/**
 * 配置异常。
 */
public class ConfigException <: Exception {
    /**
     * 创建新的配置异常
     *
     * @param message 错误消息
     */
    public ConfigException(message: String) {
        super(message)
    }
}
