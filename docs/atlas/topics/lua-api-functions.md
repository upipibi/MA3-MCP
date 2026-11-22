# grandMA3 Lua API: function catalogue (offline)

## Bottom line

About 185 table rows (several rows group sibling functions): 104 + 33 object-free (read-only / changing) and 36 + 12 object functions. About 140 rows are read-only. All 152 help pages were read (Description, Arguments, Return), plus the whole meta file. Ten most valuable unused read-only calls: (1) `GetApiDescriptor()` and `GetObjApiDescriptor()` (the build's own full function list, may reveal hidden functions); (2) `obj:PropertyCount/PropertyName/PropertyType/PropertyInfo` (schema of any object without guessing); (3) `GetRTChannel(i)` fields `dmx_default/highlight/lowlight` (stored defaults, the ladder case); (4) `GetPresetData(handle)` (preset values); (5) `SelectionFirst/Next` + `GetSubfixture` (which fixtures are selected); (6) `exec:GetFader({token=...})` (fader levels); (7) `GetDisplayCollect/GetScreenContent/GetUIObjectAtPosition` (what is on screen); (8) `GetSample(...)` and `BuildDetails()` (station health and build); (9) `obj:GetReferences()` (where used); (10) `DirList/FileExists/GetPath` (show files). Open doubts: no function found for messages (row 11), parked/tester flags (7), owner of a value (6), other users' state (9, 12), RDM (27), timecode slot settings (21), or a second user (28). Row 33: `Set` has no undo argument. Not covered: example code and notes on the help pages; nothing was run.

## Object-free functions (read-only)

Called as `Name(...)`. Evidence: [D] help 2.5 page, [M] MA meta file, [O] already run on onPC 2026-11-21. Rows marked [O] were not re-derived.

| function | arguments | returns | read-only? | meaning | evidence | relevance (GAPS row) |
|---|---|---|---|---|---|---|
| AddonVars | (string) | Handle a handle of the set of variables. | read-only | returns a handle to the set of variables connected to a specific addon. | [D] | none |
| BuildDetails | () | Build details This is the table with key-value pairs. These are the possible keys in the ta | read-only | returns a table with key-value pairs about the software build. | [D] | new gap A (software build) |
| CheckDMXCollision | (handle, string[, integer[, integer]]) | Boolean a boolean. | read-only | checks if a specific DMX address range is available or already used. | [D] | 30 (read-only check) |
| CheckFIDCollision | (integer[, integer[, integer]]) | Boolean a boolean. | read-only | checks if a specific (range of) ID is available or already used. It can be used to check FID and any type of C | [D] | 30 (read-only check) |
| ClassExists | (string) | Boolean a boolean. | read-only | returns a boolean indicating whether the provided string is a class. | [D] | bench aid |
| CmdObj | () | Handle a handle to the command line object. | read-only | returns information about the command line object. | [D][M][O] | none |
| ConfigTable | () | Table table contains key value pairs with configuration information. See the exampl | read-only | returns a table with some configuration information. This is information only. The function does not have any | [D] | new gap A |
| CurrentEnvironment | () | Handle handle to the environment. | read-only | returns a handle to the current users' selected environment. | [D][M][O] | 2, 9 |
| CurrentExecPage | () | Handle handle to the executor page. | read-only | returns a handle to the current users' selected executor page. | [D][O] | 9 |
| CurrentProfile | () | Handle handle to the user profile. | read-only | returns a handle to the current users' profile. | [D][M][O] | 9, 18, 19 |
| CurrentScreenConfig | () | Handle handle to the screen configuration. | read-only | returns a handle to the current users' screen configuration. | [D][M][O] | 19 |
| CurrentUser | () | Handle handle to the user. | read-only | returns a handle to the current user. | [D][M][O] | 9, 12, 18 |
| DataPool | () | Handle a handle to the DataPool object. | read-only | references the currently selected DataPool and is used to read or edit properties within the data pool. | [D][M] | 25 (current pool only) |
| DefaultDisplayPositions | () | Handle a handle to the command line object. | read-only | returns the handle of the conventional default display positions, which contains the first seven screens as ch | [D][M] | 19 |
| DeskLocked | () | Boolean The boolean indicates if the station is desk locked or not. | read-only | returns a boolean indicating if the station is locked. | [D][O] | new gap C |
| DeviceConfiguration | () | Handle handle to the DeviceConfiguration. | read-only | returns a handle to the DeviceConfiguration object. | [D][M][O] | 15, 16, 17 |
| DirList | (string[, string]) | Table table has elements of other tables. Each of these table elements has the foll | read-only | returns a table of files at a specified path. The returned list can be filtered using an optional filter argum | [D] | 22 |
| DumpAllHooks | () | The function does not return anything. It does print a list in the system monitor. Hint: | read-only | prints a list of the hooks in the system. The list is only shown in the System Monitor. | [D] | none |
| FileExists | (string) | Boolean - True / 1: The file exists. | read-only | checks if a file exists and returns a boolean with the result. | [D] | 22 |
| FindTexture | (string) | Handle | nil the texture handle or nil if it does not exist. | read-only | returns a handle to the texture matching the input text string - if the texture exists. | [D] | 26 (bitmaps) |
| FirstDmxModeFixture | (handle) | Handle handle to the first fixture matching the DMX mode. | read-only | returns a handle to the first fixture matching the supplied DMX mode. | [D] | 30 |
| FixtureType | () | Handle or nil The handle for the fixture type or nil. | read-only | handle or nil | [D] | none |
| FromAddr | (string[, handle]) | Handle The handle for the addressed object. | read-only | converts a numbered string address into a handle that can be used in commands. | [D] | object bench aid |
| GetApiDescriptor | () | Table table contains elements with other tables. | read-only | returns a table with a description of all the object-free Lua functions. These are descriptions only. The func | [D] | ALL (lists every function the build has) |
| GetAttributeByUIChannel | (integer) | Handle The handle to the attribute connected to the UI Channel. | read-only | returns the handle to an attribute based on a "UI Channel Index". The index number can be found in the Paramet | [D][O] | 6 |
| GetAttributeCount | () | Integer integer number represents the total amount of attribute definitions in the sh | read-only | returns the total number of attribute definitions in the show. | [D][O] | none |
| GetAttributeIndex | (string) | Integer integer number represents the total amount of patched fixtures on all the sta | read-only | returns the (0 based) index number of the attribute definition based on the system name of the attribute. | [D] | 6 |
| GetButton | (handle) | Table table is a key-value pairs table with a set of 512 pairs with a boolean value | read-only | returns a key-value pairs table indicating, with a boolean value, whether a button is pressed on an MA3Module. | [D] | new gap D (hardware module buttons) |
| GetChannelFunction | (integer, integer) | Handle handle to the channel function. | read-only | returns a handle to a channel function based on two index inputs. | [D] | 6 |
| GetChannelFunctionIndex | () | Integer integer to a channel function. | read-only | returns the integer matching a channel function based on two index inputs. | [D] | 6 |
| GetClassDerivationLevel | (string) | Integer integer indicates the class derivation level. | read-only | returns an integer indicating the derivation level index for a class based on a class name. | [D] | bench aid |
| GetCurrentCue | () | Handle handle to the cue. | read-only | returns a handle to the last activated cue in the selected sequence. | [D][O] | 1, 9 |
| GetDebugFPS | () | Number number indicates the current frames per second. | read-only | returns a float number with the frames per second. | [D][O] | new gap B |
| GetDisplayByIndex | (integer) | Handle handle to the display object. | read-only | returns a handle to the display object matching the provided index number. | [D] | 19 |
| GetDisplayCollect | () | Handle handle to the DisplayCollect. | read-only | returns a handle to the DisplayCollect object. | [D] | 19 |
| GetDMXUniverse | (integer[, boolean]) | Table table lists all the DMX addresses and the corresponding values. | read-only | returns a table with the DMX channels and their current value. | [D][O] | 5, 7, 13 |
| GetDMXValue | (integer[, integer, boolean]) | Integer or nil integer value corresponds with the value of the selected DMX address or ni | read-only | returns a number indicating the DMX value of a specified DMX address. | [D][O] | 5, 13 |
| GetExecutor | (integer) | Handle - Executor handle to the executor. | read-only | returns the handles of the executor and the page based on the executor number. | [D][O] | 8b, 20 |
| GetFocus | () | Handle handle to the object. | read-only | returns a handle to the object that currently has focus in the UI. | [D] | 19 |
| GetFocusDisplay | () | Handle handle to the display object. | read-only | returns a handle to the display object that currently has focus in the UI. | [D] | 19 |
| GetObjApiDescriptor | () | Table table contains elements with three values. | read-only | returns a table with a description of all the object Lua functions. These are descriptions only. The function | [D] | ALL (same, object functions) |
| GetPath | (string[, boolean] | The GetPath Lua function returns a string with the path of a grandMA3 folder. | R: - String: | read-only | integer) | [D] | 22 |
| GetPathOverrideFor | (string|integer, string[, boolean]) | String string is the first found full path related to the provided argument. | read-only | delivers a string with the path of a grandMA3 folder. The function is relevant when the path should be on a re | [D] | 22 |
| GetPathSeparator | () | String The string is a single character indicating the path separator based on the operat | read-only | returns a string with the path separator for the operating system. | [D] | none |
| GetPathType | (handle[, integer]) | String string is the name of the path type. | read-only | returns a string with a name for the path type. This function can be useful when importing objects. | [D] | 22 |
| GetPresetData | (handle[, boolean[, boolean]]) | Table | nil table contains the preset data. It has multiple levels of tables. | read-only | returns a table with the preset data based on the preset handle. | [D] | 24 (preset content; new) |
| GetRTChannel | (integer) | Table table contains related numbers, tables, and handles with a named identifying | read-only | returns a table with information about the related RT Channel. | [D][O] | 5, 6, 7 (dmx_default / highlight / lowlight = stored defaults) |
| GetRTChannelCount | () | Integer an integer number depicting the total amount of RT channels. | read-only | returns a number indicating the total amount of RT channels. | [D][O] | none |
| GetRTChannels | (integer[,boolean] OR handle[,boolean]) |  | read-only | returns a table with RT Channel indexes or a table with handles to the RT Channel objects. There are two diffe | [D][O] | 5, 6 |
| GetSample | (string) | Number A number (float) is returned. | read-only | returns a number representing a percentage usage based on a string input. | [D] | new gap B (CPU, memory, temperatures, fan) |
| GetScreenContent | (handle) | Handle handle to the screen content. | read-only | returns a handle to the screen content based on a provided handle to a screen configuration. | [D] | 19 |
| GetSelectedAttribute | () | Handle handle to the selected attribute. | read-only | returns a handle to the currently selected attribute. | [D][O] | none |
| GetShowFileStatus | () | String string is the enum string from "Enums.ShowFileStatus" that matches the curren | read-only | returns a string with the current device's show file status, for example, "NoShow", "ShowLoaded", "ShowDownloa | [D][O] | 22; job precondition |
| GetSubfixture | (integer) | Handle a handle to the fixture object matching the provided index number. | read-only | returns the handle of the fixture specified by its patch index number. | [D] | 4 (index to fixture handle, then FID) |
| GetSubfixtureCount | () | Integer integer number represents the total amount of patched fixtures on all the sta | read-only | returns the total number of fixtures that are patched within the show file. | [D][O] | none |
| GetTokenName | (string) | String A string with the full keyword is returned. | read-only | returns a string with the full keyword based on the short version string input or nil if there is no correspon | [D][O] | guard (keyword shortcuts) |
| GetTokenNameByIndex | (int) | String A string with the full keyword is returned. | read-only | returns a string with the keyword based on the index number provided. | [D] | guard (all keywords) |
| GetTopModal | () | Handle | nil a handle to the top modal UI object if there is one. | read-only | returns a handle for the modal at the top. Modal is the internal name for pop-ups that interrupt the system's | [D][O] | 11, 19 |
| GetTopOverlay | () | Handle | nil a handle to the top overlay UI object if there is one. | read-only | returns a handle for the overlay at the top of the display with the provided index number. Overlay is the inte | [D] | 11, 19 |
| GetUIChannelCount | () | Integer an integer number depicting the total amount of UI channels. | read-only | returns a number indicating the total amount of UI channels. | [D][O] | none |
| GetUIChannelIndex | (integer, integer) | Integer integer to a channel function. | read-only | returns the index integer matching a UI channel based on two index inputs. | [D] | 6 |
| GetUIChannels | (integer[,boolean] OR handle[,boolean]) |  | read-only | returns a table with UI Channel indexes or a table with handles to the UI Channel objects. There are two diffe | [D][O] | 6 |
| GetUIObjectAtPosition | (integer, table) | Handle | nil If a UI object is at the provided position, then the handle to the object is | read-only | returns the handle of the UI Object at a specified position on a specified display. | [D] | 19 |
| GetVar | (handle, string) | Value This is the value of the variable. | read-only | returns the value of a specific variable in a set of variables. To learn more about the variables in plugins, | [D] | 23 |
| GlobalVars | () | Handle a handle of the set of global variables. | read-only | returns a handle to the set of global variables. Read more about these in the Variables topic in the Macro sec | [D][O] | 23 |
| HandleToInt | (handle) | Integer integer is the handle converted to an integer. | read-only | converts a handle into an integer format. | [D][M] | none |
| HandleToStr | (handle) | String string is the handle number converted to a hexadecimal format. | read-only | converts a handle into a string in a hexadecimal number format. | [D][M] | none |
| HostOS | () | String string is the operating system of the grandMA3 hardware or grandMA3 onPC comp | read-only | returns a string with the type of operating system of the device where the plugin is executed (for instance, " | [D][M] | 12 |
| HostSubType | () | String string is the host sub-type of the device. | read-only | returns a string with the host sub type of the station where the plugin is executed (for example, "FullSize", | [D][M] | 12 |
| HostType | () | String string is the host type of the device. | read-only | returns a string with the host type of the device where the plugin is executed (for example, "Console" or "onP | [D][M] | 12 |
| Import | (string) | Table This is the imported table. | read-only (reads a file) | The object-free Import Lua function imports a Lua table in XML format. | [D] | none (reads a Lua table from XML file) |
| IntToHandle | (integer) | Handle handle of the object correlates with the integer. | read-only | converts an integer number into a handle. The integer needs to correlate with an actual handle. | [D][M] | none |
| IsClassDerivedFrom | (string, string) | Boolean boolean indicates if the class is derived from the base class. | read-only | returns a boolean indicating if a class is derived from a different class. | [D] | bench aid |
| IsObjectValid | (handle) | Boolean or nil value is a boolean True if the handle is a valid object or it returns nil | read-only | returns a boolean true or nil depending on whether the supplied argument is a valid object. | [D] | bench aid |
| KeyboardObj | () | Handle the handle to the keyboard object. | read-only | returns the handle to the first found keyboard object. | [D] | none |
| MasterPool | () | Handle the handle to the pool of masters. | read-only | returns the handle to the masters. | [D][M][O] | 8 |
| MouseObj | () | Handle the handle to the mouse object. | read-only | returns the handle to the first found mouse object. | [D] | none |
| NeedShowSave | () | Boolean The boolean returns True if there are unsaved changes to the show file. False ind | read-only | returns a boolean indicating if there are unsaved changes to the showfile. | [D][O] | 22; job precondition |
| ObjectList | (string[, table]) | Table a table with handles to the objects based on the string argument. | read-only | returns a table with handles. The table is created based on a string input that should create a selection. | [D][M] | 26 (bulk reads by command range) |
| Patch | () | Handle handle to the patch. | read-only | returns a handle to the patch object. | [D][M] | 30 |
| Programmer | () | Handle a handle to the Programmer object. | read-only | references the current programmer object. | [D][M][O] | 2 |
| ProgrammerPart | () | Handle a handle to the programmer part object. | read-only | references the current programmer part object. | [D][M][O] | 2 |
| Pult | () | Handle handle to the pult object. | read-only | returns a handle to the current "Pult" object at position Root/GraphicsRoot/PultCollect. The "Pult" object con | [D][M] | 19 |
| ReleaseType | () | String string is the release type of the grandMA3 software. | read-only | returns a string with the type of release for the MA software. All the software versions available from MA Lig | [D] | new gap A |
| Root | () | Handle a handle to the Root object. | read-only | returns a handle to the object at the root position. | [D][M] | all |
| SelectedFeature | () | Handle handle for the selected feature. | read-only | returns the handle of the selected feature. | [D][O] | 9 |
| SelectedLayout | () | Handle handle for the selected layout. | read-only | returns the handle of the selected layout. | [D][O] | 9, 26 |
| SelectedSequence | () | Handle handle for the selected sequence. | read-only | returns the handle of the selected sequence. | [D][O] | 9 |
| SelectedTimecode | () | Handle handle for the selected timecode object. | read-only | returns the handle of the selected timecode object. | [D][O] | 10 |
| SelectedTimer | () | Handle handle for the selected timer object. | read-only | returns the handle of the selected timer object. | [D][O] | 26 |
| Selection | () | Handle a handle to the Selection object. | read-only | returns a handle to the object holding the current selection of fixtures. | [D][M][O] | 3,4 |
| SelectionCount | () | Integer an integer number depicting the total amount of fixtures in the curre | read-only | returns a number indicating the total amount of currently selected fixtures. | [D][M][O] | 3 |
| SelectionFirst | () | Integer number is the patch index of the first fixture in the current selection. It i | read-only | returns a set of integers for the selection's first fixture. It is the patch index number and the XYZ grid val | [D][M][O] | 4 |
| SelectionNext | () | Integer number is the patch index of the first fixture in the current selection. It i | read-only | returns a set of integers for the next fixture in a selection based on the index number input as an argument. | [D][M] | 4 |
| SerialNumber | () | String string is the serial number of the grandMA3 hardware or grandMA3 onPC. | read-only | returns the serial number of the grandMA3 hardware or grandMA3 onPC. | [D] | 12 (new: station identity) |
| ShowData | () | Handle a handle to the ShowData object. | read-only | ShowData is an object-free function that returns a handle to the object at position Root/ShowData. | [D][M] | all |
| ShowSettings | () | Handle a handle to the ShowSettings object. | read-only | ShowSettings is an object-free function that returns a handle to the object at Root/ShowData/ShowSettings. | [D] | 18 |
| StrToHandle | (string) | Handle handle based on the string with a hexadecimal number. | read-only | The object-free StrToHandle Lua function converts a string with a hexadecimal number format into a handle. The | [D][M] | none |
| Time | () | Number number (float) is the on-time for the station. | read-only | returns the time (in seconds) the station has been on, as a number (float). It is basically a stopwatch that s | [D] | new gap B |
| TouchObj | () | Handle the handle to the touch object. | read-only | returns the handle to the first found touch object. | [D] | none |
| UserVars | () | Handle a handle of the set of user variables. | read-only | returns a handle to the set of user variables. Read more about these in the Variables topic in the Macro secti | [D][O] | 23 |
| WaitModal | (timeout number) | Gma3UIObj or nil | read-only (blocks the Lua thread) | waits for a pop-up | [M] | none |
| GetPropertyColumnId | (class or object, name string) | integer or nil | read-only | column id of a property | [M] | bench aid |
| GetAttributeColumnId | (attribute or name) | integer or nil | read-only | column id of an attribute | [M] | bench aid |

## Object-free functions (change something)

"changes" includes UI pop-ups, file writes, hooks, timers and anything that sends output.

| function | arguments | returns | read-only? | meaning | evidence | relevance (GAPS row) |
|---|---|---|---|---|---|---|
| AddFixtures | (table) |  | changes | adds fixtures to the patch. The argument for the function is a table, which must contain valid data for the fu | [D] | 30 |
| CloseAllOverlays | () | This function does not return anything. | changes | closes any pop-ups or menus (overlays) open on any screen. | [D] | none |
| CloseUndo | (handle) | Boolean True: The undo list was closed. | changes | closes an open undo list. The function returns a boolean indicating if the function succeeds. | [D] | 33 |
| Cmd | (string[, handle]) | String A string is returned with the execution feedback known from the command line feedbac | changes | executes a command in the grandMA3 command line. It is executed in a Lua task - not the Main task (standard ty | [D][M] | 28, 29, 33 (undo arg in meta) |
| CmdIndirect | (string[, handle[, handle]]) | This function does not return anything. | changes | executes a command within the grandMA3 command line. It is executed asynchronously in the Main task. It does n | [D][M] | none |
| CmdIndirectWait | (string[, handle[, handle]]) | This function does not return anything. | changes | executes a command within the grandMA3 command line. It does not block the Lua execution and is executed synch | [D][M] | none |
| Confirm | (string[, string[, integer[, boolean]]]) | Boolean - True / 1: The pop-up was confirmed with the [OK]. | changes | provides a simple confirmation pop-up for a true/false query. It is part of the user interface functions. | [D] | none |
| CreateMultiPatch | ({handles}, integer[, string]) | Integer | nil integer indicates the amount of multi patch fixtures created. | changes | creates a series of multi patch fixtures to a table of fixtures. | [D] | 30 |
| CreateUndo | (string) | Handle the handle to the undo list. | changes | returns a handle to a list of commands and function calls grouped in the same oops action. | [D] | 33 |
| DelVar | (handle, string) | Boolean True / 1: The variable was deleted. | changes | deletes a specific variable in a set of variables. To learn more about the variables in plugins, have a look a | [D] | 23 (write) |
| DrawPointer | (integer,table[,integer]) | This function does not return anything. | changes | draws a red pointer on the display. There can only be one pointer at a time on each station. | [D] | none |
| Echo | (string) | This function does not return anything. | changes (text output only) | prints a string in the System Monitor. | [D][M] | none |
| ErrEcho | (string) | This function does not return anything. | changes (text output only) | prints a red error message on the System Monitor. | [D][M] | none |
| ErrPrintf | (string) | This function does not return anything. | changes (text output only) | prints a red error message in the Command Line History and System Monitor. | [D] | none |
| Export | (filename, export_data) | Boolean This function returns a boolean. | changes (writes a file) | The object-free Export Lua function exports a Lua table in XML format. | [D] | none |
| ExportCSV | (filename, export_data) | Boolean This function returns a boolean. | changes | The object-free ExportCSV Lua function exports a Lua table in CSV format. | [D] | none |
| ExportJson | (filename, export_data) | Boolean This function returns a boolean. | changes | The object-free ExportJson Lua function exports a Lua table in JSON format. | [D] | none (useful: dump a table to a file) |
| HookObjectChange | (function, handle, handle[, handle]) | Integer:  an integer identifying the hook. This can be saved to unhook the obje | changes | automatically calls a function when a grandMA3 object changes. | [D][M] | 1, 11 (change events instead of 5 Hz polling) |
| IncProgress | (handle, integer) | This function does not return anything. | changes | changes the value on the range for a progress bar using an integer input. A handle input argument defines the | [D] | none |
| MessageBox | (table) |  | changes | is used to create pop-up message boxes. These can be simple or complex information pop-ups with many different | [D] | none |
| Printf | (string) | This function does not return anything. | changes (text output only) | prints a string in the Command Line History and System Monitor. | [D] | none |
| SetLED | (handle,table) | This function does not return anything. | changes | sends a table with a set of LED brightness values to an MA3Module. After around two seconds, the system automa | [D] | none |
| SetProgress | (handle, integer) | This function does not return anything. | changes | defines a value on the range for a progress bar. A handle input argument defines the progress bar. The progres | [D] | none |
| SetProgressRange | (handle, integer, integer) | This function does not return anything. | changes | defines a range for a progress bar. | [D] | none |
| SetProgressText | (handle, string) | This function does not return anything. | changes | defines a text string to be displayed in a progress bar next to the progress bar title text. The title cannot | [D] | none |
| SetVar | (handle, string, value) | Boolean True / 1: The variable was set. | changes | sets a value to a specific variable in a set of variables. To learn more about the variables in plugins, look | [D] | 23 (write) |
| StartProgress | (string) | Handle handle is the identifier for the progress bar. | changes | creates and displays a progress bar on all screens. A string input argument creates a title for the progress b | [D] | none |
| StopProgress | (handle) | This function does not return anything. | changes | removes a progress bar. A handle input argument defines which progress bar it removes. The progress bar must e | [D] | none |
| TextInput | ([string[, string[, integer[, integer]]]]) | String user input. | changes | opens a text input pop-up and returns the typed input as a string. It is part of the user interface functions. | [D] | none |
| Timer | (string, integer, integer[, string[, handle]]) | This function does not return anything. | changes | call a different function using a timer. The other function can be called multiple times using the timer inter | [D] | none |
| Unhook | (integer) | This function does not return anything.  Hint: | changes | removes a hook. | [D][M] | none |
| UnhookMultiple | (function, handle, handle) | Integer:  an integer indicating how many hooks were unhooked. | changes | unhooks multiple hooks based on an input. This input acts like a filter to identify all the hooks that should | [D] | none |
| RemoteCommand | (ip string, command string) | boolean | changes (sends a command to ANOTHER station) | runs a command line on a remote station | [M] | none; do not use |

## Object functions (read-only)

Called on a handle with colon notation. The help has only 19 object pages; most rows come from the meta file alone.

| function | arguments | returns | read-only? | meaning | evidence | relevance (GAPS row) |
|---|---|---|---|---|---|---|
| Addr | (handle[, handle[, boolean]]) | String Text string with the address in a parent-child number format separated by dots. | read-only | The returned address is from the root as a default. This optional handle can specify a different base location | [D][M][O] | bench aid |
| AddrNative | (handle[, handle[, boolean]]) | String Text string with the address in a parent-child name format separated by dots. | read-only | The returned address is from the root as a default. This optional handle can specify a different base location | [D][M] | bench aid |
| Children | (handle) | Table a table with handles for the child objects. If there are no children, | read-only | creates a table of handles for the children of an object. | [D][M][O] | all |
| Count | (handle) | Integer an integer indicating the number of children of the object. | read-only | returns an integer number indicating the number of child objects. | [D][M] | all |
| Dump | (handle) | nothing but outputs information about the object in the Command Line | read-only | returns a string with information about the object, for instance, the name, class, path of the object, its pro | [D][M] | bench aid |
| Export | (handle, string, string) | Boolean a boolean indicating if the export was a success. | read-only (writes a file) | exports an object into an XML file. | [D][M][O] | bulk export |
| Get | (handle, string[, integer]) | String the value of the property. If the property is a boolean, then the ret | read-only | returns a string with information about a specified property of the object, for instance, the object's name, c | [D][M][O] | all |
| GetChildClass | (handle) | String a text string with the name of the class of the object's children. | read-only | returns a string with the name of the class of the object's children. | [D][M] | bench aid |
| GetClass | (handle) | String the text string with the name of the object's class. | read-only | returns a string with information about the class for the object. | [D][M][O] | bench aid |
| GetDependencies | (handle) | Table a table with the handles for the different dependency objects. | read-only | returns a table with the objects' dependencies. | [D][M] | 24 |
| GetFaderText | (handle, {[string], [integer]}) |  | read-only | returns a text string indicating a fader value for the object. | [D][M][O] | 8b |
| GetReferences | (handle) | Table a table with the handles for the different objects referencing this o | read-only | returns a table with handles for the objects referencing this object. | [D][M] | 24 |
| GetUIEditor | (handle) | String a text string with the name of the object's UI editor. | read-only | returns a text string with the name of the UI editor for the object. | [D][M] | 19 |
| GetUISettings | (handle) | String a text string with the name of the object's UI settings. | read-only | returns a text string with the name of the UI settings for the object. | [D][M] | 18, 19 |
| HasActivePlayback | (handle) | Boolean a boolean indicating the playback status: | read-only | returns a boolean indicating if an object has a currently active playback, for instance, if a sequence has an | [D][M][O] | 1 |
| Ptr | (handle, integer) | Handle | nil a handle to the child object. If the child object does not exist, the | read-only | returns the handle to a child object. | [D][M][O] | all |
| Count | () | integer | read-only | number of children | [M] | all |
| CurrentChild | () | object or nil | read-only | the current child (what Cue Display calls) | [M] | 1 |
| CmdlinePtr / CmdlineChildren | (idx) / () | object / table | read-only | children as the command line sees them | [M] | bench aid |
| MaxCount | () | integer | read-only | capacity of a pool | [M] | 25, 26 |
| Index | () | integer | read-only | position in the parent | [M] | bench aid |
| Parent | () | object or nil | read-only | parent object | [M] | bench aid |
| FindParent | (class) | object or nil | read-only | nearest parent of a class | [M] | bench aid |
| Find / FindRecursive / FindWild | (name[, class]) | object or nil | read-only | search children by name (recursive, wildcard) | [M] | 26 (CAUTION: recursive walks are census-like) |
| HasParent | (obj) | boolean | read-only |  | [M] | bench aid |
| Compare | (obj) | boolean | read-only | same object? | [M] | bench aid |
| IsValid / IsEmpty / IsLocked | () | boolean | read-only | object state; IsEmpty on a ProgrammerPart may answer 'is the programmer empty' | [M] | 29 [?] |
| IsRunningPlayback | () | boolean | read-only | running (meta has this next to the documented HasActivePlayback) | [M] | 1 |
| IsClass | (class) | boolean | read-only | class test | [M] | bench aid |
| PropertyCount / PropertyName / PropertyType / PropertyInfo | (idx) | integer / string / string / table | read-only | LISTS every property of an object with type and read-only flag: reads the schema without touching values | [M] | ALL (replaces blind Get guesses) |
| GetAssignedObj | () | object or nil | read-only | the object an executor or pool button points at | [M] | 1, 8b, 20 |
| HasReferences / HasDependencies | () | boolean | read-only | cheap test before GetReferences | [M] | 24 |
| GetLineCount / GetLineAt | ()/(n) | integer / string | read-only | text lines of an object that holds text (command history, system monitor?) | [M] | 11 [?], 14 |
| HasEditSettingUI / HasEditUI | () | boolean | read-only | UI test | [M] | 19 |
| GetFader (documented only in meta and onPC [O]) | ({index, token}) | number 0..100 | read-only | fader level | [M] | 8b |
| GetExportFileName | (bool) | string | read-only |  | [M] | none |

## Object functions (change something)

| function | arguments | returns | read-only? | meaning | evidence | relevance (GAPS row) |
|---|---|---|---|---|---|---|
| Import | (handle, string, string) | Boolean a boolean indicating if the import was a success. | changes (merges XML into show data, no pop-up) | imports an object written in XML format. | [D][M] | 31, 34 |
| Set | (handle, string, string[, integer]) | This function does not return anything. | changes | sets a value to a specified property of the object, for instance, the object's name. | [D][M][O] | 33 (no undo arg) |
| SetFader | (handle, {[number], [boolean], [string]}) |  | changes | sets a fader to a specified level. It must be used on an object that has faders. | [D][M] | 35 |
| Create / Append / Acquire / Insert / Delete / Remove / Copy | (idx, class, undo) | object | changes | structural edits to show data (undo arg exists here) | [M] | 32 [?] (timecode events), 30 |
| Changed | (level) | none | changes | fires change notification | [M] | none |
| PrepareAccess | () | none | changes (state) | unclear | [M] | doubt |
| SetChildren / SetChildrenRecursive | (prop, value) | none | changes | bulk property write | [M] | none |
| Load / Save | (path, name) | boolean | changes | file load/save of the object | [M] | 31 |
| CommandCall / CommandAt / CommandDelete / CommandStore / CommandCreateDefaults | ... | none | changes | pool-button actions as commands (Store takes the programmer!) | [M] | 29: avoid |
| CmdlineChildren | () | table | read-only | see above | [M] | bench aid |
| SetFader | ({value, faderDisables, token}) | none | changes (moves a fader) |  | [M] | 35 |

## Which function closes which gap

Evidence: [D] help page, [M] meta file, [O] run on onPC 2026-11-21, [?] not proven. Every row below is a read unless it says "changes". Nothing here was run by this study (offline). Console safety still applies: each unproven call is benched on onPC first.

| GAPS row | Function(s), exact call | Verdict |
|---|---|---|
| 1 running playbacks | `seq:HasActivePlayback()`, `seq:CurrentChild()` (proven on the console by Cue Display); `seq:IsRunningPlayback()` [M]; `GetCurrentCue()` for the selected sequence | closed by tools; `HookObjectChange(fn, obj, plugin)` could replace 5 Hz polling [?] |
| 2 programmer contents | `Programmer()`, `ProgrammerPart()` [O]; `part:Export(path, name)` [O]; `part:IsEmpty()` [M] | no value-reading function; Export is the route |
| 3 selection count | `SelectionCount()` [O] | closed |
| 4 which fixtures selected | `local i = SelectionFirst()` then `i = SelectionNext(i)` until nil/0 [D][M]; `GetSubfixture(i)` gives the handle, `:Get("FID")` the number [?] | function exists; loop is bounded by SelectionCount, safe |
| 5 DMX sheet | `GetDMXUniverse(n[, true])` returns a table of 512 values, nil if the universe is not granted; `GetDMXValue(addr, universe[, percent])` [D][O] | exists; "granted" limit is a doubt (see below) |
| 6 value and its owner | `GetRTChannels(subfixture_handle_or_index, true)` then `GetRTChannel(i)` returns a table with handle `fixture`, `subfixture`, `dmx_channel`, ints `dmx_default`, `dmx_highlight`, `dmx_lowlight`, `ui_index_first`, `rt_index`, `freq`, tables `info`, `patch` [D][O]; `GetUIChannels` + `GetAttributeByUIChannel(n)` for names. Live value and owner layer: not documented | defaults and patch: yes. Owner (cue/programmer/park): no named function; test whether `info` carries it |
| 7 parked / tester channels | no function. `GetDMXValue` returns nil for ungranted addresses only | gap stays object-tree (`PARKEDCOUNT` etc.) |
| 8 masters | `MasterPool()` [O] then `Children()`/`Get("NORMEDVALUE")` | closed by `ma3_masters` |
| 8b executor and master fader levels | `GetExecutor(n)` returns executor and page [O]; `exec:GetFader({token="FaderMaster"})` returns 0..100 [O]; `:GetFaderText({token=...})`; tokens FaderMaster, FaderX, FaderXA, FaderXB, FaderTemp, FaderRate, FaderSpeed, FaderHighlight, FaderLowlight, FaderSolo, FaderTime | exists; one call per executor and per token (cap the loop) |
| 9 user selected sequence, page, world, filter | `SelectedSequence()`, `CurrentExecPage()`, `CurrentProfile()`, `CurrentEnvironment()` [O] (current user only); other users: object tree | current user only; no function takes a user argument |
| 10 timecode | `SelectedTimecode()` [O]; slot via object tree | running flag: no function |
| 11 messages | none in help or meta. `GetTopModal()`, `GetTopOverlay()` show open pop-ups only. `obj:GetLineCount()` / `GetLineAt(n)` [M, no help page] might read text objects | no function documented; bench GetLineCount on the System Monitor / history object |
| 12 users and stations | `CurrentUser()` [O]; `HostType()`, `HostSubType()`, `HostOS()`, `SerialNumber()`, `BuildDetails()` describe THIS station only | session members: no function |
| 13 granted parameters | `GetDMXValue` nil when ungranted (universe level); fixture level: no function | partial |
| 14 Oops list | `ma3_history` already | none needed |
| 15 sACN / Art-Net | `DeviceConfiguration()` [O] then `.DMXProtocols` children | no function; object tree |
| 16 DMX ports | `DeviceConfiguration()` / Root 22.1 | closed by `ma3_ports` |
| 17 remote inputs | none | gap stays object tree |
| 18 user settings | `CurrentProfile()`, `ShowSettings()` then `Get(name)` | object tree |
| 19 views, screens | `CurrentScreenConfig()` [O], `GetDisplayCollect()`, `GetDisplayByIndex(n)`, `GetScreenContent(screenconfig)`, `GetFocusDisplay()`, `GetFocus()`, `GetUIObjectAtPosition(display, {x=,y=})`, `GetTopOverlay()`, `Pult()`, `DefaultDisplayPositions()` | exists; first function family with a real "what is on screen" answer |
| 20 executor configs | `exec:Get("EXECUTORCONFIGURATION")`; `exec:GetAssignedObj()` [M] | property read; no new function |
| 21 timecode slot settings | none | gap |
| 22 show files | `GetShowFileStatus()`, `NeedShowSave()` [O]; `DirList(path[, filter])`, `FileExists(path)`, `GetPath(type)`, `GetPathOverrideFor(...)` read drives from Lua | exists; replaces the Mac-side reader if the plugin may list drives |
| 23 macro variables | `UserVars()`, `GlobalVars()` [O] then `GetVar(varset, "name")`; `AddonVars(name)` help says not useful | exists; enumerate with `:Children()` and `:Get("Name")` |
| 24 where used | `obj:GetReferences()`, `obj:GetDependencies()`, `HasReferences()`, `HasDependencies()` [D][M] | exists; per object, so bounded |
| 25 other data pools | `DataPool()` is the current pool only [D]; others via Root path | no function for a pool argument |
| 26 worlds, filters, MAtricks, timers, ... | `ObjectList("Filter 1 Thru")` etc. returns handles [D][M]; `FindTexture(name)`; `SelectedTimer()`, `SelectedLayout()`, `SelectedFeature()` [O] | exists; bulk range reads are a loop risk, cap them |
| 27 RDM | none | gap |
| 28 own user | no function creates or switches a user; `Cmd` has no user argument. `LogIn` is a command | gap |
| 29 safe Store | `Programmer():IsEmpty()` or the part's `IsEmpty()` [M, ?] is the check; `Cmd(fmt, undo)` | bench IsEmpty |
| 30 patch change | `AddFixtures({mode=, amount=, name=, fid=, patch={"1.1"}})`, `CheckDMXCollision`, `CheckFIDCollision`, `CreateMultiPatch`, `FirstDmxModeFixture` [D] | changes show data; whether it needs the Patch menu open is not stated |
| 31 import from stick | `obj:Import(path, name)` merges XML with no pop-up [D][M]; `FileExists`, `DirList` | exists, high risk; bench on a scratch object |
| 32 timecode events | `obj:Create(idx, class, undo)` / `Append` [M] on the track; never shown | [?] bench |
| 33 undo for set | `CreateUndo(name)` / `CloseUndo(handle)` [D]; `Cmd(fmt, undo)` [M]. `obj:Set(prop, value, level)` has NO undo argument in meta | `ma3_set` cannot join an undo group through `Set`; `Create/Delete/Append` can |
| 34 plugin self-update | `obj:Import(path, name)` on the plugin pool [?] | bench |
| 35 fire playback | `exec:SetFader({value=, token=})`; `Cmd("Go ...")` | possible, by Aaron's rule not done |

### New gaps to add (read-only functions that reveal what GAPS.md does not list)

- A. **Software and station identity**: `BuildDetails()` (version, git hash, compile date, host type), `ConfigTable()`, `ReleaseType()`, `SerialNumber()`. Cheap, proves which build runs.
- B. **Station health**: `GetSample("CPU"|"MEMORY"|"CPUTEMP"|"GPUTEMP"|"SYSTEMP"|"FANRPM")`, `GetDebugFPS()` [O], `Time()` (uptime). Would have shown the 2026-11-08 freeze coming.
- C. **Desk lock and modal state**: `DeskLocked()`, `GetTopModal()` [O], `GetTopOverlay()`.
- D. **Hardware modules**: `GetButton(handle)` (512 button states of an MA3 Module), `KeyboardObj()`, `MouseObj()`, `TouchObj()`.
- E. **Preset contents**: `GetPresetData(preset_handle[, phaserOnly[, byFixtures]])` returns the stored values of a preset as tables. Nothing in the ledger reads preset values.
- F. **Keyword table**: `GetTokenNameByIndex(i)` walks every command keyword; `GetTokenName(short)` [O] checks shortcuts (guard).
- G. **The API's own list**: `GetApiDescriptor()` and `GetObjApiDescriptor()` return every function THIS build has, with argument and return text. Run both once on onPC; they will list functions neither the help nor the meta file knows.
- H. **Schema without values**: `obj:PropertyCount()`, `PropertyName(i)`, `PropertyType(i)`, `PropertyInfo(i)` [M] list every property of any object and whether it is read-only. This replaces blind `Get` guesses.
- I. **Class tree**: `ClassExists`, `IsClassDerivedFrom`, `GetClassDerivationLevel`, `obj:GetChildClass()` [D].
- J. **Channel catalogue**: `GetChannelFunction(a,b)`, `GetChannelFunctionIndex`, `GetUIChannelIndex`, `GetAttributeIndex(name)`.

## Contradictions and doubts

- **Meta file is old and partial.** It lacks GetDMXValue, GetDMXUniverse, GetRTChannel(s), GetUIChannel(s), GetSubfixture, GetExecutor, GetCurrentCue, GetVar and most functions the help documents. Use it for types only where it has the function.
- **SelectionFirst**: help says no arguments and returns four integers (index, x, y, z); meta says `SelectionFirst(onlyFullySelected?)` returns one SubfixtureIndex. The help text for SelectionNext repeats SelectionFirst's return text (copy error). The 0-based index versus `GetSubfixture` 1-based use is not stated: bench.
- **Dump**: help says it prints to the Command Line History and returns nothing; meta says it returns a string. Bench before relying on either.
- **Cmd**: help gives a second optional handle; meta types it as `undo`. `Cmd` runs on the command line of the user who started the plugin (gap 28).
- **Get role argument**: help says a role integer returns text; meta types roles `Default=0, Display=1, DisplayShort=2, Edit=4, ObjectNoOnly=8`. Display-role reads are likely safer for names; unproven.
- **Set**: help marks its fourth argument "?"; meta calls it `override_change_level` (ChangeLevel enum). No undo argument exists, so gap 33 needs another route.
- **GetDMXValue / GetDMXUniverse return nil when the address or universe is "not granted".** Not defined in the help. On a console with output the meaning is unclear; row 13 depends on it.
- **GetAttributeIndex** return text is a copy of GetSubfixtureCount's (says total patched fixtures); it should be a 0-based index. CurrentExecPage text names CurrentEnvironment; DefaultDisplayPositions says it returns the command line object. Treat the one-line meanings as unreliable where signatures disagree.
- **Unhook**: help id `Unhook`, meta `UnHook`; call spelling unproven.
- **Help versions**: pages say "Version 2.2" / 2.0 inside the 2.5 help, so newer functions may be missing from the help (G above is the fix).
- **GetLineCount / GetLineAt**, **IsEmpty**, **PropertyInfo**, **Find\***, **GetAssignedObj**, **IsRunningPlayback**: meta only, no help page; whether the build still has them is unproven.
- **Console safety**: `Find`/`FindRecursive`/`ObjectList` over wide ranges and loops over `GetRTChannels` for all fixtures are census-like. Classify as "bench on onPC, then bounded" per CLAUDE.md. `Import`, `Create`, `AddFixtures`, `RemoteCommand`, `CommandStore` are never to be benched casually.
- **Not read in full**: each help page was read through its Description, Arguments and Return sections only; example code and notes were skipped. `GetPresetData`'s table layout and `GetRTChannel`'s `info` and `patch` sub-tables are not described in the help.

## Sources

- Help 2.5, `.cache/ma-help/2.5/`: all 133 `lua_objectfree_*` pages and all 19 `lua_object_*` pages listed in `toc.json` (the help has 19 object pages, not about 154; the total of `lua_object*` ids is 154 including the objectfree ones). Read via `tools/helpsite/text.py`, sections before "Example".
- MA meta file: `~/MALightingTechnology/gma3_2.5.1/shared/resource/lib_plugins/systemtests/gma3_api_meta.lua` (read whole).
- Project: `docs/GAPS.md` (read whole), `docs/atlas/topics/lua-api.md` and `docs/research/2026-11-19-live-state-bench.md` (skimmed).
- Not used: any contact with the console or onPC. [O] marks come from the task brief (2026-11-21 onPC run), not from this study.
