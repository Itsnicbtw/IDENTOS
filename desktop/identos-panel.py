#!/usr/bin/env python3
"""IDENT Desktop: intentionally small shell, not a pretend window manager."""
import os
import shutil
import subprocess
import tkinter as tk
from datetime import datetime

BG = "#111827"
PANEL = "#1d293b"
TEXT = "#eff6ff"
HOVER = "#314562"

def launch(*args):
    if not shutil.which(args[0]):
        return
    try:
        subprocess.Popen(args, start_new_session=True, close_fds=True)
    except OSError as exc:
        print(f"Could not launch {args[0]}: {exc}", flush=True)

root = tk.Tk(className="IDENTDesktop")
root.title("IDENT Desktop")
root.configure(bg=PANEL)
root.overrideredirect(True)
root.attributes("-topmost", True)

bar = tk.Frame(root, bg=PANEL)
bar.pack(fill="both", expand=True)

def action(label, command):
    btn = tk.Button(bar, text=label, command=command, bg=PANEL, fg=TEXT,
                    activebackground=HOVER, activeforeground=TEXT, relief="flat",
                    borderwidth=0, padx=16, pady=8, font=("DejaVu Sans", 10))
    btn.pack(side="left", padx=2)
    return btn

menu = tk.Menu(root, tearoff=False, bg=BG, fg=TEXT, activebackground=HOVER)
menu.add_command(label="Terminal", command=lambda: launch("xterm"))
menu.add_command(label="Files", command=lambda: launch("pcmanfm"))
menu.add_command(label="Browser selection", command=lambda: launch("identos-browser"))
menu.add_command(label="Text editor", command=lambda: launch("mousepad") if shutil.which("mousepad") else launch("xterm", "-e", "nano"))
menu.add_separator()
menu.add_command(label="Graphics diagnostics", command=lambda: launch("xterm", "-e", "identos-graphics-check"))
menu.add_command(label="Log out", command=root.destroy)

def show_menu():
    try:
        menu.tk_popup(root.winfo_rootx() + 8, root.winfo_rooty() - 210)
    finally:
        menu.grab_release()

action("◆  IDENT", show_menu)
action("Terminal", lambda: launch("xterm"))
action("Files", lambda: launch("pcmanfm"))
action("Browser", lambda: launch("identos-browser"))

clock = tk.Label(bar, bg=PANEL, fg=TEXT, padx=20, font=("DejaVu Sans", 10))
clock.pack(side="right")
def tick():
    clock.config(text=datetime.now().strftime("%a %d %b  %H:%M"))
    root.after(1000, tick)

def layout(event=None):
    width = root.winfo_screenwidth()
    height = root.winfo_screenheight()
    root.geometry(f"{width}x44+0+{height-44}")

root.bind("<Configure>", lambda event: None)
layout()
tick()
root.mainloop()
