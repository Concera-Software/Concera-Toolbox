# Bash Library Documentation

Generated from Doxygen-style Bash comments.

## Table of Contents

- **bash/toolbox-core.sh**
  - [core::function_exists](#corefunction-exists)
  - [core::get_filename](#coreget-filename)
  - [core::is_library](#coreis-library)
  - [core::load_libraries](#coreload-libraries)
  - [core::load_library](#coreload-library)
  - [core::log](#corelog)
  - [core::log_color](#corelog-color)
  - [core::log_debug](#corelog-debug)
  - [core::log_error](#corelog-error)
  - [core::log_info](#corelog-info)
  - [core::log_warning](#corelog-warning)
- **bash/toolbox-ftp.sh**
  - [ftp::check_dependencies](#ftpcheck-dependencies)
  - [ftp::ftp_file_exists](#ftpftp-file-exists)
- **bash/toolbox-log.sh**
  - [logger::get_message_type](#loggerget-message-type)
  - [logger::get_message_type_color](#loggerget-message-type-color)
  - [logger::log](#loggerlog)
  - [logger::log_critical](#loggerlog-critical)
  - [logger::log_debug](#loggerlog-debug)
  - [logger::log_error](#loggerlog-error)
  - [logger::log_info](#loggerlog-info)
  - [logger::log_notice](#loggerlog-notice)
  - [logger::log_success](#loggerlog-success)
  - [logger::log_to_console](#loggerlog-to-console)
  - [logger::log_to_file](#loggerlog-to-file)
  - [logger::log_to_syslog](#loggerlog-to-syslog)
  - [logger::log_warning](#loggerlog-warning)
  - [logger::parse_function_args](#loggerparse-function-args)
  - [string::tolower](#stringtolower)
  - [string::toupper](#stringtoupper)

---

## bash/toolbox-core.sh

### core::function_exists

**File:** `bash/toolbox-core.sh`  
**Line:** `81`

```text
Check if a Bash function exists.

This function validates whether the specified function
name is currently loaded and available in the shell.

@param $1 Function name

@return
0 Function exists
1 Function does not exist

@example
if core::function_exists "log::log"; then
echo "Logger loaded"
fi

@example
core::function_exists "core::load_library"
```

### core::get_filename

**File:** `bash/toolbox-core.sh`  
**Line:** `56`

_No documentation found._

### core::is_library

**File:** `bash/toolbox-core.sh`  
**Line:** `117`

```text
Validate whether a file is a Bash library file.

A valid library file:
- Must exist
- Must be a regular file
- Must NOT be executable
- Must NOT contain a shebang line

@param $1 Full path and filename

@return
0 File is a valid library
1 File does not exist or is not a regular file
2 File is executable
3 File contains a shebang line

@example
if core::is_library "./lib/test.lib.sh"; then
echo "Valid library"
fi

@example
core::is_library "/opt/bashlib/bashlib-log.lib.sh"
```

### core::load_libraries

**File:** `bash/toolbox-core.sh`  
**Line:** `226`

```text
Include (load) all Bash library files from a directory.

The function loads all valid library files from the given directory.
A file is considered a valid library when core::is_library() returns
success.

The input path may include a filename filter such as:

/opt/bashlib/*.lib.sh

If no filter is provided, "*.sh" is used as default.

Subdirectories can optionally be scanned by setting the depth argument.

@param $1 Directory path, optionally including a file filter
@param $2 Optional recursion depth for subdirectories, default is 0

@return
0 Libraries loaded successfully
1 Missing argument or library directory not found

@example
core::load_libraries "/opt/bashlib"

@example
core::load_libraries "/opt/bashlib/*.lib.sh"

@example
core::load_libraries "/opt/bashlib/*.lib.sh" 2
```

### core::load_library

**File:** `bash/toolbox-core.sh`  
**Line:** `164`

```text
Include (load) a single Bash library file.

The specified library file is validated using
core::is_library() before inclusion.

A library is considered successfully loaded when it
registers itself in the LIB_REGISTER array using:

LIB_REGISTER["<filename>:version"]

Already loaded libraries are skipped automatically.

@param $1 Full path and filename of the library

@return
0 Library successfully loaded or already loaded
1 File is not a valid library
2 Library inclusion failed

@example
core::load_library "./lib/bashlib-log.lib.sh"

@example
core::load_library "${BASHLIB_DIR}/bashlib-core.lib.sh"
```

### core::log

**File:** `bash/toolbox-core.sh`  
**Line:** `345`

```text
Write a formatted log message to the console.

If the external function log::log exists, the function call
is forwarded to that implementation.

@param $1 Log type
@param $2...$n Log message

@return
0 Success
1 Invalid argument count

@example
core::log "INFO" "Application started"

@example
core::log "EROR" "Database connection failed"
```

### core::log_color

**File:** `bash/toolbox-core.sh`  
**Line:** `306`

```text
Return the configured ANSI color code for a log type.

@param $1 Log type

Supported log types:
EROR = Error messages
WARN = Warning messages
INFO = Informational messages
DBUG = Debug messages

@return Echoes the ANSI color code to stdout.

@example
COLOR="$(core::log_color "INFO")"
echo -e "${COLOR}Information${env_COLOR_RESET}"
```

### core::log_debug

**File:** `bash/toolbox-core.sh`  
**Line:** `390`

```text
Write a debug log message.

This is a wrapper around core::log() using the
predefined log type DBUG.

@param $1...$n Debug message

@return
0 Success
1 Invalid argument count

@example
core::log_debug "Loading configuration"

@example
core::log_debug "Variable value:" "$TEST"
```

### core::log_error

**File:** `bash/toolbox-core.sh`  
**Line:** `412`

```text
Write an error log message.

This is a wrapper around core::log() using the
predefined log type EROR.

@param $1...$n Error message

@return
0 Success
1 Invalid argument count

@example
core::log_error "Unable to connect to database"

@example
core::log_error "Configuration file missing:" "$FILE"
```

### core::log_info

**File:** `bash/toolbox-core.sh`  
**Line:** `456`

```text
Write an informational log message.

This is a wrapper around core::log() using the
predefined log type INFO.

@param $1...$n Information message

@return
0 Success
1 Invalid argument count

@example
core::log_info "Application started"

@example
core::log_info "Loaded library:" "$FILE"
```

### core::log_warning

**File:** `bash/toolbox-core.sh`  
**Line:** `434`

```text
Write a warning log message.

This is a wrapper around core::log() using the
predefined log type WARN.

@param $1...$n Warning message

@return
0 Success
1 Invalid argument count

@example
core::log_warning "Configuration file not found"

@example
core::log_warning "Retrying connection to server"
```

## bash/toolbox-ftp.sh

### ftp::check_dependencies

**File:** `bash/toolbox-ftp.sh`  
**Line:** `34`

_No documentation found._

### ftp::ftp_file_exists

**File:** `bash/toolbox-ftp.sh`  
**Line:** `46`

_No documentation found._

## bash/toolbox-log.sh

### logger::get_message_type

**File:** `bash/toolbox-log.sh`  
**Line:** `260`

_No documentation found._

### logger::get_message_type_color

**File:** `bash/toolbox-log.sh`  
**Line:** `212`

_No documentation found._

### logger::log

**File:** `bash/toolbox-log.sh`  
**Line:** `458`

_No documentation found._

### logger::log_critical

**File:** `bash/toolbox-log.sh`  
**Line:** `528`

_No documentation found._

### logger::log_debug

**File:** `bash/toolbox-log.sh`  
**Line:** `558`

_No documentation found._

### logger::log_error

**File:** `bash/toolbox-log.sh`  
**Line:** `534`

_No documentation found._

### logger::log_info

**File:** `bash/toolbox-log.sh`  
**Line:** `546`

_No documentation found._

### logger::log_notice

**File:** `bash/toolbox-log.sh`  
**Line:** `552`

_No documentation found._

### logger::log_success

**File:** `bash/toolbox-log.sh`  
**Line:** `564`

_No documentation found._

### logger::log_to_console

**File:** `bash/toolbox-log.sh`  
**Line:** `308`

_No documentation found._

### logger::log_to_file

**File:** `bash/toolbox-log.sh`  
**Line:** `349`

_No documentation found._

### logger::log_to_syslog

**File:** `bash/toolbox-log.sh`  
**Line:** `391`

_No documentation found._

### logger::log_warning

**File:** `bash/toolbox-log.sh`  
**Line:** `540`

_No documentation found._

### logger::parse_function_args

**File:** `bash/toolbox-log.sh`  
**Line:** `178`

_No documentation found._

### string::tolower

**File:** `bash/toolbox-log.sh`  
**Line:** `151`

_No documentation found._

### string::toupper

**File:** `bash/toolbox-log.sh`  
**Line:** `165`

_No documentation found._

---

Total documented functions: 29
