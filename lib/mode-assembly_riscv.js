/* This is licensed by wilkie under the BSD, same as Ace itself */

ace.define("ace/mode/assembly_riscv_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

var AssemblyRISCVHighlightRules = function() {

    this.$rules = { start: 
       [ { token: 'keyword.control.assembly',
           regex: '\\b(?:add|addi|addiw|addw|amoadd[.](?:d|w)|amoand[.](?:d|w)|amomax[.](?:d|w)|amomaxu[.](?:d|w)|amomin[.](?:d|w)|amominu[.](?:d|w)|amoor[.](?:d|w)|amoswap[.](?:d|w)|amoxor[.](?:d|w)|and|andi|auipc|beq|bge|bgeu|blt|bltu|bne|c[.]add|c[.]addi|c[.]addi4spn|c[.]addw|c[.]and|c[.]andi|c[.]beqz|c[.]bnez|c[.]ebreak|c[.]fld|c[.]fldsp|c[.]flw|c[.]flwsp|c[.]fsd|c[.]fsdsp|c[.]fsw|c[.]fswsp|c[.]j|c[.]jal|c[.]jalr|c[.]jr|c[.]li|c[.]lui|c[.]lw|c[.]lwsp|c[.]mv|c[.]or|c[.]slli|c[.]srai|c[.]srli|c[.]sub|c[.]subw|c[.]sw|c[.]swsp|c[.]xor|csrrc|csrrci|csrrs|csrrsi|csrrw|csrrwi|div|divu|divuw|divw|dret|ebreak|ecall|fadd[.](?:d|q|s)|fclass[.](?:d|q|s)|fcvt[.]d[.](?:l|lu|q|s|w|wu)|fcvt[.]q[.](?:l|lu|d|s|w|wu)|fcvt[.]s[.](?:l|lu|d|q|w|wu)|fcvt[.]lu?[.](?:d|q|s)|fcvt[.]wu?[.](?:d|q|s)|fdiv[.](?:d|q|s)|fence|feq[.](?:d|q|s)|fld|fle[.](?:d|q|s)|flq|flt[.](?:d|q|s)|flw|fmadd[.](?:d|q|s)|fmax[.](?:d|q|s)|fmin[.](?:d|q|s)|fmsub[.](?:d|q|s)|fmul[.](?:d|q|s)|fmv[.](?:d|w)[.]x|fmv[.]x[.](?:d|w)|fnmadd[.](?:d|q|s)|fnmsub[.](?:d|q|s)|fsd|fsgnj(?:n|x)?[.](?:d|q|s)|fsq|fsqrt[.](?:d|q|s)|fsub[.](?:d|q|s)|fsw|jal|jalr|lbu?|ld|lhu?|lr[.](?:d|w)|lui|lwu?|mret|mul|mulh|mulhsu|mulhu|mulw|ori?|remu?w?|sb|sc[.](?:d|w)|sd|sfence[.]vma|sh|slli?w?|slti?u?|srai?w?|sret|srli?w?|subw?|sw|wfi|xori?|nop|mv|not|negw?|sext[.]w|seqz|snez|sltz|sgtz|fmv[.](?:s|d)|fabs[.](?:s|d)|fneg[.](?:s|d)|beqz|bnez|blez|bgez|bltz|bgtz|bgt|ble|bgtu|bleu|j|jr|ret|call|tail|la|li|move|rdinstreth?|rdcycleh?|rdtimeh?|csrr|csrw|csrs|csrc|csrwi|csrsi|csrci|frcsr|fscsr|frrm|fsrmi?|frflags|fsflagsi?)\\b',
           caseInsensitive: false },
         { token: 'variable.parameter.register.assembly',
           regex: '\\b(?:x\d\d?|t0|t1|t2|s[0-9]|s10|s11|a[0-7]|t[0-6]|ft[0-9]|ft1[0-1]|fs[0-9]|fs[1-2][0-9]|fs3[0-1]|fa[0-7]|zero|ra|sp|gp|tp|fp)\\b',
           caseInsensitive: false },
         { token: 'constant.character.decimal.assembly',
           regex: '\\b[0-9]+\\b' },
         { token: 'constant.character.hexadecimal.assembly',
           regex: '\\b0x[A-F0-9]+\\b',
           caseInsensitive: true },
         { token: 'constant.character.hexadecimal.assembly',
           regex: '\\b[A-F0-9]+h\\b',
           caseInsensitive: true },
         { token: 'string.assembly', regex: /'([^\\']|\\.)*'/ },
         { token: 'string.assembly', regex: /"([^\\"]|\\.)*"/ },
        { token: 
            [ 'support.function.directive.assembly',
              'entity.name.function.assembly',
              'support.function.directive.assembly',
              'constant.character.assembly' ],
           regex: '([.]macro\s+)([_a-zA-Z][_a-zA-Z0-9]*)(\s+)([_a-zA-Z][_a-zA-Z0-9]*)' },
         { token: 'support.function.directive.assembly',
           regex: '[.]endm' },
          { token: 'support.function.directive.assembly',
              regex: '[.](?:include|abort|file|app-file|asciz|balign|comm|data|text|def|desc|dim|double|eject|else|endef|endif|equ|extern|fill|global|globl|hword|ident|if|int|irp|irpc|lcomm|lflags|ln|line|list|long|macro|nolist|octa|org|p2align|psize|quad|rept|sbttl|scl|set|short|single|size|space|stab(?:d|s|n)|string|tag|title|type|val|align|section|byte|word|dword|ascii)',
           caseInsensitive: false },
         { token: 'constant.character.assembly', regex: '^_[\\w]+:'},
         { token: 'entity.name.function.assembly', regex: '^[^_][\\w]+:'},
         { token: 'comment.assembly', regex: '#.*$' } ] 
    };
    
    this.normalizeRules();
};

AssemblyRISCVHighlightRules.metaData = { fileTypes: [ 'asm', 's' ],
      name: 'Assembly RISC-V',
      scopeName: 'source.assembly' };


oop.inherits(AssemblyRISCVHighlightRules, TextHighlightRules);

exports.AssemblyRISCVHighlightRules = AssemblyRISCVHighlightRules;
});

ace.define("ace/mode/folding/coffee",["require","exports","module","ace/lib/oop","ace/mode/folding/fold_mode","ace/range"], function(require, exports, module) {
"use strict";

var oop = require("../../lib/oop");
var BaseFoldMode = require("./fold_mode").FoldMode;
var Range = require("../../range").Range;

var FoldMode = exports.FoldMode = function() {};
oop.inherits(FoldMode, BaseFoldMode);

var functionRE = /^([\w]+):/;

(function() {

    this.getFoldWidgetRange = function(session, foldStyle, row) {
        // Determine the function name
        // We will allow func: to swallow up any _func_foo or _funcFoo's
        // it sees along the way. (as long as it doesn't start with an _)
        var line = session.getLine(row);
        var matches = functionRE.exec(line);
        var functionName = "";
        if (matches) {
            functionName = matches[1];
        }
        var range = this.indentationBlock(session, row);
        var startColumn = line.length;
        var startRow = row;
        var endRow = row;
        var maxRow = session.getLength();

        if (functionName && functionName[0] != "_") {
            // Determine if the last row includes "_{functionName}" as a label
            var curRow = range.end.row;
            var markedRow = row;

            while(++curRow < maxRow) {
                var curLine = session.getLine(curRow);
                matches = functionRE.exec(curLine);
                if (matches && !(matches[1].startsWith("_" + functionName))) {
                    break;
                }
                else if (matches) {
                    markedRow = curRow;
                }
            }

            var lastRange = this.indentationBlock(session, markedRow);

            var endRow = lastRange.end.row;
            var endColumn = session.getLine(endRow).length;
            return new Range(startRow, startColumn, endRow, endColumn);
        }

        if (range)
            return range;

        var re = /\S/;
        var startLevel = line.search(re);
        if (startLevel == -1 || line[startLevel] != "#")
            return;

        while (++row < maxRow) {
            line = session.getLine(row);
            var level = line.search(re);

            if (level == -1)
                continue;

            if (line[level] != "#")
                break;

            endRow = row;
        }

        if (endRow > startRow) {
            var endColumn = session.getLine(endRow).length;
            return new Range(startRow, startColumn, endRow, endColumn);
        }
    };
    this.getFoldWidget = function(session, foldStyle, row) {
        var line = session.getLine(row);
        var indent = line.search(/\S/);
        var next = session.getLine(row + 1);
        var prev = session.getLine(row - 1);
        var prevIndent = prev.search(/\S/);
        var nextIndent = next.search(/\S/);

        if (indent == -1) {
            session.foldWidgets[row - 1] = prevIndent!= -1 && prevIndent < nextIndent ? "start" : "";
            return "";
        }
        if (prevIndent == -1) {
            if (indent == nextIndent && line[indent] == "#" && next[indent] == "#") {
                session.foldWidgets[row - 1] = "";
                session.foldWidgets[row + 1] = "";
                return "start";
            }
        } else if (prevIndent == indent && line[indent] == "#" && prev[indent] == "#") {
            if (session.getLine(row - 2).search(/\S/) == -1) {
                session.foldWidgets[row - 1] = "start";
                session.foldWidgets[row + 1] = "";
                return "";
            }
        }

        if (prevIndent!= -1 && prevIndent < indent)
            session.foldWidgets[row - 1] = "start";
        else
            session.foldWidgets[row - 1] = "";

        if (indent < nextIndent)
            return "start";
        else
            return "";
    };

}).call(FoldMode.prototype);

});

ace.define("ace/mode/assembly_riscv",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/assembly_riscv_highlight_rules","ace/mode/folding/coffee"], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var AssemblyRISCVHighlightRules = require("./assembly_riscv_highlight_rules").AssemblyRISCVHighlightRules;
var FoldMode = require("./folding/coffee").FoldMode;

var Mode = function() {
    this.HighlightRules = AssemblyRISCVHighlightRules;
    this.foldingRules = new FoldMode();
    this.$behaviour = this.$defaultBehaviour;
};
oop.inherits(Mode, TextMode);

(function() {
    this.lineCommentStart = ["#"];
    this.blockComment = {start: "/*", end: "*/"};
    this.$id = "ace/mode/assembly_riscv";
}).call(Mode.prototype);

exports.Mode = Mode;
});                (function() {
                    ace.require(["ace/mode/assembly_riscv"], function(m) {
                        if (typeof module == "object" && typeof exports == "object" && module) {
                            module.exports = m;
                        }
                    });
                })();
            
