------------------------------------------------------------------------------
--                                                                          --
--                             GPR TECHNOLOGY                               --
--                                                                          --
--                       Copyright (C) 2015, AdaCore                        --
--                                                                          --
-- This is  free  software;  you can redistribute it and/or modify it under --
-- terms of the  GNU  General Public License as published by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for more details.  You should have received  a copy of the  GNU  --
-- General Public License distributed with GNAT; see file  COPYING. If not, --
-- see <http://www.gnu.org/licenses/>.                                      --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Command_Line; use Ada.Command_Line;

with GNAT.OS_Lib; use GNAT.OS_Lib;

with GPR; use GPR;
with GPR.ALI; use GPR.ALI;
with GPR.Env;
with GPR.Osint; use GPR.Osint;
with GPR.Tree;  use GPR.Tree;

package Gprls is

private

   Initialized : Boolean := False;
   --  Set to True by the first call to Initialize.
   --  To avoid reinitialization of some packages.

   Save_Verbose : Boolean := False;

   Project_Search_Path : constant String := "Project Search Path:";
   --  Label displayed in verbose mode before the directories in the project
   --  search path. Do not modify without checking NOTE above.

   Prj_Path : GPR.Env.Project_Search_Path;

   Max_Column : constant := 80;

   No_Obj : aliased String := "<no_obj>";

   No_Runtime : Boolean := False;
   --  Set to True if there is no default runtime and --RTS= is not specified

   type File_Status is (
     OK,                  --  matching timestamp
     Checksum_OK,         --  only matching checksum
     Not_Found,           --  file not found on source PATH
     Not_Same);           --  neither checksum nor timestamp matching

   type Dir_Data;
   type Dir_Ref is access Dir_Data;

   type Dir_Data is record
      Value : String_Access;
      Next  : Dir_Ref;
   end record;
   --  Simply linked list of dirs

   First_Source_Dir : Dir_Ref;
   Last_Source_Dir  : Dir_Ref;
   --  The list of source directories from the command line.
   --  These directories are added using Osint.Add_Src_Search_Dir
   --  after those of the GNAT Project File, if any.

   First_Lib_Dir : Dir_Ref;
   Last_Lib_Dir  : Dir_Ref;
   --  The list of object directories from the command line.
   --  These directories are added using Osint.Add_Lib_Search_Dir
   --  after those of the GNAT Project File, if any.

   Main_File : File_Name_Type;
   Ali_File  : File_Name_Type;
   Text      : Text_Buffer_Ptr;
   Next_Arg  : Positive;

   Too_Long : Boolean := False;
   --  When True, lines are too long for multi-column output and each
   --  item of information is on a different line.

   Selective_Output : Boolean := False;
   Print_Usage      : Boolean := False;
   Print_Unit       : Boolean := True;
   Print_Source     : Boolean := True;
   Print_Object     : Boolean := True;
   --  Flags controlling the form of the output

   Dependable        : Boolean := False;  --  -d
   --  Command line flags

   Unit_Start   : Integer;
   Unit_End     : Integer;
   Source_Start : Integer;
   Source_End   : Integer;
   Object_Start : Integer;
   Object_End   : Integer;
   --  Various column starts and ends

   Spaces : constant String (1 .. Max_Column) := (others => ' ');

   RTS_Specified : String_Access := null;
   --  Used to detect multiple use of --RTS= switch

   Exit_Status : Exit_Code_Type := E_Success;
   --  Reset to E_Fatal if bad error found

   type File_Name_Source is record
      File_Name : String_Access;
      Source    : GPR.Source_Id;
      The_ALI   : ALI_Id;
   end record;

   type File_Name_Array is array (Positive range <>) of File_Name_Source;
   type File_Name_Array_Ptr is access File_Name_Array;
   File_Names : File_Name_Array_Ptr :=
                  new File_Name_Array (1 .. Argument_Count + 2);
   --  As arguments are scanned, file names are stored in this array. The array
   --  is extensible, because there may be more files than arguments on the
   --  command line.

   Number_File_Names : Natural := 0;
   --  Number of file names found on command line and placed in File_Names

   Tree : constant Project_Node_Tree_Ref := new Project_Node_Tree_Data;
   --  The project tree where the project file is parsed

   Root_Environment : GPR.Tree.Environment;

   --  Packages of project files where unknown attributes are errors

   Naming_String   : aliased String := "naming";
   Builder_String  : aliased String := "builder";
   Compiler_String : aliased String := "compiler";
   Binder_String   : aliased String := "binder";
   Linker_String   : aliased String := "linker";
   --  Name of packages to be checked when parsing/processing project files

   List_Of_Packages : aliased String_List :=
                        (Naming_String'Access,
                         Builder_String'Access,
                         Compiler_String'Access,
                         Binder_String'Access,
                         Linker_String'Access);
   Packages_To_Check : constant String_List_Access := List_Of_Packages'Access;
   --  List of the packages to be checked when parsing/processing project files

   procedure Add_File
     (File_Name : String; Source : GPR.Source_Id := No_Source);
   --  Add File_Name to File_Names

   procedure Find_General_Layout;
   --  Determine the structure of the output (multi columns or not, etc)

   function Corresponding_Sdep_Entry (A : ALI_Id; U : Unit_Id) return Sdep_Id;
   --  Give the Sdep entry corresponding to the unit U in ali record A

   procedure Output_Status (FS : File_Status; Verbose : Boolean);
   --  Print out FS either in a coded form if verbose is false or in an
   --  expanded form otherwise.

   procedure Reset_Print;
   --  Reset Print flags properly when selective output is chosen

   --  procedure Search_RTS (Name : String);
   --  Find include and objects path for the RTS name.

   Project_Tree : constant Project_Tree_Ref :=
                    new Project_Tree_Data (Is_Root_Tree => True);
   --  The project tree

end Gprls;