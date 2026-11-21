/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.bind

import std.convert.Parsable
import std.collection.{HashMap, ArrayList}
import std.time.DateTime

/**
 * 扩展 String 类型：将绑定源绑定到 String 类型
 */
extend String <: JoyBindable<String> {
    /**
     * 将绑定源绑定到字符串
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return 字符串值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?String {
        let val = source.getOne<ToString>(name)
        getString(val, defaultValue)
    }
}

private func getString(a: ?ToString, b: ?String): ?String {
    match (a) {
        case Some(x) => x.toString()
        case _ => match (b) {
            case Some(v) => v
            case _ => None
        }
    }
}

/**
 * 扩展 Option 类型：将绑定源绑定到可选值
 */
extend<T> Option<T> <: JoyBindable<Option<T>> where T <: JoyBindable<T> {
    /**
     * 将绑定源绑定到可选值
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param timeformat 日期时间格式
     * @return 可选值
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?Option<T> {
        T.bind(source, name, defaultValue, timeformat)
    }
}

private func bindParsable<T>(source: JoyBindSource, name: String, defaultValue: ?String): ?T where T <: Parsable<T> {
    let val = source.getOne<T>(name)
    match (val) {
        case Some(x) => x
        case _ => bindParsable(source.getOne<ToString>(name), defaultValue)
    }
}

private func bindParsable<T>(val: ?ToString, defaultValue: ?String): ?T where T <: Parsable<T> {
    let v = getString(val, defaultValue)
    match (v) {
        case Some(x) => match (T.tryParse(x)) {
            case Some(parsed) => Some(parsed)
            case _ => match (defaultValue) {
                // 源值存在但无法解析时，回退到 @BindField[default=...]
                case Some(d) => T.tryParse(d)
                case _ => None
            }
        }
        case _ => None
    }
}

/**
 * 扩展 Int8 类型：将绑定源绑定到 Int8 类型
 */
extend Int8 <: JoyBindable<Int8> {
    /**
     * 将绑定源绑定到 int8 类型
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return int8 值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int8 {
        bindParsable<Int8>(source, name, defaultValue)
    }
}

/**
 * 扩展 Int16 类型：将绑定源绑定到 Int16 类型
 */
extend Int16 <: JoyBindable<Int16> {
    /**
     * 将绑定源绑定到 int16 类型
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return int16 值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int16 {
        bindParsable<Int16>(source, name, defaultValue)
    }
}

/**
 * 扩展 Int32 类型：将绑定源绑定到 Int32 类型
 */
extend Int32 <: JoyBindable<Int32> {
    /**
     * 将绑定源绑定到 int32 类型
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return int32 值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int32 {
        bindParsable<Int32>(source, name, defaultValue)
    }
}

/**
 * 扩展 Int64 类型：将绑定源绑定到 Int64 类型
 */
extend Int64 <: JoyBindable<Int64> {
    /**
     * 将绑定源绑定到 int64 类型
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return int64 值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int64 {
        bindParsable<Int64>(source, name, defaultValue)
    }
}

/**
 * 扩展 UInt8 类型：将绑定源绑定到 UInt8 类型
 */
extend UInt8 <: JoyBindable<UInt8> {
    /**
     * 将绑定源绑定到 uint8 类型
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return uint8 值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt8 {
        bindParsable<UInt8>(source, name, defaultValue)
    }
}

/**
 * 扩展 UInt16 类型：将绑定源绑定到 UInt16 类型
 */
extend UInt16 <: JoyBindable<UInt16> {
    /**
     * 将绑定源绑定到 uint16 类型
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return uint16 值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt16 {
        bindParsable<UInt16>(source, name, defaultValue)
    }
}

/**
 * 扩展 UInt32 类型：将绑定源绑定到 UInt32 类型
 */
extend UInt32 <: JoyBindable<UInt32> {
    /**
     * 将绑定源绑定到 uint32 类型
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return uint32 值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt32 {
        bindParsable<UInt32>(source, name, defaultValue)
    }
}

/**
 * 扩展 UInt64 类型：将绑定源绑定到 UInt64 类型
 */
extend UInt64 <: JoyBindable<UInt64> {
    /**
     * 将绑定源绑定到 uint64 类型
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return uint64 值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt64 {
        bindParsable<UInt64>(source, name, defaultValue)
    }
}

/**
 * 扩展 Float16 类型：将绑定源绑定到 Float16 类型
 */
extend Float16 <: JoyBindable<Float16> {
    /**
     * 将绑定源绑定到 float16 类型
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return float16 值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Float16 {
        bindParsable<Float16>(source, name, defaultValue)
    }
}

/**
 * 扩展 Float32 类型：将绑定源绑定到 Float32 类型
 */
extend Float32 <: JoyBindable<Float32> {
    /**
     * 将绑定源绑定到 float32 类型
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return float32 值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Float32 {
        bindParsable<Float32>(source, name, defaultValue)
    }
}

/**
 * 扩展 Float64 类型：将绑定源绑定到 Float64 类型
 */
extend Float64 <: JoyBindable<Float64> {
    /**
     * 将绑定源绑定到 float64 类型
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return float64 值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Float64 {
        bindParsable<Float64>(source, name, defaultValue)
    }
}

/**
 * 扩展 Bool 类型：将绑定源绑定到 Bool 类型
 */
extend Bool <: JoyBindable<Bool> {
    /**
     * 将绑定源绑定到布尔值
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param _ 时间格式（未使用）
     * @return 布尔值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Bool {
        bindParsable<Bool>(source, name, defaultValue)
    }
}

// 目前未考虑 T 是 Option 类型的情况
/**
 * 扩展 Array 类型：将绑定源绑定到 Array 类型
 */
extend<T> Array<T> <: JoyBindable<Array<T>> where T <: JoyBindable<T> {
    /**
     * 将绑定源绑定到数组
     *
     * @param source 绑定源
     * @param name 字段名
     * @param _ 默认值（未使用）
     * @param _ 时间格式（未使用）
     * @return 数组值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, _: ?String, _: ?String): ?Array<T> {
        // 键不存在时返回 None，让宏应用字段默认值（而不是返回空数组）
        if (source.getOne<Any>(name).isNone()) {
            return None
        }
        // 尝试通过相同类型获取，例如 Array<String>
        let arr: Collection<T> = source.getList<T>(name)
        if (!arr.isEmpty()) {
            return arr.toArray()
        }

        let col: Collection<Any> = source.getList<Any>(name)
        bindCollection<T>(col).toArray()
    }
}

private func bindCollection<T>(col: Collection<Any>): ArrayList<T> where T <: JoyBindable<T> {
    // 通过任意类型获取，需要调用 T.bind 转换为对应类型
    // 例如 Array<Int>，首先生成临时地图
    let map = HashMap<String, Any>()
    let container = MapContainer(map)
    let res = ArrayList<T>()
    for (a in col) {
        let val = match (a) {
            // 元素本身是对象时，用它的字段直接绑定嵌套对象
            case m: HashMap<String, Any> => T.bind(MapContainer(m), "", None, None)
            case _ =>
                map[""] = a
                T.bind(container, "", None, None)
        }
        if (let Some(v) <- val) {
            res.add(v)
        }
    }
    res
}

// 目前未考虑 T 是 Option 类型的情况
/**
 * 扩展 ArrayList 类型：将绑定源绑定到 ArrayList 类型
 */
extend<T> ArrayList<T> <: JoyBindable<ArrayList<T>> where T <: JoyBindable<T> {
    /**
     * 将绑定源绑定到数组列表
     *
     * @param source 绑定源
     * @param name 字段名
     * @param _ 默认值（未使用）
     * @param _ 时间格式（未使用）
     * @return 数组列表值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, _: ?String, _: ?String): ?ArrayList<T> {
        if (source.getOne<Any>(name).isNone()) {
            return None
        }
        let arr: Collection<T> = source.getList<T>(name)
        if (!arr.isEmpty()) {
            return ArrayList(arr)
        }

        let col: Collection<Any> = source.getList<Any>(name)
        bindCollection<T>(col)
    }
}

/**
 * 扩展 DateTime 类型：将绑定源绑定到 DateTime 类型
 */
extend DateTime <: JoyBindable<DateTime> {
    /**
     * 将绑定源绑定到日期时间
     *
     * @param source 绑定源
     * @param name 字段名
     * @param defaultValue 默认值
     * @param timeformat 日期时间格式
     * @return 日期时间值，如果未找到则返回 None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?DateTime {
        func parse(str: ?ToString): ?DateTime {
            match (str) {
                case Some(v) => try {
                    match (timeformat) {
                        case Some(f) => DateTime.parse(v.toString(), f)
                        case _ => DateTime.parse(v.toString())
                    }
                } catch (_: Exception) {
                    // 非法日期回退到默认值
                    match (defaultValue) {
                        case Some(d) => match (timeformat) {
                            case Some(f) => DateTime.parse(d, f)
                            case _ => DateTime.parse(d)
                        }
                        case _ => None
                    }
                }
                case _ => None
            }
        }
        match (defaultValue) {
            case Some(dv) =>
                let str = getString(source.getOne<ToString>(name), dv)
                match (str) {
                    case Some(v) => parse(v)
                    case _ => None
                }
            case _ => parse(source.getOne<ToString>(name))
        }
    }
}
