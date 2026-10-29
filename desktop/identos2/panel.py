"""IDENT Desktop 2 panel; Openbox remains the proven window manager."""
from __future__ import annotations

import tkinter as tk
from datetime import datetime

from .core import DEFAULTS, launch, load_settings, save_settings

BG = "#111827"
PANEL = "#182439"
TEXT = "#f0f5ff"
ACCENT = "#69a5eb"


class DesktopPanel:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.settings = load_settings()
        root.title("IDENT Desktop 2")
        root.configure(bg=PANEL)
        root.overrideredirect(True)
        root.attributes("-topmost", True)

        frame = tk.Frame(root, bg=PANEL)
        frame.pack(fill="both", expand=True)
        self.menu = tk.Menu(root, tearoff=False, bg=BG, fg=TEXT)
        for label, action in (("Terminal", "terminal"), ("Files", "files"),
                              ("Browser", "browser"), ("Applications", "applications"),
                              ("Switch window", "windows"), ("Diagnostics", "diagnostics")):
            self.menu.add_command(label=label, command=lambda a=action: launch(a))
        self.menu.add_separator()
        self.menu.add_command(label="Settings", command=self.open_settings)
        self.menu.add_command(label="Log out", command=root.destroy)
        self.button(frame, "◆ IDENT", self.open_menu, foreground=ACCENT)
        for label, action in (("Terminal", "terminal"), ("Files", "files"),
                              ("Browser", "browser"), ("Apps", "applications"),
                              ("Windows", "windows")):
            self.button(frame, label, lambda a=action: launch(a))
        self.clock = tk.Label(frame, bg=PANEL, fg=TEXT, padx=20)
        self.clock.pack(side="right")
        root.bind("<Control-Alt-Tab>", lambda _: launch("windows"))
        root.bind("<Control-Alt-t>", lambda _: launch("terminal"))
        root.bind("<Configure>", self.on_configure)
        self.place()
        self.tick()

    def button(self, frame, label, command, foreground=TEXT):
        widget = tk.Button(frame, text=label, command=command, bg=PANEL,
                           fg=foreground, activebackground=BG, activeforeground=TEXT,
                           relief="flat", bd=0, padx=12, pady=6)
        widget.pack(side="left")
        return widget

    def place(self):
        height = self.settings["panel_height"]
        width = self.root.winfo_screenwidth()
        y = self.root.winfo_screenheight() - height
        self.root.geometry(f"{width}x{height}+0+{y}")

    def on_configure(self, _):
        # Resize when resolution changes; avoid feeding geometry events back endlessly.
        expected_width = self.root.winfo_screenwidth()
        if self.root.winfo_width() != expected_width:
            self.root.after_idle(self.place)

    def open_menu(self):
        try:
            self.menu.tk_popup(self.root.winfo_rootx() + 8,
                               max(0, self.root.winfo_rooty() - 260))
        finally:
            self.menu.grab_release()

    def open_settings(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("IDENT Desktop Settings")
        dialog.geometry("360x180")
        dialog.configure(bg=BG)
        twenty_four = tk.BooleanVar(value=self.settings["clock_24h"])
        tk.Checkbutton(dialog, text="24-hour clock", variable=twenty_four,
                       bg=BG, fg=TEXT, selectcolor=PANEL).pack(pady=10)
        height = tk.IntVar(value=self.settings["panel_height"])
        tk.Label(dialog, text="Panel height", bg=BG, fg=TEXT).pack()
        tk.Scale(dialog, from_=36, to=96, orient="horizontal", variable=height,
                 bg=BG, fg=TEXT).pack(fill="x", padx=20)

        def apply():
            self.settings = {"clock_24h": twenty_four.get(), "panel_height": height.get()}
            try:
                save_settings(self.settings)
            except OSError as error:
                tk.messagebox.showerror("Cannot save settings", str(error), parent=dialog)
                return
            self.place()
            dialog.destroy()
        tk.Button(dialog, text="Save settings", command=apply).pack(pady=8)

    def tick(self):
        fmt = "%a %d %b  %H:%M" if self.settings["clock_24h"] else "%a %d %b  %I:%M %p"
        self.clock.configure(text=datetime.now().strftime(fmt))
        self.root.after(1000, self.tick)


def main():
    root = tk.Tk(className="IDENTDesktop")
    DesktopPanel(root)
    root.mainloop()


if __name__ == "__main__":
    main()
