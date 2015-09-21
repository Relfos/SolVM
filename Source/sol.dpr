Program soltest;

{$APPTYPE CONSOLE}
Uses TERRA_Object, TERRA_Utils, TERRA_String, SolVM;

Function SumInt(Thread:SOL_Thread):SOL_Register;
Var
  A, B:Cardinal;
Begin
  B := Thread.Pop();
  A := Thread.Pop();
  Result := A + B;
End;

Function SumFloat(Thread:SOL_Thread):SOL_Register;
Var
  A, B:Cardinal;
Begin
  B := Thread.Pop();
  A := Thread.Pop();
  Result := SOL_Float_Pack(SOL_Float_Unpack(A) + SOL_Float_Unpack(B));
End;

Function Print(Thread:SOL_Thread):SOL_Register;
Var
  X:Cardinal;
  F:Single;
Begin
  Result := 0;
  X := Thread.Pop();
  F := SOL_Float_Unpack(X);
  WriteLn('Result = ', X);
  WriteLn('Result = ', FloatProperty.Stringify(F));
End;

Var
  Proc:SOL_Module;
  N:Integer;
Begin
  Proc := SOL_Module.Create();

  // sum two numbers
(*  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG0));
  Proc.AddInstruction(3);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG1));
  Proc.AddInstruction(5);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_INT_ADD, SOL_REG0, SOL_REG1, SOL_RESULT_REG));

  // sum two floats
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG0));
  Proc.AddInstruction(SOL_Float_Pack(3.14159));
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG1));
  Proc.AddInstruction(SOL_Float_Pack(2.0));
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_FLOAT_ADD, SOL_REG0, SOL_REG1, SOL_RESULT_REG));*)

  // native call test
(*  Proc.RegisterFunction('print', @Print, 1);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG0));
  Proc.AddInstruction(3);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG1));
  Proc.AddInstruction(5);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_INT_ADD, SOL_REG0, SOL_REG1, SOL_REG2));

  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_PUSH, SOL_REG2));
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG1));
  Proc.AddInstruction(0);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CALL, SOL_REG1));

  // native call test2
  Proc.RegisterFunction('print', @Print, 1);
  Proc.RegisterFunction('sum', @SumInt, 2);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG0));
  Proc.AddInstruction(2);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG1));
  Proc.AddInstruction(5);

  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_PUSH, SOL_REG0));
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_PUSH, SOL_REG1));

  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG1));
  Proc.AddInstruction(1);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CALL, SOL_REG1, 0, SOL_REG0));
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_PUSH, SOL_REG0));

  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG1));
  Proc.AddInstruction(0);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CALL, SOL_REG1));
*)

  // native call test3
  Proc.RegisterFunction('print', Print);
  Proc.RegisterFunction('sum', SumFloat);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG0));
  Proc.AddInstruction(SOL_Float_Pack(2.5));
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG1));
  Proc.AddInstruction(SOL_Float_Pack(4.5));

  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_PUSH, SOL_REG0));
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_PUSH, SOL_REG1));

  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG1));
  Proc.AddInstruction(1);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CALL, SOL_REG1, 0, SOL_REG0));
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_PUSH, SOL_REG0));

  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG1));
  Proc.AddInstruction(0);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CALL, SOL_REG1));



  // abs() test
(*  Proc.RegisterFunction('print', @Print, 1);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG0));
  Proc.AddInstruction(SOL_Float_Pack(-15.2));
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_FLOAT_ABS, SOL_REG0, 0, SOL_REG2));
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_PUSH, SOL_REG2));
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CONST, SOL_REG1));
  Proc.AddInstruction(0);
  Proc.AddInstruction(SOL_EncodeInstruction(SOLOP_CALL, SOL_REG1));*)

  N := Proc.Run();

  ReleaseObject(Proc);

  ReadLn;
End.