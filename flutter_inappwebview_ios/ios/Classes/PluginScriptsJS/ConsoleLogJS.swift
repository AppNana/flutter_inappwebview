//
//  ConsoleLogJS.swift
//  flutter_inappwebview
//
//  Created by Lorenzo Pichilli on 16/02/21.
//

import Foundation

public class ConsoleLogJS {
    
    public static let CONSOLE_LOG_JS_PLUGIN_SCRIPT_GROUP_NAME = "IN_APP_WEBVIEW_CONSOLE_LOG_JS_PLUGIN_SCRIPT"
    
    // This plugin is only for main frame.
    // Using it also on non-main frames could cause issues
    // such as https://github.com/pichillilorenzo/flutter_inappwebview/issues/1738
    public static func CONSOLE_LOG_JS_PLUGIN_SCRIPT(allowedOriginRules: [String]?) -> PluginScript {
        return PluginScript(
            groupName: CONSOLE_LOG_JS_PLUGIN_SCRIPT_GROUP_NAME,
            source: CONSOLE_LOG_JS_SOURCE(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true,
            allowedOriginRules: allowedOriginRules,
            requiredInAllContentWorlds: true,
            messageHandlerNames: [])
    }
    
    // the message needs to be concatenated with '' in order to have the same behavior like on Android
    public static func CONSOLE_LOG_JS_SOURCE() -> String {
        return """
        (function(console) {
            function _callHandler(logLevel, args) {
                var message = '';

                for (var i in args) {
                    try {
                        let arg = args[i];

                        // 对象转为 JSON 字符串（捕获异常）
                        if (typeof arg === 'object') {
                            try {
                                arg = JSON.stringify(arg);
                            } catch (e) {
                                arg = '[Object]';
                            }
                        } else if (typeof arg === 'symbol') {
                            arg = arg.toString(); // 防止直接拼接出错
                        } else if (typeof arg === 'function') {
                            arg = '[Function]';
                        }

                        message += message === '' ? arg : ' ' + arg;
                    } catch (ignored) {
                        message += ' [Unserializable]';
                    }
                }

                // 调用原生 JS Bridge（捕获防止报错）
                try {
                    window.\(JavaScriptBridgeJS.get_JAVASCRIPT_BRIDGE_NAME()).callHandler(
                        'onConsoleMessage',
                        {
                            level: logLevel,
                            message: message
                        }
                    );
                } catch (_) {}
            }

            var oldLogs = {
                consoleLog: console.log,
                consoleDebug: console.debug,
                consoleError: console.error,
                consoleInfo: console.info,
                consoleWarn: console.warn
            };

            for (var k in oldLogs) {
                (function(oldLog) {
                    var logLevel = oldLog.replace('console', '').toLowerCase();
                    console[logLevel] = function() {
                        oldLogs[oldLog].apply(null, arguments); // 保留原输出
                        _callHandler(logLevel, arguments);      // 通知原生
                    };
                })(k);
            }
        })(window.console);
        """
    }
}
