-- ----------------------------------------------------------------------------
--
--  Copyright (C) 2012, 2013, 2014 Stephen Leake
--  Copyright (C) 1999 Christoph Karl Walter Grein
--
--  This file is part of the OpenToken package.
--
--  The OpenToken package is free software; you can redistribute it and/or
--  modify it under the terms of the  GNU General Public License as published
--  by the Free Software Foundation; either version 3, or (at your option)
--  any later version. The OpenToken package is distributed in the hope that
--  it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for  more details.  You should have received
--  a copy of the GNU General Public License  distributed with the OpenToken
--  package;  see file GPL.txt.  If not, write to  the Free Software Foundation,
--  59 Temple Place - Suite 330,  Boston, MA 02111-1307, USA.
--
--  As a special exception, if other files instantiate generics from
--  this unit, or you link this unit with other files to produce an
--  executable, this unit does not by itself cause the resulting
--  executable to be covered by the GNU General Public License. This
--  exception does not however invalidate any other reasons why the
--  executable file might be covered by the GNU Public License.
-- ----------------------------------------------------------------------------

with Ada.Strings.Maps.Constants;
with OpenToken.Recognizer.Based_Integer_Java_Style;
with OpenToken.Recognizer.Bracketed_Comment;
with OpenToken.Recognizer.Character_Set;
with OpenToken.Recognizer.End_Of_File;
with OpenToken.Recognizer.Escape_Sequence;
with OpenToken.Recognizer.Graphic_Character;
with OpenToken.Recognizer.Identifier;
with OpenToken.Recognizer.Integer;
with OpenToken.Recognizer.Keyword;
with OpenToken.Recognizer.Line_Comment;
with OpenToken.Recognizer.Octal_Escape;
with OpenToken.Recognizer.Real;
with OpenToken.Recognizer.Separator;
with OpenToken.Recognizer.String;
with OpenToken.Token.Enumerated.Analyzer;

package Java_Lexer is

   ---------------------------------------------------------------------
   --  This ia a lexical analyser for the Java language.
   --  In the current preliminary state, not all tokens are recognized.
   --
   --  Missing:
   --   Numerals with suffixes
   --     integer suffixes l L
   --     float suffixes d D f F
   --
   --  There is another lexer for the Ada and Java languages at:
   --   <http://home.T-Online.de/home/Christ-Usch.Grein/Ada/Lexer.html>
   ---------------------------------------------------------------------

   type Java_Token is
     (
      --  Keywords JRM 3.9
      Abstract_T,
      Boolean_T, Break_T, Byte_T,
      Case_T, Catch_T, Char_T, Class_T, Const_T, Continue_T,
      Default_T, Do_T, Double_T,
      Else_T, Extends_T,
      Final_T, Finally_T, Float_T, For_T,
      Goto_T,
      If_T, Implements_T, Import_T, InstanceOf_T, Int_T, Interface_T,
      Long_T,
      Native_T, New_T,
      Package_T, Private_T, Protected_T, Public_T,
      Return_T,
      Short_T, Static_T, Super_T, Switch_T, Synchronized_T,
      This_T, Throw_T, Throws_T, Transient_T, Try_T,
      Void_T, Volatile_T,
      While_T,
      --  Separators JRM 3.11
      --  ( ) { } [ ] ; , .
      --  Operators JRM 3.12
      --  =  >  <  !  ~  ?  :
      -- == <= >= != && || ++ --
      --  +  -  *  /  &  |  ^  %  <<  >>  >>>
      --  += -= *= /= &= |= ^= %= <<= >>= >>>=
      Colon_T, Comma_T, Dot_T, Semicolon_T,             -- : , . ;
      LeftBrace_T, RightBrace_T,                        -- { }
      LeftBracket_T, RightBracket_T,                    -- [ ]
      Left_Parenthesis_T, Right_Parenthesis_T,          -- ( )
      And_T, Or_T,                                      -- & |
      ShortCutAnd_T, ShortCutOr_T,                      -- && ||
      Assignment_T, Conditional_T,                      -- = ?
      Equal_T, NotEqual_T,                              -- == !=
      Greater_Equal_T, Less_Equal_T,                    -- >= <=
      Greater_Than_T, Less_Than_T,                      -- > <
      Complement_T, Not_T, Xor_T,                       -- ~ ! ^
      Plus_T, Minus_T, Times_T, Divide_T, Remainder_T,  -- + - * / %
      Increment_T, Decrement_T,                         -- ++ --
      LeftShift_T, RightShift_T, UnsignedRightShift_T,  -- << >> >>>
      PlusAssign_T, MinusAssign_T,                      -- += -=
      TimesAssign_T, DivideAssign_T, RemainderAssign_T, -- *= /= %=
      AndAssign_T, OrAssign_T, XorAssign_T,             -- &= |= ^=
      LeftShiftAssign_T, RightShiftAssign_T,            -- <<= >>=
      UnsignedRightShiftAssign_T,                       -- >>>=
      --  Literals (JRM 3.10) (all Java reals may use lazy forms,
      --  i.e. the whole or decimal part may be missing)
      Null_T, False_T, True_T,
      Integer_T,           -- 1
      Based_Integer_T,     -- 07, 0xF
      --  LongInteger_T,       -- 1L
      --  BasedLongInteger_T,  -- 07L, 0xFL
      Real_T,              -- 1.0, 1., .1, 1E+7
      --  FloatNumber_T,       -- 1.0E+10F
      --  DoubleNumber_T,      -- 1.0E+10D
      Character_T,         -- 'x' with x any graphic character except one of "'\
      Escape_Sequence_T,   -- '\x' with x one of btnfr"'\
      Octal_Escape_T,      -- '\377'
      String_T,            -- "Any characters except " or \ and escape sequences"
      --  Other tokens
      Identifier_T,
      Annotation_T,
      EndOfLineComment_T,  -- // to end of line
      EmbeddedComment_T,   -- /* anything (even several lines) */
      Whitespace_T,
      --  Syntax error
      --  Bad_Token_T,
      --
      End_of_File_T);

   package Master_Java_Token is new OpenToken.Token.Enumerated
     (Java_Token, Java_Token'First, Java_Token'Last, Java_Token'Image);
   package Tokenizer is new Master_Java_Token.Analyzer;

   Syntax : constant Tokenizer.Syntax :=
     (Abstract_T                       => Tokenizer.Get
        (OpenToken.Recognizer.Keyword.Get
           ("abstract", Case_Sensitive => True)),
      Boolean_T                        => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("boolean", True)),
      Break_T                          => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("break", True)),
      Byte_T                           => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("byte", True)),
      Case_T                           => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("case", True)),
      Catch_T                          => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("catch", True)),
      Char_T                           => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("char", True)),
      Class_T                          => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("class", True)),
      Const_T                          => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("const", True)),
      Continue_T                       => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("continue", True)),
      Default_T                        => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("default", True)),
      Do_T                             => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("do", True)),
      Double_T                         => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("double", True)),
      Else_T                           => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("else", True)),
      Extends_T                        => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("extends", True)),
      Final_T                          => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("final", True)),
      Finally_T                        => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("finally", True)),
      Float_T                          => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("float", True)),
      For_T                            => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("for", True)),
      Goto_T                           => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("goto", True)),
      If_T                             => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("if", True)),
      Implements_T                     => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("implements", True)),
      Import_T                         => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("import", True)),
      InstanceOf_T                     => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("instanceof", True)),
      Int_T                            => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("int", True)),
      Interface_T                      => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("interface", True)),
      Long_T                           => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("long", True)),
      Native_T                         => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("native", True)),
      New_T                            => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("new", True)),
      Package_T                        => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("package", True)),
      Private_T                        => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("private", True)),
      Protected_T                      => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("protected", True)),
      Public_T                         => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("public", True)),
      Return_T                         => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("return", True)),
      Short_T                          => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("short", True)),
      Static_T                         => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("static", True)),
      Super_T                          => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("super", True)),
      Switch_T                         => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("switch", True)),
      Synchronized_T                   => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("synchronized", True)),
      This_T                           => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("this", True)),
      Throw_T                          => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("throw", True)),
      Throws_T                         => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("throws", True)),
      Transient_T                      => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("transient", True)),
      Try_T                            => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("try", True)),
      Void_T                           => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("void", True)),
      Volatile_T                       => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("volatile", True)),
      While_T                          => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("while", True)),
      Colon_T                          => Tokenizer.Get (OpenToken.Recognizer.Separator.Get (":")),
      Comma_T                          => Tokenizer.Get (OpenToken.Recognizer.Separator.Get (",")),
      Dot_T                            => Tokenizer.Get (OpenToken.Recognizer.Separator.Get (".")),
      Semicolon_T                      => Tokenizer.Get (OpenToken.Recognizer.Separator.Get (";")),
      LeftBrace_T                      => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("{")),
      RightBrace_T                     => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("}")),
      LeftBracket_T                    => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("[")),
      RightBracket_T                   => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("]")),
      Left_Parenthesis_T               => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("(")),
      Right_Parenthesis_T              => Tokenizer.Get (OpenToken.Recognizer.Separator.Get (")")),
      And_T                            => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("&")),
      Or_T                             => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("|")),
      ShortCutAnd_T                    => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("&&")),
      ShortCutOr_T                     => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("||")),
      Assignment_T                     => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("=")),
      Conditional_T                    => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("?")),
      Equal_T                          => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("==")),
      NotEqual_T                       => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("!=")),
      Greater_Equal_T                  => Tokenizer.Get (OpenToken.Recognizer.Separator.Get (">=")),
      Less_Equal_T                     => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("<=")),
      Greater_Than_T                   => Tokenizer.Get (OpenToken.Recognizer.Separator.Get (">")),
      Less_Than_T                      => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("<")),
      Complement_T                     => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("~")),
      Not_T                            => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("!")),
      Xor_T                            => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("^")),
      Plus_T                           => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("+")),
      Minus_T                          => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("-")),
      Times_T                          => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("*")),
      Divide_T                         => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("/")),
      Remainder_T                      => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("%")),
      Increment_T                      => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("++")),
      Decrement_T                      => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("--")),
      LeftShift_T                      => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("<<")),
      RightShift_T                     => Tokenizer.Get (OpenToken.Recognizer.Separator.Get (">>")),
      UnsignedRightShift_T             => Tokenizer.Get (OpenToken.Recognizer.Separator.Get (">>>")),
      PlusAssign_T                     => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("+=")),
      MinusAssign_T                    => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("-=")),
      TimesAssign_T                    => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("*=")),
      DivideAssign_T                   => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("/=")),
      RemainderAssign_T                => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("%=")),
      AndAssign_T                      => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("&=")),
      OrAssign_T                       => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("|=")),
      XorAssign_T                      => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("^=")),
      LeftShiftAssign_T                => Tokenizer.Get (OpenToken.Recognizer.Separator.Get ("<<=")),
      RightShiftAssign_T               => Tokenizer.Get (OpenToken.Recognizer.Separator.Get (">>=")),
      UnsignedRightShiftAssign_T       => Tokenizer.Get (OpenToken.Recognizer.Separator.Get (">>>=")),
      Null_T                           => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("null",  True)),
      False_T                          => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("false", True)),
      True_T                           => Tokenizer.Get (OpenToken.Recognizer.Keyword.Get ("true",  True)),
      Integer_T                        => Tokenizer.Get
        (OpenToken.Recognizer.Integer.Get
           (Allow_Underscores          => False,
            Allow_Exponent             => False,
            Allow_Signs                => False,
            Allow_Leading_Zero         => False)),
      Based_Integer_T                  => Tokenizer.Get (OpenToken.Recognizer.Based_Integer_Java_Style.Get),
      Real_T                           => Tokenizer.Get
        (OpenToken.Recognizer.Real.Get
           (Allow_Underscores          => False,
            Allow_Signs                => False,
            Allow_Laziness             => True)),
      Annotation_T                     => Tokenizer.Get
        (OpenToken.Recognizer.Identifier.Get
           (Start_Chars                => Ada.Strings.Maps.To_Set ('@'),
            Body_Chars                 => Ada.Strings.Maps.Constants.Alphanumeric_Set)),
      Identifier_T                     => Tokenizer.Get
        (OpenToken.Recognizer.Identifier.Get
           (Start_Chars                => Ada.Strings.Maps.Constants.Letter_Set,
            Body_Chars                 => Ada.Strings.Maps.Constants.Alphanumeric_Set)),
      Character_T                      => Tokenizer.Get
        (OpenToken.Recognizer.Graphic_Character.Get
           (Exclude                    => Ada.Strings.Maps.To_Set ("""'\"))),
      Escape_Sequence_T                => Tokenizer.Get
        (OpenToken.Recognizer.Escape_Sequence.Get (Ada.Strings.Maps.To_Set ("btnfr""'\"))),
      Octal_Escape_T                   => Tokenizer.Get (OpenToken.Recognizer.Octal_Escape.Get),
      String_T                         => Tokenizer.Get
        (OpenToken.Recognizer.String.Get
           (Escapeable                 => True,
            Double_Delimiter           => False,
            Escape_Mapping             => OpenToken.Recognizer.String.Java_Style_Escape_Code_Map)),
      EndOfLineComment_T               => Tokenizer.Get (OpenToken.Recognizer.Line_Comment.Get ("//")),
      EmbeddedComment_T                => Tokenizer.Get (OpenToken.Recognizer.Bracketed_Comment.Get ("/*", "*/")),
      Whitespace_T                     => Tokenizer.Get
        (OpenToken.Recognizer.Character_Set.Get (OpenToken.Recognizer.Character_Set.Standard_Whitespace)),
      End_of_File_T                    => Tokenizer.Get (OpenToken.Recognizer.End_Of_File.Get));

   Analyzer : constant Tokenizer.Handle := Tokenizer.Initialize (Syntax,
                                                                 Buffer_Size => 8192);

end Java_Lexer;
