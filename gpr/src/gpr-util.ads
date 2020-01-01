------------------------------------------------------------------------------
--                                                                          --
--                           GPR PROJECT MANAGER                            --
--                                                                          --
--          Copyright (C) 2001-2020, Free Software Foundation, Inc.         --
--                                                                          --
-- This library is free software;  you can redistribute it and/or modify it --
-- under terms of the  GNU General Public License  as published by the Free --
-- Software  Foundation;  either version 3,  or (at your  option) any later --
-- version. This library is distributed in the hope that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE.                            --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
------------------------------------------------------------------------------

--  Utilities for use in processing project files

with Ada.Calendar;                      use Ada;
with Ada.Containers.Indefinite_Vectors;

with GNAT.MD5; use GNAT.MD5;

with GPR.ALI;
with GPR.Osint; use GPR.Osint;
with GPR.Scans; use GPR.Scans;

package GPR.Util is

   package String_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, String);
   --  General-purpose vector of strings

   type String_Vector_Access is access all String_Vectors.Vector;

   type Config_Paths is array (Positive range <>) of Path_Name_Type;
   --  type used in Need_To_Compile

   Default_Config_Name : constant String := "default.cgpr";
   --  Name of the configuration file used by gprbuild and generated by
   --  gprconfig by default.

   Load_Standard_Base : Boolean := True;
   --  False when gprbuild is called with --db-

   procedure Set_Program_Name (N : String);
   --  Indicate the executable name, so that it can be displayed with
   --  Write_Program_Name below.

   procedure Write_Program_Name;
   --  Display the name of the executable in error mesages

   procedure Set_Gprls_Mode;
   --  Set Gprls_Mode to True

   procedure Check_Maximum_Processes;
   --  Check that the maximum number of simultaneous processes is not too large
   --  for the platform.

   --------------
   -- Closures --
   --------------

   type Status_Type is
     (Success,
      Unknown_Error,
      Invalid_Project,
      No_Main,
      Invalid_Main,
      Incomplete_Closure);

   procedure Get_Closures
     (Project                  : Project_Id;
      In_Tree                  : Project_Tree_Ref;
      Mains                    : String_Vectors.Vector;
      All_Projects             : Boolean := True;
      Include_Externally_Built : Boolean := False;
      Status                   : out Status_Type;
      Result                   : out String_Vectors.Vector);
   --  Return the list of source files in the closures of the Ada Mains in
   --  Result.
   --  The project and its project tree must have been parsed and processed.
   --  Mains is a list of single file names that are Ada sources of the project
   --  Project or of its subprojects.
   --  When All_Projects is False, the Mains must be sources of the Project and
   --  the sources of the closures that are sources of the imported subprojects
   --  are not included in the returned list.
   --  When All_Projects is True, mains may also be found in subprojects,
   --  including aggregated projects when Project is an aggregate project.
   --  When All_Projects is True, sources in the closures that are sources of
   --  externally built subprojects are included in the returned list only when
   --  Include_Externally_Built is True.
   --  Result is the list of path names in the closures.
   --  It is the responsibility of the caller to deallocate the Strings in
   --  Result and Result itself.
   --  When all the sources in the closures are found, Result is non null and
   --  Status is Success.
   --  When only a subset of the sources in the closures are found, Result is
   --  non null and Status is Incomplete_Closure.
   --  When there are other problems, Result is null and Status is different
   --  from Success or Incomplete_Closure.

   -------------------------
   -- Program termination --
   -------------------------

   procedure Fail_Program
     (Project_Tree   : Project_Tree_Ref;
      Message        : String;
      Flush_Messages : Boolean := True;
      No_Message     : Boolean := False;
      Command        : String := "");
   --  Terminate program with a message and a fatal status code. Do not issue
   --  any message when No_Message is True.

   procedure Finish_Program
     (Project_Tree : Project_Tree_Ref;
      Exit_Code    : Exit_Code_Type := E_Success;
      Message      : String := "";
      No_Message   : Boolean := False;
      Command      : String := "");
   --  Terminate program, with or without a message, setting the status code
   --  according to Exit_Code. This properly removes all temporary files. Don't
   --  issue any message when No_Message is True.

   procedure Compilation_Phase_Failed
     (Project_Tree : Project_Tree_Ref; No_Message : Boolean := False);
   --  Terminate program with "*** compilation phase failed" message and a
   --  fatal status code. Don't issue any message when No_Message is True.

   procedure Duplicate
     (This   : in out Name_List_Index;
      Shared : Shared_Project_Tree_Data_Access);
   --  Duplicate a name list

   function Executable_Of
     (Project        : Project_Id;
      Shared         : Shared_Project_Tree_Data_Access;
      Main           : File_Name_Type;
      Index          : Int;
      Language       : String := "";
      Include_Suffix : Boolean := True) return File_Name_Type;
   --  Return the value of the attribute Builder'Executable for file Main in
   --  the project Project, if it exists. If there is no attribute Executable
   --  for Main, remove the suffix from Main; then, when Include_Suffix
   --  is True, if the attribute Executable_Suffix is specified in package
   --  Builder, add this suffix. Attribute Executable_Suffix is either
   --  declared in the user project file or, for some platforms, in the
   --  configuration project file (for example ".exe" on Windows).

   procedure Expect (The_Token : Token_Type; Token_Image : String);
   --  Check that the current token is The_Token. If it is not, then output
   --  an error message.

   function Executable_Prefix_Path return String;
   --  Return the absolute path parent directory of the directory where the
   --  current executable resides, if its directory is named "bin", otherwise
   --  return an empty string. When a directory is returned, it is guaranteed
   --  to end with a directory separator.

   function Locate_Directory
     (Dir_Name : String;
      Path     : String)
      return String_Access;
   --  Find directory Dir_Name in Path. Return absolute path of directory, or
   --  null if directory cannot be found. The caller is responsible for
   --  freeing the returned String_Access.

   procedure Put
     (Into_List  : in out Name_List_Index;
      From_List  : String_List_Id;
      In_Tree    : Project_Tree_Ref;
      Lower_Case : Boolean := False);
   --  Append From_List list to list Into_List

   type Name_Array_Type is array (Positive range <>) of Name_Id;

   function Split (Source : String; Separator : String) return Name_Array_Type;
   --  Split string Source into several, using Separator. The different
   --  occurences of Separator are not included in the result. The result
   --  includes no empty string.

   function Value_Of
     (Variable : Variable_Value;
      Default  : String) return String;
   --  Get the value of a single string variable. If Variable is a string list,
   --  is Nil_Variable_Value,or is defaulted, return Default.

   function Value_Of
     (Index    : Name_Id;
      In_Array : Array_Element_Id;
      Shared   : Shared_Project_Tree_Data_Access) return Name_Id;
   --  Get a single string array component. Returns No_Name if there is no
   --  component Index, if In_Array is null, or if the component is a String
   --  list. Depending on the attribute (only attributes may be associative
   --  arrays) the index may or may not be case sensitive. If the index is not
   --  case sensitive, it is first set to lower case before the search in the
   --  associative array.

   function Value_Of
     (Index                  : Name_Id;
      Src_Index              : Int := 0;
      In_Array               : Array_Element_Id;
      Shared                 : Shared_Project_Tree_Data_Access;
      Force_Lower_Case_Index : Boolean := False;
      Allow_Wildcards        : Boolean := False) return Variable_Value;
   --  Get a string array component (single String or String list). Returns
   --  Nil_Variable_Value if no component Index or if In_Array is null.
   --
   --  Depending on the attribute (only attributes may be associative arrays)
   --  the index may or may not be case sensitive. If the index is not case
   --  sensitive, it is first set to lower case before the search in the
   --  associative array.

   function Value_Of
     (Name                    : Name_Id;
      Index                   : Int := 0;
      Attribute_Or_Array_Name : Name_Id;
      In_Package              : Package_Id;
      Shared                  : Shared_Project_Tree_Data_Access;
      Force_Lower_Case_Index  : Boolean := False;
      Allow_Wildcards         : Boolean := False) return Variable_Value;
   --  In a specific package:
   --   - if there exists an array Attribute_Or_Array_Name with an index Name,
   --     returns the corresponding component (depending on the attribute, the
   --     index may or may not be case sensitive, see previous function),
   --   - otherwise if there is a single attribute Attribute_Or_Array_Name,
   --     returns this attribute,
   --   - otherwise, returns Nil_Variable_Value.
   --  If In_Package is null, returns Nil_Variable_Value.

   function Value_Of
     (Index     : Name_Id;
      In_Array  : Name_Id;
      In_Arrays : Array_Id;
      Shared    : Shared_Project_Tree_Data_Access) return Name_Id;
   --  Get a string array component in an array of an array list. Returns
   --  No_Name if there is no component Index, if In_Arrays is null, if
   --  In_Array is not found in In_Arrays or if the component is a String list.

   function Value_Of
     (Name      : Name_Id;
      In_Arrays : Array_Id;
      Shared    : Shared_Project_Tree_Data_Access) return Array_Element_Id;
   --  Returns a specified array in an array list. Returns No_Array_Element
   --  if In_Arrays is null or if Name is not the name of an array in
   --  In_Arrays. The caller must ensure that Name is in lower case.

   function Value_Of
     (Name        : Name_Id;
      In_Packages : Package_Id;
      Shared      : Shared_Project_Tree_Data_Access) return Package_Id;
   --  Returns a specified package in a package list. Returns No_Package
   --  if In_Packages is null or if Name is not the name of a package in
   --  Package_List. The caller must ensure that Name is in lower case.

   function Value_Of
     (Variable_Name : Name_Id;
      In_Variables  : Variable_Id;
      Shared        : Shared_Project_Tree_Data_Access) return Variable_Value;
   --  Returns a specified variable in a variable list. Returns null if
   --  In_Variables is null or if Variable_Name is not the name of a
   --  variable in In_Variables. Caller must ensure that Name is lower case.

   procedure Write_Str
     (S          : String;
      Max_Length : Positive;
      Separator  : Character);
   --  Output string S. If S is too long to fit in one
   --  line of Max_Length, cut it in several lines, using Separator as the last
   --  character of each line, if possible.

   type Text_File is limited private;
   --  Represents a text file (default is invalid text file)

   function Is_Valid (File : Text_File) return Boolean;
   --  Returns True if File designates an open text file that has not yet been
   --  closed.

   procedure Open (File : out Text_File; Name : String);
   --  Open a text file to read (File is invalid if text file cannot be opened)

   procedure Create (File : out Text_File; Name : String);
   --  Create a text file to write (File is invalid if text file cannot be
   --  created).

   function End_Of_File (File : Text_File) return Boolean;
   --  Returns True if the end of the text file File has been reached. Fails if
   --  File is invalid. Return True if File is an out file.

   procedure Get_Line
     (File : Text_File;
      Line : out String;
      Last : out Natural);
   --  Reads a line from an open text file (fails if File is invalid or in an
   --  out file).

   procedure Put (File : Text_File; S : String);
   procedure Put_Line (File : Text_File; Line : String);
   --  Output a string or a line to an out text file (fails if File is invalid
   --  or in an in file).

   procedure Close (File : in out Text_File);
   --  Close an open text file. File becomes invalid. Fails if File is already
   --  invalid or if an out file cannot be closed successfully.

   -----------------------
   -- Source info files --
   -----------------------

   --  A source info file is a text file that contains information on the
   --  significant sources of a project tree.
   --
   --  Only sources that are not excluded and are not replaced by another
   --  source in an extending projects are described in a source info file.
   --
   --  Each source is described with 4 lines, followed by optional lines,
   --  followed by an empty line.
   --
   --  The four lines in every entry are
   --    - the name of the project
   --    - the name of the language
   --    - the kind of source: SPEC, IMPL (body) OR SEP (subunit).
   --    - the path name of the source
   --
   --  The optional lines are:
   --    - if the canonical case path name is not the same as the path name
   --      to be displayed, a line starting with "P=" followed by the canonical
   --      case path name.
   --    - if the language is unit based (Ada), a line starting with "U="
   --      followed by the unit name.
   --    - if the unit is part of a multi-unit source, a line starting with
   --      "I=" followed by the index in the multi-unit source.
   --    - if the source is a naming exception declared in its project, a line
   --      containing "N=Y".
   --    - if it is an inherited naming exception, a line containng "N=I".

   procedure Write_Source_Info_File (Tree : Project_Tree_Ref);
   --  Create a new source info file, with the path name specified in the
   --  project tree data. Issue a warning if it is not possible to create
   --  the new file.

   procedure Read_Source_Info_File (Tree : Project_Tree_Ref);
   --  Check if there is a source info file specified for the project Tree. If
   --  so, attempt to read it. If the file exists and is successfully read, set
   --  the flag Source_Info_File_Exists to True for the tree.

   type Source_Info_Data is record
      Project           : Name_Id;
      Language          : Name_Id;
      Kind              : Source_Kind;
      Display_Path_Name : Name_Id;
      Path_Name         : Name_Id;
      Unit_Name         : Name_Id               := No_Name;
      Index             : Int                   := 0;
      Naming_Exception  : Naming_Exception_Type := No;
   end record;
   --  Data read from a source info file for a single source

   type Source_Info is access all Source_Info_Data;
   No_Source_Info : constant Source_Info := null;

   type Source_Info_Iterator is private;
   --  Iterator to get the sources for a single project

   procedure Initialize
     (Iter        : out Source_Info_Iterator;
      For_Project : Name_Id);
   --  Initialize Iter for the project

   function Source_Info_Of (Iter : Source_Info_Iterator) return Source_Info;
   --  Get the source info for the source corresponding to the current value of
   --  the iterator. Returns No_Source_Info if there is no source corresponding
   --  to the iterator.

   procedure Next (Iter : in out Source_Info_Iterator);
   --  Advance the iterator to the next source in the project

   function Is_Ada_Predefined_File_Name
     (Fname : File_Name_Type) return Boolean;
   --  Return True if Fname is a runtime source file name

   function Is_Ada_Predefined_Unit (Unit : String) return Boolean;
   --  Return True if Unit is an Ada runtime unit

   function Starts_With (Item : String; Prefix : String) return Boolean;
   --  Return True if Item starts with Prefix

   generic
      with procedure Action (Source : Source_Id);
   procedure For_Interface_Sources
     (Tree    : Project_Tree_Ref;
      Project : Project_Id);
   --  Call Action for every sources that are needed to use Project. This is
   --  either the sources corresponding to the units in attribute Interfaces
   --  or all sources of the project. Note that only the bodies that are
   --  needed (because the unit is generic or contains some inline pragmas)
   --  are handled. This routine must be called only when the project has
   --  been built successfully.

   function Relative_Path (Pathname : String; To : String) return String;
   --  Returns the relative pathname which corresponds to Pathname when
   --  starting from directory to. Both Pathname and To must be absolute paths.

   function Create_Name (Name : String) return File_Name_Type;
   function Create_Name (Name : String) return Name_Id;
   function Create_Name (Name : String) return Path_Name_Type;
   --  Get an id for a name

   function Is_Subunit (Source : Source_Id) return Boolean;
   --  Return True if source is a subunit

   procedure Initialize_Source_Record
     (Source : Source_Id;
      Always : Boolean := False);
   --  Get information either about the source file, or the object and
   --  dependency file, as well as their timestamps.
   --  When Always is True, initialize Source even if it has already been
   --  initialized.

   function Source_Dir_Of (Source : Source_Id) return String;
   --  Returns the directory of the source file

   procedure Get_Switches
     (Source       : Source_Id;
      Pkg_Name     : Name_Id;
      Project_Tree : Project_Tree_Ref;
      Value        : out Variable_Value;
      Is_Default   : out Boolean);
   procedure Get_Switches
     (Source_File         : File_Name_Type;
      Source_Lang         : Name_Id;
      Source_Prj          : Project_Id;
      Pkg_Name            : Name_Id;
      Project_Tree        : Project_Tree_Ref;
      Value               : out Variable_Value;
      Is_Default          : out Boolean;
      Test_Without_Suffix : Boolean := False;
      Check_ALI_Suffix    : Boolean := False);
   --  Compute the switches (Compilation switches for instance) for the given
   --  file. This checks various attributes to see if there are file specific
   --  switches, or else defaults on the switches for the corresponding
   --  language. Is_Default is set to False if there were file-specific
   --  switches. Source_File can be set to No_File to force retrieval of the
   --  default switches. If Test_Without_Suffix is True, and there is no "for
   --  Switches(Source_File) use", then this procedure also tests without the
   --  extension of the filename. If Test_Without_Suffix is True and
   --  Check_ALI_Suffix is True, then we also replace the file extension with
   --  ".ali" when testing.

   function Object_Project
     (Project          : Project_Id;
      Must_Be_Writable : Boolean := False)
      return Project_Id;
   --  For a non aggregate project, returns the project, except when
   --  Must_Be_Writable is True and the object directory is not writable,
   --  return No_Project.
   --  For an aggregate project or an aggregate library project, returns an
   --  aggregated project that is not an aggregate project and that has
   --  a writable object directory. If there is no such project, returns
   --  No_Project.

   function To_Time_Stamp (Time : Calendar.Time) return Stamps.Time_Stamp_Type;
   --  Returns Time as a time stamp type

   function UTC_Time return Stamps.Time_Stamp_Type;
   --  Returns the UTC time

   Partial_Prefix : constant String := "p__";

   Begin_Info : constant String := "--  BEGIN Object file/option list";
   End_Info   : constant String := "--  END Object file/option list   ";

   Project_Node_Tree : constant GPR.Project_Node_Tree_Ref :=
                         new Project_Node_Tree_Data;
   --  This is also used to hold project path and scenario variables

   Complete_Output_Option    : constant String := "--complete-output";
   No_Complete_Output_Option : constant String := "--no-complete-output";

   Added_Project : constant String := "--added-project=";

   Complete_Output : Boolean := False;
   --  Set to True with switch Complete_Output_Option

   No_Complete_Output : Boolean := False;
   --  Set to True with switch -n or No_Complete_Output_Option

   No_Project_File : Boolean := False;
   --  Set to True in gprbuild and gprclean when switch --no-project is used

   --  Config project

   Config_Project_Option : constant String := "--config=";

   Autoconf_Project_Option : constant String := "--autoconf=";

   Target_Project_Option : constant String := "--target=";

   Prefix_Project_Option : constant String := "--prefix";

   No_Name_Map_File_Option : constant String := "--map-file-option";

   Restricted_To_Languages_Option : constant String :=
                                               "--restricted-to-languages=";

   No_Project_Option : constant String := "--no-project";

   Distributed_Option : constant String := "--distributed";
   Hash_Option        : constant String := "--hash";
   Hash_Value         : String_Access;

   Slave_Env_Option : constant String := "--slave-env";
   Slave_Env_Auto   : Boolean := False;

   Dry_Run_Option : constant String := "--dry-run";

   Named_Map_File_Option   : constant String := No_Name_Map_File_Option & '=';

   Config_Path : String_Access := null;

   Target_Name : String_Access := null;

   Config_Project_File_Name   : String_Access := null;
   Configuration_Project_Path : String_Access := null;
   --  Base name and full path to the configuration project file

   Autoconfiguration : Boolean := True;
   --  Whether we are using an automatically config (from gprconfig)

   Autoconf_Specified : Boolean := False;
   --  Whether the user specified --autoconf on the gprbuild command line

   Delete_Autoconf_File : Boolean := False;
   --  This variable is used by gprclean to decide if the config project file
   --  should be cleaned. It is set to True when the config project file is
   --  automatically generated or --autoconf= is used.

   --  Default project

   Default_Project_File_Name : constant String := "default.gpr";

   --  Implicit project

   Implicit_Project_File_Path : constant String :=
     "share" &
     Directory_Separator &
     "gpr" &
     Directory_Separator &
     '_' &
     Default_Project_File_Name;

   --  User projects

   Project_File_Name          : String_Access := null;
   --  The name of the project file specified with switch -P

   No_Project_File_Found : Boolean := False;
   --  True when no project file is specified and there is no .gpr file
   --  in the current working directory.

   Main_Project : Project_Id;
   --  The project id of the main project

   RTS_Option : constant String := "--RTS=";

   RTS_Language_Option : constant String := "--RTS:";

   Db_Directory_Expected : Boolean := False;
   --  True when last switch was --db

   Distributed_Mode : Boolean := False;
   --  Wether the distributed compilation mode has been activated

   Slave_Env : String_Access;
   --  The name of the distributed build environment

   --  Packages of project files where unknown attributes are errors

   Naming_String   : aliased String := "naming";
   Builder_String  : aliased String := "builder";
   Compiler_String : aliased String := "compiler";
   Binder_String   : aliased String := "binder";
   Linker_String   : aliased String := "linker";
   Clean_String    : aliased String := "clean";
   --  Name of packages to be checked when parsing/processing project files

   List_Of_Packages : aliased String_List :=
                        (Naming_String'Access,
                         Builder_String'Access,
                         Compiler_String'Access,
                         Binder_String'Access,
                         Linker_String'Access,
                         Clean_String'Access);
   Packages_To_Check : constant String_List_Access := List_Of_Packages'Access;
   --  List of the packages to be checked when parsing/processing project files

   Gprname_Packages : aliased String_List := (1 => Naming_String'Access);

   Packages_To_Check_By_Gprname : constant String_List_Access :=
                                    Gprname_Packages'Access;

   --  Local subprograms

   function Binder_Exchange_File_Name
     (Main_Base_Name : File_Name_Type; Prefix : Name_Id) return String_Access;
   --  Returns the name of the binder exchange file corresponding to an
   --  object file and a language.
   --  Main_Base_Name must have no extension specified

   ----------
   -- Misc --
   ----------

   procedure Create_Sym_Links
     (Lib_Path    : String;
      Lib_Version : String;
      Lib_Dir     : String;
      Maj_Version : String);
   --  Copy Lib_Version to Lib_Path (removing Lib_Path if it exists). If
   --  Maj_Version is set it also link Lib_Version into Lib_Dir with the
   --  specified Maj_Version.

   procedure Create_Sym_Link (From, To : String);
   --  Create a relative symlink in From pointing to To

   procedure Display_Usage_Version_And_Help;
   --  Output the two lines of usage for switches --version and --help

   procedure Display_Version
     (Tool_Name      : String;
      Initial_Year   : String;
      Version_String : String);
   --  Display version of a tool when switch --version is used

   generic
      with procedure Usage;
      --  Print tool-specific part of --help message
   procedure Check_Version_And_Help_G
     (Tool_Name      : String;
      Initial_Year   : String;
      Version_String : String);
   --  Check if switches --version or --help is used. If one of this switch is
   --  used, issue the proper messages and end the process.

   procedure Find_Binding_Languages
     (Tree         : Project_Tree_Ref;
      Root_Project : Project_Id);
   --  Check if in the project tree there are sources of languages that have
   --  a binder driver.
   --  Populates Tree's appdata (Binding and There_Are_Binder_Drivers).
   --  Nothing is done if the binding languages were already searched for
   --  this Tree.
   --  This also performs the check for aggregated project trees.

   function Get_Compiler_Driver_Path
     (Project_Tree : Project_Tree_Ref;
      Lang         : Language_Ptr) return String_Access;
   --  Get, from the config, the path of the compiler driver. This is first
   --  looked for on the PATH if needed.
   --  Returns "null" if no compiler driver was specified for the language, and
   --  exit with an error if one was specified but not found.
   --
   --  The --compiler-subst switch is taken into account. For example, if
   --  "--compiler-subst=ada,gnatpp" was given, and Lang is the Ada language,
   --  this will return the full path name for gnatpp.

   procedure Locate_Runtime
     (Project_Tree : Project_Tree_Ref;
      Language     : Name_Id);
   --  Wrapper around Set_Runtime_For. Search RTS name in the project path and
   --  if found convert it to an absolute path. Emit an error message if a
   --  full RTS name (an RTS name that contains a directory separator) is not
   --  found.

   procedure Look_For_Default_Project (Never_Fail : Boolean := False);
   --  Check if default.gpr exists in the current directory. If it does, use
   --  it. Otherwise, if there is only one file ending with .gpr, use it.
   --  Otherwise, if there is no file ending with .gpr or if Never_Fail is
   --  True, use the project file _default.gpr in <prefix>/share/gpr. Fail
   --  if Never_Fail is False and there are several files ending with .gpr.

   function Major_Id_Name
     (Lib_Filename : String;
      Lib_Version  : String) return String;
   --  Returns the major id library file name, if it exists.
   --  For example, if Lib_Filename is "libtoto.so" and Lib_Version is
   --  "libtoto.so.1.2", then "libtoto.so.1" is returned.

   function Partial_Name
     (Lib_Name      : String;
      Number        : Natural;
      Object_Suffix : String) return String;
   --  Returns the name of an object file created by the partial linker

   function Shared_Libgcc_Dir (Run_Time_Dir : String) return String;
   --  Returns the directory of the shared version of libgcc, if it can be
   --  found, otherwise returns an empty string.

   package Knowledge is

      function Normalized_Hostname return String;
      --  Return the normalized name of the host on which gprbuild is running.
      --  The knowledge base must have been parsed first.

      function Normalized_Target (Target_Name : String) return String;
      --  Return the normalized name of the specified target.
      --  The knowledge base must have been parsed first.

      procedure Parse_Knowledge_Base
        (Project_Tree : Project_Tree_Ref;
         Directory : String := "");

   end Knowledge;

   procedure Need_To_Compile
     (Source         : Source_Id;
      Tree           : Project_Tree_Ref;
      In_Project     : Project_Id;
      Conf_Paths     : Config_Paths;
      Must_Compile   : out Boolean;
      The_ALI        : out ALI.ALI_Id;
      Object_Check   : Boolean;
      Always_Compile : Boolean);
   --  Check if a source need to be compiled.
   --  A source need to be compiled if:
   --    - Force_Compilations is True
   --    - No object file generated for the language
   --    - Object file does not exist
   --    - Dependency file does not exist
   --    - Switches file does not exist
   --    - Either of these 3 files are older than the source or any source it
   --      depends on.
   --  If an ALI file had to be parsed, it is returned as The_ALI, so that the
   --  caller does not need to parse it again.
   --
   --  Object_Check should be False when switch --no-object-check is used. When
   --  True, presence of the object file and its time stamp are checked to
   --  decide if a file needs to be compiled.
   --
   --  Tree is the project tree in which Source is found (or the root tree when
   --  not using aggregate projects).
   --
   --  Always_Compile should be True when gprbuid is called with -f -u and at
   --  least one source on the command line.

   function Project_Compilation_Failed
     (Prj       : Project_Id;
      Recursive : Boolean := True) return Boolean;
   --  Returns True if all compilations for Prj (and all projects it depends on
   --  if Recursive is True) were successful and False otherwise.

   procedure Set_Failed_Compilation_Status (Prj : Project_Id);
   --  Record compilation failure status for the given project

   Maximum_Size : Integer;
   pragma Import (C, Maximum_Size, "__gnat_link_max");
   --  Maximum number of bytes to put in an invocation of the
   --  Archive_Builder.

   function Ensure_Suffix (Item : String; Suffix : String) return String;
   --  Returns Item if it ends with Suffix otherwise returns Item & Suffix

   function Ensure_Directory (Path : String) return String;
   --  Returns Path with an ending directory separator

   function Common_Prefix (Pathname1, Pathname2 : String) return String;
   --  Returns the longest common prefix for Pathname1 and Pathname2

   function File_MD5 (Pathname : String) return Message_Digest;
   --  Returns the file MD5 signature. Raises Name_Error if Pathname does not
   --  exists.

   function As_RPath
     (Path           : String;
      Case_Sensitive : Boolean) return String;
   --  Returns Path in a representation compatible with the use with --rpath or
   --  --rpath-link.
   --  This normalizes the path, and ensure the use of unix-style directory
   --  separator.

   function Common_Path_Prefix_Length (A, B : String) return Integer;
   --  Adapted from:
   --     https://www.rosettacode.org/wiki/Find_common_directory_path#Ada
   --  The result is the length of the longest common path prefix, including
   --  trailing separators.
   --  If the only common prefix is "/" then the result is zero.

   function Relative_RPath (Dest, Src, Origin : String) return String;
   --  returns Dest as a path relative to the Src directory using Origin
   --  to indicate the relative path: with dest = /foo/bar, Src = /foo/baz and
   --  Origin = $ORIGIN, the function will return $ORIGIN/../bar.
   --  If Absolute is set, then the rpath will be absolute.

   function Concat_Paths
     (List      : String_Vectors.Vector;
      Separator : String) return String;
   --  Concatenate the strings in the list, using Separator between the
   --  strings.
   --  Typical usage is to concatenate paths using the path separator between
   --  those.

   function To_Argument_List
     (List : String_Vectors.Vector) return Argument_List;
   --  Translates a string vector into an argument list

   function Slice
     (List : String_Vectors.Vector;
      From, To : Positive) return String_Vectors.Vector;
   --  Returns List (From .. To)

   --  Architecture

   function Get_Target return String;
   --  Returns the current target for the compilation

   function Check_Diff
     (Ts1, Ts2  : Stamps.Time_Stamp_Type;
      Max_Drift : Duration := 5.0) return Boolean;
   --  Check two time stamps, returns True if both time are in a range of
   --  Max_Drift seconds maximum.

   --  Compiler and package substitutions

   --  The following are used to support the --compiler-subst and
   --  --compiler-pkg-subst switches, which are used by tools such as gnatpp to
   --  have gprbuild drive gnatpp, thus calling gnatpp only on files that need
   --  it.
   --
   --  gnatpp will pass --compiler-subst=ada,gnatpp to tell gprbuild to run
   --  gnatpp instead of gcc. It will also pass
   --  --compiler-pkg-subst=pretty_printer to tell gprbuild to get switches
   --  from "package Pretty_Printer" instead of from "package Compiler".

   procedure Set_Default_Verbosity;
   --  Set the default verbosity from environment variable GPR_VERBOSITY.
   --  The values that are taken into account, case-insensitive, are:
   --  "quiet", "default", "verbose", "verbose_high", "verbose_medium" and
   --  "verbose_low".

   Compiler_Subst_Option     : constant String := "--compiler-subst=";
   Compiler_Pkg_Subst_Option : constant String := "--compiler-pkg-subst=";

   Compiler_Subst_HTable : Language_Maps.Map;
   --  A hash table to get the compiler to substitute from the from the
   --  language name. For example, if the command line option
   --  "--compiler-subst=ada,gnatpp" was given, then this mapping will include
   --  the key-->value pair "ada" --> "gnatpp". This causes gprbuild to call
   --  gnatpp instead of gcc.

   Compiler_Pkg_Subst : Name_Id := No_Name;
   --  A package name to be used when invoking the compiler, in addition to
   --  "package Compiler". Normally, this is No_Name, indicating no additional
   --  package, but it can be set by the --compiler-pkg-subst option. For
   --  example, if --compiler-pkg-subst=pretty_printer was given, then this
   --  will be "pretty_printer", and gnatpp will be invoked with switches from
   --  "package Pretty_Printer", and -inner-cargs followed by switches from
   --  "package Compiler".

   package Project_Output is
      --  Support for Gprname

      Output_FD : File_Descriptor;
      --  To save the project file and its naming project file

      procedure Write_Eol;
      --  Output an empty line

      procedure Write_A_Char (C : Character);
      --  Write one character to Output_FD

      procedure Write_A_String (S : String);
      --  Write a String to Output_FD
   end Project_Output;

   ----------------------------
   -- Command Line Arguments --
   ----------------------------

   procedure Delete_Command_Line_Arguments;
   --  Remove all previous command line arguments

   procedure Get_Command_Line_Arguments;
   --  Get the command line arguments, including those coming from argument
   --  files.

   function Last_Command_Line_Argument return Natural;
   --  The number of command line arguments that have been read

   function Command_Line_Argument (Rank : Positive) return String;
   --  Return command line argument of rank Rank. If Rank is greater than
   --  Last_Command_Line_Argument, return the empty string.

   ----------------------
   -- Time Stamp Cache --
   ----------------------

   --  There is a hash table to cache the time stamps of files.
   --  This table needs to be cleared sometimes.

   procedure Clear_Time_Stamp_Cache;

private
   type Text_File_Data is record
      FD                  : File_Descriptor := Invalid_FD;
      Out_File            : Boolean := False;
      Buffer              : String (1 .. 100_000);
      Buffer_Len          : Natural := 0;
      Cursor              : Natural := 0;
      End_Of_File_Reached : Boolean := False;
   end record;

   type Text_File is access Text_File_Data;

   type Source_Info_Iterator is record
      Info : Source_Info;
      Next : Natural;
   end record;

   function Starts_With (Item : String; Prefix : String) return Boolean
   is (Item'Length >= Prefix'Length
       and then Item (Item'First .. Item'First + Prefix'Length - 1) = Prefix);

end GPR.Util;
