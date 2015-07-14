{***********************************************************************************************************************
 *
 * SOL Virtual Machine
 * ==========================================
 *
 * Copyright (C) 2015 by Sérgio Flores (relfos@gmail.com)
 *
 ***********************************************************************************************************************
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 **********************************************************************************************************************
}


Unit SolVM;

Interface
Uses TERRA_Utils, TERRA_String, TERRA_Math;

{
  Registers list

  0 - PC (Program counter)
  1 - EX (Exception flags)
  2 - ID (current thread id)
  3 - ST (stack index/pointer)
  4..9 - Reserved

  10 to 127  - R0 to R117 (Registers)


  Instruction format (32 bits)

  Opcode | OperandA | OperandB | OperandC | Size

  Opcode  = 7 bits
  Size = 4 bits
  Operand = 7 bits

  Eg: C = A + B

  Integer size can be 1, 2, 4, 8
  Float size can be 1, 2, 3, 4 (for vector operations)

  Vector regs are interleaved in memory:
  V0_4 = R0 + R4 + R8 + R12
  V1_3 = R1 + R3 + R9
  V4_2 = R16 + R20 + R24

  V0_4.Y = R4
  V4_2.Z = R24

}

Const
  { opcodes list }

  // program control opcodes
  SOLOP_STOP      = 1; // terminates execution (the return value comes from the result register RX)
  SOLOP_BREAK     = 2; // debugger break
  SOLOP_CALL      = 3; // call function indexed by reg
  SOLOP_RETURN    = 4; // return from current function
  SOLOP_PUSH      = 5; // push reg in stack
  SOLOP_POP       = 6; // pop from stack into reg

  // moving opcodes
  SOLOP_SWAP  = 10; // swaps two regs
  SOLOP_MOVE  = 11; // copy reg to reg
  SOLOP_COPY  = 12; // moves number of bytes from location index by reg to other location by another reg
  SOLOP_READ  = 13; // copy mem value to reg
  SOLOP_WRITE = 14; // copy reg to mem value
  SOLOP_CONST = 15; // copy const to reg

  // int math opcodes
  SOLOP_INT_INC   = 20;    // increment reg
  SOLOP_INT_DEC   = 21;    // decrement reg
  SOLOP_INT_ADD   = 22;    // add reg to reg
  SOLOP_INT_SUB   = 23;    // subtract reg from reg
  SOLOP_INT_MUL   = 24;    // multiply reg with reg
  SOLOP_INT_DIV   = 25;    // divide reg by reg
  SOLOP_INT_MOD   = 26;    // modulus of reg by reg

  // bit math opcodes
  SOLOP_AND = 30;    // 'and' two regs
  SOLOP_OR  = 31;    // 'or' two regs
  SOLOP_XOR = 32;    // 'xor' two regs
  SOLOP_NOT = 33;    // negate reg
  SOLOP_SHR = 34;    // add reg to reg
  SOLOP_SHL = 35;    // add reg to reg

  // branching opcodes
  SOLOP_JMP         = 40;  // jump to location in index
  SOLOP_JMP_ZERO    = 41;  // jump if reg is zero
  SOLOP_JMP_EQUAL   = 42;  // jump if two regs are equal
  SOLOP_JMP_DIFF    = 43;  // jump if two regs are different
  SOLOP_JMP_LESS    = 44;  // jump if reg A is less than reg B
  SOLOP_JMP_LESS_EQUAL  = 45;  // jump if reg A is less or equal than reg B
  SOLOP_JMP_GREAT       = 46;  // jump if reg A is great than reg B
  SOLOP_JMP_GREAT_EQUAL = 47;  // jump if reg A is great or equal than reg B

  // pseudo-threads opcodes
  SOLOP_THREAD_START    = 50; // create a new pseudo thread and invoke function indexed by reg (new thread id is returned in RX)
  SOLOP_THREAD_STOP     = 51; // terminates execution of indexed by reg
  SOLOP_THREAD_YIELD    = 52; // yields control to another pseudo thread
  SOLOP_THREAD_SEND     = 53; // sends a reg as message to another thread
  SOLOP_THREAD_RECEIVE  = 54; // receive a message from from another thread and put it in a reg (yields until a value arrives)
  SOLOP_THREAD_PEEK     = 55; // puts the number of waiting messages in a reg
  SOLOP_THREAD_LOCK     = 56; // stops all context switches (used for sending/receiving multiple stuff^)
  SOLOP_THREAD_UNLOCK   = 57; // resumes context switches
  SOLOP_THREAD_STATUS   = 58; // returns into reg the current status of a thread

  // float math opcodes
  SOLOP_FLOAT_MOVE  = 60;    // copy int reg to float reg
  SOLOP_FLOAT_TRUNC = 61;    // truncate float reg to integer reg
  SOLOP_FLOAT_ROUND = 62;    // round float reg to integer reg
  SOLOP_FLOAT_ADD   = 63;    // add reg to reg
  SOLOP_FLOAT_SUB   = 64;    // subtract reg from reg
  SOLOP_FLOAT_MUL   = 65;    // multiply reg with reg
  SOLOP_FLOAT_DIV   = 66;    // divide reg by reg
  SOLOP_FLOAT_MOD   = 67;    // modulus of reg by reg
  SOLOP_FLOAT_SQRT  = 68;    // square root of reg
  SOLOP_FLOAT_INV_SQRT = 69; // 1.0 / square root of reg
  SOLOP_FLOAT_LOG   = 70;    // log2 of reg
  SOLOP_FLOAT_POW   = 71;    // log2 of reg
  SOLOP_FLOAT_COS   = 72;    // cosine of reg
  SOLOP_FLOAT_SIN   = 73;    // sine of reg
  SOLOP_FLOAT_TAN   = 74;    // tangent of reg
  SOLOP_FLOAT_ARCCOS = 75;   // arc cosine of reg
  SOLOP_FLOAT_ARCSIN = 76;   // arc sine of reg
  SOLOP_FLOAT_ARCTAN = 77;   // arc tangent of reg
  SOLOP_FLOAT_ATAN2 = 78;   // arctan2 of reg
  SOLOP_FLOAT_ABS 	= 79;   // absolute value of reg
  SOLOP_FLOAT_MIN 	= 80;   // copy smallest of two regs into reg
  SOLOP_FLOAT_MAX 	= 81;   // copy largest of two regs into reg

  // vec2 math opcodes
  SOLOP_VEC2_MOVE  = 80;    // copy int reg to float reg
  SOLOP_VEC2_ADD   = 81;    // add reg to reg
  SOLOP_VEC2_SUB   = 82;    // subtract reg from reg
  SOLOP_VEC2_MUL   = 83;    // multiply reg with reg
  SOLOP_VEC2_DIV   = 84;    // divide reg by reg
  SOLOP_VEC2_MOD   = 85;    // modulus of reg by reg
  SOLOP_VEC2_SQRT  = 86;    // square root of reg
  SOLOP_VEC2_INV_SQRT = 87; // 1.0 / square root of reg
  SOLOP_VEC2_LOG   = 89;    // log2 of reg
  SOLOP_VEC2_POW   = 90;    // log2 of reg
  SOLOP_VEC2_COS   = 91;    // cosine of reg
  SOLOP_VEC2_SIN   = 92;    // sine of reg
  SOLOP_VEC2_TAN   = 93;    // tangent of reg
  SOLOP_VEC2_ARCCOS = 94;   // arc cosine of reg
  SOLOP_VEC2_ARCSIN = 95;   // arc sine of reg
  SOLOP_VEC2_ARCTAN = 96;   // arc tangent of reg
  SOLOP_VEC2_ATAN2 = 97;   // arctan2 of reg
  SOLOP_VEC2_LENGTH = 98;   // length of reg (or abs() if size = 0)
  SOLOP_VEC2_SHUFFLE = 99; // switches different parts of vectors around

  // other constants
  SOL_POSITION_REG = 0;
  SOL_EXCEPT_REG = 1;
  SOL_THREAD_REG = 2;
  SOL_STACK_REG = 3;
  SOL_BASE_REG = 10;
  SOL_REG0 = SOL_BASE_REG + 0;
  SOL_REG1 = SOL_BASE_REG + 1;
  SOL_REG2 = SOL_BASE_REG + 2;
  SOL_REG3 = SOL_BASE_REG + 3;
  SOL_REG4 = SOL_BASE_REG + 4;
  SOL_REG5 = SOL_BASE_REG + 5;
  SOL_REG7 = SOL_BASE_REG + 6;
  SOL_REG8 = SOL_BASE_REG + 7;
  SOL_REG9 = SOL_BASE_REG + 8;

  SOL_REG_PAD = 4;
  SOL_MAX_REGS = 128;

  SOL_DEFAULT_STACK_SIZE = 1024*8;

  // native function convention calls
  SOLCALL_Register  = 0; // default delphi call convention
  SOLCALL_CDecl     = 1;
  SOLCALL_StdCall   = 2;
  SOLCALL_SafeCall  = 3;
  SOLCALL_ThisCall  = 4;
  // others are unsupported (eg: pascal call, fast call, vector call)

Type
  SOL_Instruction = Cardinal;
  SOL_Register = Cardinal;
  SOL_String = TERRAString;
  SOL_NativeCallConvention = Cardinal;

  SOL_NativeFunction = Record
    Name:SOL_String;
    Address:Pointer;
    ArgCount:Cardinal;
    Convention:SOL_NativeCallConvention;
  End;

  SOL_Process = Class;

  SOL_Thread = Class(TERRAObject)
    Protected
      _Owner:SOL_Process;

      _Registers:Array[0..Pred(SOL_MAX_REGS)] Of SOL_Register;
      _Stack:Array Of SOL_Register;
      _StackSize:Cardinal;

    Public
      Constructor Create(Owner:SOL_Process; BasePos, StackSize:Cardinal);
      Procedure Release(); Override;

      { Fetches the next instruction and advance the pointer}
      Function Fetch():SOL_Instruction;

      Function Pop():SOL_Register;
      Procedure Push(Const Val:SOL_Register);

      Function Run(Out ReturnValue:Cardinal):Boolean;

      { Resets the registers and move the instruction pointer to the first instruction}
      Procedure Reset(Pos:Cardinal);
  End;

  SOL_Process = Class(TERRAObject)
    Protected
      _Instructions:Array Of SOL_Instruction;
      _InstructionCount:Integer;

      _NativeFunctions:Array Of SOL_NativeFunction;
      _NativeFunctionCount:Integer;

      _Threads:Array Of SOL_Thread;
      _ThreadCount:Integer;
      _CurrentThread:SOL_Thread;

      Function Fetch(Pos:Cardinal):SOL_Instruction;
      Function CreateThread(Pos:Cardinal):SOL_Thread;

      Function Invoke(Index:Cardinal):Cardinal;

    Public
      Constructor Create();
      Procedure Release(); Override;

      Function RegisterFunction(Const Name:SOL_String; Address:Pointer; ArgCount:Cardinal; Convention:SOL_NativeCallConvention = SOLCALL_Register):Cardinal;

      Procedure AddInstruction(Inst:SOL_Instruction);

      Function Run():Cardinal;
  End;

Function SOL_EncodeInstruction(Opcode:Cardinal; Arg1:Cardinal = 0; Arg2:Cardinal = 0;  Arg3:Cardinal = 0):SOL_Instruction;
Procedure SOL_DecodeInstruction(Const Inst:Cardinal; Out Opcode, Arg1, Arg2, Arg3:Cardinal);


Function SOL_Float_Pack(Const X:Single):SOL_Register;
Function SOL_Float_Unpack(Const X:Cardinal):Single;

Implementation

Function SOL_Float_Pack(Const X:Single):SOL_Register;
Begin
  Result := Cardinal((@X)^);
End;

Function SOL_Float_Unpack(Const X:Cardinal):Single;
Begin
  Result := Single((@X)^);
End;

Function SOL_EncodeInstruction(Opcode:Cardinal; Arg1:Cardinal = 0; Arg2:Cardinal = 0;  Arg3:Cardinal = 0):SOL_Instruction;
Begin
  Result := Opcode + Size Shl 7 + Arg1 Shl 11 + Arg2 Shl 18 + Arg3 Shl 25;
End;

Procedure SOL_DecodeInstruction(Const Inst:Cardinal; Out Opcode, Arg1, Arg2, Arg3:Cardinal);
Var
  Mask:Cardinal;
Begin
  Mask := ((1 Shl 4) - 1);
  Size := (Inst Shr 7) And Mask;

  Mask := ((1 Shl 7) - 1);
  Opcode := Inst And Mask;
  Arg1 := (Inst Shr 11) And Mask;
  Arg2 := (Inst Shr 18) And Mask;
  Arg3 := (Inst Shr 25) And Mask;
End;

{ SOL_Thread }
Constructor SOL_Thread.Create(Owner:SOL_Process; BasePos, StackSize:Cardinal);
Begin
  _Owner := Owner;
  _StackSize := StackSize;
  SetLength(_Stack, _StackSize);

  Self.Reset(BasePos);
End;

Procedure SOL_Thread.Release();
Begin
End;

Procedure SOL_Thread.Reset(Pos:Cardinal);
Begin
  FillChar(_Registers[0], SOL_MAX_REGS * SizeOf(SOL_Register), 0);
  FillChar(_Stack[0], _StackSize * SizeOf(SOL_Register), 0);

  _Registers[SOL_POSITION_REG] := Pos;
End;

Function SOL_Thread.Fetch: SOL_Instruction;
Var
  Pos:Cardinal;
Begin
  Pos := _Registers[SOL_POSITION_REG];

  Result := _Owner.Fetch(Pos);

  Inc(Pos);
  _Registers[SOL_POSITION_REG] := Pos;
End;

Function SOL_Thread.Run(out ReturnValue:Cardinal): Boolean;
Var
  N:SOL_Instruction;
  Opcode, Arg1, Arg2, Arg3:Cardinal;
  I:Integer;
  F1, F2:Single;
  Temp, Size:Cardinal;
Begin
  ReturnValue := 0;
  Result := False;

  Repeat
    N := Self.Fetch();

    SOL_DecodeInstruction(N, Opcode, Size, Arg1, Arg2, Arg3);

    Case Opcode Of
    SOLOP_STOP:
      Begin
        ReturnValue := _Registers[Arg1];
        Result := False;
        Break;
      End;

    SOLOP_BREAK:
      Begin
        DebugBreak;
      End;

    SOLOP_CALL:
      Begin
        _Registers[Arg3] := _Owner.Invoke(_Registers[Arg1]);
      End;

    SOLOP_RETURN: // return from current function
      Begin
        // ReturnValue := _Registers[Arg1];
      End;

    SOLOP_PUSH: // push reg in stack
      Begin
        Self.Push(_Registers[Arg1]);
      End;

    SOLOP_POP: // pop from stack into reg
      Begin
        _Registers[Arg1]:= Self.Pop();
      End;

    SOLOP_SWAP:
      Begin
        Arg3 := _Registers[Arg1];
        _Registers[Arg1] := _Registers[Arg2];
        _Registers[Arg2] := Arg3;
      End;


    SOLOP_MOVE:
      Begin
        For I:=0 To Size Do
        Begin
          _Registers[Arg3] := _Registers[Arg1];
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_COPY: // moves number of bytes from location index by reg to other location by another reg
      Begin
        // move(bla)
      End;

    SOLOP_READ:
      Begin
       // _Registers[Arg3] := _Memory[Arg1];s
      End;

    SOLOP_WRITE: // copy reg to mem value
      Begin
        ///_Memory[Arg3] := _Registers[Arg1];
      End;

    SOLOP_CONST:
      Begin
        Temp := Fetch();
        For I:=0 To Size Do
        Begin
          _Registers[Arg1]:= Temp;
          Inc(Arg1, SOL_REG_PAD);
        End;
      End;

    SOLOP_INT_INC:
      Begin
        For I:=0 To Size Do
        Begin
          Inc(_Registers[Arg1], Arg2);
          Inc(Arg1, SOL_REG_PAD);
        End;
      End;

    SOLOP_INT_DEC:
      Begin
        For I:=0 To Size Do
        Begin
          Dec(_Registers[Arg1], Arg2);
          Inc(Arg1, SOL_REG_PAD);
        End;
      End;

    SOLOP_INT_ADD:
      Begin
        For I:=0 To Size Do
        Begin
          _Registers[Arg3] := _Registers[Arg1] + _Registers[Arg2];

          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg2, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_INT_SUB:
      Begin
        For I:=0 To Size Do
        Begin
        _Registers[Arg3] := _Registers[Arg1] - _Registers[Arg2];
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg2, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_INT_MUL:
      Begin
        For I:=0 To Size Do
        Begin
          _Registers[Arg3] := _Registers[Arg1] * _Registers[Arg2];
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg2, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_INT_DIV:
      Begin
        For I:=0 To Size Do
        Begin
          _Registers[Arg3] := _Registers[Arg1] Div _Registers[Arg2];
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg2, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_INT_MOD:
      Begin
        For I:=0 To Size Do
        Begin
          _Registers[Arg3] := _Registers[Arg1] Mod _Registers[Arg2];
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg2, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_MOVE:
      Begin
        Temp := _Registers[Arg1];
        Temp := SOL_Float_Pack(Temp);

        For I:=0 To Size Do
        Begin
          _Registers[Arg3] := Temp;
          Inc(Arg1, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_TRUNC:
      Begin
        F1 := SOL_Float_Unpack(_Registers[Arg1]);

        For I:=0 To Size Do
        Begin
          _Registers[Arg3] := Trunc(F1);
          Inc(Arg1, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_ROUND:
      Begin
        F1 := SOL_Float_Unpack(_Registers[Arg1]);

        For I:=0 To Size Do
        Begin
          _Registers[Arg3] := Round(F1);
          Inc(Arg1, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_ADD:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          F2 := SOL_Float_Unpack(_Registers[Arg2]);
          _Registers[Arg3] := SOL_Float_Pack(F1 + F2);
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg2, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;

      End;

    SOLOP_FLOAT_SUB:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          F2 := SOL_Float_Unpack(_Registers[Arg2]);
          _Registers[Arg3] := SOL_Float_Pack(F1 - F2);
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg2, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_MUL:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          F2 := SOL_Float_Unpack(_Registers[Arg2]);
          _Registers[Arg3] := SOL_Float_Pack(F1 * F2);
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg2, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_DIV:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          F2 := SOL_Float_Unpack(_Registers[Arg2]);

          If F2<>0.0 Then
            F1 := F1 / F2
          Else
            F1 := 0.0;

          _Registers[Arg3] := SOL_Float_Pack(F1);
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg2, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

   SOLOP_FLOAT_MOD:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          F2 := SOL_Float_Unpack(_Registers[Arg2]);

          If F2<>0.0 Then
            F1 := FloatMod(F1, F2)
          Else
            F1 := 0.0;

          _Registers[Arg3] := SOL_Float_Pack(F1);
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg2, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_SQRT:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          _Registers[Arg3] := SOL_Float_Pack(Sqrt(F1));
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_INV_SQRT:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          _Registers[Arg3] := SOL_Float_Pack(InvSqrt(F1));
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_LOG:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          _Registers[Arg3] := SOL_Float_Pack(Log2(F1));
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_POW:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          F2 := SOL_Float_Unpack(_Registers[Arg2]);

          _Registers[Arg3] := SOL_Float_Pack(Power(F1, F2));
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg2, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_COS:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          _Registers[Arg3] := SOL_Float_Pack(Cos(F1));
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_SIN:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          _Registers[Arg3] := SOL_Float_Pack(Sin(F1));
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_TAN:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          _Registers[Arg3] := SOL_Float_Pack(Tan(F1));
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_ARCCOS:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          _Registers[Arg3] := SOL_Float_Pack(ArcCos(F1));
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_ARCSIN:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          _Registers[Arg3] := SOL_Float_Pack(ArcSin(F1));
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_ARCTAN:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          _Registers[Arg3] := SOL_Float_Pack(ArcTan(F1));
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_ATAN2:
      Begin
        For I:=0 To Size Do
        Begin
          F1 := SOL_Float_Unpack(_Registers[Arg1]);
          F2 := SOL_Float_Unpack(_Registers[Arg2]);
          _Registers[Arg3] := SOL_Float_Pack(ATan2(F1, F2));
          Inc(Arg1, SOL_REG_PAD);
          Inc(Arg2, SOL_REG_PAD);
          Inc(Arg3, SOL_REG_PAD);
        End;
      End;

    SOLOP_FLOAT_LENGTH:
      If (Size = 0) Then
      Begin
        F1 := SOL_Float_Unpack(_Registers[Arg1]);
        _Registers[Arg3] := SOL_Float_Pack(Abs(F1));
      End Else
      Begin
        F1 := 0.0;
        For I:=0 To Size Do
        Begin
          F2 := SOL_Float_Unpack(_Registers[Arg1]);
          F1 := F1 + Sqr(F2);
          Inc(Arg1, SOL_REG_PAD);
        End;

        _Registers[Arg3] := SOL_Float_Pack(Sqrt(F1));
      End;

    SOLOP_THREAD_YIELD:
      Begin
        Result := True;
        Break;
      End;

    SOLOP_AND:
      Begin
        _Registers[Arg3] := _Registers[Arg1] And _Registers[Arg2];
      End;

    SOLOP_OR:
      Begin
        _Registers[Arg3] := _Registers[Arg1] Or _Registers[Arg2];
      End;

    SOLOP_XOR:
      Begin
        _Registers[Arg3] := _Registers[Arg1] Xor _Registers[Arg2];
      End;

     SOLOP_NOT:
      Begin
        _Registers[Arg3] := Not _Registers[Arg1];
      End;

    SOLOP_SHR:
      Begin
        _Registers[Arg3] := _Registers[Arg1] Shr _Registers[Arg2];
      End;

    SOLOP_SHL:
      Begin
        _Registers[Arg3] := _Registers[Arg1] Shl _Registers[Arg2];
      End;

    SOLOP_JMP:
      Begin
        _Registers[SOL_POSITION_REG] := Fetch();
      End;

    SOLOP_JMP_ZERO:
      Begin
        Temp := Fetch();
        If (_Registers[Arg1] = 0) Then
          _Registers[SOL_POSITION_REG] := Temp;
      End;

    SOLOP_JMP_EQUAL:
      Begin
        Temp := Fetch();
        If (_Registers[Arg1] = _Registers[Arg2]) Then
          _Registers[SOL_POSITION_REG] := Temp;
      End;

    SOLOP_JMP_DIFF:
      Begin
        Temp := Fetch();
        If (_Registers[Arg1] <> _Registers[Arg2]) Then
          _Registers[SOL_POSITION_REG] := Temp;
      End;

    SOLOP_JMP_LESS:
      Begin
        Temp := Fetch();
        If (_Registers[Arg1] < _Registers[Arg2]) Then
          _Registers[SOL_POSITION_REG] := Temp;
      End;

    SOLOP_JMP_LESS_EQUAL:
      Begin
        Temp := Fetch();
        If (_Registers[Arg1] <= _Registers[Arg2]) Then
          _Registers[SOL_POSITION_REG] := Temp;
      End;

    SOLOP_JMP_GREAT:
      Begin
        Temp := Fetch();
        If (_Registers[Arg1] > _Registers[Arg2]) Then
          _Registers[SOL_POSITION_REG] := Temp;
      End;

    SOLOP_JMP_GREAT_EQUAL:
      Begin
        Temp := Fetch();
        If (_Registers[Arg1] >= _Registers[Arg2]) Then
          _Registers[SOL_POSITION_REG] := Temp;
      End;

    End;
  Until False;
End;

Function SOL_Thread.Pop: SOL_Register;
Var
  Pos:Cardinal;
Begin
  Pos := _Registers[SOL_STACK_REG];
  If (Pos <= 0) Then
  Begin
    Result := 0;
    Exit;
  End;

  Dec(Pos);
  Result := _Stack[Pos];
  _Registers[SOL_STACK_REG] := Pos;
End;

Procedure SOL_Thread.Push(const Val: SOL_Register);
Var
  Pos:Cardinal;
Begin
  Pos := _Registers[SOL_STACK_REG];
  If (Pos>=_StackSize) Then
    Exit;

  _Stack[Pos] := Val;
  Inc(Pos);
  _Registers[SOL_STACK_REG] := Pos;
End;

{ SOL_Process }
Constructor SOL_Process.Create;
Begin
  _CurrentThread := Self.CreateThread(0);
End;

Procedure SOL_Process.AddInstruction(Inst: SOL_Instruction);
Var
  N:Integer;
Begin
  N := _InstructionCount;
  Inc(_InstructionCount);
  SetLength(_Instructions, _InstructionCount);
  _Instructions[N] := Inst;
End;

Function SOL_Process.CreateThread(Pos: Cardinal): SOL_Thread;
Var
  N:Integer;
Begin
  N := _ThreadCount;
  Inc(_ThreadCount);
  Result := SOL_Thread.Create(Self, Pos, SOL_DEFAULT_STACK_SIZE);

  SetLength(_Threads, _ThreadCount);
  _Threads[N] := Result;
End;

Function SOL_Process.Fetch(Pos: Cardinal): SOL_Instruction;
Begin
  If (Pos >= _InstructionCount) Then
    Result := SOLOP_STOP
  Else
    Result := _Instructions[Pos];
End;

Function SOL_Process.RegisterFunction(Const Name:SOL_String; Address:Pointer; ArgCount:Cardinal; Convention:SOL_NativeCallConvention):Cardinal;
Begin
  Result := _NativeFunctionCount;
  Inc(_NativeFunctionCount);
  SetLength(_NativeFunctions, _NativeFunctionCount);

  _NativeFunctions[Result].Name := Name;
  _NativeFunctions[Result].Address := Address;
  _NativeFunctions[Result].ArgCount := ArgCount;
  _NativeFunctions[Result].Convention := Convention;
End;

procedure SOL_Process.Release;
Begin
End;

Function SOL_Process.Run:Cardinal;
Begin
  Result := 0;

  Repeat
    If (Not _CurrentThread.Run(Result)) Then
    Begin
      Break;
    End;
  Until False;
End;

Type
  NativeFunction1 = Function (Arg1:Cardinal):Cardinal;
  NativeFunction2 = Function (Arg1, Arg2:Cardinal):Cardinal;
  NativeFunction3 = Function (Arg1, Arg2, Arg3:Cardinal):Cardinal;

Function SOL_Process.Invoke(Index: Cardinal): Cardinal;
Var
  Arg1, Arg2, Arg3, Arg4:Cardinal;
Begin
  Result := 0;

  If (Index>= _NativeFunctionCount) Then
    Exit;

  Case _NativeFunctions[Index].ArgCount Of
  1:Begin
      Arg1 := _CurrentThread.Pop();
      Result := NativeFunction1(_NativeFunctions[Index].Address)(Arg1);
    End;

  2:Begin
      Arg2 := _CurrentThread.Pop();
      Arg1 := _CurrentThread.Pop();
      Result := NativeFunction2(_NativeFunctions[Index].Address)(Arg1, Arg2);
    End;

  3:Begin
      Arg3 := _CurrentThread.Pop();
      Arg2 := _CurrentThread.Pop();
      Arg1 := _CurrentThread.Pop();
      Result := NativeFunction3(_NativeFunctions[Index].Address)(Arg1, Arg2, Arg3);
    End;
  End;
End;

End.