/* IDENT Desktop 2: GTK3 panel. Openbox remains the window manager. */
#include <gtk/gtk.h>
#include <glib/gstdio.h>
#include <string.h>
#include <sys/stat.h>

typedef struct {
    GtkWidget *window, *clock;
    gboolean clock24;
    int height;
} Desktop;

static const gchar *const commands[][4] = {
    {"xterm", NULL},
    {"pcmanfm", NULL},
    {"identos-browser", NULL},
    {"rofi", "-show", "drun"},
    {"rofi", "-show", "window"},
    {"xterm", "-e", "identos-graphics-check"}
};
static const char *const labels[] = {"Terminal", "Files", "Browser", "Applications", "Windows", "Diagnostics"};

static gchar *settings_file(void) {
    return g_build_filename(g_get_user_config_dir(), "identos", "desktop2.ini", NULL);
}
static void load_settings(Desktop *desktop) {
    g_autofree gchar *path = settings_file();
    g_autoptr(GKeyFile) key = g_key_file_new();
    desktop->clock24 = TRUE;
    desktop->height = 48;
    if (g_key_file_load_from_file(key, path, G_KEY_FILE_NONE, NULL)) {
        if (g_key_file_has_key(key, "Panel", "Clock24", NULL))
            desktop->clock24 = g_key_file_get_boolean(key, "Panel", "Clock24", NULL);
        if (g_key_file_has_key(key, "Panel", "Height", NULL)) {
            int height = g_key_file_get_integer(key, "Panel", "Height", NULL);
            if (height >= 36 && height <= 96) desktop->height = height;
        }
    }
}
static gboolean save_settings(Desktop *desktop, GError **error) {
    g_autofree gchar *path = settings_file();
    g_autofree gchar *dir = g_path_get_dirname(path);
    g_autoptr(GKeyFile) key = g_key_file_new();
    g_key_file_set_boolean(key, "Panel", "Clock24", desktop->clock24);
    g_key_file_set_integer(key, "Panel", "Height", desktop->height);
    if (g_mkdir_with_parents(dir, 0700) != 0) {
        g_set_error_literal(error, G_FILE_ERROR, G_FILE_ERROR_ACCES, "Cannot create settings directory");
        return FALSE;
    }
    g_autofree gchar *contents = g_key_file_to_data(key, NULL, error);
    if (!contents) return FALSE;
    g_autofree gchar *tmp = g_strconcat(path, ".tmp", NULL);
    if (!g_file_set_contents(tmp, contents, -1, error)) return FALSE;
    if (g_chmod(tmp, 0600) != 0 || g_rename(tmp, path) != 0) {
        g_unlink(tmp);
        g_set_error_literal(error, G_FILE_ERROR, G_FILE_ERROR_FAILED, "Cannot replace settings file");
        return FALSE;
    }
    return TRUE;
}
static gboolean launch(int action) {
    if (action < 0 || action >= (int)G_N_ELEMENTS(commands)) return FALSE;
    g_autofree gchar *executable = g_find_program_in_path(commands[action][0]);
    if (!executable) return FALSE;
    GError *error = NULL;
    gboolean ok = g_spawn_async(NULL, (gchar **)commands[action], NULL,
                                 G_SPAWN_SEARCH_PATH | G_SPAWN_DO_NOT_REAP_CHILD,
                                 NULL, NULL, NULL, &error);
    if (!ok) {
        g_warning("Launch failed: %s", error->message);
        g_clear_error(&error);
    }
    return ok;
}
static void on_launch(GtkWidget *widget, gpointer user_data) {
    int action = GPOINTER_TO_INT(user_data) - 1;
    if (!launch(action)) g_warning("Application unavailable: %s", labels[action]);
    (void)widget;
}
static gboolean update_clock(gpointer data) {
    Desktop *desktop = data;
    GDateTime *now = g_date_time_new_now_local();
    gchar *label = g_date_time_format(now, desktop->clock24 ? "%a %d %b  %H:%M" : "%a %d %b  %I:%M %p");
    gtk_label_set_text(GTK_LABEL(desktop->clock), label);
    g_free(label);
    g_date_time_unref(now);
    return G_SOURCE_CONTINUE;
}
static void resize_panel(Desktop *desktop) {
    GdkScreen *screen = gtk_window_get_screen(GTK_WINDOW(desktop->window));
    int w = gdk_screen_get_width(screen), h = gdk_screen_get_height(screen);
    gtk_window_move(GTK_WINDOW(desktop->window), 0, h - desktop->height);
    gtk_window_resize(GTK_WINDOW(desktop->window), w, desktop->height);
}
static void on_settings(GtkWidget *widget, gpointer data) {
    Desktop *desktop = data;
    GtkWidget *dialog = gtk_dialog_new_with_buttons("IDENT Settings", GTK_WINDOW(desktop->window),
                                  GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
                                  "_Cancel", GTK_RESPONSE_CANCEL, "_Save", GTK_RESPONSE_ACCEPT, NULL);
    GtkWidget *box = gtk_dialog_get_content_area(GTK_DIALOG(dialog));
    GtkWidget *clock = gtk_check_button_new_with_label("24-hour clock");
    GtkWidget *height = gtk_scale_new_with_range(GTK_ORIENTATION_HORIZONTAL, 36, 96, 1);
    gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(clock), desktop->clock24);
    gtk_range_set_value(GTK_RANGE(height), desktop->height);
    gtk_box_pack_start(GTK_BOX(box), clock, FALSE, FALSE, 8);
    gtk_box_pack_start(GTK_BOX(box), height, FALSE, FALSE, 8);
    gtk_widget_show_all(dialog);
    if (gtk_dialog_run(GTK_DIALOG(dialog)) == GTK_RESPONSE_ACCEPT) {
        desktop->clock24 = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(clock));
        desktop->height = (int)gtk_range_get_value(GTK_RANGE(height));
        GError *error = NULL;
        if (!save_settings(desktop, &error)) {
            g_warning("Settings not saved: %s", error->message);
            g_clear_error(&error);
        }
        resize_panel(desktop);
        update_clock(desktop);
    }
    gtk_widget_destroy(dialog);
    (void)widget;
}
static void on_logout(GtkWidget *widget, gpointer data) { (void)widget; (void)data; gtk_main_quit(); }
static void on_menu(GtkWidget *widget, gpointer data) {
    Desktop *desktop = data;
    GtkWidget *menu = gtk_menu_new();
    for (int i = 0; i < (int)G_N_ELEMENTS(commands); ++i) {
        GtkWidget *item = gtk_menu_item_new_with_label(labels[i]);
        g_signal_connect(item, "activate", G_CALLBACK(on_launch), GINT_TO_POINTER(i + 1));
        gtk_menu_shell_append(GTK_MENU_SHELL(menu), item);
    }
    GtkWidget *settings = gtk_menu_item_new_with_label("Settings");
    g_signal_connect(settings, "activate", G_CALLBACK(on_settings), desktop);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), settings);
    GtkWidget *logout = gtk_menu_item_new_with_label("Log out");
    g_signal_connect(logout, "activate", G_CALLBACK(on_logout), NULL);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), logout);
    gtk_widget_show_all(menu);
    gtk_menu_popup_at_widget(GTK_MENU(menu), widget, GDK_GRAVITY_NORTH_WEST, GDK_GRAVITY_SOUTH_WEST, NULL);
}
int main(int argc, char **argv) {
    if (argc == 2 && strcmp(argv[1], "--self-test") == 0) {
        Desktop desktop = {0};
        load_settings(&desktop);
        if (desktop.height < 36 || desktop.height > 96) return 1;
        if (launch(-1)) return 2;
        g_print("PASS: IDENT Desktop 2 C settings and command policy\n");
        return 0;
    }
    gtk_init(&argc, &argv);
    Desktop desktop = {0};
    load_settings(&desktop);
    desktop.window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(desktop.window), "IDENT Desktop 2");
    gtk_window_set_decorated(GTK_WINDOW(desktop.window), FALSE);
    gtk_window_set_keep_above(GTK_WINDOW(desktop.window), TRUE);
    gtk_window_set_skip_taskbar_hint(GTK_WINDOW(desktop.window), TRUE);
    GtkWidget *bar = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 4);
    gtk_container_add(GTK_CONTAINER(desktop.window), bar);
    GtkWidget *menu = gtk_button_new_with_label("◆ IDENT");
    g_signal_connect(menu, "clicked", G_CALLBACK(on_menu), &desktop);
    gtk_box_pack_start(GTK_BOX(bar), menu, FALSE, FALSE, 4);
    for (int i = 0; i < 5; ++i) {
        GtkWidget *button = gtk_button_new_with_label(labels[i]);
        g_signal_connect(button, "clicked", G_CALLBACK(on_launch), GINT_TO_POINTER(i + 1));
        gtk_box_pack_start(GTK_BOX(bar), button, FALSE, FALSE, 2);
    }
    desktop.clock = gtk_label_new("");
    gtk_box_pack_end(GTK_BOX(bar), desktop.clock, FALSE, FALSE, 12);
    g_signal_connect(desktop.window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    gtk_widget_show_all(desktop.window);
    resize_panel(&desktop);
    update_clock(&desktop);
    g_timeout_add_seconds(1, update_clock, &desktop);
    gtk_main();
    return 0;
}
