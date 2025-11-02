/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.version

import cjoy.log.LogTool

public const VERSION: String = "v0.80.0"
private const LOGO: String = ##"
 ________        ___  ________      ___    ___ 
|\   ____\      |\  \|\   __  \    |\  \  /  /|
\ \  \___|      \ \  \ \  \|\  \   \ \  \/  / /
 \ \  \       __ \ \  \ \  \\\  \   \ \    / / 
  \ \  \____ |\  \\_\  \ \  \\\  \   \/  /  /  
   \ \_______\ \________\ \_______\__/  / /    
    \|_______|\|________|\|_______|\___/ /     
                                  \|___|/          VERSION
"##

public func printBanner(): Unit {
    LogTool.info(LOGO.replace("VERSION", VERSION))
}
