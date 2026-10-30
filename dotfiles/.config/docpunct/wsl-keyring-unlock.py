"""Unlock the default Secret Service collection without reading any secrets."""

import ctypes as C
import sys


class Error(C.Structure):
    _fields_ = [("domain", C.c_uint), ("code", C.c_int), ("message", C.c_char_p)]


def main():
    lib = C.CDLL("libsecret-1.so.0")
    error = C.POINTER(Error)()
    error_arg = C.POINTER(C.POINTER(Error))

    get_service = lib.secret_service_get_sync
    get_service.argtypes = [C.c_int, C.c_void_p, error_arg]
    get_service.restype = C.c_void_p

    read_alias = lib.secret_service_read_alias_dbus_path_sync
    read_alias.argtypes = [C.c_void_p, C.c_char_p, C.c_void_p, error_arg]
    read_alias.restype = C.c_char_p

    unlock = lib.secret_service_unlock_dbus_paths_sync
    unlock.argtypes = [
        C.c_void_p, C.POINTER(C.c_char_p), C.c_void_p, C.c_void_p, error_arg
    ]
    unlock.restype = C.c_int

    def check_error():
        if error:
            raise RuntimeError(error.contents.message.decode(errors="replace"))

    service = get_service(0, None, C.byref(error))
    check_error()
    if not service:
        raise RuntimeError("could not open Secret Service")

    path = read_alias(service, b"default", None, C.byref(error))
    check_error()
    if not path or path == b"/":
        return  # No default keyring yet; leave creation to the user's application.

    # The provider skips unlocked collections and handles the password dialog.
    # Native allocations live only for this short-lived helper process.
    paths = (C.c_char_p * 2)(path, None)
    count = unlock(service, paths, None, None, C.byref(error))
    check_error()
    if count <= 0:
        raise RuntimeError("default keyring was not unlocked (dialog may have been cancelled)")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError) as exc:
        print(f"docpunct: WSL keyring unlock: {exc}", file=sys.stderr)
        sys.exit(1)
