// This is a hodgepodge of my own additions (wilkie) and Kagami's work on their
// ffmpeg emscripten port.

  return __utils_return;
}

var __utils_running = false;

var __stdin_buffer = [];

self.onmessage = function(e) {
  function makeOutHandler(cb) {
    var buf = [];
    return function(ch, exit) {
      if (exit && buf.length) return cb(__utils_utf8ToStr(buf, 0));
      if (ch === 10) {
        cb(__utils_utf8ToStr(buf, 0));
        buf = [];
      } else if (ch !== 0) {
        // See <https://github.com/kripken/emscripten/blob/1.34.4/
        // src/library_tty.js#L146>.
        buf.push(ch);
      }
    };
  }

  var msg = e.data;
  if (msg["type"] == "run") {
    if (__utils_running) {
      self.postMessage({"type": "error", "data": "already running"});
    } else {
      __utils_running = true;
      self.postMessage({"type": "run"});
      var opts = {};
      Object.keys(msg).forEach(function(key) {
        if (key !== "type") {
          opts[key] = msg[key]
        }
      });
      opts["stdin"] = function(ch, exit) {
          return __stdin_buffer.shift() || null;
      };
      opts["stdout"] = makeOutHandler(function(line) {
        self.postMessage({"type": "stdout", "data": line});
      });
      opts["stderr"] = makeOutHandler(function(line) {
        self.postMessage({"type": "stderr", "data": line});
      });
      opts["quit"] = function(code) {
          console.log("quit");
        // Flush buffers.
        opts["stdout"](0, true);
        opts["stderr"](0, true);
        self.postMessage({"type": "exit", "data": code});
      };
      var result = __utils(opts);
    }
  } else if (msg["type"] == "write") {
      console.log("updating", msg.data);
    __stdin_buffer.push(msg["data"]);
  } else {
    self.postMessage({"type": "error", "data": "unknown command"});
  }
};

self.postMessage({"type": "ready"});
