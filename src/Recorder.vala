
public class Recorder : Object {
    public signal void throw_error (Error err, string debug);
    public signal void save_file (string tmp_full_path, string suffix);

    public bool is_recording { get; private set; }
    public string station_name;
    private PulseAudioManager pam;
    private string full_path;
    private Gst.Pipeline pipeline;
    private uint inhibit_token = 0;
    private static Recorder _instance;
    public static Recorder get_default () {
        if (_instance == null) {
            _instance = new Recorder ();
        }

        return _instance;
    }

    private Recorder () {
        pam = PulseAudioManager.get_default ();
        pam.start ();
    }

    public void start_recording () throws Gst.ParseError {
        pipeline = new Gst.Pipeline ("pipeline");
        var sink = Gst.ElementFactory.make ("filesink", "sink");

        if (pipeline == null) {
            throw new Gst.ParseError.NO_SUCH_ELEMENT ("Failed to create the GStreamer element \"pipeline\"");
        } else if (sink == null) {
            throw new Gst.ParseError.NO_SUCH_ELEMENT ("Failed to create the GStreamer element \"filesink\"");
        }

        Gst.Element? sys_sound = Gst.ElementFactory.make ("pulsesrc", "sys_sound");
            if (sys_sound == null) {
                throw new Gst.ParseError.NO_SUCH_ELEMENT ("Failed to create the GStreamer pulsesrc element \"sys_sound\"");
            }

        string default_monitor = pam.default_sink_name + ".monitor";
        sys_sound.set ("device", default_monitor);
        debug ("Set system sound source device to \"%s\"", default_monitor);

        Gst.Element encoder = Gst.ElementFactory.make ("lamemp3enc", "encoder");
        Gst.Element? muxer = null;

        if (encoder == null) {
            throw new Gst.ParseError.NO_SUCH_ELEMENT ("Failed to create the GStreamer element \"encoder\"");
        }

        string filename = station_name + "  " + date_time();
        full_path = Environment.get_user_data_dir () + "/%s%s".printf (filename, ".mp3");
        sink.set ("location", full_path);
        debug ("The recording is temporary stored at %s", full_path);

        var caps_filter = Gst.ElementFactory.make ("capsfilter", "filter");
        caps_filter.set ("caps", new Gst.Caps.simple (
                            "audio/x-raw", "channels", Type.INT, 2));
        pipeline.add_many (caps_filter, encoder, sink);
        pipeline.add_many (sys_sound);
        sys_sound.link_many (caps_filter, encoder);

        if (muxer != null) {
            pipeline.add (muxer);
            encoder.get_static_pad ("src").link (muxer.request_pad_simple ("audio_%u"));
            muxer.link (sink);
        } else {
            encoder.link (sink);
        }

        pipeline.get_bus ().add_watch (Priority.DEFAULT, bus_message_cb);
        set_recording_state (Gst.State.PLAYING);
        inhibit_sleep ();
    }
    
    private string date_time(){
        var now = new DateTime.now_local ();
        return now.format("%d")+"."+now.format("%m")+"."+now.format("%Y")+"  "+now.format("%H")+":"+now.format("%M")+":"+now.format("%S");
   }

    private bool bus_message_cb (Gst.Bus bus, Gst.Message msg) {
        switch (msg.type) {
            case Gst.MessageType.ERROR:
                cancel_recording ();

                Error err;
                string debug;
                msg.parse_error (out err, out debug);

                throw_error (err, debug);
                break;
            case Gst.MessageType.EOS:
                set_recording_state (Gst.State.NULL);
                pipeline.dispose ();
                save_file (full_path, ".mp3");
                break;
            default:
                break;
        }

        return true;
    }

    public void cancel_recording () {
        uninhibit_sleep ();
        set_recording_state (Gst.State.NULL);
        pipeline.dispose ();

        try {
            File.new_for_path (full_path).delete ();
        } catch (Error e) {
            warning (e.message);
        }
    }

    public void stop_recording () {
        uninhibit_sleep ();
        pipeline.send_event (new Gst.Event.eos ());
    }

    public void set_recording_state (Gst.State state) {
        pipeline.set_state (state);

        switch (state) {
            case Gst.State.PLAYING:
                is_recording = true;
                break;
            case Gst.State.PAUSED:
            case Gst.State.NULL:
                is_recording = false;
                break;
            default:
                assert_not_reached ();
        }
    }

    private void inhibit_sleep () {
        unowned Gtk.Application app = (Gtk.Application) GLib.Application.get_default ();
        if (inhibit_token != 0) {
            app.uninhibit (inhibit_token);
        }

        inhibit_token = app.inhibit (
            app.get_active_window (),
            Gtk.ApplicationInhibitFlags.IDLE | Gtk.ApplicationInhibitFlags.SUSPEND,
            _("Recording is ongoing")
        );
    }

    private void uninhibit_sleep () {
        if (inhibit_token != 0) {
            ((Gtk.Application) GLib.Application.get_default ()).uninhibit (inhibit_token);
            inhibit_token = 0;
        }
    }
}
