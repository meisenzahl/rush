public class Application : Gtk.Application {
    public static GLib.Settings settings;
    Pomodoro.Service ps;
    Unity.LauncherEntry launcher;
    Cancellable? cancellable;
    Service.EventSound clock_finished_sound = new Service.EventSound ("alarm-clock-elapsed", _("Alarm done"));

    public Application () {
        Object (application_id: "com.github.naaando.rush",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE);
        settings = new Settings ("com.github.naaando.rush");

        ps = new Pomodoro.Service ();
        ps.start.connect (on_pomodoro_start);
        ps.stop.connect (on_pomodoro_stop);

        launcher = Unity.LauncherEntry.get_for_desktop_id (application_id+".desktop");

        settings.bind ("interval-work", ps, "work-interval", SettingsBindFlags.DEFAULT);
        settings.bind ("interval-break", ps, "short-break-interval", SettingsBindFlags.DEFAULT);
        settings.bind ("interval-long-break", ps, "long-break-interval", SettingsBindFlags.DEFAULT);
        settings.bind ("normal-breaks-before-long-break", ps, "normal-breaks-before-long-break", SettingsBindFlags.DEFAULT);

        add_actions ();
        command_line.connect (handle_command_line);
    }

    private void add_actions () {
        var pomodoro_start_next = new SimpleAction ("pomodoro-start-next", null);
        pomodoro_start_next.activate.connect (() => ps.start_next ());
        add_action (pomodoro_start_next);

        var pomodoro_start_work = new SimpleAction ("pomodoro-start-work", null);
        pomodoro_start_work.activate.connect (() => ps.start_work ());
        add_action (pomodoro_start_work);

        var pomodoro_start_break = new SimpleAction ("pomodoro-start-break", null);
        pomodoro_start_break.activate.connect (() => ps.start_short_break ());
        add_action (pomodoro_start_break);

        var pomodoro_start_long_break = new SimpleAction ("pomodoro-start-long-break", null);
        pomodoro_start_long_break.activate.connect (() => ps.start_long_break ());
        add_action (pomodoro_start_long_break);
    }

    protected override void activate () {
        if (get_windows ().length () > 0) {
            get_windows ().data.present ();
            return;
        }

        load_custom_css ();

        var vf = new ViewFactory (ps);
        var main_window = vf.create_main_window (this);
        main_window.show_all ();
    }

    int handle_command_line (ApplicationCommandLine command_line) {
        string[] args = command_line.get_arguments ();

        switch (args[1]) {
            case "--work":
                activate_action ("pomodoro-start-work", null);
                break;
            case "--break":
                activate_action ("pomodoro-start-break", null);
                break;
            case "--long-break":
                activate_action ("pomodoro-start-long-break", null);
                break;
            default:
                activate ();
                break;
        }

        return 0;
    }

    void on_pomodoro_start () {
        launcher.progress_visible = true;

        cancellable = new Cancellable ();
        Timeout.add (500, () => {
            if (ps.timer != null) {
                double completeness = (double) ps.timer.get_elapsed_time () / ps.timer.get_total_time ();
                launcher.progress = completeness;
            }
            return !cancellable.is_cancelled ();
        });

        clock_finished_sound.stop ();
    }

    void on_pomodoro_stop () {
        cancellable.cancel ();
        launcher.progress_visible = false;

        var notification = new Notification (@"$(ps.current_pomodoro.state) has ended.");
        notification.add_button (_("Next"), "app.pomodoro-start-next");
        notification.add_button (_("Continue working"), "app.pomodoro-start-work");
        notification.set_default_action ("app.pomodoro-start-next");

        send_notification ("pomodoro-stopped", notification);

        if (settings.get_boolean ("emit-sound")) {
            clock_finished_sound.play ();
        }
    }

    void load_custom_css () {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/naaando/rush/Application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    public static int main(string[] args) {
        return new Application ().run (args);
    }
}
