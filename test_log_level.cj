import stdx.log.{Logger, LogLevel, Attr, LogRecord}

main(): Int64 {
    let levels = [
        LogLevel.DEBUG,
        LogLevel.INFO,
        LogLevel.WARN,
        LogLevel.ERROR
    ]

    for (level in levels) {
        println("Level: ${level}")
        println("Level toString: ${level.toString()}")
    }

    return 0
}