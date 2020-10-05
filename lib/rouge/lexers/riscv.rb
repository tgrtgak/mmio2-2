# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# This is licensed by wilkie under the MIT license, same as Rouge itself
# MIT license.  See http://www.opensource.org/licenses/mit-license.php

module Rouge
  module Lexers
    class RISCV < RegexLexer
      tag 'riscv'

      title "RISC-V"
      desc "RISC-V Assembler"

      id = /[a-zA-Z_][a-zA-Z0-9_]*/

      def self.keywords
        @keywords ||= Set.new %w(
          add addi addiw addw

          amoadd.d amoadd.w
          amoand.d amoand.w
          amomax.d amomax.w
          amomaxu.d amomaxu.w
          amomin.d amomin.w
          amominu.d amominu.w
          amoor.d amoor.w
          amoswap.d amoswap.w
          amoxor.d amoxor.w

          and andi auipc

          beq bge bgeu blt bltu bne

          c.add c.addi c.addi4spn c.addw
          c.and c.andi
          c.beqz c.bnez
          c.ebreak
          c.fld c.fldsp c.flw c.flwsp c.fsd c.fsdsp c.fsw c.fswsp
          c.j c.jal c.jalr c.jr
          c.li c.lui c.lw c.lwsp
          c.mv
          c.or
          c.slli c.srai c.srli c.sub c.subw c.sw c.swsp
          c.xor

          csrrc csrrci csrrs csrrsi csrrw csrrwi
          div divu divuw divw dret
          ebreak ecall
          fadd.d fadd.q fadd.s
          fclass.d fclass.q fclass.s
          fcvt.d.l fcvt.d.lu fcvt.d.q fcvt.d.s fcvt.d.w fcvt.d.wu
          fcvt.q.l fcvt.q.lu fcvt.q.d fcvt.q.s fcvt.q.w fcvt.q.wu
          fcvt.s.l fcvt.s.lu fcvt.s.d fcvt.s.q fcvt.s.w fcvt.s.wu
          fcvt.lu.d fcvt.lu.q fcvt.lu.s
          fcvt.wu.d fcvt.wu.q fcvt.qu.s
          fdiv.d fdiv.q fdiv.s
          fence
          feq.d feq.q feq.s
          fld
          fle.d fle.q fle.s
          flq
          flt.d flt.q flt.s
          flw
          fmadd.d fmadd.q fmadd.s
          fmax.d fmax.q fmax.s
          fmin.d fmin.q fmin.s
          fmsub.d fmsub.q fmsub.q
          fmul.d fmul.q fmul.s
          fmv.d.x fmv.w.x
          fmv.x.d fmv.x.w
          fnmadd.d fnmadd.q fnmadd.s
          fnmsub.d fnmsub.q fnmsub.s
          fsd
          fsgnj.n.d fsgnj.x.d fsgnj.d fsgnj.n.q fsgnj.x.q fsgnj.q fsgnj.n.s fsgnj.x.s fsgnj.s
          fsq
          fsqrt.d fsqrt.q fsqrt.s
          fsub.d fsub.q fsub.s
          fsw

          jal jalr

          lb lbu ld lh lhu lr.d lr.w lui lw lwu
          mret mul mulh mulhsu mulhu mulw
          or ori

          rem remu remw remuw

          sb sc.d sc.w sd sfence.vma sh
          sll slli sllw slliw slt slti sltu sltiu sra srai sraw sraiw
          sret
          srl srli srlw srliw sub subw sw
          wfi
          xor xori

          nop mv not neg negw sext.w seqz snez sltz sgtz fmv.s fmv.d fabs.s fabs.d
          fneg.s fneg.d
          beqz bnez blez bgez bltz bgtz bgt ble bgtu bleu
          j jr
          ret call tail la li move
          rdinstret rdinstreth rdcycle rdcycleh rdtime rdtimeh
          csrr csrw csrs csrc csrwi csrsi csrci
          frcsr fscsr frrm fsrm fsrmi frflags fsflags fsflagsi
        )
      end

      def self.keywords_type
        @keywords_type ||= Set.new %w(
          dc ds dcb
        )
      end

      def self.reserved
        @reserved ||= Set.new %w(
          include abort file app-file asciz balign comm data text def desc dim double eject else endef endif equ extern fill global globl hword ident if int irp irpc lcomm lflags ln line list long macro nolist octa org p2align psize quad rept sbttl scl set short single size space stab(?:d s n) string tag title type val align section byte word dword ascii
        )
      end

      def self.builtins
        @builtins ||=Set.new %w(
          x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16 x17 x18 x19
          x20 x21 x22 x23 x24 x25 x26 x27 x28 x29 x30 x31

          t0 t1 t2 t3 t4 t5 t6

          s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11

          a0 a1 a2 a3 a4 a5 a6 a7

          sp gp tp fp zero ra

          ft0 ft1 ft2 ft3 ft4 ft5 ft6 ft7 ft8 ft9 ft10 ft11
          fs0 fs1 fs2 fs3 fs4 fs5 fs6 fs7 fs8 fs9 fs10 fs11 fs12 fs13 fs14
          fs15 fs16 fs17 fs18 fs19 fs20 fs21 fs22 fs23 fs24 fs25 fs26 fs27
          fs28 fs29 fs30 fs31
          fa0 fa1 fa2 fa3 fa4 fa5 fa6 fa7
        )
      end

      start { push :expr_bol }

      state :expr_bol do
        mixin :inline_whitespace
        rule(//) { pop! }
      end

      state :inline_whitespace do
        rule(/[\s]+/, Text)
      end

      state :whitespace do
        rule(/\n+/m, Text, :expr_bol)
        rule(%r(#(\\.|.)*?\n), Comment::Single, :expr_bol)
        mixin(:inline_whitespace)
      end

      state :root do
        rule(//) { push :statements }
      end

      state :statements do
        mixin :whitespace
        rule(/"/, Str, :string)
        rule(/#/, Name::Decorator)
        rule(/^\.?[a-zA-Z0-9_]+:?/, Name::Label)
        rule(/\.[bswl]\s/i, Name::Decorator)
        rule(%r('(\\.|\\[0-7]{1,3}|\\x[a-f0-9]{1,2}|[^\\'\n])')i, Str::Char)
        rule(/\$[0-9a-f]+/i, Num::Hex)
        rule(/@[0-8]+/i, Num::Oct)
        rule(/%[01]+/i, Num::Bin)
        rule(/\d+/i, Num::Integer)
        rule(%r([*~&+=\|?:<>/-]), Operator)
        rule(/\\./, Comment::Preproc)
        rule(/[(),.]/, Punctuation)
        rule(/\[[a-zA-Z0-9]*\]/, Punctuation)

        rule id do |m|
          name = m[0]

          if self.class.keywords.include? name.downcase
            token Keyword
          elsif self.class.keywords_type.include? name.downcase
            token Keyword::Type
          elsif self.class.reserved.include? name.downcase
            token Keyword::Reserved
          elsif self.class.builtins.include? name.downcase
            token Name::Builtin
          elsif name =~ /[a-zA-Z0-9]+/
            token Name::Variable
          else
            token Name
          end
        end
      end

      state :string do
        rule(/"/, Str, :pop!)
        rule(/\\([\\abfnrtv"']|x[a-fA-F0-9]{2,4}|[0-7]{1,3})/, Str::Escape)
        rule(/[^\\"\n]+/, Str)
        rule(/\\\n/, Str)
        rule(/\\/, Str) # stray backslash
      end
    end
  end
end
