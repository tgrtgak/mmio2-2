// This is a hodgepodge of my own additions (wilkie) and Kagami's work on their
// ffmpeg emscripten port.

var __utils_utf8ToStr;

function __utils(__utils_opts) {
  __utils_utf8ToStr = UTF8ArrayToString;
  __utils_opts = __utils_opts || {};
  var __utils_return;
  var Module = {};
    __utils_return = {MEMFS: []};

  function __utils_toU8(data) {
    if (Array.isArray(data) || data instanceof ArrayBuffer) {
      data = new Uint8Array(data);
    } else if (!data) {
      // `null` for empty files.
      data = new Uint8Array(0);
    } else if (!(data instanceof Uint8Array)) {
      // Avoid unnecessary copying.
      data = new Uint8Array(data.buffer);
    }
    return data;
  }

  Object.keys(__utils_opts).forEach(function(key) {
    if (key != "mounts" && key != "MEMFS") {
      Module[key] = __utils_opts[key];
    }
  });

  Module["preInit"] = function() {
    if (ENVIRONMENT_IS_NODE) {
      exit = Module["exit"] = function(status) {
        ABORT = true;
        EXITSTATUS = status;
        STACKTOP = initialStackTop;
        exitRuntime();
        if (Module["onExit"]) Module["onExit"](status);
        throw new ExitStatus(status);
      };
    }
  };

  Module["preRun"] = function() {
    (__utils_opts["mounts"] || []).forEach(function(mount) {
      var fs = FS.filesystems[mount["type"]];
      if (!fs) {
        throw new Error("Bad mount type");
      }
      var mountpoint = mount["mountpoint"];
      // NOTE(Kagami): Subdirs are not allowed in the paths to simplify
      // things and avoid ".." escapes.
      if (!mountpoint.match(/^\/[^\/]+$/) ||
          mountpoint === "/." ||
          mountpoint === "/.." ||
          mountpoint === "/tmp" ||
          mountpoint === "/home" ||
          mountpoint === "/dev" ||
          mountpoint === "/work") {
        throw new Error("Bad mount point");
      }
      FS.mkdir(mountpoint);
      FS.mount(fs, mount["opts"], mountpoint);
    });

    FS.mkdir("/work");
    FS.chdir("/work");

    (__utils_opts["MEMFS"] || []).forEach(function(file) {
      if (file["name"].match(/\//)) {
        throw new Error("Bad file name");
      }
      var fd = FS.open(file["name"], "w+");
      var data = __utils_toU8(file["data"]);
      FS.write(fd, data, 0, data.length);
      FS.close(fd);
    });
  };

  Module["postRun"] = function() {
    // NOTE(Kagami): Search for files only in working directory, one
    // level depth. Since FFmpeg shouldn't normally create
    // subdirectories, it should be enough.
    function listFiles(dir) {
      var contents = FS.lookupPath(dir).node.contents;
      var filenames = Object.keys(contents);
      // Fix for possible file with "__proto__" name. See
      // <https://github.com/kripken/emscripten/issues/3663> for
      // details.
      if (contents.__proto__ && contents.__proto__.name === "__proto__") {
        filenames.push("__proto__");
      }
      return filenames.map(function(filename) {
        return contents[filename];
      });
    }

    var inFiles = Object.create(null);
    (__utils_opts["MEMFS"] || []).forEach(function(file) {
      inFiles[file.name] = null;
    });
    var outFiles = listFiles("/work").filter(function(file) {
      return !(file.name in inFiles);
    }).map(function(file) {
      var data = __utils_toU8(file.contents);
      return {"name": file.name, "data": data};
    });
    __utils_return = {"MEMFS": outFiles};
      var result = __utils_return;
  var transfer = result["MEMFS"].map(function(file) {
    return file["data"].buffer;
  });
  self.postMessage({"type": "done", "data": result}, transfer);
  __utils_running = false;
  };

  function _memset(p,v,l) {
      for(let i=0;i<l/4;i++){HEAP32[(p+i*4)>>2]=v;}
  }
