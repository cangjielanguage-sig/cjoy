/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.multipart

/**
 * 当多部分解析失败时抛出的异常
 */
public class MultiPartParseException <: Exception {
    /**
     * 使用指定的消息初始化 MultiPartParseException 的新实例
     *
     * @param message 异常消息
     */
    public init(message: String) {
        super(message)
    }
}

/**
 * 当达到多部分大小限制时抛出的异常
 */
public class MultiPartLimitReachedException <: Exception {
    /**
     * 使用指定的消息初始化 MultiPartLimitReachedException 的新实例
     *
     * @param message 异常消息
     */
    public init(message: String) {
        super(message)
    }
}

/**
 * 用于测量内存和文件大小的数据大小常量
 */
public struct JoyDataSize {
    private let _value: Int
    const init(value: Int) {
        _value = value
    }

    /** 千字节大小常量 (1024 字节) */
    public static const KB: JoyDataSize = JoyDataSize(1 << 10)
    /** 兆字节大小常量 (1024 千字节) */
    public static const MB: JoyDataSize = JoyDataSize(1 << 20)
    /** 吉字节大小常量 (1024 兆字节) */
    public static const GB: JoyDataSize = JoyDataSize(1 << 30)

    /**
     * 将数据大小乘以整数值
     *
     * @param r 整数乘数
     * @return 结果数据大小
     */
    public operator func *(r: Int): JoyDataSize {
        JoyDataSize(_value * r)
    }

    /**
     * 获取数据大小的原始整数值
     */
    public prop value: Int {
        get() {
            _value
        }
    }
}

/**
 * 多部分解析和处理的配置
 *
 * @property maxParts 多部分请求中允许的最大部分数
 * @property maxHeaders 每个部分允许的最大头数
 * @property maxMemSize 所有部分组合的允许最大内存大小
 * @property maxFileSize 单个部分允许的最大文件大小
 * @property fileCacheDir 上传文件缓存目录
 */
public struct JoyMultiPartConfig {
    public var maxParts: Int = 10
    public var maxHeaders: Int = 5
    public var maxMemSize: JoyDataSize = JoyDataSize.MB * 32
    public var maxFileSize: JoyDataSize = JoyDataSize.MB * 32
    public var fileCacheDir: String = ""
}
