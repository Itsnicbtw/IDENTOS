# IDENT Desktop 2: Native C panel

Desktop 2 uses **GTK 3 and C** for its application panel, clock, settings and allowlisted launch actions. Openbox still manages windows and Xorg handles display and input.

The executable is compiled inside the Debian Trixie live-build chroot to avoid mixing Ubuntu and Debian shared libraries. Its session is selectable as **IDENT Desktop 2 (Experimental)** in LightDM. IDENT Desktop 1 remains the default fallback.

## Features

- Application launcher and window selector through Rofi; file manager and browser shortcuts
- Clock format (12/24 hour) and panel-height settings
- Private user settings in `$XDG_CONFIG_HOME/identos/desktop2.ini`
- Commands launched from a fixed allowlist without invoking a shell
- Headless `--self-test` and strict C compilation in CI

## Local build

```sh
sudo apt-get install libgtk-3-dev pkg-config
cc -O2 -std=c11 -Wall -Wextra -Werror -Wno-error=deprecated-declarations \
  $(pkg-config --cflags gtk+-3.0) desktop/identos2/panel.c \
  -o /tmp/identos-panel2 $(pkg-config --libs gtk+-3.0)
/tmp/identos-panel2 --self-test
```

## Limitations

This is a native panel, **not** a new compositor, window manager or display server. Openbox and Xorg are retained. Current panel positioning uses the screen dimensions, so multi-monitor behaviour, taskbar work-area reservation and graphical accessibility need interactive testing. The old Python Desktop 1 source remains a safe fallback until those tests are complete.
